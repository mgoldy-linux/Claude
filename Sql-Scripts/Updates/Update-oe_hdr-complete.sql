-- 09/22/22 → JH Can you mark order #1302719 not complete please
Use P21;

select completed
from dbo.oe_hdr
where order_no = 1302719

update dbo.oe_hdr
set completed = 'N'
where order_no = 1302719

select completed
from dbo.oe_hdr
where order_no = 1302719