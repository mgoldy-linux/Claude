Select '300'[Record Type],pl.po_line_uid[External ID],line_no[Line Number],ph.supplier_id, isu.supplier_id,item_id
from dbo.po_line pl
join dbo.inv_mast m
on pl.inv_mast_uid = m.inv_mast_uid
join po_hdr ph
on pl.po_no = ph.po_no
left join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid and ph.supplier_id = isu.supplier_id
where pl.po_no in(4016331) and ph.delete_flag = 'N' and pl.delete_flag = 'N'


-- po to item supplier mismatch
Select distinct ph.supplier_id, isu.supplier_id,item_id,pl.po_no
from dbo.po_line pl
join dbo.inv_mast m
on pl.inv_mast_uid = m.inv_mast_uid
join po_hdr ph
on pl.po_no = ph.po_no
left join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid and ph.supplier_id = isu.supplier_id
where isu.supplier_id is null and ph.delete_flag = 'N' and pl.delete_flag = 'N' and ph.complete = 'N'
order by po_no