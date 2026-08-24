select m.inv_mast_uid
from dbo.inv_mast m
where item_id = '2101069998'

exec p21_get_orderdetail_icc  1538243

exec p21_get_order_shipment_icc 1538243

select dbo.p21_fn_code_description (704)[code_Desc]

select dbo.p21_fn_convert_minutes_to_hours (120)[Hours]
-- output XML
select dbo.p21_fn_get_ListOfShipments_for_invoice (3463681)
-- output XML
select dbo.p21_fn_get_ListOfShipments_for_order (1538243)

select dbo.p21_fn_item_id (70167)

select dbo.p21_fnt_get_zip_code_distance (14530,28105,1)