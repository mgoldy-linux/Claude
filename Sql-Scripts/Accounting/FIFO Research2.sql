select *
from  fifo_layer_transaction

select *
from fifo_layers

exec p21_fn_inv_cost_basis 14487, 2, 100

select *
from inv_mast 
where item_id = '2101051159'

select *
from  p21_fnt_get_inventory_value (2101014485, 100)

exec p21_get_cost_history 2101014485,100

exec p21_item_info 2101014485,100

select *
from fifo_layers
where fifo_layer_number = 175985

select *
from p21_fnt_item_list (14487,10,'EA')

select *
from p21_fnt_get_item_location_by_landed_cost_driver (10)

exec p21_fn_fifo 51265,30,300