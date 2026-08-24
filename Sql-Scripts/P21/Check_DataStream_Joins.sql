select *
from dwobject_syntax
where [join] like '%oe_hdr_ud%'

select *
from dwobject
where dwobject_uid in (5,8)