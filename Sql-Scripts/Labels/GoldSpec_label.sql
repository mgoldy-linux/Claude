-- Gold Spec


select item_id[Part Number],item_desc[Description],upc_or_ean_id[UPC]
from inv_mast
where item_id like 'GS-%'