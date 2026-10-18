/* SA 55209 - Play test, round 2: find a real, non-deleted, non-RMA, non-Will-Call order
   on a Prepaid ship-to, so we can test an order that isn't already trivially diverged from
   the ship-to's default (like the Will Call one already tested).
*/

SELECT DISTINCT
    s.ship_to_id,
    a.name              AS ship_to_name,
    c.customer_id,
    c.customer_name,
    s.freight_code_uid  AS shipto_freight_code_uid,
    oh.order_no,
    oh.order_date,
    oh.freight_code_uid AS order_freight_code_uid,
    fc.freight_desc     AS order_freight_desc,
    oh.completed,
    oh.rma_flag
FROM   ship_to s
JOIN   customer c  ON c.customer_id = s.customer_id
JOIN   address  a  ON a.id = s.ship_to_id
JOIN   p21_view_oe_hdr oh ON oh.address_id = s.ship_to_id
LEFT JOIN p21_view_freight_code fc ON fc.freight_code_uid = oh.freight_code_uid AND fc.row_status = 704
WHERE  s.freight_code_uid = 6          -- Prepaid ship-to's, same pool as before
  AND  c.delete_flag = 'N'
  AND  s.delete_flag = 'N'
  AND  oh.delete_flag = 'N'
  AND  oh.projected_order = 'N'
  AND  oh.cancel_flag = 'N'
  AND  oh.rma_flag = 'N'                -- exclude RMAs
  AND  oh.freight_code_uid <> 8         -- exclude Will Call, already tested
ORDER BY oh.order_date DESC;
