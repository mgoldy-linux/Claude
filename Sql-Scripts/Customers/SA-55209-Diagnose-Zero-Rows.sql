/* SA 55209 diagnostic - find which join/filter is dropping all rows to zero */

-- A: any ship-to addresses at all with freight_code_uid = 6?
SELECT COUNT(*) AS a_shipto_prepaid_any_delete_flag
FROM address
WHERE shipping_address = 'Y' AND freight_code_uid = 6;

-- B: same, but with the delete_flag filter applied
SELECT COUNT(*) AS b_shipto_prepaid_not_deleted
FROM address
WHERE shipping_address = 'Y' AND delete_flag <> 'Y' AND freight_code_uid = 6;

-- C: distribution of freight_code_uid across all active ship-to addresses
-- (confirms whether ship-to addresses actually carry this column populated at all)
SELECT freight_code_uid, COUNT(*) AS cnt
FROM address
WHERE shipping_address = 'Y' AND delete_flag <> 'Y'
GROUP BY freight_code_uid
ORDER BY cnt DESC;

-- D: of the B set, how many successfully join to customer via corp_address_id?
SELECT COUNT(*) AS d_joins_to_customer
FROM address a
JOIN customer c ON c.customer_id = a.corp_address_id
WHERE a.shipping_address = 'Y' AND a.delete_flag <> 'Y' AND a.freight_code_uid = 6
  AND c.delete_flag <> 'Y';

-- E: of the D set, how many successfully join to terms via c.terms_id?
SELECT COUNT(*) AS e_joins_to_terms
FROM address a
JOIN customer c ON c.customer_id = a.corp_address_id
JOIN terms    t ON t.terms_id = c.terms_id
WHERE a.shipping_address = 'Y' AND a.delete_flag <> 'Y' AND a.freight_code_uid = 6
  AND c.delete_flag <> 'Y';

-- F: sample terms_id data types/values actually on customer (in case of type mismatch,
-- e.g. trailing spaces or a numeric vs char comparison issue against terms.terms_id)
SELECT TOP 10 c.customer_id, c.terms_id, DATALENGTH(c.terms_id) AS terms_id_len
FROM customer c
WHERE c.terms_id IS NOT NULL;
