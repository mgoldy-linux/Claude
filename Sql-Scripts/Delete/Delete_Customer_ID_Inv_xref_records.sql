/* 06/23/2021 tested on play first (1 row affected)
									(41159 rows affected)
									(0 rows affected)
	same results on both P21 & Play
*/
/*
Select count(*)[NumOf]
from inv_xref
where customer_id = 34129

delete inv_xref
where customer_id = 34129

Select *
from inv_xref
where customer_id = 34129
*/
--Use P21Play;
Select count(*)[NumOf]
from inv_xref
where customer_id = 12945 --49889

delete inv_xref
where customer_id = 12945 --49889

Select *
from inv_xref
where customer_id = 12945 --49889