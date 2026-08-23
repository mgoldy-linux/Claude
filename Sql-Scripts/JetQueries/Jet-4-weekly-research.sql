use P21Sand;

select *
from A_Invoice_Line_with_Hdr_Data_Olivia
where branch_id in (510, 520) and invoice_date between '2023-06-01' and GETDATE()


select *
from A_Invoice_Line_with_Hdr_Data_Olivia
where branch_id in (510, 520) and invoice_date between '2022-06-01' and '2022-06-13'

select *
from A_oe_pick_ticket_detail_view_Olivia
where location_id in (510, 520) and order_date between '2022-06-01' and '2022-06-13'