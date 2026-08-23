SELECT email_address, * 
FROM contacts 
WHERE (email_address LIKE '%[^a-zA-Z0-9.]%' AND email_address NOT LIKE '%@%' AND email_address <> '') 
OR (email_address NOT LIKE '%@%' AND email_address <> '') 

SELECT email_address, * 
FROM address 
WHERE (email_address LIKE '%[^a-zA-Z0-9.]%' AND email_address NOT LIKE '%@%' AND email_address <> '') 
OR (email_address NOT LIKE '%@%' AND email_address <> '') 

SELECT ship2_email_address, * 
FROM invoice_hdr 
WHERE (ship2_email_address LIKE '%[^a-zA-Z0-9.]%' AND ship2_email_address NOT LIKE '%@%' AND ship2_email_address <> '') 
OR (ship2_email_address NOT LIKE '%@%' AND ship2_email_address <> '') 
