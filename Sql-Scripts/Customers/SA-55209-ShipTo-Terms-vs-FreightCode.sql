/* SA 55209 - Freight codes
   Ask: Ship-To accounts that carry real payment terms are showing Freight Code = "Prepaid"
   (freight_code_uid = 6) when they should be "Out Freight" (freight_code_uid = 2).

   Freight code lives on ship_to.freight_code_uid (NOT address.freight_code_uid, which is
   NULL for all active ship-to rows in this environment -- confirmed via diagnostic).
   Payment terms live on customer.terms_id.

   terms_id = 21 ("Due Immediately") is excluded below -- those accounts are legitimately
   cash-basis and Prepaid freight matches that. Everything else is a real credit term where
   Prepaid freight doesn't line up with terms.

   Run in SSMS (direct TDS connection from this session is blocked -- see memory).
*/

SELECT
    c.customer_id,
    c.customer_id_string,
    c.customer_name,
    s.ship_to_id,
    a.name              AS ship_to_name,
    c.terms_id,
    t.terms_desc,
    fc.freight_desc
FROM   ship_to s
JOIN   customer c ON s.customer_id = c.customer_id
JOIN   address  a ON a.id = s.ship_to_id
JOIN   terms    t ON c.terms_id = t.terms_id
JOIN   p21_view_freight_code fc ON fc.freight_code_uid = s.freight_code_uid AND fc.row_status = 704
WHERE  s.freight_code_uid = 6        -- Prepaid
  AND  c.delete_flag = 'N'
  AND  s.delete_flag = 'N'
  AND  c.terms_id <> '21'            -- exclude Due Immediately (cash-basis, legit Prepaid)
ORDER BY c.customer_id, s.ship_to_id;
