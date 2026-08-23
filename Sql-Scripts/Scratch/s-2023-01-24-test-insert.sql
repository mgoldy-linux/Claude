select *
from vendor_ud 
where created_by = 'MGOLDYN-SQL'
/*
SET IDENTITY_INSERT vendor_ud ON
Need this line or will get this error: 
Msg 544, Level 16, State 1, Line 12
Cannot insert explicit value for identity column in table 'customer_ud' when IDENTITY_INSERT is set to OFF.
*/


INSERT INTO vendor_ud ("vendor_ud_uid","vendor_id","company_id","legacy_id","date_created","created_by","date_last_modified","last_maintained_by","legacy_company")
     VALUES (1186,69722,1,'1',GetDate(),'MGOLDYN-SQL',GetDate(),'MGOLDYN-SQL','ESORT')

select *
	 from supplier_ud
	 order by date_created desc

INSERT INTO customer_ud ("customer_ud_uid","customer_id","company_id","legacy_customer_id","date_created","created_by","date_last_modified","last_maintained_by","legacy_company_id")
     VALUES (9027,73858,1,'1',GetDate(),'MGOLDYN-SQL',GetDate(),'MGOLDYN-SQL','ESORT')