

select supplier_sort_code, *
from inventory_supplier
where supplier_id = 115718 and supplier_sort_code = 'YBR'

update dbo.inventory_supplier
set supplier_sort_code = 'YFB'
where supplier_id = 115718 and supplier_sort_code = 'YBR'

select supplier_sort_code, *
from inventory_supplier
where supplier_id = 115718 and supplier_sort_code = 'YFB'

select supplier_sort_code, *
from inventory_supplier
where supplier_id = 182518 and supplier_sort_code = 'YBR'

update dbo.inventory_supplier
set supplier_sort_code = 'YFB'
where supplier_id = 182518 and supplier_sort_code = 'YBR'

select supplier_sort_code, *
from inventory_supplier
where supplier_id = 182518 and supplier_sort_code = 'YFB'
