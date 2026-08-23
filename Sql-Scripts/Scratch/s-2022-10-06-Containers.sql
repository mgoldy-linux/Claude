--  dbo.p21_view_container_building_report t
-- join dbo.p21_view_container_building_po_report l


select *
from dbo.p21_view_container_building_report t
join dbo.p21_view_container_building_po_report l
on t.container_building_uid = l.container_building_uid
join dbo.inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
join dbo.vessel_receipts_container vrc
on t.container_building_uid = vrc.container_building_uid
join dbo.inv_mast_ud mu
on m.inv_mast_uid = mu.inv_mast_uid
join dbo.po_line pl
on l.po_no = pl.po_no and l.line_no = pl.line_no
where  (vrc.row_status_flag not in (700,701,705) or vrc.row_status_flag is null) and t.container_name = 'EMBE00 46740 - EMS220816491 - CONT.1397'

select  *
from dbo.p21_view_container_building t
join dbo.p21_view_container_building_po_report l
on t.container_building_uid = l.container_building_uid
join dbo.inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
left join dbo.vessel_receipts_container vrc
on t.container_building_uid = vrc.container_building_uid
join dbo.inv_mast_ud mu
on m.inv_mast_uid = mu.inv_mast_uid
join dbo.po_line pl
on l.po_no = pl.po_no and l.line_no = pl.line_no
where (vrc.row_status_flag not in (700,701,705) or vrc.row_status_flag is null) and   t.container_name = 'EMBE00 46740 - EMS220816491 - CONT.1397'