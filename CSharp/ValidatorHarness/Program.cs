// ValidatorHarness / Program.cs
//
// Replays the Capture-OldValidator-Matrix.sql cases through OrderValidationEngine.Validate()
// and diffs verdict + FULL MESSAGE TEXT against what dbo.kb_fnt_br_order_validator_v2
// actually returned in BRR on 2026-09-01.
//
// No P21, no database. Compile with OrderValidationEngine.cs alone:
//     csc /out:ValidatorHarness.exe Program.cs ..\OrderValidationEngine.cs
// (or add both to a console project targeting .NET Framework 4.7.2)
//
// WHY TEXT AND NOT JUST THE CODE: matrix cases 12/13 once reported PASS on a matching
// expected_code while silently testing nothing -- a truncated variable made them duplicate
// another case that happened to expect the same code. Only the message text distinguishes a
// real pass from a coincidental one.
//
// SEED VALUES are pinned below. They are baked into the expected strings (freight code
// descriptions, carrier names), so if the matrix is re-run in a different environment these
// must be updated from that run's #seed output or every text comparison will fail.

using System;
using System.Collections.Generic;
using System.Linq;
using asi_Order_Validator;

internal static class Program
{
    // ---- Seeds, from Capture-OldValidator-Matrix.sql STEP 0 (BRR, 2026-09-01) ----
    const string NONWC_CARRIER = "Wood Dale - 100";
    const string WC_CARRIER    = "Will Call";
    const string ST380_DEFAULT = "Denver";           // default carrier of SHIP_TO 380
    const decimal ST380_FREIGHT = 0m;                // its val_freight
    const string ST1000310_DEFAULT = "Wood Dale - 100";
    const decimal ST1000310_FREIGHT = 110m;
    const string STOCK_ITEM = "STOCKITEM";           // identity is irrelevant; only membership
                                                     // of CountedItemIds matters
    const string FC2_DESC = "Out Freight";           // FC_AUTOADD, outgoing_freight = Y
    const string FC9_DESC = "UPS (Manual Entry)";    // FC_NOAUTO,  outgoing_freight = N
    const string FC6_DESC = "Prepaid";
    const string FC8_DESC = "Will Call (No Freight)";
    const string FC12_DESC = "Third";                // never reaches a message

    static int Main()
    {
        int failures = 0;
        failures += RunNumberShortenTests();
        failures += RunMatrixTests();

        Console.WriteLine();
        Console.WriteLine(failures == 0
            ? "ALL TESTS PASSED"
            : failures + " FAILURE(S)");
        return failures == 0 ? 0 : 1;
    }

    #region kb_fn_number_shorten -- STEP 3b reference table

    static int RunNumberShortenTests()
    {
        // input, dollars_off, dollars_on -- verbatim from Capture-OldValidator-Matrix.sql STEP 3b.
        var cases = new[]
        {
            Tuple.Create(-1500000.00, "-1.5mln", "-$1.5mln"),
            Tuple.Create(-15000.00,   "-15k",    "-$15k"),
            Tuple.Create(-1500.00,    "-1.5k",   "-$1.5k"),
            Tuple.Create(-110.00,     "-110",    "-$110"),
            Tuple.Create(-1.50,       "-1.50",   "-$1.50"),
            Tuple.Create(0.00,        "0",       "$0"),
            Tuple.Create(1.00,        "1",       "$1"),
            Tuple.Create(1.50,        "1.50",    "$1.50"),
            Tuple.Create(99.99,       "99.99",   "$99.99"),
            Tuple.Create(100.00,      "100",     "$100"),
            Tuple.Create(100.01,      "100",     "$100"),
            Tuple.Create(110.00,      "110",     "$110"),
            Tuple.Create(999.99,      "1000",    "$1000"),   // rounds up past its own branch
            Tuple.Create(1000.00,     "1000",    "$1000"),   // strict > : boundary falls BELOW
            Tuple.Create(1000.01,     "1.0k",    "$1.0k"),
            Tuple.Create(1500.00,     "1.5k",    "$1.5k"),
            Tuple.Create(1550.00,     "1.6k",    "$1.6k"),   // half-away-from-zero
            Tuple.Create(9999.99,     "10.0k",   "$10.0k"),
            Tuple.Create(10000.00,    "10.0k",   "$10.0k"),
            Tuple.Create(10000.01,    "10k",     "$10k"),
            Tuple.Create(15000.00,    "15k",     "$15k"),
            Tuple.Create(15500.00,    "16k",     "$16k"),
            Tuple.Create(999999.99,   "1000k",   "$1000k"),  // never becomes 1.0mln
            Tuple.Create(1000000.00,  "1000k",   "$1000k"),
            Tuple.Create(1000000.01,  "1.0mln",  "$1.0mln"),
            Tuple.Create(1500000.00,  "1.5mln",  "$1.5mln"),
            Tuple.Create(10000000.01, "10mln",   "$10mln"),
            Tuple.Create(15000000.00, "15mln",   "$15mln"),
            Tuple.Create(1000000000.01,  "1.0bln",  "$1.0bln"),
            Tuple.Create(1500000000.00,  "1.5bln",  "$1.5bln"),
            Tuple.Create(10000000000.01, "10bln",   "$10bln"),
            Tuple.Create(15000000000.00, "15bln",   "$15bln"),
        };

        Console.WriteLine("=== NumberShorten (32 cases) ===");
        int fails = 0;
        foreach (var c in cases)
        {
            string off = OrderValidationEngine.NumberShorten(c.Item1, false);
            string on  = OrderValidationEngine.NumberShorten(c.Item1, true);
            if (off != c.Item2 || on != c.Item3)
            {
                fails++;
                Console.WriteLine("  FAIL {0}: expected [{1}] [{2}], got [{3}] [{4}]",
                                  c.Item1, c.Item2, c.Item3, off, on);
            }
        }
        Console.WriteLine(fails == 0 ? "  all 32 OK" : "  " + fails + " failed");
        return fails;
    }

    #endregion

    #region Matrix replay

    sealed class Case
    {
        public int Id;
        public string Descr;
        public string Credit = "NORMAL";
        public int FreightCode;
        public string FreightCodeDesc;
        public bool AutoAdds;
        public string Packing = "Order Complete";
        public string Carrier;
        public string DefaultCarrier;
        public decimal? FreightCharge;
        public DateTime ReqDate = new DateTime(2026, 6, 1);
        public DateTime Created = new DateTime(2026, 1, 1);
        public string OrderType = "OE";
        public string WillCall = "N";
        public decimal? FreightAmt;
        public decimal FreightOpen;
        public decimal? StockAmt;
        public decimal StockOpen;
        public bool FreightNote;
        public bool SigNote;
        /// <summary>Expected message in SQL form (literal \r\n). Null = expected to pass.</summary>
        public string Expected;
    }

    static int RunMatrixTests()
    {
        var cases = BuildCases();
        Console.WriteLine();
        Console.WriteLine("=== Matrix replay ({0} cases) ===", cases.Count);

        int fails = 0;
        foreach (var c in cases)
        {
            var snap = new OrderSnapshot
            {
                OrderNo = "SYNTH",
                DateCreated = c.Created,
                RequestedDate = c.ReqDate,
                FreightCodeUid = c.FreightCode,
                ShipToId = 380m,
                CustomerId = 12345m,
                CarrierName = c.Carrier,
                PackingBasis = c.Packing,
                CreditStatus = c.Credit,
                OrderType = c.OrderType,
                FreightQuoteNotePresent = c.FreightNote,
                SignatureNotePresent = c.SigNote
            };

            if (c.FreightAmt.HasValue)
                snap.Lines.Add(new OrderLine
                { ItemId = "FREIGHT CHARGE", QtyOpen = c.FreightOpen, ExtendedPrice = c.FreightAmt });
            if (c.StockAmt.HasValue)
                snap.Lines.Add(new OrderLine
                { ItemId = STOCK_ITEM, QtyOpen = c.StockOpen, ExtendedPrice = c.StockAmt });

            snap.QualifyingOpenLineCount = snap.Lines.Count(l => l.QtyOpen > 0m);

            var reference = new ReferenceData
            {
                FreightAutoAdds = c.AutoAdds ? "Y" : "N",
                FreightCodeName = c.FreightCodeDesc,
                CarrierWillCall = c.WillCall,
                DefaultCarrierName = c.DefaultCarrier,
                FreightCharge = c.FreightCharge
            };
            // FREIGHT CHARGE sits in product group OCHARGE and is excluded from @order_total
            // and @items_open; only the stock item counts.
            reference.CountedItemIds.Add(STOCK_ITEM);

            ValidationOutcome outcome = OrderValidationEngine.Validate(snap, reference);

            string expected = c.Expected == null ? null : Unescape(c.Expected);
            string actual = outcome.Message;

            bool ok = string.Equals(expected, actual, StringComparison.Ordinal)
                      && (c.Expected == null) == outcome.Passed;

            if (!ok)
            {
                fails++;
                Console.WriteLine("  FAIL {0} {1}", c.Id, c.Descr);
                Console.WriteLine("    expected passed={0}", c.Expected == null);
                Console.WriteLine("    actual   passed={0}", outcome.Passed);
                if (expected != actual)
                {
                    Console.WriteLine("    expected: {0}", Show(expected));
                    Console.WriteLine("    actual  : {0}", Show(actual));
                    int i = FirstDiff(expected, actual);
                    if (i >= 0) Console.WriteLine("    first difference at index {0}", i);
                }
            }
        }
        Console.WriteLine(fails == 0 ? "  all " + cases.Count + " OK" : "  " + fails + " failed");
        return fails;
    }

    /// <summary>
    /// The TVF stores messages with LITERAL backslash-r-backslash-n; the engine emits real
    /// CRLF. Converting here (rather than in the engine) is what proves replacing
    /// Regex.Unescape with a targeted replace was safe.
    /// </summary>
    static string Unescape(string s)
    {
        return s.Replace("\\r\\n", "\r\n");
    }

    static string Show(string s)
    {
        if (s == null) return "(null)";
        return s.Replace("\r", "\\r").Replace("\n", "\\n");
    }

    static int FirstDiff(string a, string b)
    {
        if (a == null || b == null) return 0;
        int n = Math.Min(a.Length, b.Length);
        for (int i = 0; i < n; i++) if (a[i] != b[i]) return i;
        return a.Length == b.Length ? -1 : n;
    }

    static List<Case> BuildCases()
    {
        // Expected strings are copied VERBATIM from the matrix run's result_message column.
        return new List<Case>
        {
new Case { Id=1, Descr="S1a auto-freight + COD, freight added manually", Credit="COD",
    FreightCode=2, FreightCodeDesc=FC2_DESC, AutoAdds=true, Carrier=NONWC_CARRIER,
    DefaultCarrier=ST380_DEFAULT, FreightCharge=ST380_FREIGHT,
    FreightAmt=50m, FreightOpen=1m, StockAmt=100m, StockOpen=1m,
    Expected=@"[v2err#1a] You have manually added the freight charge because this customer has a credit status of COD, and the order is not a will call order.  However, you must also change the Freight Code to something else, because leaving it as Out Freight will cause the freight charge to be applied again on invoicing.  To fix this, one solution is: \r\n\r\n— Change the Freight Code on the Ship Info tab to Prepaid\r\n\r\nAfter doing this, please retry saving the order.  " },

new Case { Id=2, Descr="S1c auto-freight + COD, no freight item", Credit="COD",
    FreightCode=2, FreightCodeDesc=FC2_DESC, AutoAdds=true, Carrier=NONWC_CARRIER,
    DefaultCarrier=ST380_DEFAULT, FreightCharge=ST380_FREIGHT,
    StockAmt=100m, StockOpen=1m,
    Expected=@"[v2err#1c] This customer has a credit status of COD, so the freight will need to be added manually and you must also change the Freight Code.  Leaving it as Out Freight will cause the freight charge to be applied again on invoicing.  To fix this, one solution is: \r\n\r\n— Change the Freight Code on the Ship Info tab to Prepaid, AND \r\n— Add Freight Charge item, quantity 1, price $0 \r\nThis will allow you to save the order and get a quote for the price of freight using Wood Dale - 100 since their normal carrier is Denver. You'll need to add the real price once you get it\r\n\r\nAfter doing this, please retry saving the order." },

new Case { Id=3, Descr="S2a auto-freight + freight present + Order Cmp",
    FreightCode=2, FreightCodeDesc=FC2_DESC, AutoAdds=true, Carrier=NONWC_CARRIER,
    DefaultCarrier=ST380_DEFAULT, FreightCharge=ST380_FREIGHT,
    FreightAmt=50m, FreightOpen=1m, StockAmt=100m, StockOpen=1m,
    Expected=@"[v2err#2a] This order has Out Freight for the Freight Code and ships with the packing basis Order Complete, but the Freight Charge item has been added manually to this order.  This will cause the freight charge to be applied to this order twice.  To fix this: \r\n\r\n— Remove the Freight Charge line item from this order, OR\r\n— Change the Freight Code on the Ship Info tab to Prepaid \r\n\r\nAfter doing this, please retry saving the order." },

new Case { Id=4, Descr="S2b auto-freight + freight OPEN + partial",
    FreightCode=2, FreightCodeDesc=FC2_DESC, AutoAdds=true, Packing="Item Complete",
    Carrier=NONWC_CARRIER, DefaultCarrier=ST380_DEFAULT, FreightCharge=ST380_FREIGHT,
    FreightAmt=50m, FreightOpen=1m, StockAmt=100m, StockOpen=1m,
    Expected=@"[v2err#2b] This order has Out Freight for the Freight Code and ships with the packing basis Item Complete, but a Freight Charge item is still open and has already been added manually to this order.  This will cause the freight charge to be applied to this order too many times.  To fix this: \r\n\r\n— Remove the open Freight Charge line item from this order, OR\r\n— Change the Freight Code on the Ship Info tab to Prepaid \r\n\r\nAfter doing this, please retry saving the order." },

new Case { Id=5, Descr="S3a prepaid(6) + no freight item + Order Cmp",
    FreightCode=6, FreightCodeDesc=FC6_DESC, Carrier=NONWC_CARRIER,
    DefaultCarrier=ST380_DEFAULT, FreightCharge=ST380_FREIGHT, StockAmt=100m, StockOpen=1m,
    Expected=@"[v2err#3a] This order has Prepaid for the Freight Code and a packing basis of Order Complete, but the Freight Charge item is missing from this order.  To fix this: \r\n\r\n— Add Freight Charge item, quantity 1, price $0 \r\nThis will allow you to save the order and get a quote for the price of freight using Wood Dale - 100 since their normal carrier is Denver. You'll need to add the real price once you get it\r\n\r\nAfter doing this, please retry saving the order." },

new Case { Id=6, Descr="S3b prepaid(6) + no OPEN freight + items open",
    FreightCode=6, FreightCodeDesc=FC6_DESC, Packing="Item Complete", Carrier=NONWC_CARRIER,
    DefaultCarrier=ST380_DEFAULT, FreightCharge=ST380_FREIGHT,
    FreightAmt=50m, FreightOpen=0m, StockAmt=100m, StockOpen=1m,
    Expected=@"[v2err#3b] This order has Prepaid for the Freight Code and a packing basis of Item Complete, but there are open items on this order and no open Freight Charge item.  To fix this: \r\n\r\n— Add Freight Charge item, quantity 1, price $0 \r\nThis will allow you to save the order and get a quote for the price of freight using Wood Dale - 100 since their normal carrier is Denver. You'll need to add the real price once you get it\r\n\r\nAfter doing this, please retry saving the order." },

new Case { Id=7, Descr="S4a will-call code(8) + non-will-call carrier",
    FreightCode=8, FreightCodeDesc=FC8_DESC, Carrier=NONWC_CARRIER,
    DefaultCarrier=ST380_DEFAULT, FreightCharge=ST380_FREIGHT, StockAmt=100m, StockOpen=1m,
    Expected=@"[v2err#4a] This order has Will Call (No Freight) for the Freight Code, but the carrier, Wood Dale - 100, is not marked as being a Will Call carrier.  To fix this: \r\n\r\n— Change the Carrier on the Ship Info tab to a Will Call one, OR \r\n— Change the Freight Code on the Ship Info tab (to Out Freight or No Freight, for example)\r\n\r\nAfter doing this, please retry saving the order." },

new Case { Id=8, Descr="S4c will-call carrier + non-will-call code",
    FreightCode=9, FreightCodeDesc=FC9_DESC, Carrier=WC_CARRIER, WillCall="Y",
    DefaultCarrier=ST380_DEFAULT, FreightCharge=ST380_FREIGHT, StockAmt=100m, StockOpen=1m,
    Expected=@"[v2err#4c] This order has UPS (Manual Entry) for the Freight Code, but the carrier, Will Call, is marked as a Will Call carrier.  To fix this: \r\n\r\n— Change the Carrier on the Ship Info tab to no longer be a Will Call one, OR \r\n— Change the Freight Code on the Ship Info tab to WILL CALL\r\n\r\nAfter doing this, please retry saving the order." },

new Case { Id=9, Descr="S6a COD + zero freight + not Will Advise", Credit="COD",
    FreightCode=9, FreightCodeDesc=FC9_DESC, Carrier=NONWC_CARRIER,
    DefaultCarrier=ST380_DEFAULT, FreightCharge=ST380_FREIGHT, StockAmt=100m, StockOpen=1m,
    Expected=@"[v2err#6a] This order is not ready to be picked and instead needs to be placed on Will Advise, because a freight quote is needed.  The customer has a COD credit status, the carrier is not a will call, and the freight amount on the order is zero.  To fix this: \r\n\r\n— Change the Required Date to 12/31/49\r\n\r\nAfter doing this, please retry saving the order." },

new Case { Id=10, Descr="S6b Will Advise + freight non-zero + note",
    FreightCode=9, FreightCodeDesc=FC9_DESC, Carrier=NONWC_CARRIER,
    DefaultCarrier=ST380_DEFAULT, FreightCharge=ST380_FREIGHT,
    ReqDate=new DateTime(2049,12,31), FreightAmt=50m, FreightOpen=1m,
    StockAmt=100m, StockOpen=1m, FreightNote=true,
    Expected=@"[v2err#6b] This order may be ready to be picked but is placed on Will Advise, because a freight quote was needed and was recently added.  To fix this: \r\n\r\n— Update the Required Date (using the button if needed), OR \r\n— If the order needs to remain on Will Advise, set the Freight Quote Required note to no longer be Mandatory (uncheck it)\r\n\r\nAfter doing this, please retry saving the order." },

new Case { Id=11, Descr="S7 order over $15k with no signature note",
    FreightCode=9, FreightCodeDesc=FC9_DESC, Carrier=NONWC_CARRIER,
    DefaultCarrier=ST380_DEFAULT, FreightCharge=ST380_FREIGHT, StockAmt=16000m, StockOpen=1m,
    Expected="[v2err#7] This order has over $15,000 of product on it, but it does not have the Signature Required order header note.  To fix this: \\r\\n\\r\\n— Go to the Order Notes tab in the order header, click the Add Note button, select the \"Signature Required: Large Order\" Notepad Class to populate the note, and then add this note to Print Invoices and Print Order Acknowledgements. \\r\\n\\r\\nAfter doing this, please retry saving the order." },

// The two branches that only reach the message via the ship-to's OWN default carrier.
// Case 12 is the only path that calls NumberShorten.
new Case { Id=12, Descr="S3a w/ default carrier + NON-ZERO freight charge",
    FreightCode=6, FreightCodeDesc=FC6_DESC, Carrier=ST1000310_DEFAULT,
    DefaultCarrier=ST1000310_DEFAULT, FreightCharge=ST1000310_FREIGHT,
    StockAmt=100m, StockOpen=1m,
    Expected=@"[v2err#3a] This order has Prepaid for the Freight Code and a packing basis of Order Complete, but the Freight Charge item is missing from this order.  To fix this: \r\n\r\n— Add Freight Charge item, quantity 1, price $110 each\r\n\r\nAfter doing this, please retry saving the order." },

new Case { Id=13, Descr="S3a w/ default carrier + ZERO freight charge",
    FreightCode=6, FreightCodeDesc=FC6_DESC, Carrier=ST380_DEFAULT,
    DefaultCarrier=ST380_DEFAULT, FreightCharge=0m, StockAmt=100m, StockOpen=1m,
    Expected=@"[v2err#3a] This order has Prepaid for the Freight Code and a packing basis of Order Complete, but the Freight Charge item is missing from this order.  To fix this: \r\n\r\n— Add Freight Charge item, quantity 1, price $0 \r\nThis will allow you to save the order and ask Susan to set the default Freight Charge on this Ship To because it is missing.  You'll need to add the real price once you get it\r\n\r\nAfter doing this, please retry saving the order." },

// ===== NEGATIVES: must pass, Expected = null =====
new Case { Id=20, Descr="clean order, nothing wrong", FreightCode=9, FreightCodeDesc=FC9_DESC,
    Carrier=NONWC_CARRIER, DefaultCarrier=ST380_DEFAULT, FreightCharge=ST380_FREIGHT,
    FreightAmt=50m, FreightOpen=1m, StockAmt=100m, StockOpen=1m },

new Case { Id=21, Descr="S7 boundary: 14999.99 under threshold", FreightCode=9,
    FreightCodeDesc=FC9_DESC, Carrier=NONWC_CARRIER, DefaultCarrier=ST380_DEFAULT,
    FreightCharge=ST380_FREIGHT, FreightAmt=50m, FreightOpen=1m,
    StockAmt=14999.99m, StockOpen=1m },

new Case { Id=22, Descr="S7 exempt: CUO Entry", FreightCode=9, FreightCodeDesc=FC9_DESC,
    Carrier=NONWC_CARRIER, DefaultCarrier=ST380_DEFAULT, FreightCharge=ST380_FREIGHT,
    OrderType="CUO Entry", FreightAmt=50m, FreightOpen=1m, StockAmt=16000m, StockOpen=1m },

new Case { Id=23, Descr="S7 satisfied: signature note present", FreightCode=9,
    FreightCodeDesc=FC9_DESC, Carrier=NONWC_CARRIER, DefaultCarrier=ST380_DEFAULT,
    FreightCharge=ST380_FREIGHT, FreightAmt=50m, FreightOpen=1m,
    StockAmt=16000m, StockOpen=1m, SigNote=true },

new Case { Id=24, Descr="S6a exempt: freight code 12", Credit="COD", FreightCode=12,
    FreightCodeDesc=FC12_DESC, Carrier=NONWC_CARRIER, DefaultCarrier=ST380_DEFAULT,
    FreightCharge=ST380_FREIGHT, StockAmt=100m, StockOpen=1m },

new Case { Id=25, Descr="S4c allowed: will-call carrier + code 12", FreightCode=12,
    FreightCodeDesc=FC12_DESC, Carrier=WC_CARRIER, WillCall="Y",
    DefaultCarrier=ST380_DEFAULT, FreightCharge=ST380_FREIGHT, StockAmt=100m, StockOpen=1m },

new Case { Id=26, Descr="S6a satisfied: freight non-zero", Credit="COD", FreightCode=9,
    FreightCodeDesc=FC9_DESC, Carrier=NONWC_CARRIER, DefaultCarrier=ST380_DEFAULT,
    FreightCharge=ST380_FREIGHT, FreightAmt=50m, FreightOpen=1m,
    StockAmt=100m, StockOpen=1m },

new Case { Id=27, Descr="S6b not met: Will Advise but no freight note", FreightCode=9,
    FreightCodeDesc=FC9_DESC, Carrier=NONWC_CARRIER, DefaultCarrier=ST380_DEFAULT,
    FreightCharge=ST380_FREIGHT, ReqDate=new DateTime(2049,12,31),
    FreightAmt=50m, FreightOpen=1m, StockAmt=100m, StockOpen=1m },

new Case { Id=28, Descr="S5 gap case -- nothing should fire", Credit="COD", FreightCode=9,
    FreightCodeDesc=FC9_DESC, Carrier=NONWC_CARRIER, DefaultCarrier=ST380_DEFAULT,
    FreightCharge=ST380_FREIGHT, FreightAmt=50m, FreightOpen=1m,
    StockAmt=100m, StockOpen=1m },

new Case { Id=29, Descr="pre-2018 order: always allowed", Credit="COD", FreightCode=2,
    FreightCodeDesc=FC2_DESC, AutoAdds=true, Carrier=NONWC_CARRIER,
    DefaultCarrier=ST380_DEFAULT, FreightCharge=ST380_FREIGHT,
    Created=new DateTime(2018,1,1), StockAmt=100m, StockOpen=1m },
        };
    }

    #endregion
}
