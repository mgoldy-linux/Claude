-- Testing 2101004522,2101004518, 2101004247,2101004250,2101001109,2101015807,2101023279,2101048010,2101055304,2101070565

select top 5 *
from Bar_Solve_Items_VW
where class_id1 = 'LMS'

select top 5 *
from Bar_Solve_Items_VW
where class_id1 = 'IPTCI'

select top 5 *
from Bar_Solve_Items_VW
where class_id1 = 'PTI' and len(legacy_item_id) > 24

select top 5 *
from Bar_Solve_Items_VW
where class_id1 = 'Tritan'


select top 5 *
from Bar_Solve_Items_VW
where legacy_item_id like '6204X3/4 ZZ/C3 PRX%'

select top 5 *
from Bar_Solve_Items_VW
where class_id1 = 'Grainger'
