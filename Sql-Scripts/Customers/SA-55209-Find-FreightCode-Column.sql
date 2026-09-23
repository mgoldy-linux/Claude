/* SA 55209 - find which table actually stores the ship-to/customer's default freight code
   (address.freight_code_uid is NULL for all 61,637 active ship-to rows, so the Customer/
   Ship-To Maintenance screen's Freight Code field must be sourced from somewhere else). */

-- A: every column named freight_code_uid (or similar) anywhere in the DB, with its table
SELECT t.name AS table_name, c.name AS column_name
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
WHERE c.name LIKE '%freight_code%'
ORDER BY t.name, c.name;

-- B: same net for freight_cd in case a different column name is used on customer/address
SELECT t.name AS table_name, c.name AS column_name
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
WHERE c.name LIKE '%freight_cd%'
ORDER BY t.name, c.name;
