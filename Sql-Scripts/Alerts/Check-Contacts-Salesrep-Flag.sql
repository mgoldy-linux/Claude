-- Confirming contacts.salesrep exists and what values it holds before using it
-- to scope Fix-Blank-Salesrep-Emails-From-Login.sql's UPDATE.

SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'contacts' AND COLUMN_NAME = 'salesrep';

SELECT salesrep, COUNT(*) AS contact_count
FROM contacts
GROUP BY salesrep;
