// Decompiled with JetBrains decompiler
// Type: kb_Order_Validator_v2.kb_Order_Validator_v2
// Assembly: kb_Order_Validator_v2, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null
// MVID: 89449C28-7DC0-4558-B397-A6B3F2F94257
// Assembly location: C:\Business_Rules\BusinessRulesDLL\kb_Order_Validator_v2.dll

using Atlas.CrownSurcharge5011348;
using Atlas.CrownSurcharge5011348.SurchargeValidation;
using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Reflection;
using System.Text.RegularExpressions;

// 2026-06-23 Bus App Team: block-scoped namespace + #nullable removed (C# 7.3);
// kb_SQLHelper retired -- P21SqlConnection + LogRuleError (business_rule_log).
namespace kb_Order_Validator_v2
{

public class kb_Order_Validator_v2 : P21.Extensions.BusinessRule.Rule
{
  private string className = new string(MethodBase.GetCurrentMethod().DeclaringType.Name.Where<char>(new System.Func<char, bool>(char.IsLetterOrDigit)).ToArray<char>());
  private int subsection = 0;

  public override RuleResult Execute()
  {
    string str1 = "Initializing";
    RuleResult ruleResult = new RuleResult();
    try
    {
      DataTable dataTable1 = new DataTable();
      string empty1 = string.Empty;
      string empty2 = string.Empty;
      string empty3 = string.Empty;
      Decimal num1 = 0M;
      DataTable dataTable2 = new DataTable();
      DataTable dataTable3 = new DataTable();
      DataTable dataTable4 = new DataTable();
      int num2 = 0;
      string empty4 = string.Empty;
      ruleResult.Success = true;
      str1 = "Adding Columns to C# DataTables";
      ++this.subsection;
      dataTable2.Columns.Add("item_id", typeof (string)).AllowDBNull = false;
      ++this.subsection;
      dataTable2.Columns.Add("line_seq_no", typeof (int)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("oe_line_line_no", typeof (Decimal)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("extended_price", typeof (Decimal)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("unit_price", typeof (Decimal)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("price_page_uid", typeof (int)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("manual_price_overide", typeof (string)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("unit_commission_cost", typeof (Decimal)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("unit_other_cost", typeof (Decimal)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("unit_order_cost", typeof (Decimal)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("commission_cost_edited", typeof (string)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("other_cost_edited", typeof (string)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("order_cost_edited", typeof (string)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("disposition", typeof (string)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("oe_line_complete", typeof (string)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("qty_open", typeof (Decimal)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("qty_invoiced_uom", typeof (Decimal)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("qty_ordered", typeof (Decimal)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("qty_canceled_uom", typeof (Decimal)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("qty_allocated_uom", typeof (Decimal)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("qty_on_pick_tickets", typeof (Decimal)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("unit_of_measure", typeof (string)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("unit_size", typeof (Decimal)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("pricing_unit", typeof (string)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("pricing_unit_size", typeof (Decimal)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("full_rolled_item_cd", typeof (string)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("extended_reward", typeof (Decimal)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("reward_program_id", typeof (string)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("oe_salesrep_id", typeof (int)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("source_loc_id", typeof (Decimal)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("ship_loc_id", typeof (Decimal)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("will_call", typeof (string)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("product_type", typeof (string)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("expedite_date", typeof (DateTime)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("required_date", typeof (DateTime)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("date_created", typeof (DateTime)).AllowDBNull = true;
      ++this.subsection;
      dataTable2.Columns.Add("date_last_modified", typeof (DateTime)).AllowDBNull = true;
      ++this.subsection;
      dataTable3.Columns.Add("topic", typeof (string));
      ++this.subsection;
      dataTable3.Columns.Add("notepad_class_id", typeof (string));
      ++this.subsection;
      dataTable3.Columns.Add("mandatory", typeof (string));
      ++this.subsection;
      dataTable3.Columns.Add("note", typeof (string));
      ++this.subsection;
      dataTable4.Columns.Add("s1", typeof (string));
      ++this.subsection;
      dataTable4.Columns.Add("s2", typeof (string));
      ++this.subsection;
      dataTable4.Columns.Add("s3", typeof (string));
      ++this.subsection;
      dataTable4.Columns.Add("s4", typeof (string));
      str1 = "Do not run if";
      this.subsection = 0;
      if (this.Data.Set.Tables["d_oe_header"].Rows[0].Field<string>("rma_flag").Equals("Y") || this.Data.Set.Tables["d_oe_header"].Rows[0].Field<string>("quote").Equals("Y") || this.Data.Set.Tables["d_oe_header"].Rows[0].Field<string>("cancel_flag").Equals("Y"))
        return ruleResult;
      str1 = "More initializing";
      this.subsection = 0;
      DataTable table = this.Data.Set.Tables["d_dw_oe_line_dataentry"];
      if (table == null || table.Rows.Count == 0)
      {
        this.LogRuleError($"Order Lines table was empty or not present for order # {this.Data.Set.Tables["d_oe_header"].Rows[0].Field<string>("order_no") ?? "n/a"}, so the business rule failed.");
        return ruleResult;
      }
      this.subsection = 1;
      DataRow row1 = this.Data.Set.Tables["d_oe_header"].Rows[0];
      this.subsection = 2;
      DataRow row2 = this.Data.Set.Tables["d_front_counter"].Rows[0];
      str1 = "Looping through the order lines";
      this.subsection = 0;
      int num3 = table.Rows.Count - 1;
      Decimal? nullable1;
      int? nullable2;
      DateTime? nullable3;
      for (int index = 0; index <= num3; ++index)
      {
        this.subsection = 1;
        if ((table.Rows[index].Field<string>("delete_flag") == null || !table.Rows[index].Field<string>("delete_flag").Equals("Y")) && table.Rows[index].Field<string>("oe_order_item_id") != null)
        {
          DataRow row3 = table.Rows[index];
          this.subsection = 2;
          Decimal? nullable4 = new Decimal?(new Decimal(0.0));
          nullable1 = row3.Field<Decimal?>("unit_size");
          Decimal num4 = nullable1 ?? new Decimal(1.0);
          if (num4 == new Decimal(0.0))
            num4 = new Decimal(1.0);
          ref Decimal? local = ref nullable4;
          nullable1 = row3.Field<Decimal?>("qty_ordered");
          Decimal num5;
          if (!nullable1.HasValue)
          {
            Decimal num6 = new Decimal(0.0);
            Decimal? nullable5 = row3.Field<Decimal?>("canceled_qty");
            Decimal num7 = nullable5 ?? new Decimal(0.0) * num4;
            Decimal num8 = num6 - num7;
            nullable5 = row3.Field<Decimal?>("invoiced_qty");
            Decimal num9 = nullable5 ?? new Decimal(0.0) * num4;
            num5 = num8 - num9;
          }
          else
            num5 = nullable1.GetValueOrDefault();
          local = new Decimal?(num5);
          this.subsection = 3;
          nullable1 = nullable4;
          Decimal num10 = 0M;
          if (nullable1.GetValueOrDefault() > num10 & nullable1.HasValue && !row3.Field<string>("oe_line_complete").Equals("Y") && !row3.Field<string>("product_type").Equals("B"))
          {
            ++num2;
            if (row3.Field<string>("oe_order_item_id").Equals("INBOUND FUEL SURCHARGE"))
            {
              Decimal d1 = num1;
              nullable1 = row3.Field<Decimal?>("extended_price");
              Decimal d2 = nullable1 ?? new Decimal(0.0);
              num1 = Decimal.Add(d1, d2);
            }
          }
          else
            nullable4 = new Decimal?(new Decimal(0.0));
          this.subsection = 4;
          DataRow row4 = dataTable2.NewRow();
          row4["item_id"] = (object) row3.Field<string>("oe_order_item_id");
          this.subsection = 5;
          DataRow dataRow1 = row4;
          nullable2 = row3.Field<int?>("line_seq_no");
          object obj1 = nullable2.HasValue ? (object) row3.Field<int?>("line_seq_no") : (object) DBNull.Value;
          dataRow1["line_seq_no"] = obj1;
          this.subsection = 6;
          DataRow dataRow2 = row4;
          nullable1 = row3.Field<Decimal?>("oe_line_line_no");
          object obj2 = nullable1.HasValue ? (object) row3.Field<Decimal?>("oe_line_line_no") : (object) DBNull.Value;
          dataRow2["oe_line_line_no"] = obj2;
          this.subsection = 7;
          DataRow dataRow3 = row4;
          nullable1 = row3.Field<Decimal?>("extended_price");
          object obj3 = nullable1.HasValue ? (object) row3.Field<Decimal?>("extended_price") : (object) DBNull.Value;
          dataRow3["extended_price"] = obj3;
          this.subsection = 8;
          DataRow dataRow4 = row4;
          nullable1 = row3.Field<Decimal?>("unit_price");
          object obj4 = nullable1.HasValue ? (object) row3.Field<Decimal?>("unit_price") : (object) DBNull.Value;
          dataRow4["unit_price"] = obj4;
          this.subsection = 9;
          DataRow dataRow5 = row4;
          nullable2 = row3.Field<int?>("price_page_uid");
          object obj5 = nullable2.HasValue ? (object) row3.Field<int?>("price_page_uid") : (object) DBNull.Value;
          dataRow5["price_page_uid"] = obj5;
          this.subsection = 10;
          row4["manual_price_overide"] = (object) row3.Field<string>("manual_price_overide") ?? (object) DBNull.Value;
          this.subsection = 11;
          DataRow dataRow6 = row4;
          nullable1 = row3.Field<Decimal?>("commission_cost");
          object obj6 = nullable1.HasValue ? (object) row3.Field<Decimal?>("commission_cost") : (object) DBNull.Value;
          dataRow6["unit_commission_cost"] = obj6;
          this.subsection = 12;
          DataRow dataRow7 = row4;
          nullable1 = row3.Field<Decimal?>("other_cost");
          object obj7 = nullable1.HasValue ? (object) row3.Field<Decimal?>("other_cost") : (object) DBNull.Value;
          dataRow7["unit_other_cost"] = obj7;
          this.subsection = 13;
          DataRow dataRow8 = row4;
          nullable1 = row3.Field<Decimal?>("sales_cost");
          object obj8 = nullable1.HasValue ? (object) row3.Field<Decimal?>("sales_cost") : (object) DBNull.Value;
          dataRow8["unit_order_cost"] = obj8;
          this.subsection = 14;
          row4["commission_cost_edited"] = (object) row3.Field<string>("commission_cost_edited") ?? (object) DBNull.Value;
          this.subsection = 15;
          row4["other_cost_edited"] = (object) row3.Field<string>("other_cost_edited") ?? (object) DBNull.Value;
          this.subsection = 16 /*0x10*/;
          row4["order_cost_edited"] = (object) row3.Field<string>("order_cost_edited") ?? (object) DBNull.Value;
          this.subsection = 17;
          row4["disposition"] = (object) row3.Field<string>("disposition") ?? (object) DBNull.Value;
          this.subsection = 18;
          row4["oe_line_complete"] = (object) row3.Field<string>("oe_line_complete") ?? (object) DBNull.Value;
          this.subsection = 19;
          DataRow dataRow9 = row4;
          nullable1 = nullable4;
          object obj9 = (object) nullable1 ?? (object) DBNull.Value;
          dataRow9["qty_open"] = obj9;
          this.subsection = 20;
          DataRow dataRow10 = row4;
          nullable1 = row3.Field<Decimal?>("invoiced_qty");
          object obj10 = nullable1.HasValue ? (object) row3.Field<Decimal?>("invoiced_qty") : (object) DBNull.Value;
          dataRow10["qty_invoiced_uom"] = obj10;
          this.subsection = 21;
          DataRow dataRow11 = row4;
          nullable1 = row3.Field<Decimal?>("qty_ordered");
          object obj11 = nullable1.HasValue ? (object) row3.Field<Decimal?>("qty_ordered") : (object) DBNull.Value;
          dataRow11["qty_ordered"] = obj11;
          this.subsection = 22;
          DataRow dataRow12 = row4;
          nullable1 = row3.Field<Decimal?>("canceled_qty");
          object obj12 = nullable1.HasValue ? (object) row3.Field<Decimal?>("canceled_qty") : (object) DBNull.Value;
          dataRow12["qty_canceled_uom"] = obj12;
          this.subsection = 23;
          DataRow dataRow13 = row4;
          nullable1 = row3.Field<Decimal?>("allocated_qty");
          object obj13 = nullable1.HasValue ? (object) row3.Field<Decimal?>("allocated_qty") : (object) DBNull.Value;
          dataRow13["qty_allocated_uom"] = obj13;
          this.subsection = 24;
          DataRow dataRow14 = row4;
          nullable1 = row3.Field<Decimal?>("qty_on_pick_tickets");
          object obj14 = nullable1.HasValue ? (object) row3.Field<Decimal?>("qty_on_pick_tickets") : (object) DBNull.Value;
          dataRow14["qty_on_pick_tickets"] = obj14;
          this.subsection = 25;
          row4["unit_of_measure"] = (object) row3.Field<string>("unit_of_measure") ?? (object) DBNull.Value;
          this.subsection = 26;
          DataRow dataRow15 = row4;
          nullable1 = row3.Field<Decimal?>("unit_size");
          object obj15 = nullable1.HasValue ? (object) row3.Field<Decimal?>("unit_size") : (object) DBNull.Value;
          dataRow15["unit_size"] = obj15;
          this.subsection = 27;
          row4["pricing_unit"] = (object) row3.Field<string>("pricing_unit") ?? (object) DBNull.Value;
          this.subsection = 28;
          DataRow dataRow16 = row4;
          nullable1 = row3.Field<Decimal?>("pricing_unit_size");
          object obj16 = (object) nullable1 ?? (object) DBNull.Value;
          dataRow16["pricing_unit_size"] = obj16;
          this.subsection = 29;
          row4["full_rolled_item_cd"] = (object) row3.Field<string>("full_rolled_item_cd") ?? (object) DBNull.Value;
          this.subsection = 30;
          nullable1 = row3.Field<Decimal?>("ufc_oe_line_ud_extended_reward");
          if (!nullable1.HasValue)
          {
            row4["extended_reward"] = (object) DBNull.Value;
          }
          else
          {
            nullable1 = row3.Field<Decimal?>("ufc_oe_line_ud_extended_reward");
            int num11;
            if (nullable1.Value <= 9999999999.99999M)
            {
              nullable1 = row3.Field<Decimal?>("ufc_oe_line_ud_extended_reward");
              num11 = nullable1.Value >= -9999999999.99999M ? 1 : 0;
            }
            else
              num11 = 0;
            row4["extended_reward"] = num11 == 0 ? (object) 9999999999.99999M : (object) row3.Field<Decimal?>("ufc_oe_line_ud_extended_reward");
          }
          this.subsection = 31 /*0x1F*/;
          row4["reward_program_id"] = (object) row3.Field<string>("ufc_oe_line_ud_reward_program_id") ?? (object) DBNull.Value;
          this.subsection = 32 /*0x20*/;
          DataRow dataRow17 = row4;
          nullable2 = row3.Field<int?>("ufc_oe_line_ud_oe_salesrep_id");
          object obj17 = nullable2.HasValue ? (object) row3.Field<int?>("ufc_oe_line_ud_oe_salesrep_id") : (object) DBNull.Value;
          dataRow17["oe_salesrep_id"] = obj17;
          this.subsection = 33;
          DataRow dataRow18 = row4;
          nullable1 = row3.Field<Decimal?>("source_loc_id");
          object obj18 = nullable1.HasValue ? (object) row3.Field<Decimal?>("source_loc_id") : (object) DBNull.Value;
          dataRow18["source_loc_id"] = obj18;
          this.subsection = 34;
          DataRow dataRow19 = row4;
          nullable1 = row3.Field<Decimal?>("ship_loc_id");
          object obj19 = nullable1.HasValue ? (object) row3.Field<Decimal?>("ship_loc_id") : (object) DBNull.Value;
          dataRow19["ship_loc_id"] = obj19;
          this.subsection = 35;
          row4["will_call"] = (object) row3.Field<string>("will_call") ?? (object) DBNull.Value;
          this.subsection = 36;
          row4["product_type"] = (object) row3.Field<string>("product_type") ?? (object) DBNull.Value;
          this.subsection = 37;
          DataRow dataRow20 = row4;
          nullable3 = row3.Field<DateTime?>("expedite_date");
          object obj20 = (object) nullable3 ?? (object) DBNull.Value;
          dataRow20["expedite_date"] = obj20;
          this.subsection = 38;
          DataRow dataRow21 = row4;
          nullable3 = row3.Field<DateTime?>("required_date");
          object obj21 = (object) nullable3 ?? (object) DBNull.Value;
          dataRow21["required_date"] = obj21;
          this.subsection = 39;
          DataRow dataRow22 = row4;
          nullable3 = row3.Field<DateTime?>("date_created");
          object obj22 = (object) nullable3 ?? (object) DBNull.Value;
          dataRow22["date_created"] = obj22;
          this.subsection = 40;
          DataRow dataRow23 = row4;
          nullable3 = row3.Field<DateTime?>("date_last_modified");
          object obj23 = (object) nullable3 ?? (object) DBNull.Value;
          dataRow23["date_last_modified"] = obj23;
          this.subsection = 41;
          dataTable2.Rows.Add(row4);
        }
      }
      str1 = "Looping Through Payment Lines";
      this.subsection = 0;
      if (this.Data.Set.Tables["d_oe_payment_details"] != null)
      {
        ++this.subsection;
        int num12 = this.Data.Set.Tables["d_oe_payment_details"].Rows.Count - 1;
        if (num12 >= 0)
        {
          ++this.subsection;
          for (int index = 0; index <= num12; ++index)
          {
            ++this.subsection;
            this.subsection += 100;
            DataRowCollection rows = dataTable4.Rows;
            object[] objArray = new object[4]
            {
              (object) this.Data.Set.Tables["d_oe_payment_details"].Rows[index].Field<string>("payment_method_id") ?? (object) DBNull.Value,
              (object) this.Data.Set.Tables["d_oe_payment_details"].Rows[index].Field<string>("delete_flag") ?? (object) DBNull.Value,
              null,
              null
            };
            nullable1 = this.Data.Set.Tables["d_oe_payment_details"].Rows[index].Field<Decimal?>("payment_amount");
            object obj;
            if (!nullable1.HasValue)
            {
              obj = (object) DBNull.Value;
            }
            else
            {
              nullable1 = this.Data.Set.Tables["d_oe_payment_details"].Rows[index].Field<Decimal?>("payment_amount");
              obj = (object) nullable1.ToString();
            }
            objArray[2] = obj;
            objArray[3] = (object) this.Data.Set.Tables["d_oe_payment_details"].Rows[index].Field<string>("payment_desc") ?? (object) DBNull.Value;
            rows.Add(objArray);
          }
        }
      }
      str1 = "Determining whether the inbound fuel surcharge box should be checked";
      this.subsection = 0;
      if (num2 > 0 && num1 == new Decimal(0.0) && row1.Field<string>("ufc_oe_hdr_ud_oe_surcharge").Equals("Y"))
      {
        this.subsection = 1;
        row1.SetField<string>("ufc_oe_hdr_ud_oe_surcharge", "N");
      }
      else if (num2 > 0 && num1 != new Decimal(0.0) && row1.Field<string>("ufc_oe_hdr_ud_oe_surcharge").Equals("N"))
      {
        this.subsection = 2;
        row1.SetField<string>("ufc_oe_hdr_ud_oe_surcharge", "Y");
      }
      str1 = "Reviewing the existing order header notes";
      this.subsection = 0;
      if (this.Data.Set.Tables["d_dw_oe_hdr_notepad_dataentry"] != null)
      {
        int num13 = this.Data.Set.Tables["d_dw_oe_hdr_notepad_dataentry"].Rows.Count - 1;
        for (int index = 0; index <= num13; ++index)
        {
          if (!this.Data.Set.Tables["d_dw_oe_hdr_notepad_dataentry"].Rows[index].Field<string>("delete_flag").Equals("Y"))
            dataTable3.Rows.Add((object) this.Data.Set.Tables["d_dw_oe_hdr_notepad_dataentry"].Rows[index].Field<string>("topic") ?? (object) DBNull.Value, (object) this.Data.Set.Tables["d_dw_oe_hdr_notepad_dataentry"].Rows[index].Field<string>("notepad_class_id") ?? (object) DBNull.Value, (object) this.Data.Set.Tables["d_dw_oe_hdr_notepad_dataentry"].Rows[index].Field<string>("mandatory") ?? (object) DBNull.Value, (object) this.Data.Set.Tables["d_dw_oe_hdr_notepad_dataentry"].Rows[index].Field<string>("note") ?? (object) DBNull.Value);
        }
      }
      str1 = "Preparing to run table function";
      this.subsection = 0;
      if (num2 > 0)
      {
        // kb_SQLHelper retired: use the base-class P21SqlConnection (already open,
        // framework-owned -- do NOT dispose or re-Open). Bare block keeps the
        // existing 'connection' references below unchanged.
        SqlConnection connection = P21SqlConnection;
        {
          str1 = "Preparing function parameters";
          this.subsection = 0;
          using (SqlCommand sqlCommand = new SqlCommand("SELECT success_bool, result_message, atlas_surcharge_on\r\n                        FROM dbo.kb_fnt_br_order_validator_v2(@req_date, @date_created, @order_date, @fcuid, @stid, @carrier_name, \r\n                            @packing_basis, @ship_route, @jobsite, @front_counter, @custid, @user, @taker, @ordernumber,\r\n                            @company_id, @order_type, @order_source, @sales_loc_id, @ccstatus, @terms, \r\n                            @payment_info, @ship_total, @total_due, @total_paid, @amount_tendered, @balance, @total_sugg_amt,\r\n                            @inv_batch_no, @print_tix, @fax_tix, @email_tix, \r\n                            @print_orderack, @fax_orderack, @email_orderack, @create_invoice, @print_invoice, @fax_invoice, @email_invoice,\r\n                            @print_downpayment, @fax_downpayment, @email_downpayment, @print_pack_list, @fax_pack_list, @email_pack_list,\r\n                            @will_call_box, @signature_capture, \r\n                            @oe_class1, @contact_id, @order_contact, @job_name, \r\n                            @ship2_name, @ship2_add1, @ship2_add2, @ship2_add3, @ship2_city, @ship2_state, @ship2_zip, @ship2_country,\r\n                            @order_table, @oehnote_table)", connection))
          {
            SqlParameter sqlParameter1 = new SqlParameter("@order_table", SqlDbType.Structured);
            sqlParameter1.TypeName = "dbo.kb_TableTypeItemsOnOrder";
            sqlParameter1.Value = (object) dataTable2;
            SqlParameter sqlParameter2 = sqlParameter1;
            sqlCommand.Parameters.Add(sqlParameter2);
            ++this.subsection;
            SqlParameter sqlParameter3 = new SqlParameter("@oehnote_table", SqlDbType.Structured);
            sqlParameter3.TypeName = "dbo.kb_TableTypeFourStrings";
            sqlParameter3.Value = (object) dataTable3;
            SqlParameter sqlParameter4 = sqlParameter3;
            sqlCommand.Parameters.Add(sqlParameter4);
            ++this.subsection;
            SqlParameter sqlParameter5 = sqlCommand.Parameters.Add("@req_date", SqlDbType.DateTime);
            nullable3 = row1.Field<DateTime?>("requested_date");
            object obj24 = (object) nullable3 ?? (object) DBNull.Value;
            sqlParameter5.Value = obj24;
            ++this.subsection;
            SqlParameter sqlParameter6 = sqlCommand.Parameters.Add("@date_created", SqlDbType.DateTime);
            nullable3 = row1.Field<DateTime?>("date_created");
            object obj25 = (object) nullable3 ?? (object) DBNull.Value;
            sqlParameter6.Value = obj25;
            ++this.subsection;
            SqlParameter sqlParameter7 = sqlCommand.Parameters.Add("@order_date", SqlDbType.DateTime);
            nullable3 = row1.Field<DateTime?>("order_date");
            object obj26 = (object) nullable3 ?? (object) DBNull.Value;
            sqlParameter7.Value = obj26;
            ++this.subsection;
            SqlParameter sqlParameter8 = sqlCommand.Parameters.Add("@fcuid", SqlDbType.Int);
            nullable2 = row1.Field<int?>("freight_code_uid");
            object obj27 = (object) nullable2 ?? (object) DBNull.Value;
            sqlParameter8.Value = obj27;
            ++this.subsection;
            SqlParameter sqlParameter9 = sqlCommand.Parameters.Add("@stid", SqlDbType.Decimal, 19);
            nullable1 = row1.Field<Decimal?>("ship_to_id");
            object obj28 = nullable1.HasValue ? (object) row1.Field<Decimal?>("ship_to_id") : (object) DBNull.Value;
            sqlParameter9.Value = obj28;
            ++this.subsection;
            sqlCommand.Parameters.Add("@carrier_name", SqlDbType.VarChar, (int) byte.MaxValue).Value = (object) this.Data.Set.Tables["d_dw_oe_hdr_shipinfo"].Rows[0].Field<string>("oe_hdr_carrier_id") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@packing_basis", SqlDbType.VarChar, 16 /*0x10*/).Value = (object) row1.Field<string>("packing_basis") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@ship_route", SqlDbType.VarChar, (int) byte.MaxValue).Value = (object) this.Data.Set.Tables["d_dw_oe_hdr_shipinfo"].Rows[0].Field<string>("ship_route") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@jobsite", SqlDbType.VarChar, 1).Value = (object) row1.Field<string>("ufc_oe_hdr_ud_jobsite") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@front_counter", SqlDbType.VarChar, 1).Value = (object) row1.Field<string>("front_counter") ?? (object) DBNull.Value;
            ++this.subsection;
            SqlParameter sqlParameter10 = sqlCommand.Parameters.Add("@custid", SqlDbType.Decimal, 19);
            nullable1 = row1.Field<Decimal?>("customer_id");
            object obj29 = (object) nullable1 ?? (object) DBNull.Value;
            sqlParameter10.Value = obj29;
            ++this.subsection;
            sqlCommand.Parameters.Add("@user", SqlDbType.VarChar, 60).Value = (object) this.Session.UserID ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@taker", SqlDbType.VarChar, 30).Value = (object) row1.Field<string>("taker") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@ordernumber", SqlDbType.VarChar, 8).Value = (object) row1.Field<string>("order_no") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@company_id", SqlDbType.VarChar, 8).Value = (object) row1.Field<string>("company_id") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@order_type", SqlDbType.VarChar, (int) byte.MaxValue).Value = (object) row1.Field<string>("order_type") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@order_source", SqlDbType.VarChar, (int) byte.MaxValue).Value = (object) row1.Field<string>("source_code_no") ?? (object) DBNull.Value;
            ++this.subsection;
            SqlParameter sqlParameter11 = sqlCommand.Parameters.Add("@sales_loc_id", SqlDbType.Decimal, 19);
            nullable1 = row1.Field<Decimal?>("sales_loc_id");
            object obj30 = (object) nullable1 ?? (object) DBNull.Value;
            sqlParameter11.Value = obj30;
            ++this.subsection;
            sqlCommand.Parameters.Add("@ccstatus", SqlDbType.VarChar, 8).Value = (object) this.Data.Set.Tables["d_oe_hdr_credit"].Rows[0].Field<string>("credit_status") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@terms", SqlDbType.VarChar, (int) byte.MaxValue).Value = (object) this.Data.Set.Tables["d_dw_oe_hdr_terms"].Rows[0].Field<string>("terms") ?? (object) DBNull.Value;
            ++this.subsection;
            SqlParameter sqlParameter12 = new SqlParameter("@payment_info", SqlDbType.Structured);
            sqlParameter12.TypeName = "dbo.kb_TableTypeFourStrings";
            sqlParameter12.Value = (object) dataTable4;
            SqlParameter sqlParameter13 = sqlParameter12;
            sqlCommand.Parameters.Add(sqlParameter13);
            ++this.subsection;
            SqlParameter sqlParameter14 = sqlCommand.Parameters.Add("@ship_total", SqlDbType.Decimal, 19);
            nullable1 = this.Data.Set.Tables["d_dw_oe_hdr_totals_remit"].Rows[0].Field<Decimal?>("cf_ship_total");
            object obj31 = nullable1.HasValue ? (object) this.Data.Set.Tables["d_dw_oe_hdr_totals_remit"].Rows[0].Field<Decimal?>("cf_ship_total") : (object) DBNull.Value;
            sqlParameter14.Value = obj31;
            ++this.subsection;
            SqlParameter sqlParameter15 = sqlCommand.Parameters.Add("@total_due", SqlDbType.Decimal, 19);
            nullable1 = this.Data.Set.Tables["d_dw_oe_hdr_totals_remit"].Rows[0].Field<Decimal?>("cf_total_due");
            object obj32 = nullable1.HasValue ? (object) this.Data.Set.Tables["d_dw_oe_hdr_totals_remit"].Rows[0].Field<Decimal?>("cf_total_due") : (object) DBNull.Value;
            sqlParameter15.Value = obj32;
            ++this.subsection;
            SqlParameter sqlParameter16 = sqlCommand.Parameters.Add("@total_paid", SqlDbType.Decimal, 19);
            nullable1 = this.Data.Set.Tables["d_dw_oe_hdr_totals_remit"].Rows[0].Field<Decimal?>("total_paid");
            object obj33 = nullable1.HasValue ? (object) this.Data.Set.Tables["d_dw_oe_hdr_totals_remit"].Rows[0].Field<Decimal?>("total_paid") : (object) DBNull.Value;
            sqlParameter16.Value = obj33;
            ++this.subsection;
            SqlParameter sqlParameter17 = sqlCommand.Parameters.Add("@amount_tendered", SqlDbType.Decimal, 19);
            nullable1 = this.Data.Set.Tables["d_dw_oe_hdr_totals_remit"].Rows[0].Field<Decimal?>("amount_tendered");
            object obj34 = nullable1.HasValue ? (object) this.Data.Set.Tables["d_dw_oe_hdr_totals_remit"].Rows[0].Field<Decimal?>("amount_tendered") : (object) DBNull.Value;
            sqlParameter17.Value = obj34;
            ++this.subsection;
            SqlParameter sqlParameter18 = sqlCommand.Parameters.Add("@balance", SqlDbType.Decimal, 19);
            nullable1 = this.Data.Set.Tables["d_dw_oe_hdr_totals_remit"].Rows[0].Field<Decimal?>("cf_balance");
            object obj35 = nullable1.HasValue ? (object) this.Data.Set.Tables["d_dw_oe_hdr_totals_remit"].Rows[0].Field<Decimal?>("cf_balance") : (object) DBNull.Value;
            sqlParameter18.Value = obj35;
            ++this.subsection;
            SqlParameter sqlParameter19 = sqlCommand.Parameters.Add("@total_sugg_amt", SqlDbType.Decimal, 19);
            nullable1 = this.Data.Set.Tables["d_dw_oe_hdr_totals_remit"].Rows[0].Field<Decimal?>("cf_total_sugg_amt");
            object obj36 = nullable1.HasValue ? (object) this.Data.Set.Tables["d_dw_oe_hdr_totals_remit"].Rows[0].Field<Decimal?>("cf_total_sugg_amt") : (object) DBNull.Value;
            sqlParameter19.Value = obj36;
            ++this.subsection;
            SqlParameter sqlParameter20 = sqlCommand.Parameters.Add("@inv_batch_no", SqlDbType.Int);
            nullable2 = this.Data.Set.Tables["d_oe_hdr_ship_to"].Rows[0].Field<int?>("invoice_batch_number");
            object obj37 = (object) nullable2 ?? (object) DBNull.Value;
            sqlParameter20.Value = obj37;
            ++this.subsection;
            sqlCommand.Parameters.Add("@print_tix", SqlDbType.VarChar, 1).Value = (object) row2.Field<string>("print_tix") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@fax_tix", SqlDbType.VarChar, 1).Value = (object) row2.Field<string>("fax_tix") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@email_tix", SqlDbType.VarChar, 1).Value = (object) row2.Field<string>("email_tix") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@print_orderack", SqlDbType.VarChar, 1).Value = (object) row2.Field<string>("print_orderack") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@fax_orderack", SqlDbType.VarChar, 1).Value = (object) row2.Field<string>("fax_orderack") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@email_orderack", SqlDbType.VarChar, 1).Value = (object) row2.Field<string>("email_orderack") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@create_invoice", SqlDbType.VarChar, 1).Value = (object) row2.Field<string>("ship") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@print_invoice", SqlDbType.VarChar, 1).Value = (object) row2.Field<string>("print_invoice") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@fax_invoice", SqlDbType.VarChar, 1).Value = (object) row2.Field<string>("fax_invoice") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@email_invoice", SqlDbType.VarChar, 1).Value = (object) row2.Field<string>("email_invoice") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@print_downpayment", SqlDbType.VarChar, 1).Value = (object) row2.Field<string>("print_downpayment") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@fax_downpayment", SqlDbType.VarChar, 1).Value = (object) row2.Field<string>("fax_downpayment") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@email_downpayment", SqlDbType.VarChar, 1).Value = (object) row2.Field<string>("email_downpayment") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@print_pack_list", SqlDbType.VarChar, 1).Value = (object) row2.Field<string>("print_pack_list") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@fax_pack_list", SqlDbType.VarChar, 1).Value = (object) row2.Field<string>("fax_pack_list") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@email_pack_list", SqlDbType.VarChar, 1).Value = (object) row2.Field<string>("email_pack_list") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@will_call_box", SqlDbType.VarChar, 1).Value = (object) row2.Field<string>("will_call") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@signature_capture", SqlDbType.VarChar, 1).Value = (object) row2.Field<string>("signature_capture") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@oe_class1", SqlDbType.VarChar, (int) byte.MaxValue).Value = (object) this.Data.Set.Tables["d_oe_hdr_class"].Rows[0].Field<string>("oe_hdr_class_1id") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@contact_id", SqlDbType.VarChar, 16 /*0x10*/).Value = (object) row1.Field<string>("contact_id") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@order_contact", SqlDbType.VarChar, 100).Value = (object) row1.Field<string>("ufc_oe_hdr_ud_order_contact") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@job_name", SqlDbType.VarChar, 40).Value = (object) row1.Field<string>("job_name") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@ship2_name", SqlDbType.VarChar, 50).Value = (object) row1.Field<string>("ship_to_name") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@ship2_add1", SqlDbType.VarChar, 50).Value = (object) row1.Field<string>("oe_hdr_ship2_add1") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@ship2_add2", SqlDbType.VarChar, 50).Value = (object) row1.Field<string>("oe_hdr_ship2_add2") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@ship2_add3", SqlDbType.VarChar, 50).Value = (object) row1.Field<string>("oe_hdr_ship2_add3") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@ship2_city", SqlDbType.VarChar, 50).Value = (object) row1.Field<string>("oe_hdr_ship2_city") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@ship2_state", SqlDbType.VarChar, 50).Value = (object) row1.Field<string>("oe_hdr_ship2_state") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@ship2_zip", SqlDbType.VarChar, 10).Value = (object) row1.Field<string>("oe_hdr_ship2_zip") ?? (object) DBNull.Value;
            ++this.subsection;
            sqlCommand.Parameters.Add("@ship2_country", SqlDbType.VarChar, 50).Value = (object) row1.Field<string>("oe_hdr_ship2_country") ?? (object) DBNull.Value;
            ++this.subsection;
            str1 = "Executing the function query";
            this.subsection = 0;
            using (SqlDataReader reader = sqlCommand.ExecuteReader())
            {
              str1 = "Loading the results of the function query";
              dataTable1.Load((IDataReader) reader);
              str1 = "Evaluating the results of the function query";
              this.subsection = 0;
              if (dataTable1.Rows.Count < 1)
              {
                this.subsection = 1;
                this.LogRuleError($"Got no data back from SQL for order# {row1.Field<string>("order_no") ?? "n/a"}.");
                ruleResult.Message = "The Order Validator business rule hit an error and got no data back from SQL.\r\n\r\nThis error has been logged.  If you continue to get it, please contact ITSupport@allsurfaces.com.";
                return ruleResult;
              }
              this.subsection = 2;
              if (dataTable1.Rows[0].Field<string>("result_message") != "" && dataTable1.Rows[0].Field<string>("result_message") != null)
              {
                this.subsection = 3;
                string str2 = Regex.Unescape(dataTable1.Rows[0].Field<string>("result_message"));
                ruleResult.Message = str2;
              }
              this.subsection = 4;
              if (!dataTable1.Rows[0].Field<string>("success_bool").Equals("Y"))
              {
                this.subsection = 5;
                ruleResult.Success = false;
              }
              this.subsection = 6;
              if (dataTable1.Rows[0].Field<string>("atlas_surcharge_on").Equals("Y"))
              {
                this.subsection = 7;
                P21Context p21Context = Utility.GetP21Context(this.RuleState.TriggerWindowTitle);
                SurchargeValidationResult validationResult = Surcharge.Validate(new SurchargeValidationRequest()
                {
                  Data = this.Data,
                  Session = this.Session,
                  RuleName = this.GetName(),
                  P21Context = p21Context,
                  RuleState = this.RuleState,
                  RuleXmlData = this.XmlData
                });
                this.subsection = 8;
                if (!validationResult.Success)
                  ruleResult.Success = false;
                this.subsection = 9;
                if (validationResult.Message != "" && validationResult.Message != null)
                {
                  this.subsection = 10;
                  if (dataTable1.Rows[0].Field<string>("result_message") != "" && dataTable1.Rows[0].Field<string>("result_message") != null)
                  {
                    this.subsection = 11;
                    ruleResult.Message = $"{validationResult.Message}\r\n\r\n{Regex.Unescape(dataTable1.Rows[0].Field<string>("result_message"))}";
                  }
                  else
                  {
                    this.subsection = 12;
                    ruleResult.Message = validationResult.Message;
                  }
                }
              }
            }
          }
        }
      }
      return ruleResult;
    }
    catch (Exception ex)
    {
      this.LogRuleError($"{str1} for order# {this.Data.Set.Tables["d_oe_header"].Rows[0].Field<string>("order_no") ?? "n/a"}, subsection {this.subsection.ToString()}.\r\n{ex}");
      ruleResult.Message = $"{this.subsection.ToString()} - The {this.className} business rule hit this error while {str1}: {ex.Message}\r\n\r\nThis error has been logged.  If you continue to get it, please contact ITSupport@allsurfaces.com.";
      return ruleResult;
    }
  }

  public override string GetDescription()
  {
    return "Validates orders before save to block any orders with bad data, as defined in kb_fnt_br_order_validator_v2 and Atlas' surcharge rule.";
  }

  public override string GetName() => this.className;

  // Replaces kb_SQLHelper.LogError / kb_table_br_error_log. Writes to the P21
  // native business_rule_log table so failures are queryable:
  // WHERE log_action = 'Error' AND rule_name = 'kb_Order_Validator_v2'.
  // Best-effort: a logging failure must never mask the original rule error.
  private void LogRuleError(string details)
  {
    try
    {
      const string logSql =
        @"INSERT INTO business_rule_log
            (user_id, log_action, rule_name, rule_assembly_name, run_type,
             return_value, return_message,
             date_created, created_by, date_last_modified, last_maintained_by)
          VALUES
            (@User, 'Error', @Rule, @Asm, 'Synchronous (Internal)',
             'Failure', @Msg,
             GETDATE(), @User, GETDATE(), @User)";

      using (SqlCommand logCmd = new SqlCommand(logSql, P21SqlConnection))
      {
        string userId = this.Session != null && !string.IsNullOrEmpty(this.Session.UserID)
          ? this.Session.UserID
          : "unknown";

        logCmd.Parameters.Add("@User", SqlDbType.VarChar, 255).Value = userId;
        logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(kb_Order_Validator_v2);
        logCmd.Parameters.Add("@Asm", SqlDbType.VarChar, 255).Value = GetType().Assembly.GetName().Name;
        logCmd.Parameters.Add("@Msg", SqlDbType.VarChar, 8000).Value =
          details.Length > 8000 ? details.Substring(0, 8000) : details;
        logCmd.ExecuteNonQuery();
      }
    }
    catch
    {
      // Swallow -- logging must never mask the original error.
    }
  }
}
}
