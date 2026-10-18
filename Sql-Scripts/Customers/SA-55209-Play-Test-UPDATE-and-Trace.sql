/* SA 55209 - Play test: verify the freight_code_uid UPDATE works, and trace what happens
   to an existing OPEN ORDER on that ship-to when the default freight code changes underneath it.

   Run against P21Play only. Nothing here touches Prod.
   Run STEP 1-3 first, review the picked candidate, THEN run STEP 4 (the UPDATE).
*/

-- =====================================================================================
-- STEP 1: find a real test candidate -- a ship-to that is currently Prepaid (freight_code_uid
-- = 6) AND has at least one real OPEN order sitting on it right now, so we can watch what
-- happens to that order. "Open" defined the same way as Sql-Scripts\Orders\Open-Order-Age.sql:
-- not complete, not cancelled, not deleted, header not a projected order/quote.
-- =====================================================================================
SELECT DISTINCT
    s.ship_to_id,
    a.name              AS ship_to_name,
    c.customer_id,
    c.customer_name,
    c.terms_id,
    t.terms_desc,
    s.freight_code_uid,
    oh.order_no,
    oh.order_date,
    oh.freight_code_uid AS order_freight_code_uid
FROM   ship_to s
JOIN   customer c  ON c.customer_id = s.customer_id
JOIN   address  a  ON a.id = s.ship_to_id
JOIN   terms    t  ON t.terms_id = c.terms_id
JOIN   p21_view_oe_hdr  oh ON oh.address_id = s.ship_to_id
JOIN   p21_view_oe_line ol ON ol.order_no = oh.order_no
WHERE  s.freight_code_uid = 6          -- Prepaid
  AND  c.delete_flag = 'N'
  AND  s.delete_flag = 'N'
  AND  oh.delete_flag = 'N'
  AND  oh.projected_order = 'N'
  AND  oh.cancel_flag = 'N'
  AND  ol.delete_flag = 'N'
  AND  ol.complete = 'N'
  AND  ol.parent_oe_line_uid = 0
ORDER BY oh.order_date DESC;

-- Pick one ship_to_id/order_no pair from the result above and plug it into @test_ship_to_id
-- and @test_order_no below before continuing.


-- =====================================================================================
-- STEP 2: BEFORE snapshot -- capture the exact state of the ship-to and the open order's
-- header before touching anything.
-- =====================================================================================
DECLARE @test_ship_to_id INT = 1131993;
DECLARE @test_order_no   INT = 6061630;

SELECT 'BEFORE - ship_to' AS label, s.ship_to_id, s.freight_code_uid, fc.freight_desc
FROM   ship_to s
LEFT JOIN p21_view_freight_code fc ON fc.freight_code_uid = s.freight_code_uid AND fc.row_status = 704
WHERE  s.ship_to_id = @test_ship_to_id;

SELECT 'BEFORE - order header' AS label, oh.order_no, oh.address_id, oh.freight_code_uid,
       fc.freight_desc, oh.order_date, oh.completed
FROM   p21_view_oe_hdr oh
LEFT JOIN p21_view_freight_code fc ON fc.freight_code_uid = oh.freight_code_uid AND fc.row_status = 704
WHERE  oh.order_no = @test_order_no;


-- =====================================================================================
-- STEP 3: sanity check -- confirm this is really a single, specific row before updating it.
-- =====================================================================================
DECLARE @test_ship_to_id INT = 1131993;
SELECT COUNT(*) AS should_be_1 FROM ship_to WHERE ship_to_id = @test_ship_to_id;


-- =====================================================================================
-- STEP 4: THE UPDATE. One row. Play only. Do not run against Prod from this script.
-- =====================================================================================
 DECLARE @test_ship_to_id INT = 1131993;
 DECLARE @test_order_no   INT = 6061630;
 UPDATE ship_to
 SET    freight_code_uid = 2   -- Out Freight
 WHERE  ship_to_id = @test_ship_to_id;


-- =====================================================================================
-- STEP 5: AFTER snapshot -- re-run the same two SELECTs from STEP 2 (same @test_ship_to_id/
-- @test_order_no values) immediately after the UPDATE. Expectation: ship_to now shows
-- freight_code_uid = 2, and the EXISTING open order's oe_hdr.freight_code_uid is UNCHANGED
-- (still 6) -- because P21 snapshots the freight code onto the order header at creation
-- time rather than looking it up live from ship_to. If the order's value changes too,
-- that's a real finding worth flagging, not the expected behavior.
-- =====================================================================================
DECLARE @test_ship_to_id INT = 1131993;
DECLARE @test_order_no   INT = 6061630;
SELECT 'AFTER - ship_to' AS label, s.ship_to_id, s.freight_code_uid, fc.freight_desc
FROM   ship_to s
LEFT JOIN p21_view_freight_code fc ON fc.freight_code_uid = s.freight_code_uid AND fc.row_status = 704
WHERE  s.ship_to_id = @test_ship_to_id;

SELECT 'AFTER - order header' AS label, oh.order_no, oh.address_id, oh.freight_code_uid,
       fc.freight_desc, oh.order_date, oh.completed
FROM   p21_view_oe_hdr oh
LEFT JOIN p21_view_freight_code fc ON fc.freight_code_uid = oh.freight_code_uid AND fc.row_status = 704
WHERE  oh.order_no = @test_order_no;


-- =====================================================================================
-- STEP 6 (manual, in the P21Play client -- not SQL): open @test_order_no in Order Entry
-- and look at the Ship Info tab's freight code:
--   a) Does it still show the order's original value (Prepaid), matching the SQL result above?
--   b) If you re-select/re-confirm the ship-to field on that SAME order (without touching
--      freight code directly), does the client offer to refresh the freight default, or
--      does it leave the order's value alone?
--   c) Create a brand-new test order for the same customer/ship-to. Confirm it defaults
--      to "Out Freight" now, proving new orders pick up the change going forward.
-- =====================================================================================


-- =====================================================================================
-- ROLLBACK -- restore Play to its original state once the trace is done, so this test
-- doesn't leave stray drift in a lower environment.
-- =====================================================================================
-- UPDATE ship_to
-- SET    freight_code_uid = 6   -- back to Prepaid
-- WHERE  ship_to_id = @test_ship_to_id;
