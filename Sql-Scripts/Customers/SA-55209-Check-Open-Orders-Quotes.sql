/* SA 55209 - Freight codes: check for open orders/quotes before flipping ship_to defaults

   oe_hdr.freight_code_uid is confirmed populated on the order header itself (see
   feedback_p21_datawindow_missing_vs_null -- a WILL CALL example uses it directly), meaning
   it's a snapshot copied in at order/quote entry, NOT a live lookup to ship_to. So an order
   or quote already sitting open for one of the 173 ship-to's may still carry the old Prepaid
   code (6) after we flip ship_to's default to Out Freight (2) -- worth knowing about before
   running the UPDATE, not after.

   Quotes are included, not just orders: quotes and orders share the same oe_hdr row
   (projected_order = 'Y' for a quote, 'N' for a real order -- confirmed in
   project_2026_09_21_order_deletion_criteria_test_cases), and freight_code_uid is a
   header-level field either way. A quote sitting open today will eventually convert to an
   order in place on the same row, carrying whatever freight code it already has.

   CONFIRMED 2026-09-28: oe_hdr has NO foreign key back to ship_to/address at all -- only
   denormalized copy fields (ship2_name, ship2_add1-3, ship2_city, ship2_state, ship2_zip,
   ship2_country, ship2_email_address, ship2_latitude/longitude, ship2_url,
   ship_to_phone, plus unrelated blind_ship_flag/dflt_ups_ship_via_code/
   requested_ship_date/ship_confirmed_flag/shipping_route_uid/limit_max_shipments_per_order).
   No uid/id among them. So the join below goes through customer_id (a real column,
   confirmed elsewhere in this project) and uses ship2_name as a soft text match only to
   tell apart which specific ship-to an order was for -- only matters for the handful of
   multi-ship-to customers on this list (e.g. Eckard Distributors, 3 locations). For every
   single-ship-to customer (the large majority of the 173) customer_id alone is exact.
*/

-- CORRECTED 2026-09-28: narrowed to oh.freight_code_uid = 6 only. The first pass showed
-- open orders/quotes with every freight code under the sun (Out Freight, No Freight, Will
-- Call, UPS...) -- proof that oe_hdr.freight_code_uid gets set/overridden independently at
-- order entry, not just copied from ship_to and left alone. Those non-Prepaid rows have
-- nothing to do with this change and were pure noise. The only rows that actually represent
-- "will keep a stale Prepaid code after the ship_to UPDATE" are the ones where the order's
-- own code is STILL Prepaid.
--
-- Open orders AND live (non-expired) quotes for the 173-account list where the order's own
-- freight code is still Prepaid. Already-expired quotes are excluded per the user's call --
-- they're candidates for the Order Deletion Criteria cleanup, not something worth a
-- freight-code correction. A NULL expiration_date is treated as still-live, not expired (per
-- the confirmed NULL-expiration trap in project_2026_09_21_order_deletion_criteria_test_cases
-- -- P21 itself doesn't treat NULL as protected, so it's not safe to treat it as "expired"
-- here either).
SELECT
    CASE oh.projected_order WHEN 'Y' THEN 'Quote' ELSE 'Order' END AS record_type,
    oh.order_no,
    c.customer_id,
    c.customer_name,
    s.ship_to_id,
    a.name                   AS shipto_on_file,
    oh.ship2_name            AS shipto_on_order,
    CASE WHEN oh.ship2_name = a.name THEN 'Match' ELSE 'Check -- different ship-to on order' END AS shipto_match,
    oh.order_date,
    qh.expiration_date       AS quote_expiration_date,
    oh.completed,
    oh.cancel_flag,
    fc.freight_desc          AS order_freight_code,
    fc_ship.freight_desc     AS shipto_freight_code_current
FROM   oe_hdr  oh
JOIN   customer c  ON c.customer_id = oh.customer_id
JOIN   ship_to  s  ON s.customer_id = c.customer_id
JOIN   address  a  ON a.id = s.ship_to_id
JOIN   terms    t  ON c.terms_id = t.terms_id
LEFT JOIN quote_hdr qh                  ON qh.oe_hdr_uid = oh.oe_hdr_uid
LEFT JOIN p21_view_freight_code fc      ON fc.freight_code_uid = oh.freight_code_uid AND fc.row_status = 704
LEFT JOIN p21_view_freight_code fc_ship ON fc_ship.freight_code_uid = s.freight_code_uid AND fc_ship.row_status = 704
WHERE  s.freight_code_uid = 6           -- still Prepaid as of the 9/23 report (pre-UPDATE state)
  AND  oh.freight_code_uid = 6          -- and the order/quote's OWN code is still Prepaid too
  AND  c.delete_flag = 'N'
  AND  s.delete_flag = 'N'
  AND  c.terms_id <> '21'
  AND  oh.delete_flag = 'N'
  AND  ISNULL(oh.cancel_flag, 'N') <> 'Y'
  AND  ISNULL(oh.rma_flag, 'N') <> 'Y'    -- RMAs excluded -- 4543757 was one, caught 9/28
  AND  oh.completed <> 'Y'                -- "open": not yet completed/invoiced
  AND  (oh.projected_order = 'N'          -- real orders: always included
        OR qh.expiration_date IS NULL     -- quotes: only if not expired (or no expiration set)
        OR qh.expiration_date > GETDATE())
ORDER BY c.customer_id, oh.order_date;

-- Nothing back? No open exposure -- safe to run the freight-code UPDATE without a follow-up
-- fix. Rows back? Each one is a genuinely at-risk order or live quote -- still Prepaid on
-- both the ship-to and the order itself -- that will keep that stale code even after
-- ship_to's default changes. Decide with the user whether those need a one-off correction
-- too, especially any close to shipping/invoicing. Rows flagged "Check -- different
-- ship-to" belong to a multi-location customer and the order may not actually be for the
-- ship-to in scope -- read the address fields before assuming it matters.
