-----------------------
-- SA 55014: equivalence check — original portal (kb_sales_history_report_view) vs.
-- new native TVF (dbo.asi_fnt_sa55014_sales_invoiced_yesterday).
-- Run in Prod AFTER deploying the TVF. Read-only, safe to run.
-- Both sides resolve "yesterday" relative to GETDATE() at execution time, so run this
-- in one shot (not split across a midnight boundary) so they agree on the same date.
-----------------------
DECLARE @user_id VARCHAR(20) = 'ckramer';
DECLARE @mfg VARCHAR(30) = NULL;

DECLARE @y_start AS DATETIME, @y_end AS DATETIME;
SET @y_start = dbo.kb_fn_date_rng_calc(GetDate(),'yesterday_start');
SET @y_end   = dbo.kb_fn_date_rng_calc(GetDate(),'yesterday_end');

;WITH old_result AS (
    -- exact original portal query, unchanged, parameterized
    SELECT
        kb_sales_history_report_view.invoice_no
        ,kb_sales_history_report_view.line_no
        ,kb_sales_history_report_view.order_no
        ,kb_sales_history_report_view.oe_line_number
        ,kb_sales_history_report_view.invoice_date
        ,kb_sales_history_report_view.customer_id
        ,kb_sales_history_report_view.customer_name
        ,kb_sales_history_report_view.product_group_desc
        ,kb_sales_history_report_view.item_id
        ,kb_sales_history_report_view.extended_desc
        ,COALESCE(p21_view_oe_line.qty_ordered, kb_sales_history_report_view.qty_shipped) AS qty_ordered
        ,p21_view_inv_mast.base_unit
        ,kb_sales_history_report_view.qty_shipped
        ,CASE ISNULL(kb_sales_history_report_view.qty_shipped,0) WHEN 0 THEN NULL ELSE
            FORMAT(kb_sales_history_report_view.sales_price_home/(kb_sales_history_report_view.qty_shipped/p21_view_inv_mast.sales_pricing_unit_size),'c') +
            '/' + p21_view_inv_mast.sales_pricing_unit
        END AS unit_price
        ,kb_sales_history_report_view.sales_price_home
        ,kb_sales_history_report_view.line_other_cost_home
        ,kb_sales_history_report_view.gross_profit_dollars
        ,p21_view_vendor_rebate.rebate_due
        ,CASE p21_view_oe_line.other_cost_edited WHEN 'Y' THEN 'Manual Edit' ELSE '' END AS other_cost_edited
        ,kb_sales_history_report_view.manual_price_overide
        ,p21_view_oe_hdr.job_name
        ,p21_view_price_page.description AS price_page
        ,CASE WHEN p21_view_invoice_hdr.print_date IS NULL THEN 'N' ELSE 'Y' END AS printed
        ,kb_sales_history_report_view.price_family_desc
    FROM kb_sales_history_report_view
    INNER JOIN (SELECT location_id FROM dbo.kb_fnt_get_user_loc(@user_id)) AS my_locs
        ON my_locs.location_id = kb_sales_history_report_view.sales_location_id
    LEFT JOIN p21_view_oe_line
        ON p21_view_oe_line.oe_line_uid = kb_sales_history_report_view.oe_line_uid
    LEFT JOIN p21_view_oe_hdr
        ON p21_view_oe_hdr.order_no = p21_view_oe_line.order_no
    LEFT JOIN p21_view_inv_mast
        ON p21_view_inv_mast.inv_mast_uid = kb_sales_history_report_view.inv_mast_uid
    LEFT JOIN p21_view_vendor_rebate
        ON p21_view_vendor_rebate.invoice_line_uid = kb_sales_history_report_view.invoice_line_uid
    LEFT JOIN p21_view_price_page
        ON kb_sales_history_report_view.cost_price_page_uid = p21_view_price_page.price_page_uid
    LEFT JOIN p21_view_invoice_hdr
        ON kb_sales_history_report_view.invoice_no = p21_view_invoice_hdr.invoice_no
    WHERE kb_sales_history_report_view.invoice_date BETWEEN @y_start AND @y_end
        AND (@mfg IS NULL OR @mfg = kb_sales_history_report_view.item_class1)
),
new_result AS (
    SELECT
        invoice_no, line_no, order_no, oe_line_number, invoice_date, customer_id, customer_name,
        product_group_desc, item_id, extended_desc, qty_ordered, base_unit, qty_shipped, unit_price,
        sales_price_home, line_other_cost_home, gross_profit_dollars, rebate_due, other_cost_edited,
        manual_price_overide, job_name, price_page, printed, price_family_desc
    FROM dbo.asi_fnt_sa55014_sales_invoiced_yesterday(@user_id, @mfg)
)
SELECT 'old_row_count' AS metric, COUNT(*) AS value FROM old_result
UNION ALL
SELECT 'new_row_count', COUNT(*) FROM new_result
UNION ALL
SELECT 'in_old_not_new (should be 0)', COUNT(*) FROM (SELECT * FROM old_result EXCEPT SELECT * FROM new_result) a
UNION ALL
SELECT 'in_new_not_old (should be 0)', COUNT(*) FROM (SELECT * FROM new_result EXCEPT SELECT * FROM old_result) b;

-- if either EXCEPT count above is nonzero, pull the actual mismatched rows to see what differs:
-- SELECT * FROM old_result EXCEPT SELECT * FROM new_result;
-- SELECT * FROM new_result EXCEPT SELECT * FROM old_result;
