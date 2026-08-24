select *
from inv_xref
where last_maintained_by = 'MGOLDYN'
order by date_last_modified desc

Delete inv_xref
where last_maintained_by = 'MGOLDYN'

select *
from inv_xref
where last_maintained_by = 'MGOLDYN'
order by date_last_modified desc