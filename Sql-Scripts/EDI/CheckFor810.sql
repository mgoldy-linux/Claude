select a.name[Kaman_Branch_Name],c.customer_id,cet.edi_transaction
from customer c	
join address a
on c.customer_id = a.id
join customer_edi_transaction cet
on c.customer_id = cet.customer_id 
where c.class_2id = 'kaman' and default_branch_id = 100 and c.delete_flag = 'N' and cet.customer_id != 12136

select max(customer_edi_trans_detail_uid)
from customer_edi_trans_detail
order by customer_edi_trans_detail_uid desc

select *
from customer_edi_transaction
where customer_id = 11977 


--test inserting multiple rows
 insert into customer_edi_trans_detail (customer_edi_trans_detail_uid,customer_edi_transaction_uid,name,value,data_type_cd,data_type_length,data_type_scale,date_created,date_last_modified)
            values('26670','5441','transaction_map_name','12','851','255','0',GETDATE(),GETDATE()),
            ('26671','5441','override_trading_partner_flag','N','851','255','0',GETDATE(),GETDATE()),
            ('26672','5441','edi_interchange_id_qualifier','','851','255','0',GETDATE(),GETDATE()),
            ('26672','5441','edi_interchange_id','','851','255','0',GETDATE(),GETDATE()),
            ('26672','5441','application_code','','851','255','0',GETDATE(),GETDATE()),
            ('26672','5441','override_your_edi_id_flag','N','851','255','0',GETDATE(),GETDATE()),
            ('26672','5441','your_edi_interchange_id_qual','','851','255','0',GETDATE(),GETDATE()),
            ('26672','5441','your_edi_interchange_id','','851','255','0',GETDATE(),GETDATE()),
            ('26672','5441','your_application_code','','851','255','0',GETDATE(),GETDATE());