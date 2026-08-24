select *
from p21_fnt_invoice_hdr('company_id', 'begin_invoice_number','end_invoice_number', begin_invoice_number, end_invoice_number, 'begin_branch_id ', 'end_branch_id', begin_customer_id, end_customer_id, 'begin_zip_code', 'end_zip_code', 'begin_route', 'end_route', begin_ship_to,end+ship_to, 'begin_date', 'end_date', 'Is_reprint', 'is_disputed', 'is_print_components','invoice_print_type','include_DP_invoices', 'open_invoices_only','print_nonconsolidated_CUO_invoices','include_rebill_credits')




select *
from p21_fnt_invoice_hdr('1', '3069750','3069750', 0, 9999, ' ', 'ZZZZ', 0, 99999, ' ', 'ZZZZZZZZZZ', ' ', 'ZZZZZZ', 0,99999999, '01/01/1950 00:00:00', '12/31/2049 00:00:00', 'Y', 'N', 'Y','B','Y', 'N','Y','Y')