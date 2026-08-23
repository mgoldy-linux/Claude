select *
from inv_mast
where item_id like '2309251%'

select top 9*
from Bar_Item_ID_PTI_Labels_VW
where select_item_id in ('2309251501','2309251502')

select *
from Bar_Timken_Item_ID_Labels_VW
where SIMG = '2101049135'

select *
from inv_mast
where item_id =  '2101049135'

select *
from inventory_supplier
where inv_mast_uid = 49141

use P21Play;
exec p21_set_counter @counter_id='vendor_edi_transaction',@counter_num = 690