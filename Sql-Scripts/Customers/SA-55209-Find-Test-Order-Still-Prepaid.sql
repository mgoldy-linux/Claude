/* SA 55209 - Freight codes: find a live open order/quote still on Prepaid

   Use this AFTER running the ship_to UPDATE (SA-55209-Update-FreightCode-To-OutFreight.sql)
   in whatever environment you're testing in (Play first, per the 2026-09-28 test plan).
   Picks a candidate order whose freight code is still Prepaid even though its ship-to's
   default was just flipped to Out Freight -- open it in the P21 client, save it without
   changing anything, and see whether the Freight Code field updates on save or stays frozen.
   That answers whether open orders self-correct over time or need an explicit fix.

   Run in SSMS, pointed at the environment you're testing.
*/

SELECT TOP 5
    oh.order_no, oh.customer_id, c.customer_name, oh.ship2_name,
    oh.order_date, oh.completed, oh.cancel_flag,
    fc.freight_desc AS order_freight_code
FROM   oe_hdr  oh
JOIN   customer c ON c.customer_id = oh.customer_id
JOIN   p21_view_freight_code fc ON fc.freight_code_uid = oh.freight_code_uid AND fc.row_status = 704
WHERE  oh.freight_code_uid = 6          -- still Prepaid, post-ship_to-update
  AND  oh.delete_flag = 'N'
  AND  ISNULL(oh.cancel_flag,'N') <> 'Y'
  AND  ISNULL(oh.rma_flag,'N') <> 'Y'
  AND  oh.completed <> 'Y'
ORDER BY oh.order_date DESC;

-- Pick a row where customer_id matches one you just updated in this environment, so its
-- ship-to's default really did just change while the order itself is still stuck on Prepaid.
