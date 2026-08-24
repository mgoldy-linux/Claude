-- =NL("sum","p21_view_fifo_layers","period_completed","datasource=","p21live","fifo_layer_number",$B7)

select *
from p21_view_fifo_layers
where period_completed = 9 and fifo_layer_number = 3043