select *
from  vendor_edi_transaction
where vendor_id = 15778

select *
from  vendor_edi_transaction_detail

select max(vendor_edi_trans_detail_uid)[mvdtd_muid]
from dbo.vendor_edi_transaction_detail

INSERT INTO "vendor_edi_transaction_detail" ( "vendor_edi_trans_detail_uid", "vendor_edi_transaction_uid", "name", "value", "data_type_cd", "data_type_length", "data_type_scale", "date_created", "date_last_modified", "last_maintained_by" ) VALUES (48, 6, 'accept_invoice_without_po', 'Y', 851, 255, 0, GETDATE(), GETDATE(),'mgoldyn-sql'),
(49,6,'expense_account', '63110100100', 851, 255, 0,GETDATE(),GETDATE(),'mgoldyn-sql'),
(50,6,'purchase_description', 'Computer Expense ', 851, 255, 0,GETDATE(),GETDATE(),'mgoldyn-sql'),
(51,6, 'vouch_unreconciled_invoices', 'N', 851, 255, 0,GETDATE(),GETDATE(),'mgoldyn-sql'),
(52,6,'approve_unreconciled_vouchers', 'N', 851, 255, 0, GETDATE(),GETDATE(),'mgoldyn-sql'),
(53,6,'prepaid_invoice_acct', '', 851, 255, 0, GETDATE(),GETDATE(),'mgoldyn-sql'),
(54,6,'validate_item_id', 'N', 851, 255, 0,GETDATE(),GETDATE(),'mgoldyn-sql'),
(55,6,'validate_unit_size', 'N', 851, 255, 0, GETDATE(),GETDATE(),'mgoldyn-sql'),
(56,6,'auto_convert_vi_direct_po', 'N', 851, 255, 0,GETDATE(),GETDATE(),'mgoldyn-sql'),
(57,6, 'transaction_map_name', '', 851, 255, 0, GETDATE(), GETDATE(),'mgoldyn-sql'),
(58,6,'override_trading_partner_flag', 'N', 851, 255, 0,GETDATE(),GETDATE(),'mgoldyn-sql'),
(59,6,'edi_interchange_id_qualifier', '', 851, 255, 0,GETDATE(),GETDATE(),'mgoldyn-sql'),
(60,6, 'edi_interchange_id', '', 851, 255, 0,GETDATE(),GETDATE(),'mgoldyn-sql'),
(61,6,'application_code', '', 851, 255, 0, GETDATE(),GETDATE(),'mgoldyn-sql'),
(62,6,'override_your_edi_id_flag', 'N', 851, 255, 0, GETDATE(),GETDATE(),'mgoldyn-sql'),
(63,6,'your_edi_interchange_id_qual', '', 851, 255, 0,GETDATE(),GETDATE(),'mgoldyn-sql'),
(64,6,'your_edi_interchange_id', '', 851, 255, 0, GETDATE(),GETDATE(),'mgoldyn-sql'),
(65,6,'your_application_code', '', 851, 255, 0,GETDATE(),GETDATE(),'mgoldyn-sql');

select max(vendor_edi_trans_detail_uid)[mvdtd_muid]
from dbo.vendor_edi_transaction_detail

exec p21_set_counter @counter_id='vendor_edi_transaction_detail',@counter_num = 12341

select *
from dbo.vendor_edi_transaction_detail
where vendor_edi_trans_detail_uid = 12341

