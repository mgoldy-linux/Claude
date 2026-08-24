Select *
from vendor
where vendor_id = 18748
--hdr
INSERT INTO "vendor_edi_transaction" ( "vendor_edi_transaction_uid", "company_id", "vendor_id", "edi_transaction", "row_status_flag", "date_created", "date_last_modified", "last_maintained_by" ) VALUES ( 5, '1', 18748, 946, 708, '2024-02-05 15:13:30.136', '2024-02-05 15:13:30.136', 'MGOLDYN' )
--1
INSERT INTO "vendor_edi_transaction_detail" ( "vendor_edi_trans_detail_uid", "vendor_edi_transaction_uid", "name", "value", "data_type_cd", "data_type_length", "data_type_scale", "date_created", "date_last_modified", "last_maintained_by" ) VALUES ( 48, 5, 'accept_invoice_without_po', 'Y', 851, 255, 0, '2024-02-05 15:13:30.136', '2024-02-05 15:13:30.136', 'MGOLDYN' )
--2
INSERT INTO "vendor_edi_transaction_detail" ( "vendor_edi_trans_detail_uid", "vendor_edi_transaction_uid", "name", "value", "data_type_cd", "data_type_length", "data_type_scale", "date_created", "date_last_modified", "last_maintained_by" ) VALUES ( 49, 5, 'expense_account', '54020000300', 851, 255, 0, '2024-02-05 15:13:30.136', '2024-02-05 15:13:30.136', 'MGOLDYN' )
--3
INSERT INTO "vendor_edi_transaction_detail" ( "vendor_edi_trans_detail_uid", "vendor_edi_transaction_uid", "name", "value", "data_type_cd", "data_type_length", "data_type_scale", "date_created", "date_last_modified", "last_maintained_by" ) VALUES ( 50, 5, 'purchase_description', 'Freight', 851, 255, 0, '2024-02-05 15:13:30.136', '2024-02-05 15:13:30.136', 'MGOLDYN' )
--4
INSERT INTO "vendor_edi_transaction_detail" ( "vendor_edi_trans_detail_uid", "vendor_edi_transaction_uid", "name", "value", "data_type_cd", "data_type_length", "data_type_scale", "date_created", "date_last_modified", "last_maintained_by" ) VALUES ( 51, 5, 'vouch_unreconciled_invoices', 'N', 851, 255, 0, '2024-02-05 15:13:30.136', '2024-02-05 15:13:30.136', 'MGOLDYN' )
--5
INSERT INTO "vendor_edi_transaction_detail" ( "vendor_edi_trans_detail_uid", "vendor_edi_transaction_uid", "name", "value", "data_type_cd", "data_type_length", "data_type_scale", "date_created", "date_last_modified", "last_maintained_by" ) VALUES ( 52, 5, 'approve_unreconciled_vouchers', 'N', 851, 255, 0, '2024-02-05 15:13:30.136', '2024-02-05 15:13:30.136', 'MGOLDYN' )
--6
INSERT INTO "vendor_edi_transaction_detail" ( "vendor_edi_trans_detail_uid", "vendor_edi_transaction_uid", "name", "value", "data_type_cd", "data_type_length", "data_type_scale", "date_created", "date_last_modified", "last_maintained_by" ) VALUES ( 53, 5, 'prepaid_invoice_acct', '', 851, 255, 0, '2024-02-05 15:13:30.136', '2024-02-05 15:13:30.136', 'MGOLDYN' )
--7
INSERT INTO "vendor_edi_transaction_detail" ( "vendor_edi_trans_detail_uid", "vendor_edi_transaction_uid", "name", "value", "data_type_cd", "data_type_length", "data_type_scale", "date_created", "date_last_modified", "last_maintained_by" ) VALUES ( 54, 5, 'validate_item_id', 'Y', 851, 255, 0, '2024-02-05 15:13:30.136', '2024-02-05 15:13:30.136', 'MGOLDYN' )
--8
INSERT INTO "vendor_edi_transaction_detail" ( "vendor_edi_trans_detail_uid", "vendor_edi_transaction_uid", "name", "value", "data_type_cd", "data_type_length", "data_type_scale", "date_created", "date_last_modified", "last_maintained_by" ) VALUES ( 55, 5, 'validate_unit_size', 'N', 851, 255, 0, '2024-02-05 15:13:30.136', '2024-02-05 15:13:30.136', 'MGOLDYN' )
--9
INSERT INTO "vendor_edi_transaction_detail" ( "vendor_edi_trans_detail_uid", "vendor_edi_transaction_uid", "name", "value", "data_type_cd", "data_type_length", "data_type_scale", "date_created", "date_last_modified", "last_maintained_by" ) VALUES ( 56, 5, 'auto_convert_vi_direct_po', 'N', 851, 255, 0, '2024-02-05 15:13:30.136', '2024-02-05 15:13:30.136', 'MGOLDYN' )
--10
INSERT INTO "vendor_edi_transaction_detail" ( "vendor_edi_trans_detail_uid", "vendor_edi_transaction_uid", "name", "value", "data_type_cd", "data_type_length", "data_type_scale", "date_created", "date_last_modified", "last_maintained_by" ) VALUES ( 56, 5, 'auto_convert_vi_direct_po', 'N', 851, 255, 0, '2024-02-05 15:13:30.136', '2024-02-05 15:13:30.136', 'MGOLDYN' )
--11
INSERT INTO "vendor_edi_transaction_detail" ( "vendor_edi_trans_detail_uid", "vendor_edi_transaction_uid", "name", "value", "data_type_cd", "data_type_length", "data_type_scale", "date_created", "date_last_modified", "last_maintained_by" ) VALUES ( 58, 5, 'override_trading_partner_flag', 'N', 851, 255, 0, '2024-02-05 15:13:30.136', '2024-02-05 15:13:30.136', 'MGOLDYN' )
--12
INSERT INTO "vendor_edi_transaction_detail" ( "vendor_edi_trans_detail_uid", "vendor_edi_transaction_uid", "name", "value", "data_type_cd", "data_type_length", "data_type_scale", "date_created", "date_last_modified", "last_maintained_by" ) VALUES ( 59, 5, 'edi_interchange_id_qualifier', '', 851, 255, 0, '2024-02-05 15:13:30.136', '2024-02-05 15:13:30.136', 'MGOLDYN' )
--13
INSERT INTO "vendor_edi_transaction_detail" ( "vendor_edi_trans_detail_uid", "vendor_edi_transaction_uid", "name", "value", "data_type_cd", "data_type_length", "data_type_scale", "date_created", "date_last_modified", "last_maintained_by" ) VALUES ( 60, 5, 'edi_interchange_id', '', 851, 255, 0, '2024-02-05 15:13:30.136', '2024-02-05 15:13:30.136', 'MGOLDYN' )
--14
INSERT INTO "vendor_edi_transaction_detail" ( "vendor_edi_trans_detail_uid", "vendor_edi_transaction_uid", "name", "value", "data_type_cd", "data_type_length", "data_type_scale", "date_created", "date_last_modified", "last_maintained_by" ) VALUES ( 61, 5, 'application_code', '', 851, 255, 0, '2024-02-05 15:13:30.136', '2024-02-05 15:13:30.136', 'MGOLDYN' )
--15
INSERT INTO "vendor_edi_transaction_detail" ( "vendor_edi_trans_detail_uid", "vendor_edi_transaction_uid", "name", "value", "data_type_cd", "data_type_length", "data_type_scale", "date_created", "date_last_modified", "last_maintained_by" ) VALUES ( 62, 5, 'override_your_edi_id_flag', 'N', 851, 255, 0, '2024-02-05 15:13:30.136', '2024-02-05 15:13:30.136', 'MGOLDYN' )
--16
INSERT INTO "vendor_edi_transaction_detail" ( "vendor_edi_trans_detail_uid", "vendor_edi_transaction_uid", "name", "value", "data_type_cd", "data_type_length", "data_type_scale", "date_created", "date_last_modified", "last_maintained_by" ) VALUES ( 63, 5, 'your_edi_interchange_id_qual', '', 851, 255, 0, '2024-02-05 15:13:30.136', '2024-02-05 15:13:30.136', 'MGOLDYN' )
--17
INSERT INTO "vendor_edi_transaction_detail" ( "vendor_edi_trans_detail_uid", "vendor_edi_transaction_uid", "name", "value", "data_type_cd", "data_type_length", "data_type_scale", "date_created", "date_last_modified", "last_maintained_by" ) VALUES ( 64, 5, 'your_edi_interchange_id', '', 851, 255, 0, '2024-02-05 15:13:30.136', '2024-02-05 15:13:30.136', 'MGOLDYN' )
--18
INSERT INTO "vendor_edi_transaction_detail" ( "vendor_edi_trans_detail_uid", "vendor_edi_transaction_uid", "name", "value", "data_type_cd", "data_type_length", "data_type_scale", "date_created", "date_last_modified", "last_maintained_by" ) VALUES ( 65, 5, 'your_application_code', '', 851, 255, 0, '2024-02-05 15:13:30.136', '2024-02-05 15:13:30.136', 'MGOLDYN' )
