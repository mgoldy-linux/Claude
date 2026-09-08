// ============================================================
// asi_oe_order_ack_email_subject.cs
// ============================================================
// Description : SA 54321 -- inserts the customer PO number and Sidemark
//               (oe_hdr.po_no / oe_hdr.job_name) into the SUBJECT line of
//               Order Acknowledgment emails, so customers and territory
//               managers can find an ack by a number they recognise.
//               Result looks like:
//                 ** ... ** - Acknowledgement# 5977563 | PO JS001561 <rep's text>
//               The PO/Sidemark are inserted right after the order-number
//               digits, ahead of whatever the rep typed.
//
// Event       : On-Demand rule attached to window w_email_response
//               ("Email Order Acknowledgment"), trigger control cb_ok --
//               the SAME attach point as asi_oe_email_close_diag. Not tied
//               to a published event (business_rule_event_uid = NULL).
//
// Registration: On-Demand rule, window w_email_response, trigger cb_ok.
//               Multi-Row = YES at creation (required for Data.Set; NOT
//               editable in place -- BRR uid 167 was recreated once to get
//               this). Field Selector:
//                 - Window Controls > Buttons > cb_ok : Selected + Triggers Rule
//                 - d_dw_email_info > subject         : Selected  (read + write)
//                 - d_dw_email_info > company_id      : Selected  (lookup scope)
//               Do NOT also select memo -- asi_oe_email_close_diag owns it.
//               Enable for all users. Before every test confirm exactly ONE
//               active registration and that BOTH rules' element lists are
//               intact -- delete+recreate cycles leave orphans, and saving in
//               Rule Manager REPLACES the element list. On 2026-09-06
//               asi_oe_email_close_diag was left holding this rule's
//               `subject` element instead of its own `memo` and failed every
//               fire. Audit with
//               Sql-Scripts\Business-Rules\Audit-OrderAck-Email-Rule-Registrations.sql.
//
// Structure   : Data.Set only (multi-row). Table "d_dw_email_info", 1 row.
//               Columns confirmed present at this attach point (Field
//               Selector, 2026-09-06): subject, company_id, memo,
//               from_company, from_email_address, from_name,
//               to_email_address, cc_*/bc_*, attachment*, b_add_attachments,
//               b_default_subject, use_branch_name_in_subject_flag,
//               include_recipient_info_in_body.
//
//               CRITICAL -- what `subject` actually is here (proved
//               2026-09-06, see change log): it is NOT the delivered subject
//               line. It is the rep's free-text portion: empty when the
//               window opens, char(60), readOnly=N. P21 builds
//               "All Surfaces - Acknowledgement# <order>" itself at send time
//               and appends this field. So this rule PREPENDS its segment to
//               whatever the rep typed, and the customer sees:
//                 All Surfaces - Acknowledgement# 5977563 | PO JS001561 <rep's text>
//
//               There is NO form_type / document_nos / order_no column here,
//               so both facts come from asi_email_context_flag (written by
//               the FormPreEmail rule asi_email_context_flag, the same gate
//               asi_oe_email_close_diag reads):
//                 * is_order_ack -> is this an Order Ack?
//                 * document_nos -> the order number for the oe_hdr lookup
//
// Relationship to SA 53475 : INDEPENDENT rule. Shares the attach point and
//               the asi_email_context_flag gate table with
//               asi_oe_email_close_diag, but no shared code. This one only
//               ever touches "subject"; that one only ever touches "memo".
//               Deploy / roll back separately.
//
// Safety      : Writes ONE field (subject), plain text. Reversible by
//               deregistration. RuleResult.Success is always true -- a
//               failure here never blocks the email window from closing or
//               the email from sending. Free-text guarding on po_no /
//               job_name (see SegmentPolicy) so internal notes staff park
//               in those fields are not shipped to a customer. Per the
//               2026-07-28 incident (feedback_p21_test_env_live_email) test
//               only against an order whose recipient address you control --
//               BRR / Play have real customer data and a live SMTP path.
//
// OPEN ITEMS BEFORE GOING LIVE:
//   1. RESOLVED 2026-09-06 -- "subject" reports ReadOnly=False here and the
//      Return XML shows readOnly="N" (unlike the attachment fields, which
//      were "Y" and threw an uncatchable client error). Still worth one
//      ReadOnlyProbe=false run watched for a PowerBuilder error before
//      trusting it in Play/Prod.
//   2. RESOLVED 2026-09-06 -- the DataColumn reports MaxLength=-1 (.NET is
//      not enforcing) but the Return XML gives the real DataWindow width:
//      char(60). SubjectCap is 60, NOT the 255 originally assumed. The
//      runtime clamp below still applies if MaxLength ever reports sane.
//   3. Decide SegmentPolicy after reviewing the SA 54321 content scan of
//      2026 po_no / job_name values. Default IdentifierOnly (safest).
//   4. Requires asi_email_context_flag v1.0.0.2+ (writes document_nos) and
//      the document_nos column on the flag table. Against an older flag
//      writer this rule logs "no order number" and changes nothing -- safe,
//      but a no-op.
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-09-06  Bus App Team
//   - Initial draft (SA 54321). Targeted the FormPreEmail event /
//     EmailDataMisc dataset. ReadOnlyProbe = true.
// 2026-09-06  Bus App Team
//   - RE-TARGETED to the cb_ok / w_email_response attach point (dataset
//     d_dw_email_info). Reason: it was registered on that attach point in
//     BRR (uid 167), where Data.Set has no EmailDataMisc table (that table
//     only exists on the FormPreEmail event) -- every run logged
//     "EmailDataMisc table not found". The cb_ok point also has the edge
//     that a memo write there is already proven to reach the delivered
//     email (asi_oe_email_close_diag), whereas a FormPreEmail subject write
//     was never proven. Consequences of the move:
//       * dataset table is d_dw_email_info, 1 row
//       * no form_type    -> gate on asi_email_context_flag + the subject
//                            "Acknowledgement#" marker
//       * no document_nos -> parse the order number out of the subject
//       * company_id IS present in d_dw_email_info -> used for the lookup
//       * the rep's typed comment is already in the subject by the time
//         cb_ok fires -> the PO/Sidemark segment is INSERTED just after the
//         order-number digits, not appended to the end.
//     Still ReadOnlyProbe = true -- OPEN ITEM 1 (subject writability here)
//     is unresolved.
// 2026-09-06  Bus App Team
//   - FIRST BRR RUN, and it disproved the core assumption. Log evidence:
//       * "subject column: MaxLength=-1 ReadOnly=False DataType=String"
//         and readOnly="N" / dataType="char(60)" in the Return XML
//         -> subject IS writable here; the real cap is 60, not 255.
//       * "Context flag says Order Ack, but subject has no
//         'Acknowledgement# <digits>' marker -- subject='Test 4'"
//       * the sibling rule's Return XML 48s earlier, with the window
//         already open, shows d_dw_email_info.subject EMPTY.
//     Conclusion: d_dw_email_info.subject is the rep's free-text portion,
//     not the delivered subject line. P21 generates
//     "All Surfaces - Acknowledgement# <order>" and appends this field at
//     send time (consistent with char(60) and with b_default_subject /
//     use_branch_name_in_subject_flag being separate columns). There is no
//     order number in this field to parse, and never will be.
//     Reworked accordingly:
//       * ExtractOrderNoFromSubject / AckMarker / AckMarkerAlt DELETED.
//       * the order number now comes from asi_email_context_flag.document_nos,
//         written by asi_email_context_flag v1.0.0.2 at FormPreEmail (that
//         event does expose document_nos). One extra column on a table this
//         rule already reads for its gate -- no new query, no new round trip.
//       * the segment is PREPENDED to the rep's text rather than spliced
//         after order-number digits, which lands in exactly the requested
//         position once P21 adds its prefix.
//       * SubjectCap 255 -> 60. Drop-order (Sidemark first, then PO, never
//         truncate a value mid-string) is unchanged and now matters: at 60
//         chars a PO+Sidemark segment can genuinely crowd out the rep.
//     ReadOnlyProbe stays TRUE for one more run to see a real
//     "would set subject" line with a real order number before writing.
//
//   - v1.0.0.3 -- ReadOnlyProbe flipped to FALSE. The rule now actually
//     writes row["subject"].
//     Cleared by the 2026-09-06 rework's probe run in BRR on 2026-09-08
//     (uid 171, v1.0.0.2, order 6108923, log rows 8808006-8808010):
//       Context flag check: is_order_ack=True form_type='Order Acknowledgement'
//                           document_nos='6108923' order_no='6108923'
//       PROBE (no write) order 6108923 Policy=IdentifierOnly
//                        -- would set subject 'After Table rebuild'
//                        -> '| PO 57354 After Table rebuild'
//     That is the "prose dropped" test case: po_no=57354 rendered,
//     job_name='Serena Residence' correctly suppressed by IdentifierOnly.
//     Prerequisite confirmed in the same run: dbo.asi_email_context_flag
//     has document_nos (its absence was error 207 in the 10:09 run).
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Text;

namespace asi_OeOrderAckEmailSubject
{
    public class asi_oe_order_ack_email_subject : P21.Extensions.BusinessRule.Rule
    {
        // ---- Configuration ------------------------------------------------

        // TRUE  = compute and log the new subject but DO NOT write it.
        // FALSE = actually set row["subject"]. Flip only after OPEN ITEMS 1-2.
        private const bool ReadOnlyProbe = false;

        // Assembled as  label + value  ->  "| PO 12345", then joined with a
        // single space and prepended to the rep's own text.
        private const string PoLabel       = "| PO ";
        private const string SidemarkLabel = "| Sidemark ";

        // Per-field ceiling. IdentifierOnly drops a longer value; ScrubAndCap
        // truncates it.
        private const int MaxSegmentLen = 30;

        // Ceiling for THIS field, which is the rep's free-text portion of the
        // subject, not the whole line -- P21 prefixes its own
        // "All Surfaces - Acknowledgement# <order>" at send time and that
        // prefix does not count against this. Confirmed char(60) from the
        // 2026-09-06 Return XML; the DataColumn itself reports MaxLength=-1,
        // so .NET will not catch an overrun and a too-long write risks the
        // client-side PowerBuilder error. The clamp below is the only guard.
        private const int SubjectCap = 60;

        // How much of a free-text value we are willing to put in a
        // customer-facing subject.
        //   IdentifierOnly : include a field only if it looks like a bare
        //                    token (no spaces, <= MaxSegmentLen, chars in
        //                    [A-Za-z0-9/#._-]). Kills the internal-note prose
        //                    staff park in these fields (e.g. "ROACH CHRIS",
        //                    "put on wrong account", "Replacement for Leyza").
        //   ScrubAndCap    : include any non-blank value with control chars
        //                    stripped and length capped, UNLESS it hits the
        //                    blocklist. Looser -- only after the content scan.
        private enum SegmentPolicy { IdentifierOnly, ScrubAndCap }
        private const SegmentPolicy Policy = SegmentPolicy.IdentifierOnly;

        // Used only by ScrubAndCap. Mirrors the High-severity buckets of the
        // SA 54321 content scan.
        private static readonly string[] BlockedTerms =
        {
            "fuck", "f*ck", "shit", "sh!t", "asshole", "bitch", "idiot",
            "moron", "stupid", "dumbass",
            "pita", "nightmare", "liar", "deadbeat", "cheapskate", "rude",
            "credit hold", "past due", "collection", "wont pay", "won't pay",
            "slow pay", "no pay", "non pay", "cod only", "prepay only",
            "hold for payment",
            "lawsuit", "attorney", "lawyer", "chargeback", "charge back",
            "fraud",
            "margin", "markup", "mark up", "our cost", "profit margin",
            "commission", "rebate", "spiff",
            "our fault", "our error", "our mistake", "rep error",
            "wrong material", "wrong item", "shipped wrong", "wrong account",
            "incorrectly shipped", "misship", "mis-ship", "messed up",
            "screwed up", "defective", "complaint",
            "do not use", "asdf", "test order"
        };

        // ---- Entry point ------------------------------------------------

        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();

            try
            {
                DataSet ds = this.Data.Set;

                if (ds == null || !ds.Tables.Contains("d_dw_email_info"))
                {
                    LogRuleError("d_dw_email_info table not found in Data.Set. "
                        + "Check the rule's Field Selector / attach point (expected: On-Demand, w_email_response, cb_ok).");
                }
                else
                {
                    ProcessEmailInfo(ds.Tables["d_dw_email_info"]);
                }
            }
            catch (Exception ex)
            {
                LogRuleError("Execute failed: " + ex);
            }

            // Never block the window close / email send, whatever happened above.
            ruleResult.Success = true;
            return ruleResult;
        }

        private void ProcessEmailInfo(DataTable t)
        {
            if (t.Rows.Count < 1 || !t.Columns.Contains("subject"))
            {
                LogRuleError("d_dw_email_info has no rows or no 'subject' column. Check the Field Selector.");
                return;
            }

            DataRow row = t.Rows[0];
            DataColumn subjectCol = t.Columns["subject"];

            // Always logged -- the answer to OPEN ITEMS 1 & 2.
            LogRuleInfo("subject column: MaxLength=" + subjectCol.MaxLength
                + " ReadOnly=" + subjectCol.ReadOnly
                + " DataType=" + subjectCol.DataType.Name);

            string originalSubject = row["subject"] as string ?? string.Empty;

            // Gate: the shared Order-Ack flag (same row asi_oe_email_close_diag
            // reads) -- w_email_response is shared by Packing List Transfer,
            // RMA Ack, etc. The same read also hands back the order number,
            // which this attach point cannot see any other way.
            bool isOrderAck = IsOrderAckEmail(out string orderNo, out string flagDetails);
            LogRuleInfo("Context flag check: " + flagDetails);
            if (!isOrderAck)
            {
                LogRuleInfo("asi_email_context_flag says this is not an Order Acknowledgment email -- subject left unchanged.");
                return;
            }

            // Idempotency -- never stamp twice.
            if (originalSubject.IndexOf(PoLabel, StringComparison.OrdinalIgnoreCase) >= 0
                || originalSubject.IndexOf(SidemarkLabel, StringComparison.OrdinalIgnoreCase) >= 0)
            {
                LogRuleInfo("Subject already carries a PO/Sidemark stamp -- skipping. subject='" + originalSubject + "'");
                return;
            }

            if (string.IsNullOrEmpty(orderNo))
            {
                LogRuleError("Context flag says Order Ack but carries no usable order number in document_nos -- "
                    + "not modifying. Check that asi_email_context_flag is v1.0.0.2+ AND has document_nos in its "
                    + "Field Selector. subject='" + originalSubject + "'");
                return;
            }

            string companyId = t.Columns.Contains("company_id") ? (row["company_id"] as string ?? string.Empty) : string.Empty;

            if (!TryGetOrderRefs(orderNo, companyId, out string poNo, out string sidemark, out string lookupDetails))
            {
                LogRuleInfo(lookupDetails + " -- subject left unchanged.");
                return;
            }

            string poSeg = BuildSegment(PoLabel, poNo, null);
            string smSeg = BuildSegment(SidemarkLabel, sidemark, poNo);   // dedup Sidemark against PO

            if (poSeg.Length == 0 && smSeg.Length == 0)
            {
                LogRuleInfo("Policy=" + Policy + " order " + orderNo
                    + ": nothing usable to add (po_no='" + poNo + "' job_name='" + sidemark + "'). Subject left unchanged.");
                return;
            }

            int effectiveCap = SubjectCap;
            if (subjectCol.MaxLength > 0 && subjectCol.MaxLength < effectiveCap)
                effectiveCap = subjectCol.MaxLength;

            // Prepend, so that once P21 puts its own
            // "All Surfaces - Acknowledgement# <order>" in front at send time the
            // stamp lands between the order number and the rep's comment.
            string newSubject = Compose(Join(poSeg, smSeg), originalSubject);

            if (newSubject.Length > effectiveCap)
            {
                // Drop Sidemark first, then give up -- never truncate a value.
                // If PO was the segment that got dropped by policy, there is
                // nothing left to fall back to.
                if (poSeg.Length == 0)
                {
                    LogRuleInfo("order " + orderNo + ": Sidemark alone would exceed the " + effectiveCap
                        + "-char cap on this field (rep's text is already " + originalSubject.Length
                        + " chars) and there is no PO to fall back to. Subject left unchanged.");
                    return;
                }

                newSubject = Compose(poSeg, originalSubject);
                if (newSubject.Length > effectiveCap)
                {
                    LogRuleInfo("order " + orderNo + ": adding PO would exceed the " + effectiveCap
                        + "-char cap on this field (rep's text is already " + originalSubject.Length
                        + " chars). Subject left unchanged.");
                    return;
                }

                LogRuleInfo("order " + orderNo + ": Sidemark dropped to fit the " + effectiveCap + "-char cap.");
            }

            if (ReadOnlyProbe)
            {
                LogRuleInfo("PROBE (no write) order " + orderNo + " Policy=" + Policy
                    + " -- would set subject '" + originalSubject + "' -> '" + newSubject + "'");
            }
            else
            {
                row["subject"] = newSubject;
                LogRuleInfo("order " + orderNo + " Policy=" + Policy
                    + " -- subject '" + originalSubject + "' -> '" + newSubject + "'");
            }
        }

        // ---- Order-Ack gate (shared flag) ---------------------------

        // Reads asi_email_context_flag for the current user -- written by the
        // FormPreEmail rule asi_email_context_flag earlier in this same
        // window's lifecycle. Same gate asi_oe_email_close_diag uses, plus
        // document_nos, which is the ONLY way this attach point can learn the
        // order number (d_dw_email_info exposes no document/order column, and
        // the subject field here is the rep's comment, not the ack line).
        // One PK seek, on a row the gate has to read anyway.
        private bool IsOrderAckEmail(out string orderNo, out string details)
        {
            orderNo = string.Empty;

            const string selectSql =
                @"SELECT is_order_ack, form_type, document_nos, updated_at
                    FROM asi_email_context_flag
                   WHERE user_id = @User";

            using (SqlCommand cmd = new SqlCommand(selectSql, P21SqlConnection))
            {
                cmd.Parameters.Add("@User", SqlDbType.VarChar, 30).Value = GetUserId();

                using (SqlDataReader reader = cmd.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        bool isOrderAck = (bool)reader["is_order_ack"];
                        string formType = reader["form_type"] as string ?? string.Empty;
                        string docNos = reader["document_nos"] as string ?? string.Empty;
                        DateTime updatedAt = (DateTime)reader["updated_at"];

                        orderNo = ParseFirstOrderNo(docNos);

                        details = "is_order_ack=" + isOrderAck + " form_type='" + formType
                            + "' document_nos='" + docNos + "' order_no='" + orderNo
                            + "' updated_at=" + updatedAt.ToString("O");
                        return isOrderAck;
                    }

                    details = "No asi_email_context_flag row for this user -- treating as not an Order Ack.";
                    return false;
                }
            }
        }

        // document_nos is a free-form label ("5977563", "Order 5977563",
        // possibly a delimited list). An Order Ack is always a single order
        // (confirmed SA 54321), so the first digit run is the order number.
        // Returns "" when there is none -- the caller then changes nothing.
        private static string ParseFirstOrderNo(string documentNos)
        {
            if (string.IsNullOrEmpty(documentNos))
                return string.Empty;

            int i = 0;
            while (i < documentNos.Length && !char.IsDigit(documentNos[i]))
                i++;

            int start = i;
            while (i < documentNos.Length && char.IsDigit(documentNos[i]))
                i++;

            return i > start ? documentNos.Substring(start, i - start) : string.Empty;
        }

        // ---- oe_hdr lookup --------------------------------------------

        // Single row expected -- an Order Ack is always one order (confirmed
        // SA 54321). company_id from d_dw_email_info is used when present;
        // otherwise the newest oe_hdr row for that order_no is taken, which
        // is correct for a single-company install.
        private bool TryGetOrderRefs(string orderNo, string companyId,
            out string poNo, out string sidemark, out string details)
        {
            poNo = string.Empty;
            sidemark = string.Empty;

            bool haveCompany = !string.IsNullOrEmpty(companyId);

            // oe_hdr.order_no is varchar in P21 -- pass a string param.
            string sql = haveCompany
                ? @"SELECT po_no, job_name
                      FROM oe_hdr
                     WHERE order_no = @OrderNo AND company_id = @CompanyId"
                : @"SELECT TOP (1) po_no, job_name
                      FROM oe_hdr
                     WHERE order_no = @OrderNo
                     ORDER BY date_created DESC";

            using (SqlCommand cmd = new SqlCommand(sql, P21SqlConnection))
            {
                cmd.Parameters.Add("@OrderNo", SqlDbType.VarChar, 40).Value = orderNo;
                if (haveCompany)
                    cmd.Parameters.Add("@CompanyId", SqlDbType.VarChar, 40).Value = companyId;

                using (SqlDataReader r = cmd.ExecuteReader())
                {
                    if (!r.Read())
                    {
                        details = "oe_hdr: no row for order_no='" + orderNo + "'"
                            + (haveCompany ? " company_id='" + companyId + "'" : " (no company filter)");
                        return false;
                    }

                    poNo = r["po_no"] as string ?? string.Empty;
                    sidemark = r["job_name"] as string ?? string.Empty;
                    details = "oe_hdr: po_no='" + poNo + "' job_name='" + sidemark + "'";
                    return true;
                }
            }
        }

        // ---- Subject assembly ---------------------------------------

        // Space-joins the two segments, skipping whichever is empty.
        private static string Join(string a, string b)
        {
            if (a.Length == 0) return b;
            if (b.Length == 0) return a;
            return a + " " + b;
        }

        // Prepends the segment to the rep's own text. The delivered subject is
        // P21's "All Surfaces - Acknowledgement# <order>" + this value, so the
        // stamp ends up between the order number and the rep's comment.
        private static string Compose(string segment, string originalSubject)
        {
            return originalSubject.Length == 0 ? segment : segment + " " + originalSubject;
        }

        // ---- Segment building / free-text guarding ------------------

        // Returns "" (nothing added) or e.g. "| PO JS001561".
        private string BuildSegment(string label, string rawValue, string dedupAgainst)
        {
            if (string.IsNullOrWhiteSpace(rawValue))
                return string.Empty;

            // Collapse whitespace first -- also turns CR/LF/TAB into a single
            // space, which defuses subject-header injection.
            string val = CollapseWhitespace(rawValue);

            // PO and Sidemark hold the same string on a large share of orders
            // -- suppress the duplicate.
            if (dedupAgainst != null
                && string.Equals(val, CollapseWhitespace(dedupAgainst), StringComparison.OrdinalIgnoreCase))
                return string.Empty;

            switch (Policy)
            {
                case SegmentPolicy.IdentifierOnly:
                    if (!LooksLikeIdentifier(val))
                        return string.Empty;
                    break;

                case SegmentPolicy.ScrubAndCap:
                    if (ContainsBlockedTerm(val))
                        return string.Empty;
                    if (val.Length > MaxSegmentLen)
                        val = val.Substring(0, MaxSegmentLen).TrimEnd();
                    break;
            }

            return label + val;
        }

        // Bare token: no spaces, sane length, only chars you'd expect in a
        // real PO / job code.
        private static bool LooksLikeIdentifier(string s)
        {
            if (string.IsNullOrEmpty(s) || s.Length > MaxSegmentLen)
                return false;

            foreach (char c in s)
            {
                if (char.IsLetterOrDigit(c))
                    continue;
                if (c == '/' || c == '#' || c == '.' || c == '_' || c == '-')
                    continue;
                return false;
            }
            return true;
        }

        private static bool ContainsBlockedTerm(string val)
        {
            string lower = val.ToLowerInvariant();
            foreach (string term in BlockedTerms)
            {
                if (lower.IndexOf(term, StringComparison.Ordinal) >= 0)
                    return true;
            }
            return false;
        }

        private static string CollapseWhitespace(string s)
        {
            if (string.IsNullOrEmpty(s))
                return string.Empty;

            StringBuilder sb = new StringBuilder(s.Length);
            bool prevWs = false;
            foreach (char c in s)
            {
                bool ws = char.IsWhiteSpace(c);
                if (ws)
                {
                    if (!prevWs) sb.Append(' ');
                }
                else
                {
                    sb.Append(c);
                }
                prevWs = ws;
            }
            return sb.ToString().Trim();
        }

        // ---- Logging (P21 native business_rule_log) ----------------

        private string GetUserId()
        {
            return this.Session != null && !string.IsNullOrEmpty(this.Session.UserID)
                ? this.Session.UserID
                : "unknown";
        }

        private void LogRuleInfo(string details)
        {
            LogRule("Info", "Success", details);
        }

        private void LogRuleError(string details)
        {
            LogRule("Error", "Failure", details);
        }

        // Best-effort: a logging failure must never mask or block the email
        // window from closing / sending.
        private void LogRule(string logAction, string returnValue, string details)
        {
            try
            {
                const string logSql =
                    @"INSERT INTO business_rule_log
                        (user_id, log_action, rule_name, rule_assembly_name, run_type,
                         return_value, return_message,
                         date_created, created_by, date_last_modified, last_maintained_by)
                      VALUES
                        (@User, @Action, @Rule, @Asm, 'Synchronous (Internal)',
                         @Return, @Msg,
                         GETDATE(), @User, GETDATE(), @User)";

                using (SqlCommand logCmd = new SqlCommand(logSql, P21SqlConnection))
                {
                    string userId = GetUserId();

                    logCmd.Parameters.Add("@User", SqlDbType.VarChar, 255).Value = userId;
                    logCmd.Parameters.Add("@Action", SqlDbType.VarChar, 50).Value = logAction;
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_oe_order_ack_email_subject);
                    logCmd.Parameters.Add("@Asm", SqlDbType.VarChar, 255).Value = GetType().Assembly.GetName().Name;
                    logCmd.Parameters.Add("@Return", SqlDbType.VarChar, 50).Value = returnValue;
                    logCmd.Parameters.Add("@Msg", SqlDbType.VarChar, 8000).Value =
                        details.Length > 8000 ? details.Substring(0, 8000) : details;
                    logCmd.ExecuteNonQuery();
                }
            }
            catch
            {
                // Swallow -- logging must never mask or block the real send.
            }
        }

        public override string GetDescription()
        {
            return "SA 54321 -- prepends customer PO (oe_hdr.po_no) and Sidemark (oe_hdr.job_name) to the rep's portion of the Order Acknowledgment email subject, on the cb_ok button of w_email_response. Gated on asi_email_context_flag, which also supplies the order number (document_nos). Free-text guarded so internal notes in those fields are not sent to customers. Independent of SA 53475.";
        }

        public override string GetName()
        {
            return nameof(asi_oe_order_ack_email_subject);
        }
    }
}
