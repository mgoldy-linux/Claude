select container_name, count(item_id)[NumOfLines]
from BAR_100_Receipt_Label_VW
group by container_name
order by NumOfLines desc

