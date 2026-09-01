// OrderValidationEngine.cs
//
// The order-validation decision logic, extracted from asi_Order_Validator so it can be
// tested without P21. This file has ZERO P21 references and zero database access -- it is
// pure functions over plain objects. Do not add any.
//
//   asi_Order_Validator.cs   -- adapter: reads Data.Set, runs the reference SQL, logs
//   OrderValidationEngine.cs -- this file: decides
//   ValidatorHarness         -- console app: replays the 23 matrix cases against Validate()
//
// Replaces dbo.kb_fnt_br_order_validator_v2. The nine live checks run as an ordered
// if/else chain -- FIRST MATCH WINS, and the order is behavior, not style. Do not reorder.
//
// EQUIVALENCE POLICY: reproduces the TVF bug-for-bug. Items marked [PRESERVED-BUG] are
// deliberate and must NOT be "fixed" until the baseline diff is clean; they are Phase 2.
//
// Verified against Capture-OldValidator-Matrix.sql (2026-09-01, BRR): 23/23 cases, and
// NumberShorten against that script's 32-value STEP 3b table.
//
// Targets C# 7.3 (P21 constraint). No C# 8+ syntax.

using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;

namespace asi_Order_Validator
{
    #region Inputs

    /// <summary>One order line, reduced to what the checks actually read.</summary>
    public sealed class OrderLine
    {
        public string ItemId;
        /// <summary>Post-gating: qty_ordered when the line qualifies, else 0.</summary>
        public decimal QtyOpen;
        public decimal? ExtendedPrice;
    }

    /// <summary>The order, as the checks see it. Built from the DataWindow by the adapter.</summary>
    public sealed class OrderSnapshot
    {
        public string OrderNo;
        public DateTime? DateCreated;
        public DateTime? RequestedDate;
        public int? FreightCodeUid;
        public decimal? ShipToId;
        public decimal? CustomerId;
        public string CarrierName;
        public string PackingBasis;
        public string CreditStatus;
        public string OrderType;

        public List<OrderLine> Lines = new List<OrderLine>();
        public int QualifyingOpenLineCount;
        public decimal FuelSurchargeExtendedTotal;

        /// <summary>
        /// DataWindow columns the adapter expected but could not find. NOT the same as a
        /// column that exists and is null: a null value means the user left the field blank
        /// and the precursor checks must block, whereas a MISSING column means this DataSet
        /// does not carry the field at all and the rule has no basis to judge the order.
        /// Blocking on a missing column accuses the user of an error that isn't theirs.
        /// The adapter aborts validation (and logs) when this is non-empty.
        /// </summary>
        public List<string> MissingColumns = new List<string>();

        public bool FreightQuoteNotePresent;
        public bool SignatureNotePresent;
    }

    /// <summary>Lookups the adapter resolves against native P21 objects.</summary>
    public sealed class ReferenceData
    {
        public string FreightAutoAdds = "N";
        public string FreightCodeName = string.Empty;
        /// <summary>NULL when the carrier name matched nothing -- see [PRESERVED-BUG] below.</summary>
        public string CarrierWillCall;
        public string DefaultCarrierName;
        /// <summary>NULL when the ship-to row was not found.</summary>
        public decimal? FreightCharge;
        /// <summary>Item ids that count toward @order_total / @items_open.</summary>
        public HashSet<string> CountedItemIds =
            new HashSet<string>(StringComparer.OrdinalIgnoreCase);
    }

    public sealed class ValidationOutcome
    {
        public bool Passed = true;
        public string Message;

        public static ValidationOutcome Pass()
        {
            return new ValidationOutcome();
        }

        public static ValidationOutcome Fail(string code, string message)
        {
            return new ValidationOutcome { Passed = false, Message = "[" + code + "] " + message };
        }
    }

    #endregion

    public static class OrderValidationEngine
    {
        #region Constants

        /// <summary>Orders predating the original validator always save.</summary>
        public static readonly DateTime ValidatorEpoch = new DateTime(2018, 7, 23);

        public const int FreightCodePrepaid = 6;
        public const int FreightCodeWillCall = 8;
        public const decimal SignatureNoteThreshold = 15000m;

        /// <summary>WILL CALL (8), THIRD (12), IN FREIGHT (7).</summary>
        public static readonly HashSet<int> FreightCodesAllowingWillCallCarrier =
            new HashSet<int> { 8, 12, 7 };

        /// <summary>NO FREIGHT (5), IN FREIGHT (7), FREE DAYS (10), THIRD (12).</summary>
        public static readonly HashSet<int> FreightCodesExemptFromQuote =
            new HashSet<int> { 5, 7, 10, 12 };

        public static readonly string[] FreightItemIds =
            { "FREIGHT CHARGE", "UPS CHARGE", "SPEEDEE CHARGE" };

        public const string FuelSurchargeItemId = "INBOUND FUEL SURCHARGE";
        public const string TopicFreightQuote = "Freight Quote Required";
        public const string TopicSignatureRequired = "Signature Required";
        public const string StatusWillAdvise = "Will Advise";

        /// <summary>
        /// Replaces dbo.kb_table_required_date_statuses (4 rows).
        /// [PRESERVED-BUG] The original lookup had NO row_status_flag filter, so the retired
        /// 2022-02-22 row (row_status_flag 700, not 704) still matches. Kept for equivalence.
        /// </summary>
        public static readonly Dictionary<DateTime, string> RequiredDateStatuses =
            new Dictionary<DateTime, string>
            {
                { new DateTime(2022,  2, 22), "Will Advise" },            // row_status_flag 700 - RETIRED
                { new DateTime(2033,  3,  3), "Ship with Other Goods" },
                { new DateTime(2033,  3, 23), "Reserve" },
                { new DateTime(2049, 12, 31), "Will Advise" },
            };

        #endregion

        /// <summary>
        /// Runs the nine checks in order. First match wins.
        /// Assumes the caller already applied the skip conditions (RMA / quote / cancelled)
        /// and the QualifyingOpenLineCount == 0 short-circuit.
        /// </summary>
        public static ValidationOutcome Validate(OrderSnapshot snap, ReferenceData reference)
        {
            if (snap.DateCreated.HasValue && snap.DateCreated.Value < ValidatorEpoch)
                return ValidationOutcome.Pass();

            // ---- Precursor checks: required header data P21 sometimes lets through ----
            if (!snap.FreightCodeUid.HasValue)
                return ValidationOutcome.Fail("v2err#0",
                    "The FREIGHT CODE on this order is blank.  This field is required.  Please fill in the freight code, " +
                    "located on the Order and/or Ship Info tab, and then retry saving the order.");

            if (snap.Lines.Count == 0)
                return ValidationOutcome.Fail("v2err#0",
                    "No ITEMS exist on this order.  Please add some items and then retry saving the order.");

            if (!snap.ShipToId.HasValue)
                return ValidationOutcome.Fail("v2err#0",
                    "The SHIP TO ID on this order is blank.  This field is required.  Please fill in the ship to ID " +
                    "and then retry saving the order.");

            if (snap.CreditStatus == null)
                return ValidationOutcome.Fail("v2err#0",
                    "The customer CREDIT STATUS on this order is blank.  This field is required.  Please check for a " +
                    "customer credit status and then retry saving the order.");

            if (!snap.CustomerId.HasValue)
                return ValidationOutcome.Fail("v2err#0",
                    "The CUSTOMER ID on this order is blank.  This field is required.  Please fill in the customer ID " +
                    "and then retry saving the order.");

            if (snap.CarrierName == null)
                return ValidationOutcome.Fail("v2err#0",
                    "The CARRIER on this order is blank.  This field is required.  Please fill in the carrier, " +
                    "located on the Order and/or Ship Info tab, and then retry saving the order.");

            if (snap.PackingBasis == null)
                return ValidationOutcome.Fail("v2err#0",
                    "The PACKING BASIS on this order is blank.  This field is required.  Please fill in the packing basis, " +
                    "located on the Order and/or Ship Info tab, and then retry saving the order.");

            // ---- Derived values ----
            int freightCode = snap.FreightCodeUid.Value;
            string packingBasis = snap.PackingBasis;
            bool orderComplete = IsEqual(packingBasis, "Order Complete");

            // The TVF lowercased everything except COD purely for message prose, then compared
            // IN ('COD','CASH','PREPAY') against the lowercased value -- which only worked
            // because the collation is case-insensitive. Made explicit here.
            string creditForProse = IsEqual(snap.CreditStatus, "COD")
                ? "COD"
                : StripBackslashes(snap.CreditStatus.ToLowerInvariant());
            bool codCashPrepay = IsAny(snap.CreditStatus, "COD", "CASH", "PREPAY");

            string carrierName = StripBackslashes(snap.CarrierName);

            bool freightPresent = snap.Lines.Any(l => IsFreightItem(l.ItemId));
            bool freightOpen = snap.Lines.Where(l => IsFreightItem(l.ItemId))
                                         .Sum(l => decimal.Round(l.QtyOpen, 4)) > 0m;
            bool freightZero = !freightPresent
                               || snap.Lines.Where(l => IsFreightItem(l.ItemId))
                                            .Sum(l => l.ExtendedPrice ?? 0m) == 0m;

            decimal orderTotal = decimal.Round(
                snap.Lines.Where(l => reference.CountedItemIds.Contains(l.ItemId))
                          .Sum(l => l.ExtendedPrice ?? 0m), 4);
            bool itemsOpen = decimal.Round(
                snap.Lines.Where(l => reference.CountedItemIds.Contains(l.ItemId))
                          .Sum(l => l.QtyOpen), 4) > 0m;

            string orderStatus = LookupRequiredDateStatus(snap.RequestedDate);

            // NULL-safe by construction: a carrier that matched nothing leaves CarrierWillCall
            // null, so BOTH of these are false -- exactly SQL's UNKNOWN behavior.
            // [PRESERVED-BUG] An unrecognized carrier therefore bypasses checks 1, 3, 4 and 6
            // entirely and the order saves unvalidated.
            bool willCallCarrier = IsEqual(reference.CarrierWillCall, "Y");
            bool notWillCallCarrier = IsEqual(reference.CarrierWillCall, "N");

            bool freightAutoAdds = IsEqual(reference.FreightAutoAdds, "Y");
            string freightMessage = BuildFreightMessage(carrierName, reference);

            // ================= ORDERED CHECK CHAIN -- first match wins =================

            // 1: auto-add freight on a COD/CASH/PREPAY, non-will-call order.
            if (codCashPrepay && freightAutoAdds && notWillCallCarrier)
            {
                if (freightPresent)
                    return ValidationOutcome.Fail("v2err#1a",
                        "You have manually added the freight charge because this customer has a credit status of " +
                        creditForProse + ", and the order is not a will call order.  However, you must also change the " +
                        "Freight Code to something else, because leaving it as " + reference.FreightCodeName +
                        " will cause the freight charge to be applied again on invoicing.  " +
                        "To fix this, one solution is: \r\n\r\n" +
                        "— Change the Freight Code on the Ship Info tab to Prepaid\r\n" +
                        "\r\nAfter doing this, please retry saving the order.  ");

                return ValidationOutcome.Fail("v2err#1c",
                    "This customer has a credit status of " + creditForProse +
                    ", so the freight will need to be added manually and you must also change the Freight Code.  " +
                    "Leaving it as " + reference.FreightCodeName +
                    " will cause the freight charge to be applied again on invoicing.  " +
                    "To fix this, one solution is: \r\n\r\n" +
                    "— Change the Freight Code on the Ship Info tab to Prepaid, AND \r\n" +
                    "— " + freightMessage + "\r\n" +
                    "\r\nAfter doing this, please retry saving the order.");
            }

            // 2: freight would be charged twice.
            if (freightAutoAdds && freightPresent && orderComplete)
                return ValidationOutcome.Fail("v2err#2a",
                    "This order has " + reference.FreightCodeName + " for the Freight Code and ships with the packing basis " +
                    packingBasis + ", but the Freight Charge item has been added manually to this order.  " +
                    "This will cause the freight charge to be applied to this order twice.  " +
                    "To fix this: \r\n\r\n" +
                    "— Remove the Freight Charge line item from this order, OR\r\n" +
                    "— Change the Freight Code on the Ship Info tab to Prepaid \r\n" +
                    "\r\nAfter doing this, please retry saving the order.");

            if (freightAutoAdds && freightOpen && !orderComplete)
                return ValidationOutcome.Fail("v2err#2b",
                    "This order has " + reference.FreightCodeName + " for the Freight Code and ships with the packing basis " +
                    packingBasis + ", but a Freight Charge item is still open and has already been added manually to this order.  " +
                    "This will cause the freight charge to be applied to this order too many times.  " +
                    "To fix this: \r\n\r\n" +
                    "— Remove the open Freight Charge line item from this order, OR\r\n" +
                    "— Change the Freight Code on the Ship Info tab to Prepaid \r\n" +
                    "\r\nAfter doing this, please retry saving the order.");

            // 3: prepaid freight code but no freight charge item.
            if (freightCode == FreightCodePrepaid && !freightPresent && notWillCallCarrier && orderComplete)
                return ValidationOutcome.Fail("v2err#3a",
                    "This order has " + reference.FreightCodeName + " for the Freight Code and a packing basis of " +
                    packingBasis + ", but the Freight Charge item is missing from this order.  " +
                    "To fix this: \r\n\r\n" +
                    "— " + freightMessage + "\r\n" +
                    "\r\nAfter doing this, please retry saving the order.");

            if (freightCode == FreightCodePrepaid && !freightOpen && itemsOpen && notWillCallCarrier && !orderComplete)
                return ValidationOutcome.Fail("v2err#3b",
                    "This order has " + reference.FreightCodeName + " for the Freight Code and a packing basis of " +
                    packingBasis + ", but there are open items on this order and no open Freight Charge item.  " +
                    "To fix this: \r\n\r\n" +
                    "— " + freightMessage + "\r\n" +
                    "\r\nAfter doing this, please retry saving the order.");

            // 4: will-call setting mismatch.
            if (freightCode == FreightCodeWillCall && notWillCallCarrier)
                return ValidationOutcome.Fail("v2err#4a",
                    "This order has " + reference.FreightCodeName + " for the Freight Code, but the carrier, " +
                    carrierName + ", is not marked as being a Will Call carrier.  " +
                    "To fix this: \r\n\r\n" +
                    "— Change the Carrier on the Ship Info tab to a Will Call one, OR \r\n" +
                    "— Change the Freight Code on the Ship Info tab (to Out Freight or No Freight, for example)\r\n" +
                    "\r\nAfter doing this, please retry saving the order.");

            if (!FreightCodesAllowingWillCallCarrier.Contains(freightCode) && willCallCarrier)
                return ValidationOutcome.Fail("v2err#4c",
                    "This order has " + reference.FreightCodeName + " for the Freight Code, but the carrier, " +
                    carrierName + ", is marked as a Will Call carrier.  " +
                    "To fix this: \r\n\r\n" +
                    "— Change the Carrier on the Ship Info tab to no longer be a Will Call one, OR \r\n" +
                    "— Change the Freight Code on the Ship Info tab to WILL CALL\r\n" +
                    "\r\nAfter doing this, please retry saving the order.");

            // 5 (inbound fuel surcharge missing) is intentionally ABSENT and must stay absent.
            // Its guard was `@fuel_message <> ''`, and @fuel_message became unreachable when the
            // Atlas cutover hardcoded @a_schg_on = 'Y' (a literal, never reassigned, feeding
            // `CASE WHEN @a_schg_on='Y' THEN ''`). Atlas owns this check now.

            // 6: freight quote / Will Advise required date.
            if (orderStatus != StatusWillAdvise && codCashPrepay && freightZero && notWillCallCarrier
                && !FreightCodesExemptFromQuote.Contains(freightCode))
                return ValidationOutcome.Fail("v2err#6a",
                    "This order is not ready to be picked and instead needs to be placed on Will Advise, because a freight " +
                    "quote is needed.  The customer has a " + creditForProse + " credit status, the carrier is not a will call, " +
                    "and the freight amount on the order is zero.  To fix this: \r\n\r\n" +
                    "— Change the Required Date to 12/31/49\r\n" +
                    "\r\nAfter doing this, please retry saving the order.");

            if (orderStatus == StatusWillAdvise && !freightZero && snap.FreightQuoteNotePresent
                && notWillCallCarrier && !FreightCodesExemptFromQuote.Contains(freightCode))
                return ValidationOutcome.Fail("v2err#6b",
                    "This order may be ready to be picked but is placed on Will Advise, because a freight quote was needed " +
                    "and was recently added.  To fix this: \r\n\r\n" +
                    "— Update the Required Date (using the button if needed), OR \r\n" +
                    "— If the order needs to remain on Will Advise, set the Freight Quote Required note to no longer be " +
                    "Mandatory (uncheck it)\r\n" +
                    "\r\nAfter doing this, please retry saving the order.");

            // 7: large order needs the signature note.
            // A NULL order_type must NOT fire this -- SQL's `NULL NOT IN (...)` is UNKNOWN.
            if (orderTotal >= SignatureNoteThreshold && !snap.SignatureNotePresent
                && snap.OrderType != null && !IsEqual(snap.OrderType, "CUO Entry"))
                return ValidationOutcome.Fail("v2err#7",
                    "This order has over $15,000 of product on it, but it does not have the Signature Required order " +
                    "header note.  To fix this: \r\n\r\n" +
                    "— Go to the Order Notes tab in the order header, click the Add Note button, select the " +
                    "\"Signature Required: Large Order\" Notepad Class to populate the note, and then add this note to " +
                    "Print Invoices and Print Order Acknowledgements. \r\n" +
                    "\r\nAfter doing this, please retry saving the order.");

            return ValidationOutcome.Pass();
        }

        /// <summary>
        /// Three branches, all three exercised by matrix cases 12, 13 and 5 respectively.
        /// Branch 1 is the only caller of NumberShorten.
        /// </summary>
        public static string BuildFreightMessage(string carrierName, ReferenceData reference)
        {
            const string prefix = "Add Freight Charge item, quantity 1, ";
            bool sameCarrier = IsEqual(carrierName, reference.DefaultCarrierName);

            // FreightCharge is null when the ship-to row was not found. In SQL both `<> 0.0`
            // and `= 0.0` were UNKNOWN then, so control fell to the ELSE. Same here.
            if (sameCarrier && reference.FreightCharge.HasValue && reference.FreightCharge.Value != 0m)
                return prefix + "price " + NumberShorten((double)reference.FreightCharge.Value, true) + " each";

            if (sameCarrier && reference.FreightCharge.HasValue && reference.FreightCharge.Value == 0m)
                return prefix + "price $0 \r\nThis will allow you to save the order and ask Susan to set the default " +
                       "Freight Charge on this Ship To because it is missing.  You'll need to add the real price once you get it";

            return prefix + "price $0 \r\nThis will allow you to save the order and get a quote for the price of freight using " +
                   carrierName + " since their normal carrier is " + reference.DefaultCarrierName +
                   ". You'll need to add the real price once you get it";
        }

        public static string LookupRequiredDateStatus(DateTime? requestedDate)
        {
            if (!requestedDate.HasValue) return string.Empty;
            string status;
            // The SQL compared full DATETIME equality; .Date makes a stray time component
            // match rather than silently miss. Identical for midnight values.
            return RequiredDateStatuses.TryGetValue(requestedDate.Value.Date, out status)
                ? status
                : string.Empty;
        }

        public static bool IsFreightItem(string itemId)
        {
            return itemId != null &&
                   FreightItemIds.Any(f => f.Equals(itemId, StringComparison.OrdinalIgnoreCase));
        }

        #region kb_fn_number_shorten port

        /// <summary>
        /// Faithful port of dbo.kb_fn_number_shorten(@conversion_number FLOAT, @dollars TINYINT).
        /// Verified against all 32 values in Capture-OldValidator-Matrix.sql STEP 3b.
        ///
        /// Two traps, both load-bearing:
        ///  - T-SQL ROUND() is half-AWAY-FROM-ZERO; .NET Math.Round defaults to banker's.
        ///  - Every threshold is a strict '>' so the exact boundary falls to the branch BELOW:
        ///    1000 -> "1000", but 1000.01 -> "1.0k"; 10000 -> "10.0k", 10000.01 -> "10k".
        ///  - The '$' goes AFTER the minus sign (STUFF(v,2,0,'$')), giving "-$1.50".
        /// </summary>
        public static string NumberShorten(double n, bool dollars)
        {
            CultureInfo inv = CultureInfo.InvariantCulture;
            string v;

            if (n > 10000000000d || n < -10000000000d)
                v = RoundAway(n / 1000000000d, 0).ToString("#,##0bln;-#,##0bln", inv);
            else if (n > 1000000000d || n < -1000000000d)
                v = RoundAway(n / 1000000000d, 1).ToString("0.0bln;-0.0bln", inv);
            else if (n > 10000000d || n < -10000000d)
                v = RoundAway(n / 1000000d, 0).ToString("0mln;-0mln", inv);
            else if (n > 1000000d || n < -1000000d)
                v = RoundAway(n / 1000000d, 1).ToString("0.0mln;-0.0mln", inv);
            else if (n > 10000d || n < -10000d)
                v = RoundAway(n / 1000d, 0).ToString("0k;-0k", inv);
            else if (n > 1000d || n < -1000d)
                v = RoundAway(n / 1000d, 1).ToString("0.0k;-0.0k", inv);
            else if (n > 100d || n < -100d)
                v = n.ToString("0", inv);
            else
                v = Math.Truncate(n) == n ? n.ToString("0", inv) : n.ToString("0.00", inv);

            if (!dollars) return v;
            return n < 0 ? v.Insert(1, "$") : "$" + v;
        }

        private static double RoundAway(double x, int digits)
        {
            return Math.Round(x, digits, MidpointRounding.AwayFromZero);
        }

        #endregion

        #region Comparison helpers

        /// <summary>
        /// Constant-first and case-insensitive: null-safe, and mirrors SQL's CI collation.
        /// A null value yields false, which is how SQL's UNKNOWN behaves in these predicates.
        /// </summary>
        public static bool IsEqual(string value, string expected)
        {
            return expected.Equals(value, StringComparison.OrdinalIgnoreCase);
        }

        public static bool IsAny(string value, params string[] options)
        {
            if (value == null) return false;
            for (int i = 0; i < options.Length; i++)
                if (options[i].Equals(value, StringComparison.OrdinalIgnoreCase)) return true;
            return false;
        }

        /// <summary>
        /// The TVF stripped backslashes before interpolating these into messages, because the
        /// C# then ran Regex.Unescape over the result. We no longer use Regex.Unescape, but
        /// the stripping stays so message text matches character for character.
        /// </summary>
        public static string StripBackslashes(string s)
        {
            return s == null ? null : s.Replace("\\", string.Empty);
        }

        #endregion
    }
}
