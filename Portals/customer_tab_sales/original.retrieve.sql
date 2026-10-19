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
OUTER APPLY (
	SELECT SUM(s1.sales_price_home) AS sales_price_home, SUM(s1.gross_profit_dollars) AS gross_profit_dollars 
	FROM kb_sales_history_report_view AS s1
	WHERE s1.customer_id = :customer_id 
		AND s1.company_id = :company_id
		AND s1.year_for_period = p1.year_for_period AND s1.[period] = p1.[period]
	) AS shrv
LEFT JOIN p21_view_periods AS p2
	ON DateAdd(Year, -1, p1.beginning_date) = p2.beginning_date
OUTER APPLY (
	SELECT SUM(s2.sales_price_home) AS sales_price_home, SUM(s2.gross_profit_dollars) AS gross_profit_dollars 
	FROM kb_sales_history_report_view AS s2
	WHERE s2.customer_id = :customer_id 
		AND s2.company_id = :company_id
		AND s2.year_for_period = p2.year_for_period AND s2.[period] = p2.[period]
	) AS shrv2


WHERE p1.beginning_date > DateAdd(Year, -1, GetDate()) 
	AND CAST(p1.ending_date AS DATE) <= EOMONTH(GETDATE())
	AND p1.[period] <> 13 -- why is this even... ugh, nevermind

ORDER BY p1.ending_date DESC