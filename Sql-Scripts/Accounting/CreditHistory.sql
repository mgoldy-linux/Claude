SELECT
   COALESCE(dt_ch.company_id, dt_company.company_id) company_id,
   COALESCE(dt_ch.customer_id, dt_company.customer_id) customer_id,
   COALESCE(dt_ch.year_invoiced, dt_date.date_year) year_invoiced,
   COALESCE(dt_ch.month_invoiced, dt_date.date_month) month_invoiced,
   COALESCE(dt_ch.high_credit_used, 0) high_credit_used,
   COALESCE(dt_ch.amount_paid, 0) amount_paid,
   COALESCE(dt_ch.avg_fast_slow_days, 0) avg_fast_slow_days,
   COALESCE(dt_ch.sum_days_x_payment, 0) sum_days_x_payment,
   COALESCE(dt_ch.invoiced_sales, 0) invoiced_sales,
   COALESCE(dt_ch.company_name, dt_company.company_name) company_name,
   COALESCE(dt_ch.customer_name, dt_company.customer_name) customer_name,
   dt_date.date_label month_invoiced_label
FROM
   (
      SELECT
         DISTINCT DATENAME(mm, DATEADD(mm, p21_number.number -1, 0)) + ' ' + Cast(
            Datepart(yy, periods.beginning_date) AS VARCHAR(10)
         ) date_label,
         p21_number.number date_month,
         Datepart(yy, periods.beginning_date) date_year
      FROM
         periods CROSS
         JOIN p21_number
      where
         p21_number.number >= 1
         and p21_number.number <= 12
         AND Dateadd(
            day,
            0,
            Dateadd(
               Month,
               p21_number.number - 1,
               Dateadd(
                  Year,
                  datepart(yy, periods.beginning_date) - 1900,
                  0
               )
            )
         ) <= getdate()
         AND Dateadd(
            day,
            0,
            Dateadd(
               Month,
               p21_number.number - 1,
               Dateadd(
                  Year,
                  datepart(yy, periods.beginning_date) - 1900,
                  0
               )
            )
         ) >= (
            SELECT
               TOP 1 Dateadd(
                  day,
                  0,
                  Dateadd(
                     Month,
                     month_invoiced - 1,
                     Dateadd(Year, year_invoiced - 1900, 0)
                  )
               )
            FROM
               customer_credit_history
            WHERE
               customer_credit_history.customer_id = 13843
               AND customer_credit_history.company_id = 1
            ORDER BY
               customer_credit_history.year_invoiced ASC,
               customer_credit_history.month_invoiced ASC
         )
   ) dt_date CROSS
   JOIN (
      SELECT
         company.company_id,
         customer.customer_id,
         company.company_name,
         customer.customer_name
      FROM
         company
         JOIN customer ON company.company_id = customer.company_id
      WHERE
         customer.customer_id = 13843
         AND company.company_id = 1
   ) dt_company
   LEFT JOIN (
      SELECT
         customer_credit_history.company_id,
         customer_credit_history.customer_id,
         customer_credit_history.year_invoiced,
         customer_credit_history.month_invoiced,
         COALESCE(customer_credit_history.high_credit_used, 0) high_credit_used,
         COALESCE(customer_credit_history.amount_paid, 0) amount_paid,
         COALESCE(customer_credit_history.avg_fast_slow_days, 0) avg_fast_slow_days,
         COALESCE(customer_credit_history.sum_days_x_payment, 0) sum_days_x_payment,
         COALESCE(customer_credit_history.invoiced_sales, 0) + COALESCE(
            customer_credit_history.invoiced_other_charges,
            0
         ) invoiced_sales,
         company.company_name,
         customer.customer_name,
         '' month_invoiced_label
      FROM
         company
         JOIN customer ON company.company_id = customer.company_id
         LEFT JOIN customer_credit_history ON customer.company_id = customer_credit_history.company_id
         AND customer.customer_id = customer_credit_history.customer_id
      WHERE
         customer_credit_history.customer_id = 13843
         AND customer_credit_history.company_id = 1
   ) dt_ch ON dt_ch.month_invoiced = dt_date.date_month
   AND dt_ch.year_invoiced = dt_date.date_year
ORDER BY
   date_year DESC,
   date_month DESC
