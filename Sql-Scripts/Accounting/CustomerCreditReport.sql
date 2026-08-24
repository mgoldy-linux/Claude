SELECT
   customer.customer_id,
   customer.customer_name,
   NULLIF('2000-01-01', '2000-01-01') max_order_date,
   terms.terms_desc,
   0.000000000 avg_f_s_month,
   0.000000000 avg_f_s_threemonth,
   0.0000 sales_prior_month,
   0.0000 sales_ytd,
   0.0000 sales_last_ytd,
   0.0000 curr_due,
   0.0000 bucket1,
   0.0000 bucket2,
   0.0000 bucket3,
   0.0000 bucket4,
   customer.credit_status,
   customer.credit_limit,
   customer.credit_limit_used,
   0.0000 inv_date_bucket1,
   0.0000 inv_date_bucket2,
   0.0000 inv_date_bucket3,
   0.0000 inv_date_bucket4,
   NULLIF('2000-01-01', '2000-01-01') cmax_date_retreived,
   0.00 open_orders,
   0.0000 sales_mtd,
   0.00 open_ar,
   NULLIF('2000-01-01', '2000-01-01') last_invoice_date,
   0.00 last_invoice_amt,
   customer.credit_limit_per_order,
   customer.date_acct_opened,
   0.00 last_order_amt,
   0.00 last_payment_amt,
   0.00 mtd_high_credit,
   0.00 ytd_high_credit,
   0.00 high_credit_used,
   dbo.p21_fn_days_sales_outstanding(
      customer.company_id,
      customer.customer_id,
      100,
      GETDATE()
   ) average_dso,
   dbo.p21_fn_get_delinquent_ar_cost_to_carry(customer.company_id, customer.customer_id) cost_to_carry_late_invoices,
   company.business_days_per_year,
   company.average_pretax_profit
FROM
   customer
   INNER JOIN company ON company.company_id = customer.company_id
   INNER JOIN terms ON terms.terms_id = customer.terms_id
WHERE
   customer.customer_id = 13843
   AND customer.company_id = 1
