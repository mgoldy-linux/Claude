Use P21;

select legacy_id[Import Set No.],'1'[Company ID],vendor_id,vendor_name,'Y'[Pri], created_by, date_created
from vendor
order by date_created desc
where class_1id= 'SPB-CHEC'


Select legacy_id[Import Set No.],supplier_id, supplier_name, created_by,date_created
from supplier
where legacy_id like 'SPB%' and delete_flag = 'N'
order by date_created 


select *
from customer_salesrep
where customer_id = 47670 and primary_salesrep_flag = 'Y' and salesrep_id = 27833