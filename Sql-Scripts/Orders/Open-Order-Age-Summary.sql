-- Open Order Age -- Summary rollups
-- Companion to Open-Order-Age.sql (same filters/definitions -- see that file's header).
-- Counts are DISTINCT orders, not lines, so multi-line orders don't inflate the numbers.

	DECLARE @lookback_years INT = 10;

	-- 0) Quick check -- are there open orders older than the @lookback_years window below?
	-- Cheap existence count, not a full aging breakdown -- run this first. If it's > 0, the
	-- capped queries below are NOT the full open-order picture, just the recent slice; widen
	-- @lookback_years (or run the old Open-Order-Age-Summary version with =50) to see them.
	SELECT COUNT(DISTINCT oe_hdr.order_no) AS open_orders_over_lookback
	FROM p21_view_oe_hdr oe_hdr
		INNER JOIN p21_view_oe_line oe_line
			ON oe_lineBack.order_no = oe_hdr.order_no
			AND oe_line.parent_oe_line_uid = 0
	WHERE
		oe_hdr.delete_flag         = 'N'
		AND oe_hdr.projected_order = 'N'
		AND oe_hdr.cancel_flag     = 'N'
		AND oe_line.delete_flag    = 'N'
		AND oe_line.complete       = 'N'
		AND oe_hdr.order_date < DATEADD(YEAR, -@lookback_years, GETDATE());

	-- 1) Aging buckets -- the backlog-health view: how much of what's open is old vs. fresh
	;WITH open_orders AS (
		SELECT
			oe_hdr.order_no,
			oe_hdr.order_date,
			DATEDIFF(DAY, oe_hdr.order_date, GETDATE()) AS order_age_days
		FROM p21_view_oe_hdr oe_hdr
			INNER JOIN p21_view_oe_line oe_line
				ON oe_line.order_no = oe_hdr.order_no
				AND oe_line.parent_oe_line_uid = 0
		WHERE
			oe_hdr.delete_flag         = 'N'
			AND oe_hdr.projected_order = 'N'
			AND oe_hdr.cancel_flag     = 'N'
			AND oe_line.delete_flag    = 'N'
			AND oe_line.complete       = 'N'
			AND oe_hdr.order_date >= DATEADD(YEAR, -@lookback_years, GETDATE())
		GROUP BY oe_hdr.order_no, oe_hdr.order_date
	)
	SELECT
		CASE
			WHEN order_age_days <= 30   THEN '1: 0-30 days'
			WHEN order_age_days <= 60   THEN '2: 31-60 days'
			WHEN order_age_days <= 90   THEN '3: 61-90 days'
			WHEN order_age_days <= 180  THEN '4: 91-180 days'
			WHEN order_age_days <= 365  THEN '5: 181-365 days'
			WHEN order_age_days <= 730  THEN '6: 1-2 years'
			WHEN order_age_days <= 1825 THEN '7: 2-5 years'
			ELSE                              '8: 5+ years'
		END AS age_bucket,
		COUNT(*)                        AS open_order_count,
		AVG(order_age_days * 1.0)       AS avg_age_days,
		MIN(order_age_days)             AS min_age_days,
		MAX(order_age_days)             AS max_age_days
	FROM open_orders
	GROUP BY
		CASE
			WHEN order_age_days <= 30   THEN '1: 0-30 days'
			WHEN order_age_days <= 60   THEN '2: 31-60 days'
			WHEN order_age_days <= 90   THEN '3: 61-90 days'
			WHEN order_age_days <= 180  THEN '4: 91-180 days'
			WHEN order_age_days <= 365  THEN '5: 181-365 days'
			WHEN order_age_days <= 730  THEN '6: 1-2 years'
			WHEN order_age_days <= 1825 THEN '7: 2-5 years'
			ELSE                              '8: 5+ years'
		END
	ORDER BY age_bucket;

-- 2) By order year/month -- trend view: which order months still have open backlog
SELECT
	YEAR(oe_hdr.order_date)  AS order_year,
	MONTH(oe_hdr.order_date) AS order_month,
	COUNT(DISTINCT oe_hdr.order_no) AS open_order_count,
	COUNT(*)                        AS open_line_count,
	AVG(DATEDIFF(DAY, oe_hdr.order_date, GETDATE()) * 1.0) AS avg_age_days
FROM p21_view_oe_hdr oe_hdr
	INNER JOIN p21_view_oe_line oe_line
		ON oe_line.order_no = oe_hdr.order_no
		AND oe_line.parent_oe_line_uid = 0
WHERE
	oe_hdr.delete_flag         = 'N'
	AND oe_hdr.projected_order = 'N'
	AND oe_hdr.cancel_flag     = 'N'
	AND oe_line.delete_flag    = 'N'
	AND oe_line.complete       = 'N'
	AND oe_hdr.order_date >= DATEADD(YEAR, -@lookback_years, GETDATE())
GROUP BY YEAR(oe_hdr.order_date), MONTH(oe_hdr.order_date)
ORDER BY order_year, order_month;
