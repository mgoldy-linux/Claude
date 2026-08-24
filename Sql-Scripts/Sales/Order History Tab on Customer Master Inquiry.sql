--Order History Tab on Customer Master Inquiry: 47831 (AERO INDUSTRIES, INC.)*
SELECT
   customer_order_history.customer_order_history_uid,
   customer_order_history.company_id,
   customer_order_history.customer_id,
   customer_order_history.year_ordered,
   customer_order_history.month_ordered,
   customer_order_history.extended_price * COALESCE(drv_ExchangeRate.exchange_rate, 1),
   customer_order_history.extended_cost * COALESCE(drv_ExchangeRate.exchange_rate, 1),(
      customer_order_history.extended_price - customer_order_history.extended_cost
   ) * COALESCE(drv_ExchangeRate.exchange_rate, 1) extended_profit,
   customer_order_history.extended_price,
   customer_order_history.extended_cost,(
      customer_order_history.extended_price - customer_order_history.extended_cost
   ) extended_profit_company,
   customer_order_history.extended_price * COALESCE(drv_ExchangeRate.exchange_rate, 1),
   customer_order_history.extended_cost * COALESCE(drv_ExchangeRate.exchange_rate, 1),(
      customer_order_history.extended_price - customer_order_history.extended_cost
   ) * COALESCE(drv_ExchangeRate.exchange_rate, 1) extended_profit_customer
FROM
   customer_order_history
   INNER JOIN company ON (
      company.company_id = customer_order_history.company_id
   )
   INNER JOIN customer ON (
      customer.customer_id = customer_order_history.customer_id
   )
   AND (
      customer.company_id = customer_order_history.company_id
   ) OUTER APPLY p21_fnt_get_exchange_rate(
      company.home_currency_id,
      customer.currency_id,
      cast(
         cast(
            customer_order_history.year_ordered * 10000 + customer_order_history.month_ordered * 100 + 1 as varchar(255)
         ) as date
      )
   ) AS drv_ExchangeRate
where customer.customer_id = 47831