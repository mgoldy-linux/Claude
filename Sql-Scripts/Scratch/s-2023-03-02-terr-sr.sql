select  invoice_no,territory,customer_id_on_order,sales
from A_INV_LINE_with_Hdr_Data_MG
where customer_id_on_order = 10896

select  invoice_no,territory,customer_id_on_order,sales
from A_INV_LINE_with_Hdr_Data_MG
where invoice_no = '3144987'

select *
from Territory_SalesReps
where customer_id_on_order = 10896