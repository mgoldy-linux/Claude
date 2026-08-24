select currency_id,*
from supplier
where supplier_id = 188587

select *
from currency_hdr

update dbo.supplier
set currency_id = 5
where supplier_id = 188587

select currency_id,*
from supplier
where supplier_id = 188587