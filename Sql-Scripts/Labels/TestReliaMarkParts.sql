select item_id, upc_or_ean_id, item_desc,check_digit
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
where default_product_group in ('K1','K1CR','K1SE')