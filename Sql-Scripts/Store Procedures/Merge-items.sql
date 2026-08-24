select p.name[sp_name],parameter_id,user_type_id,system_type_id,s.name[data_type],p.is_nullable,p.max_length,p.precision
from sys.parameters p
join sys.systypes s
on p.user_type_id = s.xtype
where object_id in (424193107,882622733)

SELECT OBJECT_ID('p21_merge_items', 'P')[Sp_id];


select *
from sys.systypes

select *
from inv_mast
where item_id in ('2212090946', '2101052739')
-- this one failed supplier ID
exec p21_merge_items '2212090946', '2101052739'
-- this one worked
exec p21_merge_items_app '2212090946', '2101052739'

select *
from inv_mast
where item_id in ('2212090946', '2101052739')

Use P21;
select *
from inv_mast
where item_id in ('2100029967', '2101052854', '2100029970','2101052906','2100029968','2100029966' )

exec p21_merge_items_app '2100029967', '2101052854','0','N','N'
exec p21_merge_items_app '2100029970', '2101052906','0','N','N'
exec p21_merge_items_app '2100029968', '2100029966','0','N','N'

select *
from inv_mast
where item_id in ('2100029967', '2101052854', '2100029970','2101052906','2100029968','2100029966' )

Use P21Play
--exec p21_merge_items_app '2100029968', '2100029966','0','N','N'
exec p21_merge_items_app '2100029967', '2101052854','0','Y','Y'
