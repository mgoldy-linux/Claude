-- Reduce size of the DB
Use BartenderTest;

select Count(*)
from p21_item_view

delete 
from p21_item_view
where class_id1 != 'IPTCI' or class_id2 != 'EPL'

select Count(*)
from p21_item_view


