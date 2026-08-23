select *
from customer
where customer_name like '%fastenal%'

Update customer
set trading_partner_name = '042653634G', send_ucc128info = 'Y',
prnt_ucc128_label_after_final_pkg_flag = 'Y',mfr_no = '0888569',
ucc128_form_filename = '\\pti-sql21\P21Shares\Reports_Play2\Fastenal_UCC_128.rpt'
where customer_id = 11400

insert into customer_edi_transaction (customer_edi_transaction_uid,company_id,customer_id,
edi_transaction,row_status_flag,date_created,date_last_modified,last_maintained_by)
values(5795,'1',11400,'989','2709',GETDATE(),GETDATE(),'mgoldyn')

insert into customer_edi_setting (customer_edi_setting_uid,company_id,customer_id,
trading_partner_name,edi_interchange_id_qualifier,edi_interchange_id,application_code,
element_separator,functional_ack_flag,validate_x12_document_flag,testing_mode_flag,
eighty_column_line_break_flag,date_created,created_by,date_last_modified,last_maintained_by,edi855_consignment_only_flag)
values (6952,'1',11400,'042653634G','01','042653634G','042653634G','|','Y','N','N','N',
GETDATE(),'mgoldyn',GETDATE(),'mgoldyn','N');

select max(customer_edi_transaction_uid)[trans_uid_cet]
from customer_edi_transaction

--exec p21_set_counter @counter_id='customer_edi_trans' ,@counter_num = 41782

select max(customer_edi_setting_uid)[trans_uid_ces]
from customer_edi_setting

--exec p21_set_counter @counter_id='customer_edi_setting' ,@counter_num = 41782
