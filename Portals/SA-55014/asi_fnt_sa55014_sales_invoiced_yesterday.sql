-----------------------
-- SA 55014: BR SAL SALES INVOICED YESTERDAY Portal
-- Native P21 rewrite of the retired kb_sales_history_report_view / kb_view_invoice_line_rewards
-- dependency chain, scoped to exactly what this portal needs.
--
-- Inline TVF (not a view) because the .srd's `<user_id>` portal-substitution placeholder
-- must reach a real parameter — a view can't accept one. Kept as a single-SELECT inline
-- TVF (no DECLARE/multi-statement body) so SQL Server can still inline it into the caller's
-- plan instead of materializing it — same reason the CTE/CROSS APPLY rewrite in SSMS got
-- from 4:39 down to 42s.
-----------------------
CREATE OR ALTER FUNCTION dbo.asi_fnt_sa55014_sales_invoiced_yesterday
(
    @user_id VARCHAR(20),
    @mfg VARCHAR(30) = NULL
)
RETURNS TABLE
AS
RETURN
(
    WITH cte_dates AS (
        -- computed once, referenced everywhere below, so every CTE and the outer query
        -- agree on the exact same "yesterday" window within a single execution
        SELECT
            DATEADD(DAY, -1, CAST(GETDATE() AS DATE)) AS y_start,
            CAST(GETDATE() AS DATE) AS y_end
    ),
    cte_user_locations AS (
        SELECT location_id FROM dbo.asi_fnt_get_user_loc(@user_id)
    ),
    cte_target_lines AS (
        -- scopes the three aggregating CTEs below to yesterday's invoice lines for
        -- this user's locations only, instead of aggregating the entire invoice history
        SELECT il.invoice_no, il.line_no, il.order_no, il.oe_line_number, il.invoice_line_uid, il.qty_shipped
        FROM p21_view_invoice_line il
        INNER JOIN invoice_hdr ih WITH (NOLOCK) ON ih.invoice_no = il.invoice_no
        LEFT OUTER JOIN oe_hdr oh WITH (NOLOCK) ON ih.order_no = oh.order_no
        CROSS JOIN cte_dates d
        WHERE ih.invoice_date >= d.y_start AND ih.invoice_date < d.y_end
          AND (
              ih.sales_location_id IN (SELECT location_id FROM cte_user_locations)
              OR (ih.sales_location_id IS NULL AND oh.location_id IN (SELECT location_id FROM cte_user_locations))
          )
    ),
    cte_oe_line_invoice_count AS (
        -- "split across multiple invoices" is a lifetime property of the order line, not a
        -- yesterday-only one — the COUNT stays unfiltered (full history). Only the driving
        -- oel rows are narrowed to order/lines that matter for yesterday's report.
        SELECT
            oel.order_no, oel.line_no, oel.qty_ordered,
            COUNT(il.invoice_no) AS invoice_count
        FROM p21_view_oe_line AS oel
        LEFT JOIN p21_view_invoice_line AS il
            ON il.order_no = oel.order_no
            AND il.oe_line_number = oel.line_no
        WHERE EXISTS (
            SELECT 1 FROM cte_target_lines tl
            WHERE tl.order_no = oel.order_no AND tl.oe_line_number = oel.line_no
        )
        GROUP BY oel.order_no, oel.line_no, oel.qty_ordered
        HAVING COUNT(il.invoice_no) > 1
    ),
    cte_incentive_rewards AS (
        -- native replacement for kb_view_invoice_line_rewards.incentive_rewards (the only
        -- column this report needs — not coop_rewards / oe_incentive_rewards / auto_incentive_rewards)
        SELECT
            il.invoice_no,
            il.line_no,
            SUM(COALESCE(rpv.accumulated_incentive_points,0))
            + MAX(CASE
                  WHEN cnt.invoice_count IS NULL THEN COALESCE(ilu.extended_reward, olu.extended_reward, 0)
                  ELSE CASE WHEN ilu.extended_reward IS NOT NULL THEN ilu.extended_reward
                            ELSE COALESCE(olu.extended_reward,0) * (il.qty_shipped / cnt.qty_ordered)
                       END
              END) AS incentive_rewards
        FROM cte_target_lines il
        LEFT JOIN cte_oe_line_invoice_count cnt
            ON cnt.order_no = il.order_no AND cnt.line_no = il.oe_line_number
        LEFT JOIN p21_view_rewards_program_values rpv
            ON rpv.invoice_line_uid = il.invoice_line_uid
            AND rpv.row_status_flag = 704
        LEFT JOIN oe_line_ud olu WITH (NOLOCK)
            ON il.order_no = olu.order_no AND il.oe_line_number = olu.line_no
        LEFT JOIN invoice_line_ud ilu WITH (NOLOCK)
            ON il.invoice_no = ilu.invoice_no AND il.line_no = ilu.line_no
        WHERE
            (COALESCE(rpv.accumulated_coop_dollars,0) <> 0
             OR COALESCE(rpv.accumulated_incentive_points,0)
                + CASE
                    WHEN cnt.invoice_count IS NULL THEN COALESCE(ilu.extended_reward, olu.extended_reward, 0)
                    ELSE COALESCE(ilu.extended_reward, olu.extended_reward, 0) * (il.qty_shipped / cnt.qty_ordered)
                  END <> 0)
        GROUP BY il.invoice_no, il.line_no
    ),
    cte_sumlines AS (
        -- native replacement for kb_sales_history_report_view's drv_sumlines derived table
        -- (only sum_price_home / sum_other_cost_home — the only two fields
        -- sales_price_home / line_other_cost_home actually read from it).
        -- date/location-filtered — safe because lot-bill child rows always share their
        -- parent's invoice_hdr row (same invoice_date, same sales_location_id).
        SELECT
            SUM(invoice_line.extended_price_home) AS sum_price_home,
            SUM(CASE invoice_line.invoice_line_type
                    WHEN 1577 THEN invoice_line.other_cost_home * invoice_line.hours_worked
                    WHEN 1719 THEN invoice_line.other_cost_home * invoice_line.qty_shipped
                END) AS sum_other_cost_home,
            invoice_line.invoice_line_uid_parent
        FROM p21_view_invoice_line invoice_line
        INNER JOIN invoice_hdr WITH (NOLOCK) ON invoice_hdr.invoice_no = invoice_line.invoice_no
        LEFT OUTER JOIN oe_hdr WITH (NOLOCK) ON invoice_hdr.order_no = oe_hdr.order_no
        CROSS JOIN cte_dates d
        WHERE invoice_line.invoice_line_type IN (1719, 1577)
          AND invoice_hdr.invoice_date >= d.y_start AND invoice_hdr.invoice_date < d.y_end
          AND (
              invoice_hdr.sales_location_id IN (SELECT location_id FROM cte_user_locations)
              OR (invoice_hdr.sales_location_id IS NULL AND oe_hdr.location_id IN (SELECT location_id FROM cte_user_locations))
          )
        GROUP BY invoice_line.invoice_line_uid_parent
    )
    SELECT
        invoice_hdr.invoice_no
        ,p21_view_invoice_line.line_no
        ,invoice_hdr.order_no
        ,p21_view_invoice_line.oe_line_number
        ,invoice_hdr.invoice_date
        ,invoice_hdr.sold_to_customer_id AS customer_id
        ,customer.customer_name
        ,COALESCE(product_group.product_group_desc, 'N/A') AS product_group_desc
        ,COALESCE(inv_mast.item_id, p21_view_invoice_line.item_id) AS item_id
        ,inv_mast.extended_desc
        ,COALESCE(p21_view_oe_line.qty_ordered, p21_view_invoice_line.qty_shipped) AS qty_ordered
        ,p21_view_inv_mast.base_unit
        ,p21_view_invoice_line.qty_shipped
        ,CASE ISNULL(p21_view_invoice_line.qty_shipped,0) WHEN 0 THEN NULL ELSE
            FORMAT(pricing.sales_price_home/(p21_view_invoice_line.qty_shipped/p21_view_inv_mast.sales_pricing_unit_size),'c') +
            '/' + p21_view_inv_mast.sales_pricing_unit
        END AS unit_price
        ,pricing.sales_price_home
        ,pricing.line_other_cost_home
        ,pricing.sales_price_home - pricing.line_other_cost_home AS gross_profit_dollars
        ,p21_view_vendor_rebate.rebate_due
        ,CASE p21_view_oe_line.other_cost_edited WHEN 'Y' THEN 'Manual Edit' ELSE '' END AS other_cost_edited
        ,oe_line.manual_price_overide
        ,oe_hdr.job_name
        ,p21_view_price_page.description AS price_page
        ,CASE WHEN p21_view_invoice_hdr.print_date IS NULL THEN 'N' ELSE 'Y' END AS printed
        ,COALESCE(pf.price_family_desc,'') AS price_family_desc
    FROM invoice_hdr WITH (NOLOCK)
    CROSS JOIN cte_dates d
    INNER JOIN p21_view_invoice_line WITH (NOLOCK)
        ON invoice_hdr.invoice_no = p21_view_invoice_line.invoice_no
    INNER JOIN company WITH (NOLOCK)
        ON invoice_hdr.company_no = company.company_id
    INNER JOIN customer WITH (NOLOCK)
        ON invoice_hdr.sold_to_customer_id = customer.customer_id
        AND invoice_hdr.company_no = customer.company_id
    INNER JOIN address_history WITH (NOLOCK)
        ON invoice_hdr.sold_to_ah_uid = address_history.address_history_uid
    INNER JOIN currency_hdr WITH (NOLOCK)
        ON currency_hdr.currency_id = customer.currency_id
    -- dedup guard: an order can have multiple salesreps split-commission; without this filter
    -- rows multiply 1-per-rep (see split-commission trap)
    LEFT OUTER JOIN invoice_hdr_salesrep WITH (NOLOCK)
        ON invoice_hdr_salesrep.invoice_number = invoice_hdr.invoice_no
        AND invoice_hdr_salesrep.primary_salesrep = 'Y'
    LEFT OUTER JOIN oe_hdr WITH (NOLOCK)
        ON invoice_hdr.order_no = oe_hdr.order_no
    LEFT OUTER JOIN oe_hdr_advance_billing WITH (NOLOCK)
        ON oe_hdr_advance_billing.order_no = invoice_hdr.order_no
    LEFT OUTER JOIN inv_loc WITH (NOLOCK)
        ON p21_view_invoice_line.inv_mast_uid = inv_loc.inv_mast_uid
        AND invoice_hdr.sales_location_id = inv_loc.location_id
        AND invoice_hdr.company_no = inv_loc.company_id
    LEFT OUTER JOIN inv_loc AS inv_loc100 WITH (NOLOCK)
        ON inv_loc100.location_id = 100
        AND inv_loc100.company_id = invoice_hdr.company_no
        AND inv_loc100.inv_mast_uid = p21_view_invoice_line.inv_mast_uid
    LEFT OUTER JOIN product_group WITH (NOLOCK)
        ON p21_view_invoice_line.company_id = product_group.company_id
        AND COALESCE(
            CASE inv_loc.product_group_id WHEN '' THEN NULL ELSE inv_loc.product_group_id END,
            CASE inv_loc100.product_group_id WHEN '' THEN NULL ELSE inv_loc100.product_group_id END
        ) = product_group.product_group_id
    LEFT OUTER JOIN oe_line WITH (NOLOCK)
        ON p21_view_invoice_line.oe_line_number = oe_line.line_no
        AND p21_view_invoice_line.order_no = oe_line.order_no
        AND p21_view_invoice_line.invoice_line_type <> 1577
    LEFT OUTER JOIN inv_mast WITH (NOLOCK)
        ON p21_view_invoice_line.inv_mast_uid = inv_mast.inv_mast_uid
    LEFT OUTER JOIN p21_view_inv_mast
        ON p21_view_inv_mast.inv_mast_uid = p21_view_invoice_line.inv_mast_uid
    LEFT OUTER JOIN p21_view_price_family AS pf
        ON pf.price_family_uid = inv_mast.default_price_family_uid
    LEFT OUTER JOIN p21_view_price_page
        ON p21_view_price_page.price_page_uid = COALESCE(p21_view_invoice_line.cost_price_page_uid, oe_line.cost_price_page_uid, oe_line.price_page_uid)
    LEFT OUTER JOIN p21_view_oe_line
        ON p21_view_oe_line.oe_line_uid = oe_line.oe_line_uid
    LEFT OUTER JOIN p21_view_vendor_rebate
        ON p21_view_vendor_rebate.invoice_line_uid = p21_view_invoice_line.invoice_line_uid
    LEFT OUTER JOIN p21_view_invoice_hdr
        ON p21_view_invoice_hdr.invoice_no = invoice_hdr.invoice_no
    LEFT JOIN cte_incentive_rewards incentive_rewards
        ON p21_view_invoice_line.invoice_no = incentive_rewards.invoice_no
        AND p21_view_invoice_line.line_no = incentive_rewards.line_no
    LEFT JOIN cte_sumlines drv_sumlines
        ON drv_sumlines.invoice_line_uid_parent = p21_view_invoice_line.invoice_line_uid
    -- Limit to this user's sales location
    INNER JOIN cte_user_locations AS my_locs
        ON my_locs.location_id = invoice_hdr.sales_location_id
        OR (invoice_hdr.sales_location_id IS NULL AND my_locs.location_id = oe_hdr.location_id)
    CROSS APPLY (
        SELECT
            (CASE COALESCE(oe_hdr_advance_billing.advance_bill, 'N')
                WHEN 'Y' THEN ((p21_view_invoice_line.qty_shipped * (p21_view_invoice_line.unit_price_home /
                    COALESCE(p21_view_invoice_line.pricing_unit_size,1))) - COALESCE(incentive_rewards.incentive_rewards, 0))
                WHEN 'N' THEN
                    CASE COALESCE(oe_line.pricing_option,0)
                        WHEN 1 THEN (
                            CASE p21_view_invoice_line.invoice_line_uid_parent
                                WHEN 0 THEN 0
                                ELSE p21_view_invoice_line.extended_price_home - COALESCE(incentive_rewards.incentive_rewards, 0)
                            END)
                        WHEN 2 THEN (
                            CASE p21_view_invoice_line.invoice_line_uid_parent
                                WHEN 0 THEN p21_view_invoice_line.extended_price_home - COALESCE(incentive_rewards.incentive_rewards, 0)
                                ELSE 0
                            END)
                        WHEN 3 THEN (
                            CASE p21_view_invoice_line.invoice_line_uid_parent
                                WHEN 0 THEN p21_view_invoice_line.extended_price_home - COALESCE(incentive_rewards.incentive_rewards, 0)
                                ELSE 0
                            END)
                        WHEN 4 THEN 0
                        WHEN 0 THEN (
                            CASE oe_hdr.order_type
                                WHEN 1706 THEN (
                                    CASE
                                        WHEN p21_view_invoice_line.invoice_line_type = 0 THEN drv_sumlines.sum_price_home - COALESCE(incentive_rewards.incentive_rewards, 0)
                                        ELSE p21_view_invoice_line.extended_price_home - COALESCE(incentive_rewards.incentive_rewards, 0)
                                    END)
                                ELSE p21_view_invoice_line.extended_price_home - COALESCE(incentive_rewards.incentive_rewards, 0)
                            END)
                        ELSE p21_view_invoice_line.extended_price_home - COALESCE(incentive_rewards.incentive_rewards, 0)
                    END
            END) AS sales_price_home,
            (CASE COALESCE(oe_line.pricing_option, 0)
                WHEN 1 THEN (
                    CASE p21_view_invoice_line.invoice_line_uid_parent
                        WHEN 0 THEN 0
                        ELSE (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped)
                    END)
                WHEN 2 THEN (
                    CASE p21_view_invoice_line.invoice_line_uid_parent
                        WHEN 0 THEN (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped)
                        ELSE 0
                    END)
                WHEN 3 THEN (
                    CASE p21_view_invoice_line.invoice_line_uid_parent
                        WHEN 0 THEN (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped)
                        ELSE 0
                    END)
                WHEN 4 THEN (
                    CASE p21_view_invoice_line.invoice_line_uid_parent
                        WHEN 0 THEN (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped)
                        ELSE 0
                    END)
                WHEN 0 THEN (
                    CASE WHEN oe_hdr.order_type = 1706 THEN (
                        CASE p21_view_invoice_line.invoice_line_type
                            WHEN 1577 THEN p21_view_invoice_line.other_cost_home * p21_view_invoice_line.hours_worked
                            WHEN 1719 THEN p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped
                            ELSE drv_sumlines.sum_other_cost_home
                        END)
                    ELSE (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped)
                    END)
                ELSE (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped)
            END) AS line_other_cost_home
    ) AS pricing
    WHERE
        invoice_hdr.approved = 'Y'
        AND (
            ISNULL(invoice_hdr.source_type_cd,0) <> 1661
            OR p21_view_invoice_line.item_id NOT IN (
                'DELIVERY', 'DISC', 'FUEL CHG', 'FUND', 'HAND', 'MISC', 'OVERPAYMENT', 'INBOUND FUEL SURCHARGE',
                'BALANCING_ITEM','FREIGHT_ITEM','HANDLING_ITEM')
        )
        AND (
            ISNULL(invoice_hdr.source_type_cd,0) = 1661
            OR invoice_hdr.invoice_class NOT IN ('Z')
        )
        AND invoice_hdr.invoice_class NOT IN ('FINANCE')
        AND p21_view_invoice_line.item_id <> 'FRT OUT'
        AND COALESCE(product_group.product_group_id,'') NOT IN ('OCI', 'OCHARGE')
        AND p21_view_invoice_line.inv_mast_uid <> 0
        AND invoice_hdr.invoice_adjustment_type NOT IN ('B', 'T', 'X', 'R', 'W', 'A', 'P', 'Z', 'Y')
        AND invoice_hdr.consolidated <> 'C'
        AND p21_view_invoice_line.tax_item = 'N'
        AND invoice_hdr.original_document_type <> 'T'
        AND p21_view_invoice_line.invoice_line_type NOT IN (928, 929, 930, 3)
        AND p21_view_invoice_line.item_id NOT IN ('DOWNPAYMENT','PREPAYMENT','cash deposit')
        AND p21_view_invoice_line.item_id <> 'ADVANCE BILL AMOUNT'
        AND invoice_hdr_salesrep.primary_salesrep = 'Y'
        AND (
            p21_view_invoice_line.qty_shipped > 0.0000
            OR p21_view_invoice_line.qty_shipped < 0.0000
            OR (p21_view_invoice_line.invoice_line_type = 1577
                AND (COALESCE(p21_view_invoice_line.hours_worked, 0) <> 0
                     OR p21_view_invoice_line.extended_price <> 0))
        )
        AND (
            (COALESCE(oe_line.lot_bill,'N') = 'N')
            OR (oe_line.lot_bill = 'Y'
                AND p21_view_invoice_line.invoice_line_uid_parent = 0
                AND p21_view_invoice_line.invoice_line_type = 4)
        )
        AND invoice_hdr.invoice_date >= d.y_start
        AND invoice_hdr.invoice_date <  d.y_end
        AND (@mfg IS NULL OR @mfg = COALESCE(inv_mast.class_id1, 'N/A'))
)
GO

-- grants per shop convention for new native asi_ objects
GRANT SELECT ON dbo.asi_fnt_sa55014_sales_invoiced_yesterday TO p21_application_role
GO
GRANT SELECT ON dbo.asi_fnt_sa55014_sales_invoiced_yesterday TO PxxiUser
GO
