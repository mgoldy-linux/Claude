SELECT 
	DATENAME(MONTH, DATEADD(MONTH, p1.[period], 0) - 1) + ' ' + CAST(p1.year_for_period AS VARCHAR(4)) + '' AS [month],
	ISNULL(shrv.sales_price_home,0) AS sales,
	ISNULL(shrv.gross_profit_dollars,0) AS gp_dollars,
	CASE ISNULL(shrv.sales_price_home,0) WHEN 0 THEN 0
		ELSE ISNULL(shrv.gross_profit_dollars,0) / ISNULL(shrv.sales_price_home,0) END AS gp_pct,
	'' AS empty_col,
	DATENAME(MONTH, DATEADD(MONTH, p2.[period], 0) - 1) + ' ' + CAST(p2.year_for_period AS VARCHAR(4)) + '' AS [month2],
	ISNULL(shrv2.sales_price_home,0) AS sales2,
	ISNULL(shrv2.gross_profit_dollars,0) AS gp_dollars2,
	CASE ISNULL(shrv2.sales_price_home,0) WHEN 0 THEN 0
		ELSE ISNULL(shrv2.gross_profit_dollars,0) / ISNULL(shrv2.sales_price_home,0) END AS gp_pct2

FROM p21_view_periods AS p1
LEFT JOIN dbo.asi_fnt_customer_period_sales(:company_id, :customer_id, YEAR(GETDATE()) - 2) AS shrv
	ON shrv.year_for_period = p1.year_for_period AND shrv.[period] = p1.[period]
LEFT JOIN p21_view_periods AS p2
	ON DateAdd(Year, -1, p1.beginning_date) = p2.beginning_date
LEFT JOIN dbo.asi_fnt_customer_period_sales(:company_id, :customer_id, YEAR(GETDATE()) - 2) AS shrv2
	ON shrv2.year_for_period = p2.year_for_period AND shrv2.[period] = p2.[period]


WHERE p1.beginning_date > DateAdd(Year, -1, GetDate()) 
	AND CAST(p1.ending_date AS DATE) <= EOMONTH(GETDATE())
	AND p1.[period] <> 13 -- why is this even... ugh, nevermind

ORDER BY p1.ending_date DESC