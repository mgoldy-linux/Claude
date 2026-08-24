-- qry for PTI label

select upc_or_ean_id,item_id,item_desc --,'P.T.International'[company],'We Revolve Around You'[tagline]
from inv_mast
where class_id1 = 'PTI' and upc_or_ean_id = '80067515987'