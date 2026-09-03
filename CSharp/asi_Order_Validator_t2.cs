// asi_Order_Validator_t2.cs
//
// Replaces kb_Order_Validator_v2 + dbo.kb_fnt_br_order_validator_v2.
//
// This file is the ADAPTER only: it reads the DataWindow, resolves reference data against
// native P21 objects, hands both to OrderValidationEngine, and logs. All decision logic
// lives in OrderValidationEngine.cs, which has no P21 dependency and is unit-tested by
// ValidatorHarness against the 23 cases in Capture-OldValidator-Matrix.sql.
//
// WHY: custom stored procedures / functions / table types are being retired. Every lookup
// below is a parameterized SELECT over NATIVE P21 tables and views on the framework-owned
// P21SqlConnection, batched into one round trip.
//
// RETIRED BY THIS RULE:
//   dbo.kb_fnt_br_order_validator_v2        -> OrderValidationEngine.Validate()
//   dbo.kb_fnt_br_shipto_info               -> SqlFreightCharge (no full-scan guard)
//   dbo.kb_view_carrier                     -> p21_view_address + address_ud, carrier_flag='Y'
//   dbo.kb_view_item_classifications_loc100 -> inv_mast + product_group (SqlCountedItems)
//   dbo.kb_fn_number_shorten                -> OrderValidationEngine.NumberShorten()
//   dbo.kb_table_required_date_statuses     -> OrderValidationEngine.RequiredDateStatuses
//   dbo.kb_TableTypeItemsOnOrder            -> dropped (no TVPs)
//   dbo.kb_TableTypeFourStrings             -> dropped (no TVPs)
//   dbo.kb_table_inbound_fuel_surcharge     -> dropped (dead path only)
//   dbo.kb_view_customer                    -> dropped (dead path only)
//   rewards_program (native, but unused)    -> dropped (dead path only)
//
// No kb_ or js_ object is referenced by any executable line in this file.
//
// Targets C# 7.3 (P21 constraint). No C# 8+ syntax.

using Atlas.CrownSurcharge5011348;
using Atlas.CrownSurcharge5011348.SurchargeValidation;
using P21.Extensions.BusinessRule;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Linq;
using System.Text;
using asi_OrderValidator;          // OrderValidationEngine + its POCOs

namespace asi_OrderValidator_t2
{
    public class asi_Order_Validator_t2 : P21.Extensions.BusinessRule.Rule
    {
        // Was: reflection over MethodBase.GetCurrentMethod(), which stripped underscores and
        // yielded "kbOrderValidatorv2" -- a name that matched nothing. nameof() is compile-time
        // and survives a rename, matching the other asi_ rules.
        private const string RuleNameConst = nameof(asi_Order_Validator_t2);
        private const string SupportEmail = "ITSupport@allsurfaces.com";

        #region SQL -- native P21 objects only

        // @freight_auto_adds + @freight_code_name
        private const string SqlFreightCode = @"
SELECT ISNULL(outgoing_freight,'N') AS auto_adds,
       ISNULL(freight_desc,'')      AS freight_desc
FROM   p21_view_freight_code
WHERE  row_status = 704 AND freight_code_uid = @freight_code_uid;";

        // @wc -- inlines kb_view_carrier (p21_view_address + address_ud, carrier_flag='Y').
        // [PRESERVED-BUG] The original was a scalar subquery matched on a NON-UNIQUE name:
        // two carriers sharing a name threw "Subquery returned more than 1 value" and the
        // catch swallowed it into a save. TOP 1 cannot throw, but a NOT-FOUND carrier still
        // yields NULL (not 'N'), which is the original's fail-open. Kept.
        private const string SqlCarrierWillCall = @"
SELECT TOP 1 COALESCE(ud.will_call,'N') AS will_call
FROM   p21_view_address a
LEFT   JOIN address_ud ud ON ud.id = a.id
WHERE  a.carrier_flag = 'Y' AND a.name = @carrier_name
ORDER BY a.id;";

        // @default_carrier. NOTE: the original does NOT filter ship-to delete_flag here,
        // unlike SqlFreightCharge below. That divergence is real -- preserved.
        private const string SqlDefaultCarrier = @"
SELECT dc.name AS default_carrier_name
FROM   p21_view_ship_to st
LEFT   JOIN p21_view_address dc
       ON dc.id = st.default_carrier_id AND dc.carrier_flag = 'Y'
WHERE  st.ship_to_id = @ship_to_id;";

        // @freight_charge -- replaces dbo.kb_fnt_br_shipto_info's val_freight column.
        // The original TVF opened with
        //     IF @shipto_id NOT IN (SELECT ship_to_id FROM p21_view_ship_to WHERE delete_flag='N')
        // a FULL SCAN of the ship-to view on every call purely to test existence. That was the
        // 774-logical-reads-per-call cost ranked #1 in Recommended-P21-Performance-Fixes.md.
        // Two index seeks now. No row here == the TVF's not-found branch (val_freight NULL).
        private const string SqlFreightCharge = @"
SELECT ISNULL(fcb.[value], 0) AS val_freight
FROM   p21_view_ship_to st
OUTER  APPLY (SELECT TOP 1 b.[value]
              FROM   p21_view_freight_charge_break b
              WHERE  b.freight_charge_uid = st.freight_charge_uid
              ORDER BY b.freight_charge_break_uid) fcb
WHERE  st.ship_to_id = @ship_to_id AND st.delete_flag = 'N';";

        // Replaces the kb_view_item_classifications_loc100 join behind @order_total and
        // @items_open. Returns the item_ids that COUNT toward those two.
        //
        // Distilled from the view: product_group_id came from
        //     LEFT JOIN product_group pg ON pg.product_group_id = im.default_product_group
        // The "loc100" in its name is an inv_loc join (location_id = 100) supplying prices and
        // costs only -- a LEFT JOIN that filters no rows, so it is not reproduced. The view has
        // no WHERE clause at all and notably does NOT filter im.delete_flag, so a soft-deleted
        // item still counts toward the order total. Preserved.
        //
        // The INNER JOIN to product_group is load-bearing: it reproduces the original's
        // referential filter. An inv_mast row whose default_product_group matches no
        // product_group row yielded NULL, and the original's LEFT JOIN + WHERE ... NOT IN
        // ('OCHARGE') then dropped it (a WHERE against the null side demotes a LEFT JOIN to an
        // INNER JOIN, and NULL NOT IN (...) is UNKNOWN either way).
        // [PRESERVED-BUG] Items missing a product group are excluded from the $15k threshold.
        //
        // DISTINCT is a deliberate, safe divergence: the original join could multiply an order
        // line if inv_mast held duplicate item_ids, double-counting extended_price. The engine
        // sums each line once regardless. Confirm duplicates don't exist:
        //   SELECT item_id, COUNT(*) FROM inv_mast GROUP BY item_id HAVING COUNT(*) > 1;
        private const string SqlCountedItems = @"
SELECT DISTINCT im.item_id
FROM   inv_mast im
JOIN   product_group pg ON pg.product_group_id = im.default_product_group
WHERE  pg.product_group_id NOT IN ('OCHARGE')
  AND  im.item_id IN ({0});";

        private const string SqlLogError = @"
INSERT INTO business_rule_log
    (user_id, log_action, rule_name, rule_assembly_name, run_type,
     return_value, return_message,
     date_created, created_by, date_last_modified, last_maintained_by)
VALUES
    (@User, 'Error', @Rule, @Asm, 'Synchronous (Internal)',
     'Failure', @Msg,
     GETDATE(), @User, GETDATE(), @User);";

        // Records a blocked save (the popup the user saw). Distinct log_action so these never
        // pollute the 'Error' queries: log_action = 'Error' means the rule broke,
        // 'Validation' means the rule worked and stopped someone.
        //
        // business_rule_log has no order-number column, so the order is embedded in
        // return_message behind a fixed delimiter that the baseline harness splits on.
        // Keep BlockMessageDelimiter and the harness's CHARINDEX in step.
        private const string SqlLogValidation = @"
INSERT INTO business_rule_log
    (user_id, log_action, rule_name, rule_assembly_name, run_type,
     return_value, return_message,
     date_created, created_by, date_last_modified, last_maintained_by)
VALUES
    (@User, 'Validation', @Rule, @Asm, 'Synchronous (Internal)',
     'Failure', @Msg,
     GETDATE(), @User, GETDATE(), @User);";

        internal const string BlockMessageDelimiter = " :: ";

        private const int ReferenceCommandTimeoutSeconds = 30;

        #endregion

        public override string GetName()
        {
            return nameof(asi_Order_Validator_t2);
        }

        public override string GetDescription()
        {
            return "Validates orders before save and blocks orders with bad data. " +
                   "All checks are native C#; reference lookups hit native P21 views only.";
        }

        public override RuleResult Execute()
        {
            var result = new RuleResult();
            result.Success = true;

            string stage = "Initializing";
            string orderNo = "n/a";

            try
            {
                stage = "Reading order header";
                DataRow hdr = FirstRow("d_oe_header");
                if (hdr == null)
                {
                    LogRuleError("d_oe_header was missing or empty; validation skipped.");
                    return result;
                }
                orderNo = Str(hdr, "order_no") ?? "n/a";

                // Skip conditions FIRST -- the old rule built 40+ DataTable columns before
                // reaching this check and threw them away on every RMA/quote/cancelled save.
                stage = "Evaluating skip conditions";
                if (IsYes(hdr, "rma_flag") || IsYes(hdr, "quote") || IsYes(hdr, "cancel_flag"))
                    return result;

                stage = "Reading order lines";
                DataTable lineTable = Table("d_dw_oe_line_dataentry");
                if (lineTable == null || lineTable.Rows.Count == 0)
                {
                    LogRuleError("Order Lines table was empty or not present for order # " +
                                 orderNo + ", so the business rule failed.");
                    return result;
                }

                stage = "Building the order snapshot";
                OrderSnapshot snap = BuildSnapshot(hdr, lineTable);

                // A partial DataSet is not a bad order. If the DataWindow does not carry the
                // precursor fields, this rule has no basis to judge and MUST NOT block --
                // blocking would accuse the user of leaving a field blank that they actually
                // filled in (order 6108922: freight code WILL CALL on screen, reported blank).
                // Log loudly and let the save through, which is also what the old rule did,
                // though only by accident via an unhandled NullReferenceException.
                if (snap.MissingColumns.Count > 0)
                {
                    LogRuleError("Order# " + orderNo + ": validation SKIPPED -- d_oe_header/" +
                                 "d_dw_oe_hdr_shipinfo/d_oe_hdr_credit did not carry: " +
                                 string.Join(", ", snap.MissingColumns.ToArray()) +
                                 ". The save was allowed. This is a rule-binding problem, not " +
                                 "an order problem.");
                    LogFieldDiagnostic(hdr);
                    return result;
                }

                stage = "Applying the inbound fuel surcharge toggle";
                ApplyFuelSurchargeToggle(hdr, snap);

                // The old rule short-circuited on num2 > 0 before calling SQL. Same gate.
                if (snap.QualifyingOpenLineCount == 0)
                    return result;

                stage = "Loading reference data";
                ReferenceData reference = LoadReferenceData(snap);

                stage = "Running validation checks";
                ValidationOutcome outcome = OrderValidationEngine.Validate(snap, reference);

                // Verdict BEFORE message formatting. The old rule set Message first and Success
                // second; anything throwing between the two (Regex.Unescape on a stray
                // backslash, a NULL success_bool) returned Success = true and let a rejected
                // order save.
                if (!outcome.Passed)
                    result.Success = false;
                if (!string.IsNullOrEmpty(outcome.Message))
                    result.Message = outcome.Message;

                // Persist the popup. Best-effort, like LogRuleError -- a logging failure must
                // never turn a blocked save into a saved one.
                if (!outcome.Passed)
                    LogValidationBlock(orderNo, outcome.Message);

                // atlas_surcharge_on was hardcoded 'Y' in the TVF and never reassigned, so this
                // path always ran. Unconditional now; the dead flag is gone.
                stage = "Running the Atlas surcharge validation";
                ApplyAtlasSurcharge(result, outcome.Message);

                return result;
            }
            catch (Exception ex)
            {
                // orderNo is a local captured early -- the old catch re-read
                // Data.Set.Tables["d_oe_header"].Rows[0], so a missing header made the error
                // handler itself throw, which escapes a P21 rule uncatchably.
                LogRuleError(stage + " for order# " + orderNo + "." + Environment.NewLine + ex);
                result.Message = "The " + RuleNameConst + " business rule hit an error while " +
                                 stage + "." + Environment.NewLine + Environment.NewLine +
                                 "This error has been logged. If you continue to get it, please contact " +
                                 SupportEmail + ".";
                // Fail-open on internal errors is the documented, intended behavior (TEST-PLAN A8).
                return result;
            }
        }

        #region Snapshot -- DataWindow -> engine input

        private OrderSnapshot BuildSnapshot(DataRow hdr, DataTable lineTable)
        {
            var snap = new OrderSnapshot();
            snap.OrderNo = Str(hdr, "order_no");
            snap.DateCreated = Dt(hdr, "date_created");
            snap.RequestedDate = Dt(hdr, "requested_date");

            // Precursor fields are recorded as MISSING when the column is absent, which is
            // NOT the same as present-but-null. A null value is a blank the user must fix;
            // an absent column means this DataSet cannot answer the question.
            //
            // CORRECTION 2026-09-03: an earlier version of this comment cited order 6108922 as
            // proof that P21 hands out partial DataSets on its own. That was wrong. The DataSet
            // was short because BRR's business_rule_data_element list had been truncated (114/11
            // -> 74/3) by a Rule Manager save -- not because the save context omits DataWindows.
            // A missing table here means the REGISTRATION is broken, which is why MissingColumns
            // fails open with a loud "rule-binding problem, not an order problem" message rather
            // than blocking. Do not treat a partial DataSet as normal; it is always a bug to fix
            // in business_rule_data_element.
            snap.FreightCodeUid = Int(hdr, "freight_code_uid", snap);
            // NOTE: the d_oe_header DataWindow exposes this as ship_to_id; the underlying
            // oe_hdr column is address_id. The DataWindow name is correct here.
            snap.ShipToId = Dec(hdr, "ship_to_id", snap);
            snap.CustomerId = Dec(hdr, "customer_id", snap);
            snap.PackingBasis = Str(hdr, "packing_basis", snap);
            // The DataWindow hands over the code DESCRIPTION ('OE', 'CUO Entry'), not the raw
            // int in oe_hdr.order_type. Confirmed 2026-09-01 via code group 1215.
            snap.OrderType = Str(hdr, "order_type");

            DataRow shipInfo = FirstRow("d_dw_oe_hdr_shipinfo");
            if (shipInfo == null)
                snap.MissingColumns.Add("d_dw_oe_hdr_shipinfo (table absent)");
            else
                snap.CarrierName = Str(shipInfo, "oe_hdr_carrier_id", snap);

            DataRow credit = FirstRow("d_oe_hdr_credit");
            if (credit == null)
                snap.MissingColumns.Add("d_oe_hdr_credit (table absent)");
            else
                snap.CreditStatus = Str(credit, "credit_status", snap);

            foreach (DataRow row in lineTable.Rows)
            {
                if (IsYes(row, "delete_flag")) continue;
                string itemId = Str(row, "oe_order_item_id");
                if (itemId == null) continue;

                // The old code derived qty_open from canceled/invoiced when qty_ordered was
                // NULL, but that branch could only ever produce <= 0, so the line never
                // qualified and qty_open was reset to 0 anyway. Collapsed.
                decimal qtyOpen = Dec(row, "qty_ordered") ?? 0m;

                bool qualifies = qtyOpen > 0m
                                 && !IsYes(row, "oe_line_complete")
                                 && !OrderValidationEngine.IsEqual(Str(row, "product_type"), "B");

                decimal? extPrice = Dec(row, "extended_price");

                if (qualifies)
                {
                    snap.QualifyingOpenLineCount++;
                    if (OrderValidationEngine.IsEqual(itemId, OrderValidationEngine.FuelSurchargeItemId))
                        snap.FuelSurchargeExtendedTotal += extPrice ?? 0m;
                }
                else
                {
                    qtyOpen = 0m;   // matches the old TVP's qty_open reset
                }

                snap.Lines.Add(new OrderLine
                {
                    ItemId = itemId,
                    QtyOpen = qtyOpen,
                    ExtendedPrice = extPrice
                });
            }

            DataTable notes = Table("d_dw_oe_hdr_notepad_dataentry");
            if (notes != null)
            {
                foreach (DataRow row in notes.Rows)
                {
                    if (IsYes(row, "delete_flag")) continue;
                    string topic = Str(row, "topic");
                    if (topic == null) continue;

                    if (OrderValidationEngine.IsEqual(topic, OrderValidationEngine.TopicFreightQuote)
                        && IsYes(row, "mandatory"))
                        snap.FreightQuoteNotePresent = true;
                    if (OrderValidationEngine.IsEqual(topic, OrderValidationEngine.TopicSignatureRequired))
                        snap.SignatureNotePresent = true;
                }
            }

            return snap;
        }

        // Unchanged behavior: keeps the header UD surcharge flag in step with the presence of
        // INBOUND FUEL SURCHARGE dollars on qualifying lines.
        private void ApplyFuelSurchargeToggle(DataRow hdr, OrderSnapshot snap)
        {
            if (snap.QualifyingOpenLineCount <= 0) return;

            string current = Str(hdr, "ufc_oe_hdr_ud_oe_surcharge");
            if (snap.FuelSurchargeExtendedTotal == 0m && OrderValidationEngine.IsEqual(current, "Y"))
                hdr.SetField("ufc_oe_hdr_ud_oe_surcharge", "N");
            else if (snap.FuelSurchargeExtendedTotal != 0m && OrderValidationEngine.IsEqual(current, "N"))
                hdr.SetField("ufc_oe_hdr_ud_oe_surcharge", "Y");
        }

        #endregion

        #region Reference data -- native lookups

        private ReferenceData LoadReferenceData(OrderSnapshot snap)
        {
            var reference = new ReferenceData();

            List<string> itemIds = snap.Lines
                .Select(l => l.ItemId)
                .Where(id => !string.IsNullOrEmpty(id))
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            var batch = new StringBuilder();
            batch.Append(SqlFreightCode);
            batch.Append(SqlCarrierWillCall);
            batch.Append(SqlDefaultCarrier);
            batch.Append(SqlFreightCharge);

            string itemParamList = null;
            if (itemIds.Count > 0)
            {
                itemParamList = string.Join(",",
                    Enumerable.Range(0, itemIds.Count)
                              .Select(i => "@item" + i.ToString(CultureInfo.InvariantCulture)));
                batch.Append(string.Format(CultureInfo.InvariantCulture, SqlCountedItems, itemParamList));
            }

            using (var cmd = new SqlCommand(batch.ToString(), P21SqlConnection))
            {
                cmd.CommandTimeout = ReferenceCommandTimeoutSeconds;

                AddInt(cmd, "@freight_code_uid", snap.FreightCodeUid);
                AddVarChar(cmd, "@carrier_name", snap.CarrierName, 255);
                // Explicit precision/scale. The old rule passed SqlDbType.Decimal with a *size*
                // of 19, which is meaningless for decimal and left scale to inference.
                AddDecimal(cmd, "@ship_to_id", snap.ShipToId, 19, 0);

                for (int i = 0; i < itemIds.Count; i++)
                    AddVarChar(cmd, "@item" + i.ToString(CultureInfo.InvariantCulture), itemIds[i], 40);

                using (SqlDataReader reader = cmd.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        reference.FreightAutoAdds = reader.IsDBNull(0) ? "N" : reader.GetString(0);
                        reference.FreightCodeName = reader.IsDBNull(1) ? string.Empty : reader.GetString(1);
                    }

                    reader.NextResult();
                    if (reader.Read() && !reader.IsDBNull(0))
                        reference.CarrierWillCall = reader.GetString(0);

                    reader.NextResult();
                    if (reader.Read() && !reader.IsDBNull(0))
                        reference.DefaultCarrierName = reader.GetString(0);

                    reader.NextResult();
                    if (reader.Read() && !reader.IsDBNull(0))
                        reference.FreightCharge = reader.GetDecimal(0);

                    if (itemParamList != null)
                    {
                        reader.NextResult();
                        while (reader.Read())
                            if (!reader.IsDBNull(0))
                                reference.CountedItemIds.Add(reader.GetString(0));
                    }
                }
            }

            reference.FreightCodeName =
                OrderValidationEngine.StripBackslashes(reference.FreightCodeName);
            reference.DefaultCarrierName =
                OrderValidationEngine.StripBackslashes(reference.DefaultCarrierName ?? "Will Call");

            return reference;
        }

        #endregion

        #region Atlas surcharge

        private void ApplyAtlasSurcharge(RuleResult result, string existingMessage)
        {
            P21Context context = Utility.GetP21Context(RuleState.TriggerWindowTitle);
            SurchargeValidationResult atlas = Surcharge.Validate(new SurchargeValidationRequest
            {
                Data = Data,
                Session = Session,
                RuleName = GetName(),
                P21Context = context,
                RuleState = RuleState,
                RuleXmlData = XmlData
            });

            if (!atlas.Success)
                result.Success = false;

            if (string.IsNullOrEmpty(atlas.Message))
                return;

            result.Message = string.IsNullOrEmpty(existingMessage)
                ? atlas.Message
                : atlas.Message + "\r\n\r\n" + existingMessage;
        }

        #endregion

        #region DataSet / SQL helpers

        private DataTable Table(string name)
        {
            if (Data == null || Data.Set == null) return null;
            return Data.Set.Tables[name];
        }

        private DataRow FirstRow(string name)
        {
            DataTable t = Table(name);
            return (t == null || t.Rows.Count == 0) ? null : t.Rows[0];
        }

        private static bool HasColumn(DataRow row, string column)
        {
            return row != null && row.Table.Columns.Contains(column);
        }

        private static string Str(DataRow row, string column)
        {
            if (!HasColumn(row, column) || row.IsNull(column)) return null;
            return row.Field<string>(column);
        }

        private static decimal? Dec(DataRow row, string column)
        {
            if (!HasColumn(row, column) || row.IsNull(column)) return null;
            // Convert.To* rather than Field<decimal?>: DataWindow numerics are not reliably
            // the CLR type the column name suggests, and Field<T> throws on a mismatch.
            return Convert.ToDecimal(row[column], CultureInfo.InvariantCulture);
        }

        private static int? Int(DataRow row, string column)
        {
            if (!HasColumn(row, column) || row.IsNull(column)) return null;
            return Convert.ToInt32(row[column], CultureInfo.InvariantCulture);
        }

        // ---- Precursor overloads: record a MISSING column instead of silently nulling ----
        // Present-but-null still returns null (a blank the user must fix). Only an absent
        // column is recorded, and that aborts validation rather than blocking the save.

        private static string Str(DataRow row, string column, OrderSnapshot snap)
        {
            if (!HasColumn(row, column)) { snap.MissingColumns.Add(column); return null; }
            return Str(row, column);
        }

        private static decimal? Dec(DataRow row, string column, OrderSnapshot snap)
        {
            if (!HasColumn(row, column)) { snap.MissingColumns.Add(column); return null; }
            return Dec(row, column);
        }

        private static int? Int(DataRow row, string column, OrderSnapshot snap)
        {
            if (!HasColumn(row, column)) { snap.MissingColumns.Add(column); return null; }
            return Int(row, column);
        }

        private static DateTime? Dt(DataRow row, string column)
        {
            if (!HasColumn(row, column) || row.IsNull(column)) return null;
            return row.Field<DateTime?>(column);
        }

        private static bool IsYes(DataRow row, string column)
        {
            return OrderValidationEngine.IsEqual(Str(row, column), "Y");
        }

        private static void AddVarChar(SqlCommand cmd, string name, string value, int size)
        {
            cmd.Parameters.Add(name, SqlDbType.VarChar, size).Value = (object)value ?? DBNull.Value;
        }

        private static void AddInt(SqlCommand cmd, string name, int? value)
        {
            cmd.Parameters.Add(name, SqlDbType.Int).Value = (object)value ?? DBNull.Value;
        }

        private static void AddDecimal(SqlCommand cmd, string name, decimal? value, byte precision, byte scale)
        {
            SqlParameter p = cmd.Parameters.Add(name, SqlDbType.Decimal);
            p.Precision = precision;
            p.Scale = scale;
            p.Value = (object)value ?? DBNull.Value;
        }

        #endregion

        #region Logging

        private void LogRuleError(string details)
        {
            WriteLog(SqlLogError, details);
        }

        // TEMPORARY DIAGNOSTIC. Reports, for each precursor field, whether d_oe_header even
        // has the column, its CLR type, whether the cell is null, and the raw value -- plus
        // every column whose name mentions freight/carrier/ship, in case the DataWindow uses
        // a different name than the underlying oe_hdr column. Delete once mapping is fixed.
        private void LogFieldDiagnostic(DataRow hdr)
        {
            try
            {
                var sb = new StringBuilder();
                sb.Append("FIELD DIAGNOSTIC d_oe_header: ");

                string[] wanted =
                {
                    "freight_code_uid", "ship_to_id", "customer_id", "packing_basis",
                    "order_type", "requested_date", "date_created", "order_no"
                };

                foreach (string col in wanted)
                {
                    sb.Append(col).Append("=");
                    if (!hdr.Table.Columns.Contains(col))
                    {
                        sb.Append("[NO SUCH COLUMN] ");
                        continue;
                    }
                    DataColumn dc = hdr.Table.Columns[col];
                    object raw = hdr[col];
                    sb.Append("{type=").Append(dc.DataType.Name)
                      .Append(",isnull=").Append(hdr.IsNull(col))
                      .Append(",raw=").Append(raw == null || raw == DBNull.Value ? "<null>" : raw.ToString())
                      .Append("} ");
                }

                sb.Append(" || candidates: ");
                foreach (DataColumn dc in hdr.Table.Columns)
                {
                    string n = dc.ColumnName;
                    if (n.IndexOf("freight", StringComparison.OrdinalIgnoreCase) >= 0
                        || n.IndexOf("carrier", StringComparison.OrdinalIgnoreCase) >= 0
                        || n.IndexOf("ship_to", StringComparison.OrdinalIgnoreCase) >= 0)
                        sb.Append(n).Append("(").Append(dc.DataType.Name).Append(")=")
                          .Append(hdr.IsNull(n) ? "<null>" : hdr[n].ToString()).Append(" ");
                }

                sb.Append(" || tables: ");
                if (Data != null && Data.Set != null)
                    foreach (DataTable t in Data.Set.Tables)
                        sb.Append(t.TableName).Append("(").Append(t.Rows.Count).Append(") ");

                WriteLog(SqlLogError, sb.ToString());
            }
            catch
            {
                // Diagnostic only -- never let it affect the rule.
            }
        }

        private void LogValidationBlock(string orderNo, string message)
        {
            WriteLog(SqlLogValidation,
                "order#" + (orderNo ?? "n/a") + BlockMessageDelimiter + (message ?? string.Empty));
        }

        // Best-effort: a logging failure must never mask the original error, and must never
        // turn a blocked save into a saved one.
        private void WriteLog(string sql, string details)
        {
            try
            {
                using (var cmd = new SqlCommand(sql, P21SqlConnection))
                {
                    string userId = (Session != null && !string.IsNullOrEmpty(Session.UserID))
                        ? Session.UserID
                        : "unknown";

                    AddVarChar(cmd, "@User", userId, 255);
                    AddVarChar(cmd, "@Rule", RuleNameConst, 255);
                    AddVarChar(cmd, "@Asm", GetType().Assembly.GetName().Name, 255);
                    AddVarChar(cmd, "@Msg",
                        details.Length > 8000 ? details.Substring(0, 8000) : details, 8000);

                    cmd.ExecuteNonQuery();
                }
            }
            catch
            {
                // Swallowed by design.
            }
        }

        #endregion
    }
}
