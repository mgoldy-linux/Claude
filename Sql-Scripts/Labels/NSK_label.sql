--nsk qry  - nsk parts end "-N"

select item_id,left(item_id,(len(item_id)-2))[LabelItemID],item_desc,upc_or_ean_id
from inv_mast
where item_id like '%-n'