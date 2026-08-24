use P21;
--use Play2;

select *
from Territory_SalesReps
where customer_id_on_order = 12338

delete Territory_SalesReps
where customer_id_on_order = 12338 and Territory = 'Midwest'

select *
from Territory_SalesReps
where customer_id_on_order = 12338
