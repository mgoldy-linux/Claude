-- Check Play2 Mapper
use Play2;

select *
from p21_mapper_translation_table
where table_name = 'Baldor_items' 
order by date_last_modified desc

-- IPTCI Parts
select *
from p21_mapper_translation_table
where table_name = 'IDC_items' and mapper_trans_key like '%IPT' --and mapper_trans_value like '39I905300-BOX'
order by date_last_modified desc

-- PTI Parts
select *
from p21_mapper_translation_table
where table_name = 'IDC_items' and mapper_trans_key like '%BLD'-- and mapper_trans_value not like ' '
order by date_last_modified desc

select *
from p21_mapper_translation_table
where table_name = 'Applied_items' 
order by date_last_modified desc

select *
from p21_mapper_translation_table
where table_name = 'APPLIED_CUSTOMER'
order by date_last_modified desc

select *
from p21_mapper_translation_table
where table_name = 'IDC_CUSTOMER'
ORDER BY date_created desc


select *
from p21_mapper_translation_table
where table_name = 'IDC_SCAC_810'


select *
from p21_mapper_translation_table
where table_name = 'IDC_CONTACT'

select distinct table_name
from p21_mapper_translation_table

select *
from p21_mapper_translation_table
where table_name = 'KAMAN_CUSTOMERS'
order by date_last_modified desc


select *
from p21_mapper_translation_table
where table_name = 'KAMAN_CUSTOMER_BACK'

select *
from p21_mapper_translation_table
where table_name = 'MOTION_CUSTOMER_810'
order by date_last_modified desc


select *
from p21_mapper_translation_table
where table_name = 'MOTION_CUSTOMER'
order by date_last_modified desc
