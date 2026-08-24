/*
	Test script for EDI updating
*/

use P21Play;
/*
update customer 
set trading_partner_name = '077316412TA' where customer_id = 11977 
*/

/* update will not work because, customer id is not in the table
update customer_edi_setting
set  edi_interchange_id_qualifier = '01', edi_interchange_id = '077316412TA', application_code = '077316412TA', element_separator = '~', functional_ack_flag = 'N', validate_x12_document_flag = 'N', testing_mode_flag = 'N'
where customer_id = 11977 


insert into  customer_edi_setting (company_id,customer_id,trading_partner_name,edi_interchange_id_qualifier,edi_interchange_id,application_code,element_separator,functional_ack_flag,validate_x12_document_flag,testing_mode_flag)
values ('1','11977','077316412TA','01','077316412TA','077316412TA','~','N','N','N');

select *
from customer_edi_setting
where customer_id = 11977
*/

insert into customer_edi_transaction (customer_edi_transaction_uid,company_id,customer_id,edi_transaction,row_status_flag,date_created,date_last_modified)
values('5127','1','11977','942','2709',GETDATE(),GETDATE())

select *
from customer_edi_transaction
where customer_id = 11977
