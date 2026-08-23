select REPLACE(item_desc,'T-','')[Pallet_desc], item_desc
from inv_mast
where item_id = '2101026163'

select *
from po_line
where inv_mast_uid = 26165

select *
from oe_hdr
where po_no = '4701092767'

select *
from oe_pick_ticket
where order_no = 1310095

select *
from Bar_Timken_Pick_Ticket_Labels_VW
order by SIMG

select m.item_id,item_desc,extended_desc, isu.supplier_id,ist.country_of_origin
from dbo.inv_mast m 
join inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
join dbo.inventory_supplier_trade ist
on isu.inventory_supplier_uid = ist.inventory_supplier_uid
where country_of_origin = 'RY' and supplier_id = 29586