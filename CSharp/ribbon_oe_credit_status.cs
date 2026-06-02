using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;

namespace ribbon_oe_credit_status_T1
{
  public class ribbon_oe_credit_status_T1 : P21.Extensions.BusinessRule.Rule
  {
    // Background color codes — green (low risk) to red (high risk)
    private const string COLOR_DEFAULT  = "00B050"; // Green        — normal / low risk
    private const string COLOR_NO_CHECK = "92D050"; // Yellow-green — slight caution
    private const string COLOR_COD      = "FFC000"; // Amber        — moderate risk
    private const string COLOR_CASH     = "FF8C00"; // Orange       — elevated risk
    private const string COLOR_PREPAY   = "FF4500"; // Orange-red   — high risk
    private const string COLOR_BLOCK    = "FF0000"; // Red          — blocked

    // Font color codes — white on dark backgrounds, black on light backgrounds
    private const string FONT_DEFAULT  = "FFFFFF"; // White — on green
    private const string FONT_NO_CHECK = "000000"; // Black — on yellow-green
    private const string FONT_COD      = "000000"; // Black — on amber
    private const string FONT_CASH     = "000000"; // Black — on orange
    private const string FONT_PREPAY   = "FFFFFF"; // White — on orange-red
    private const string FONT_BLOCK    = "FFFFFF"; // White — on red

    public override RuleResult Execute()
    {
      RuleResult ruleResult = new RuleResult();
      ruleResult.Success = true;

      string customerId     = this.Data.Fields["customer_id"].FieldValue ?? string.Empty;
      string creditStatusId = this.Data.Fields["credit_status"].FieldValue ?? string.Empty;

      // If both blank, clear result and exit
      if (string.IsNullOrEmpty(customerId) && string.IsNullOrEmpty(creditStatusId))
      {
        this.Data.Fields["business_rule_result"].FieldValue = "";
        return ruleResult;
      }

      try
      {
        // Step 1: Validate credit_status_id against p21_view_credit_status
        if (!string.IsNullOrEmpty(creditStatusId))
        {
          using (SqlCommand cmd = new SqlCommand(
            "SELECT credit_status_id FROM p21_view_credit_status WHERE credit_status_id = @cred_id",
            this.P21SqlConnection))
          {
            cmd.Parameters.Add("@cred_id", SqlDbType.VarChar, 40).Value = creditStatusId;
            object result = cmd.ExecuteScalar();
            creditStatusId = (result != null && result != DBNull.Value) ? result.ToString() : null;
          }
        }

        // Step 2: If credit_status_id is null, look up from customer with corp rollup
        if (string.IsNullOrEmpty(creditStatusId) && !string.IsNullOrEmpty(customerId))
        {
          string lookupSql = @"
            SELECT CASE
              WHEN p21_view_address.corp_address_id <> p21_view_address.id
                OR ISNULL(p21_view_customer.credit_limit, 0.0) = 0.0
              THEN corp_cust.credit_status
              ELSE p21_view_customer.credit_status
            END AS credit_status
            FROM p21_view_address
            LEFT JOIN p21_view_customer
              ON p21_view_customer.customer_id = p21_view_address.id
            LEFT JOIN p21_view_customer AS corp_cust
              ON corp_cust.customer_id = p21_view_address.corp_address_id
            WHERE p21_view_address.id = CONVERT(DECIMAL(19,0), @cust_id)";

          using (SqlCommand cmd = new SqlCommand(lookupSql, this.P21SqlConnection))
          {
            cmd.Parameters.Add("@cust_id", SqlDbType.VarChar, 10).Value = customerId;
            object result = cmd.ExecuteScalar();
            creditStatusId = (result != null && result != DBNull.Value) ? result.ToString() : null;
          }
        }

        // Step 3: Map credit status to short label, background color, and font color
        string credShort;
        string credColor;
        string credFont;

        if (string.IsNullOrEmpty(creditStatusId))
        {
          credShort = "";
          credColor = "BEBBBB";
          credFont  = "000000";
        }
        else
        {
          switch (creditStatusId.ToUpper())
          {
            case "COD":      credShort = "COD";                    credColor = COLOR_COD;      credFont = FONT_COD;      break;
            case "CASH":     credShort = "CASH";                   credColor = COLOR_CASH;     credFont = FONT_CASH;     break;
            case "PREPAY":   credShort = "PrePay";                 credColor = COLOR_PREPAY;   credFont = FONT_PREPAY;   break;
            case "BLOCK":    credShort = "BLOCK";                  credColor = COLOR_BLOCK;    credFont = FONT_BLOCK;    break;
            case "NO CHECK": credShort = "no chk";                 credColor = COLOR_NO_CHECK; credFont = FONT_NO_CHECK; break;
            default:         credShort = creditStatusId.ToLower(); credColor = COLOR_DEFAULT;  credFont = FONT_DEFAULT;  break;
          }
        }

        this.Data.Fields["business_rule_result"].FieldValue            = credShort;
        this.Data.Fields["business_rule_result_color"].FieldValue      = credColor;
        this.Data.Fields["business_rule_result_font_color"].FieldValue = credFont;
      }
      catch (Exception ex)
      {
        ruleResult.Success = false;
        ruleResult.Message = $"Error obtaining credit status for Customer {customerId}: {ex.Message}";
      }

      return ruleResult;
    }

    public override string GetDescription() => "Formats the credit status and its color based on customer and credit status ID.";

    public override string GetName() => nameof(ribbon_oe_credit_status_T1);
  }
}
