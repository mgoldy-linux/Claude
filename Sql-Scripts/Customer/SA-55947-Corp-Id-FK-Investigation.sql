/* SA 55947 - Customer Maintenance error 547, FK fk_corp_id_address
   INSERT INTO corp_id (company_id, address_id = 61864, ...) failed: address.id 61864 not found.
   Customer 3029245 (Prosper Rei), company 1, user cthompson, 2026-09-28 14:03.
   Read-only. Run on P21 (Prod). corp_address_id lives on dbo.address (address.id = customer_id for a
   customer's own address), NOT on dbo.customer. */

DECLARE @company_id varchar(8) = '1',
        @customer_id decimal(19,0) = 3029245,
        @address_id int = 61864;

-- 1. Does the address row the screen is pointing at exist? (expect 0 rows = the cause)
SELECT 'address 61864' AS chk, a.*
FROM dbo.address a
WHERE a.id = @address_id;

-- 2. What does the customer's own address row hold for corp_address_id?
SELECT c.company_id, c.customer_id, c.customer_name, c.delete_flag, a.id AS address_id, a.corp_address_id,
       c.date_created, c.date_last_modified, c.last_maintained_by
FROM dbo.customer c
LEFT JOIN dbo.address a ON a.id = c.customer_id
WHERE c.company_id = @company_id AND c.customer_id = @customer_id;

-- 3. Any existing corp_id row for that address (would not FK-fail, but shows the pattern)?
SELECT 'corp_id for 61864' AS chk, ci.*
FROM dbo.corp_id ci
WHERE ci.company_id = @company_id AND ci.address_id = @address_id;

-- 4. Orphans: corp_id rows whose address is missing (should be impossible with the FK live)
SELECT ci.company_id, ci.address_id, ci.date_created, ci.last_maintained_by
FROM dbo.corp_id ci
WHERE NOT EXISTS (SELECT 1 FROM dbo.address a WHERE a.id = ci.address_id);

-- 5. Addresses pointing at a corp address that does not exist (other affected records)
SELECT a.id, a.name, a.corp_address_id, a.last_maintained_by, a.date_last_modified
FROM dbo.address a
WHERE a.corp_address_id IS NOT NULL AND a.corp_address_id <> 0
  AND NOT EXISTS (SELECT 1 FROM dbo.address p WHERE p.id = a.corp_address_id);

-- 6. Neighbouring address ids - was 61864 recently deleted / never committed? (gap check)
SELECT TOP (10) a.id, a.phys_address1, a.phys_city, a.phys_state, a.date_created, a.last_maintained_by
FROM dbo.address a
WHERE a.id BETWEEN @address_id - 5 AND @address_id + 5
ORDER BY a.id;

-- 7. Counter drift: is the address counter behind the highest id in use? (see feedback_p21_counter_drift)
SELECT MAX(a.id) AS max_address_id FROM dbo.address a;
DECLARE @counters TABLE (id VARCHAR(50), description VARCHAR(255), counter_num INT);
INSERT @counters EXEC p21_set_counter;   -- no args = list only
SELECT * FROM @counters WHERE id LIKE '%address%';

-- 8. Customer's own address rows by customer - what did the user actually create today?
SELECT a.id, a.name, a.mail_address1, a.mail_city, a.mail_state, a.mail_postal_code, a.date_created, a.last_maintained_by
FROM dbo.address a
WHERE a.last_maintained_by = 'cthompson'
  AND a.date_created >= '2026-09-28'
ORDER BY a.date_created DESC;

-- 9. FK definition, to confirm what it references
SELECT fk.name, OBJECT_NAME(fk.parent_object_id) AS child_table, OBJECT_NAME(fk.referenced_object_id) AS parent_table,
       fk.is_disabled, fk.is_not_trusted
FROM sys.foreign_keys fk
WHERE fk.name = 'fk_corp_id_address';

-- 10. Follow-up: what did jmoeller intend as the corp parent for 3029245? (61864 does not exist)
--     a) ids that end in / contain 61864 (dropped-digit typo)
SELECT a.id, a.name, a.corp_address_id, a.phys_address1, a.phys_city, a.phys_state, a.customer, a.delete_flag
FROM dbo.address a
WHERE CAST(a.id AS varchar(20)) LIKE '%61864%';

--     b) other rows for the same name / street (likely the real parent or sibling ship-tos)
SELECT a.id, a.name, a.corp_address_id, a.phys_address1, a.phys_city, a.phys_state, a.date_created, a.last_maintained_by
FROM dbo.address a
WHERE (a.name LIKE 'Prosper Rei%' OR a.phys_address1 LIKE '1528 County Road 1000%' OR a.mail_address1 LIKE '1528 County Road 1000%')
ORDER BY a.date_created;

--     c) how normal ship-tos look: corp_address_id equals the parent's id and has a corp_id row
SELECT TOP (5) a.id, a.name, a.corp_address_id, ci.address_id AS corp_id_row
FROM dbo.address a
LEFT JOIN dbo.corp_id ci ON ci.company_id = '1' AND ci.address_id = a.corp_address_id
WHERE a.customer = 'Y' AND a.date_created >= '2026-09-01' AND a.id <> 3029245
ORDER BY a.date_created DESC;
