use P21Sand;

select *
from dbo.oe_hdr
where customer_id = 126061

select m.item_id, m.item_desc,l.qty_on_hand,l.location_id
from inv_mast m
join inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
where class_id1 = 'MD' and location_id = 601

select *
from inv_mast
where class_id1 is null and delete_flag = 'N'

select top 77 *
from A_Invoice_Line_with_Hdr_Data_Olivia
where ItemBrand is null and product_group_id is not null