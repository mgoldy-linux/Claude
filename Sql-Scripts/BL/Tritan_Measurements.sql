select distinct default_sales_discount_group
from inv_mast

select item_id[SIMG #], item_desc,purchasing_weight,length,width,height,u.pack_type,u.box_size,u.bag_size,u.add_logo,u.label_desc_line_1,u.label_desc_line_2,u.label_size,u.label_position,u.tube_size,u.tube_qty,u.carton_size,u.carton_qty,u.carton_weight,u.usa_bag_size,u.usa_box_size,u.pack_notes_1,u.pack_notes_2,u.pack_notes_3,u.pack_notes_4,u.pack_notes_5,u.pack_type
from dbo.inv_mast m
join dbo.inv_mast_ud u
on m.inv_mast_uid = u.inv_mast_uid
where default_purchase_disc_group = 'TRITAN' and delete_flag = 'N'