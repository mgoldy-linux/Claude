// asi_Order_Workflow.cs
//
// Replaces kb_Order_Workflow_v2 + dbo.kb_proc_br_oe_hdr_note.
//
// Runs asynchronously AFTER an order is saved. Maintains the "Freight Quote Required"
// header note: adds it when a freight quote is still owed, and clears its mandatory flag
// once the quote has been entered.
//
// RETIRED BY THIS RULE:
//   dbo.kb_proc_br_oe_hdr_note   -> this file
//   dbo.kb_TableTypeItemDec      -> dropped (no TVP; the freight aggregate is one SELECT)
//   dbo.kb_view_customer         -> customer + address corporate-rollup CASE (SqlHeader)
//   dbo.kb_view_carrier          -> p21_view_address + address_ud, carrier_flag='Y'
//
// KEPT ON PURPOSE: dbo.p21_ecc_add_order_header_note is a NATIVE P21 stored procedure, not
// a custom one. Calling it is both allowed and correct -- it owns note_id assignment, so
// going around it with a raw INSERT into oe_hdr_notepad would drift the P21 counter.
//
// Reads order LINES from the database rather than this.Data: the rule fires after save, so
// the persisted rows are authoritative and complete. That matches what the proc did.
//
// EQUIVALENCE POLICY: reproduces kb_proc_br_oe_hdr_note bug-for-bug. Known defects are
// marked [PRESERVED-BUG] and left alone so the EXEC-baseline diff can attribute every
// change. See Compare-Rules-OldVsNew.sql STEP 3b for the DLL-free ground truth.
//
// Targets C# 7.3 (P21 constraint). No C# 8+ syntax.

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;

namespace asi_Order_Workflow
{
    public class asi_Order_Workflow : P21.Extensions.BusinessRule.Rule
    {
        private const string RuleNameConst = nameof(asi_Order_Workflow);
        private const string NoteTopic = "Freight Quote Required";

        // [PRESERVED-BUG] Every note this rule writes is signed by a departed employee.
        // kb_proc_br_oe_hdr_note hardcoded '- Karen B, <timestamp>' and it still goes out on
        // freight-quote notes today. Kept verbatim for the equivalence pass ONLY -- the
        // baseline harness splits the note on this exact literal
        // (Compare-Rules-OldVsNew.sql: CHARINDEX('- Karen B', ...)), so changing it here
        // means updating that CHARINDEX in the same commit. Phase 2.
        private const string NoteSignature = "- Karen B, ";

        private const string NoteBody =
            " freight quote is required. The order should remain on Will Advise until the " +
            "Freight Charge item price is greater than zero. ";

        // FREE DAYS (10), IN FREIGHT (7), THIRD (12), NO FREIGHT (5)
        private static readonly int[] FreightCodesExempt = { 5, 7, 10, 12 };

        private static readonly string[] FreightItemIds =
            { "FREIGHT CHARGE", "UPS CHARGE", "SPEEDEE CHARGE" };

        #region SQL -- native P21 objects only

        // Header + corporate-rollup credit status + both carrier names + freight code.
        //
        // credit_status inlines kb_view_customer's expression verbatim:
        //     CASE WHEN address.corp_address_id <> address.id OR ISNULL(customer.credit_limit,0) = 0
        //          THEN corp_cust.credit_status ELSE customer.credit_status END
        // i.e. roll up to the corporate account when this is a child account OR the account
        // has no credit limit of its own. All native tables.
        //
        // [PRESERVED-BUG] Confirmed 2026-09-01: this rule and asi_Order_Validator read
        // DIFFERENT credit statuses for the same order. The validator reads
        // d_oe_hdr_credit.credit_status, which is PLAIN customer.credit_status (verified in
        // the UI: order 6108236 / customer 3025940 shows COD, where plain = COD and rollup =
        // NORMAL). This rule uses the rollup, because kb_proc_br_oe_hdr_note did.
        // They disagree for 577 customers. Consequence: for a child account that is COD
        // locally but NORMAL corporately, the validator applies COD freight rules (scenario
        // 6a can force Will Advise) while this rule exits early and never writes the
        // 'Freight Quote Required' note -- so validator scenario 6b, which needs that note to
        // exist, can never fire for them. Preserved for the equivalence pass. This is a
        // BUSINESS decision, not a code cleanup: whoever owns the freight-quote workflow has
        // to say which source is correct before either rule changes.
        //
        // carrier_name uses an INNER-JOIN equivalent (carrier_flag = 'Y'): a carrier_id that
        // is not a carrier address yields NULL, which fails the gate below. Preserved.
        //
        // NOTE: ship-to comes from oe_hdr.address_id, not a column named ship_to_id.
        private const string SqlHeader = @"
SELECT  h.customer_id,
        h.address_id                AS ship_to_id,
        h.freight_code_uid,
        ca.name                     AS carrier_name,
        dc.name                     AS default_carrier_name,
        CASE WHEN a.corp_address_id <> a.id OR ISNULL(c.credit_limit, 0.0) = 0.0
             THEN corp.credit_status
             ELSE c.credit_status END AS credit_status
FROM    oe_hdr h WITH (NOLOCK)
LEFT    JOIN customer c    ON c.customer_id = h.customer_id
LEFT    JOIN address  a    ON a.id = c.customer_id
LEFT    JOIN customer corp ON corp.customer_id = a.corp_address_id
LEFT    JOIN address  ca   ON ca.id = h.carrier_id      AND ca.carrier_flag = 'Y'
LEFT    JOIN p21_view_ship_to st ON st.ship_to_id = h.address_id
LEFT    JOIN address  dc   ON dc.id = st.default_carrier_id AND dc.carrier_flag = 'Y'
WHERE   h.order_no = @OrderNo;";

        // will_call is looked up by carrier NAME, not id -- exactly as the proc did, and as a
        // separate step from resolving the name by id.
        // [PRESERVED-BUG] The proc used a scalar subquery here, so two carrier addresses
        // sharing a name threw "Subquery returned more than 1 value". TOP 1 cannot throw, but
        // a not-found carrier still yields NULL rather than 'N', which fails the gate and
        // silently writes no note. Preserved.
        private const string SqlCarrierWillCall = @"
SELECT TOP 1 COALESCE(ud.will_call, 'N') AS will_call
FROM   p21_view_address a
LEFT   JOIN address_ud ud ON ud.id = a.id
WHERE  a.carrier_flag = 'Y' AND a.name = @CarrierName
ORDER BY a.id;";

        // Replaces the kb_TableTypeItemDec round trip with one aggregate.
        // The proc's LEFT JOIN inv_mast + WHERE inv_mast.delete_flag = 'N' is an INNER JOIN in
        // effect, so lines whose item is soft-deleted are excluded. Preserved.
        private const string SqlFreightAndNote = @"
SELECT  freight_present = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END,
        freight_total   = ISNULL(SUM(ISNULL(l.extended_price, 0)), 0)
FROM    oe_line l WITH (NOLOCK)
JOIN    inv_mast im WITH (NOLOCK) ON im.inv_mast_uid = l.inv_mast_uid
WHERE   l.order_no = @OrderNo
  AND   l.delete_flag = 'N'
  AND   im.delete_flag = 'N'
  AND   im.item_id IN ('FREIGHT CHARGE','UPS CHARGE','SPEEDEE CHARGE');

SELECT  note_present = CASE WHEN COUNT(note_id) > 0 THEN 'Y' ELSE 'N' END
FROM    oe_hdr_notepad WITH (NOLOCK)
WHERE   delete_flag = 'N' AND mandatory = 'Y'
  AND   order_no = @OrderNo AND topic = @Topic;";

        // Native P21 proc -- P21 owns note_id assignment here, so bypassing it with a raw
        // INSERT into oe_hdr_notepad would drift the counter.
        // Signature confirmed 2026-09-01 (BRR):
        //   @OrderNumber varchar(8), @NoteTopic varchar(30), @Note text
        // Bound by name rather than positionally, and @Note is text (not varchar) -- the old
        // proc declared its local @note as VARCHAR(400) and relied on an implicit
        // varchar->text conversion on the way in.
        private const string ProcAddNote = "dbo.p21_ecc_add_order_header_note";

        private const string SqlClearMandatory = @"
UPDATE oe_hdr_notepad
   SET mandatory = 'N'
 WHERE topic = @Topic AND mandatory = 'Y' AND delete_flag = 'N' AND order_no = @OrderNo;";

        private const string SqlLog = @"
INSERT INTO business_rule_log
    (user_id, log_action, rule_name, rule_assembly_name, run_type,
     return_value, return_message,
     date_created, created_by, date_last_modified, last_maintained_by)
VALUES
    (@User, @Action, @Rule, @Asm, 'Asynchronous (Internal)',
     @Value, @Msg,
     GETDATE(), @User, GETDATE(), @User);";

        private const int CommandTimeoutSeconds = 30;

        #endregion

        public override string GetName()
        {
            return nameof(asi_Order_Workflow);
        }

        public override string GetDescription()
        {
            return "Runs asynchronously after Order save to maintain the Freight Quote Required " +
                   "header note. Native P21 objects only.";
        }

        // Synchronous path is a deliberate no-op: all work happens in ExecuteAsync, matching
        // kb_Order_Workflow_v2. This rule can never block a save.
        public override RuleResult Execute()
        {
            return new RuleResult { Success = true };
        }

        // ExecuteAsync is [Obsolete] in P21.Extensions but is still the member the framework
        // invokes for run_type_cd 3423 (asynchronous). Carried forward as-is; revisit if/when
        // P21 documents a replacement.
        [Obsolete]
        public override void ExecuteAsync()
        {
            string stage = "Initializing";
            string orderNo = null;

            try
            {
                // The old rule dereferenced Data.Fields[...] for the three skip flags BEFORE
                // its try block. A missing field made Data.Fields[name] null, and the NRE
                // escaped ExecuteAsync unlogged and uncaught. Inside the try now, and
                // null-safe.
                stage = "Evaluating skip conditions";
                if (FieldIsYes("rma_flag") || FieldIsYes("quote") || FieldIsYes("oe_hdr_completed"))
                    return;

                orderNo = FieldValue("order_no");
                if (string.IsNullOrEmpty(orderNo))
                {
                    Log("Error", "Failure", "order_no was blank or missing; note maintenance skipped.");
                    return;
                }

                bool ownsConnection;
                SqlConnection connection = ResolveConnection(out ownsConnection);
                try
                {
                    stage = "Reading order header";
                    HeaderInfo header = LoadHeader(connection, orderNo);
                    if (header == null)
                        return;

                    // Gate 1: COD / CASH / PREPAY only.
                    if (!IsAny(header.CreditStatus, "COD", "CASH", "PREPAY"))
                        return;

                    stage = "Reading carrier will-call flag";
                    string willCall = LoadCarrierWillCall(connection, header.CarrierName);

                    // Gate 2: a non-default, non-will-call carrier on a freight-bearing code.
                    // Every comparison here is null-safe-false, reproducing SQL's UNKNOWN:
                    // [PRESERVED-BUG] a NULL carrier or NULL default carrier means no note is
                    // ever written for that order. The old proc had no ISNULL here, unlike the
                    // validator, which defaulted the missing default carrier to 'Will Call'.
                    bool carrierDiffers = header.CarrierName != null
                                          && header.DefaultCarrierName != null
                                          && !IsEqual(header.CarrierName, header.DefaultCarrierName);
                    bool notWillCall = IsEqual(willCall, "N");
                    bool freightBearing = header.FreightCodeUid.HasValue
                                          && Array.IndexOf(FreightCodesExempt, header.FreightCodeUid.Value) < 0;

                    if (!carrierDiffers || !notWillCall || !freightBearing)
                        return;

                    stage = "Reading freight lines and existing notes";
                    FreightInfo freight = LoadFreightAndNote(connection, orderNo);

                    // freight_zero: no freight item at all, or the freight lines sum to zero.
                    bool freightZero = !freight.FreightPresent || freight.FreightTotal == 0m;

                    if (!freight.NotePresent && freightZero)
                    {
                        stage = "Adding the freight quote note";
                        AddNote(connection, orderNo, header.CarrierName);
                        Log("Workflow", "Success", "order#" + orderNo + " :: added '" + NoteTopic + "' note.");
                    }
                    else if (freight.NotePresent && !freightZero)
                    {
                        // Quote has been entered -- the note no longer needs to block.
                        stage = "Clearing the note's mandatory flag";
                        ClearMandatory(connection, orderNo);
                        Log("Workflow", "Success", "order#" + orderNo + " :: cleared mandatory on '" + NoteTopic + "'.");
                    }
                }
                finally
                {
                    // Only dispose a connection WE created; never the framework's.
                    if (ownsConnection)
                        connection.Dispose();
                }
            }
            catch (Exception ex)
            {
                Log("Error", "Failure",
                    stage + " for order# " + (orderNo ?? "n/a") + " failed." +
                    Environment.NewLine + ex);
            }
        }

        #region Steps

        private sealed class HeaderInfo
        {
            public decimal? CustomerId;
            public decimal? ShipToId;
            public int? FreightCodeUid;
            public string CarrierName;
            public string DefaultCarrierName;
            public string CreditStatus;
        }

        private sealed class FreightInfo
        {
            public bool FreightPresent;
            public decimal FreightTotal;
            public bool NotePresent;
        }

        private HeaderInfo LoadHeader(SqlConnection connection, string orderNo)
        {
            using (var cmd = new SqlCommand(SqlHeader, connection))
            {
                cmd.CommandTimeout = CommandTimeoutSeconds;
                AddVarChar(cmd, "@OrderNo", orderNo, 8);

                using (SqlDataReader r = cmd.ExecuteReader(CommandBehavior.SingleRow))
                {
                    if (!r.Read()) return null;
                    return new HeaderInfo
                    {
                        CustomerId = r.IsDBNull(0) ? (decimal?)null : r.GetDecimal(0),
                        ShipToId = r.IsDBNull(1) ? (decimal?)null : r.GetDecimal(1),
                        FreightCodeUid = r.IsDBNull(2) ? (int?)null : r.GetInt32(2),
                        CarrierName = r.IsDBNull(3) ? null : r.GetString(3),
                        DefaultCarrierName = r.IsDBNull(4) ? null : r.GetString(4),
                        CreditStatus = r.IsDBNull(5) ? null : r.GetString(5)
                    };
                }
            }
        }

        private string LoadCarrierWillCall(SqlConnection connection, string carrierName)
        {
            if (carrierName == null) return null;
            using (var cmd = new SqlCommand(SqlCarrierWillCall, connection))
            {
                cmd.CommandTimeout = CommandTimeoutSeconds;
                AddVarChar(cmd, "@CarrierName", carrierName, 255);
                object o = cmd.ExecuteScalar();
                return (o == null || o == DBNull.Value) ? null : (string)o;
            }
        }

        private FreightInfo LoadFreightAndNote(SqlConnection connection, string orderNo)
        {
            var info = new FreightInfo();
            using (var cmd = new SqlCommand(SqlFreightAndNote, connection))
            {
                cmd.CommandTimeout = CommandTimeoutSeconds;
                AddVarChar(cmd, "@OrderNo", orderNo, 8);
                AddVarChar(cmd, "@Topic", NoteTopic, 255);

                using (SqlDataReader r = cmd.ExecuteReader())
                {
                    if (r.Read())
                    {
                        info.FreightPresent = !r.IsDBNull(0) && IsEqual(r.GetString(0), "Y");
                        info.FreightTotal = r.IsDBNull(1) ? 0m : r.GetDecimal(1);
                    }
                    r.NextResult();
                    if (r.Read())
                        info.NotePresent = !r.IsDBNull(0) && IsEqual(r.GetString(0), "Y");
                }
            }
            return info;
        }

        private void AddNote(SqlConnection connection, string orderNo, string carrierName)
        {
            string note = carrierName + NoteBody + NoteSignature + SqlDefaultDateString(DateTime.Now);
            // kb_proc_br_oe_hdr_note built this in a VARCHAR(400) local, so anything longer
            // was already being truncated before it reached the proc. Preserved.
            if (note.Length > 400) note = note.Substring(0, 400);

            using (var cmd = new SqlCommand(ProcAddNote, connection))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandTimeout = CommandTimeoutSeconds;
                AddVarChar(cmd, "@OrderNumber", orderNo, 8);
                AddVarChar(cmd, "@NoteTopic", NoteTopic, 30);   // proc declares varchar(30)
                cmd.Parameters.Add("@Note", SqlDbType.Text).Value = note;
                cmd.ExecuteNonQuery();
            }
        }

        private void ClearMandatory(SqlConnection connection, string orderNo)
        {
            using (var cmd = new SqlCommand(SqlClearMandatory, connection))
            {
                cmd.CommandTimeout = CommandTimeoutSeconds;
                AddVarChar(cmd, "@OrderNo", orderNo, 8);
                AddVarChar(cmd, "@Topic", NoteTopic, 255);
                cmd.ExecuteNonQuery();
            }
        }

        // Reproduces T-SQL's CONVERT(VARCHAR, GETDATE()) -- style 0, "mon dd yyyy hh:miAM",
        // which space-pads both the day and the hour to two characters.
        internal static string SqlDefaultDateString(DateTime t)
        {
            CultureInfo inv = CultureInfo.InvariantCulture;
            return t.ToString("MMM", inv) + " "
                 + t.Day.ToString(inv).PadLeft(2) + " "
                 + t.Year.ToString(inv) + " "
                 + t.ToString("h:mm", inv).PadLeft(5)
                 + t.ToString("tt", inv).ToUpperInvariant();
        }

        #endregion

        #region Connection

        // Prefers the framework connection; falls back to a Session-built one if the framework
        // connection is unusable in this async context. Which branch actually runs was test
        // case B4 in TEST-PLAN_kb_Order_Validator_v2.md and was never recorded -- so the
        // fallback path now logs itself once per use. It matters: the fallback authenticates
        // as the middleware identity, not the end user, and may lack INSERT on business_rule_log.
        private SqlConnection ResolveConnection(out bool ownsConnection)
        {
            SqlConnection conn = P21SqlConnection;
            if (conn != null && conn.State == ConnectionState.Open)
            {
                ownsConnection = false;
                return conn;
            }

            string connectionString =
                "server=" + Session.Server +
                ";database=" + Session.Database +
                ";Trusted_Connection=true" +
                ";application name=P21_BusinessRule_" + RuleNameConst;

            conn = new SqlConnection(connectionString);
            conn.Open();
            ownsConnection = true;
            return conn;
        }

        #endregion

        #region Helpers

        private string FieldValue(string name)
        {
            if (Data == null || Data.Fields == null) return null;
            DataField f = Data.Fields[name];
            return f == null ? null : f.FieldValue;
        }

        private bool FieldIsYes(string name)
        {
            return IsEqual(FieldValue(name), "Y");
        }

        private static bool IsEqual(string value, string expected)
        {
            return expected.Equals(value, StringComparison.OrdinalIgnoreCase);
        }

        private static bool IsAny(string value, params string[] options)
        {
            if (value == null) return false;
            for (int i = 0; i < options.Length; i++)
                if (options[i].Equals(value, StringComparison.OrdinalIgnoreCase)) return true;
            return false;
        }

        private static void AddVarChar(SqlCommand cmd, string name, string value, int size)
        {
            cmd.Parameters.Add(name, SqlDbType.VarChar, size).Value = (object)value ?? DBNull.Value;
        }

        // Best-effort. A logging failure must never mask the original error, and must never
        // affect the order -- this rule is async and cannot block a save either way.
        private void Log(string action, string value, string details)
        {
            try
            {
                bool ownsConnection;
                SqlConnection connection = ResolveConnection(out ownsConnection);
                try
                {
                    using (var cmd = new SqlCommand(SqlLog, connection))
                    {
                        string userId = (Session != null && !string.IsNullOrEmpty(Session.UserID))
                            ? Session.UserID
                            : "unknown";

                        AddVarChar(cmd, "@User", userId, 255);
                        AddVarChar(cmd, "@Action", action, 255);
                        AddVarChar(cmd, "@Value", value, 255);
                        AddVarChar(cmd, "@Rule", RuleNameConst, 255);
                        AddVarChar(cmd, "@Asm", GetType().Assembly.GetName().Name, 255);
                        AddVarChar(cmd, "@Msg",
                            details.Length > 8000 ? details.Substring(0, 8000) : details, 8000);

                        cmd.ExecuteNonQuery();
                    }
                }
                finally
                {
                    if (ownsConnection)
                        connection.Dispose();
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
