select sequence_number,* 
from dbo.price_library_x_cust_x_cmpy
where customer_id = 10024 and price_library_uid = 153

select price_library_uid,price_library_id
from dbo.price_library
where price_library_id in ('IPTCI-LIST','IPTCI-DIST-42','PTI-DIST-42','PTI-LIST','PTI-OEM-53','TRITAN-LIST','TRITAN-DIST-42','TRITAN-B35','TRITAN-ADMP','TRITAN-OEM-53')

select *
from dbo.price_library
where price_library_id in ('PTI-LIST','PTI-OEM-53')

select *
from dbo.price_library
where price_library_id in ('TRITAN-LIST','TRITAN-DIST-42','TRITAN-B35','TRITAN-ADMP')

select *
from dbo.price_library
where price_library_id in ('TRITAN-OEM-53','TRITAN-DIST-42')

select *
from dbo.price_family
where price_family_uid in (4,33)

select item_id, *
from dbo.inv_mast
where default_price_family_uid = 33
order by inv_mast.item_id

select price_family_id, price_family_uid,price_family_desc
from price_family
where price_family_id in ('DISTRIBUTED','EZO','KOYO','KSM','ORS','SILVERTHIN','TRITAN B4','TRITAN BB','TRITAN CHAIN','TRITAN FAMILY','TRITAN FAST MOVER','TRITAN SPROCKET')
order by price_family_uid