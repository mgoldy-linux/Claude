select *
from MasterDrive_items_xref_vw
--where supplier_id = 72078
--where default_product_group is null
where item_desc in ('AK61-5/8','H1-7/16-STL','1VP50-1-1/8','AK79-1','2BK110-1-7/16','2AK32-1') and supplier_id != 72078           

--where SIMG = '2105000489'