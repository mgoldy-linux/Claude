select bin, COUNT (item_id)[NumOf]
from Bar_BL_Transfer_Items
group by bin

select *
from Bar_BL_Transfer_Items
where bin = 'LM1601005S'