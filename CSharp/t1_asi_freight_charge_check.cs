using P21.Extensions.BusinessRule;
using System;

// Change History:
// 2026-05-06 MG - Created. Caps qty_shipped to 1 when item_id is "FREIGHT CHARGE".
//                 Fixed: file-scoped namespace (C# 7.3 compat), GetFieldByAlias → Fields[] indexer,
//                 redundant Decimal.Parse replaced with TryParse result variable.

namespace FreightChargeNotGreaterThan1
{
    public class t1_asi_freight_charge_check : Rule
    {
        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();
            if (string.Equals(this.Data.Fields["item_id"].FieldValue, "FREIGHT CHARGE"))
            {
                Decimal result = 0M;
                if (Decimal.TryParse(this.Data.Fields["qty_shipped"].FieldValue, out result) && result > 1M)
                {
                    this.Data.Fields["qty_shipped"].FieldValue = "1";
                }
            }
            return ruleResult;
        }

        public override string GetName() => "Shipping - Freight Charge Check";

        public override string GetDescription() => "Caps qty shipped to 1 when the item is FREIGHT CHARGE.";
    }
}
