-- Fix for Remark labels

SELECT m.item_id[select_item_id],item_desc,sum(d.print_quantity)[Num2Print],x.their_item_id,'K1'[default_product_group],extended_desc[ext_item_desc]
FROM oe_pick_ticket_detail d
join inv_mast m
on d.inv_mast_uid = m.inv_mast_uid
join inv_xref x
on m.inv_mast_uid = x.inv_mast_uid
where pick_ticket_no in (2229624, 2229408,2229412,2229411,2229604,2228454,2228455,2227026,2229703,2229413,2229409,2229410,2227026,2229414,2229416) and customer_id = 12081
group by m.item_id,item_desc,x.their_item_id,extended_desc
order by item_id