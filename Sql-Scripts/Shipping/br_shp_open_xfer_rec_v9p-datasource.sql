-- 20260422 - SA 43045 add loc_id as parameter
-- 20260127 replace ds-view transfers with v_transfer_portal_status split out loc id & name
-- 20250813 source for promise and require dates changed to 'line views'; ranked promise date updated to remove duplicate lines
-- 20250918 add packing status
-- 20250717 SA 27775 add order no
-- 20250707 add promise date day of week
-- 20250702 add promise date & route code
-- 20250627 replace plan_recpt_dt with required date
-- Transfer Status is shipped because it will be received at the user's location soon

WITH RankedTransfers AS (
    SELECT
        from_loc, from_name,
        to_loc, to_name,
        transfer_no,
        shipment_no,
        carrier, route_code,
        xfer_dt,
        required_dt, cur_promise_date, day_of_week,
        line_no,
        item_id,
        item_desc,
        qty_shipped, items_xfer_wt,
        qty_recvd,
        uom,
        status,
        CASE
            WHEN LEFT(created_by, 4) = 'AHI\' THEN SUBSTRING(created_by, 5, 40)
            ELSE created_by
        END AS created_by,
        order_no,
        ROW_NUMBER() OVER (PARTITION BY t.transfer_no, t.item_id ORDER BY t.cur_promise_date DESC) AS rn
    FROM v_transfer_portal_status t
    INNER JOIN (
        SELECT CAST(location_id AS VARCHAR) AS location_id
        FROM dbo.asi_fnt_get_user_loc('BGABBERT')  -- test user
        -- FROM dbo.asi_fnt_get_user_loc('<user_id>')  -- production
    ) AS my_locs
        ON my_locs.location_id = t.to_loc
    WHERE
        status_no NOT IN (1, 2, 5, 6)
        AND status <> 'PT Canceled'
        AND (:to_loc IS NULL OR t.to_loc = :to_loc)  -- SA 43045 branch loc filter (retrieval arg: String)
)
SELECT
    RT.*,
    voh.packing_basis
FROM RankedTransfers RT
LEFT JOIN p21_view_oe_hdr voh
    ON RT.order_no = voh.order_no
WHERE rn = 1
ORDER BY
    required_dt,
    from_loc,
    transfer_no,
    shipment_no,
    line_no
