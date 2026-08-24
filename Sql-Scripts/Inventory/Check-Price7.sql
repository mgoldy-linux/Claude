use [P21Play2021.1.4420Local];


select Item_id, price1, price7, price8
from inv_mast m
where class_id1 = 'IPTCI' and class_id2 = 'NOTEPL' and price1 != 0 and price7 = price8