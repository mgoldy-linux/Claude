--10/12/22 - update all NOBIN to NO_PRIMARY - location id = 430 per Ralph
-- 01/13/2023 - fix "No Primary" to "NO_PRIMARY"
-- 01/16/2023 - update working: Msg 2627, Level 14, State 1, Line 46
-- Violation of PRIMARY KEY constraint 'pk_inv_bin'. Cannot insert duplicate key in object 'dbo.inv_bin'. The duplicate key value is (10007, 100, NO_PRIMARY, 1).
-- The statement has been terminated.
/*
select distinct primary_bin
from inv_loc
where location_id = 430 and primary_bin not like 'L%' and primary_bin not like 'P%'
order by primary_bin
*/
-- use P21Play;
-- use p21;
/*
select count(*)[NumOF]
from inv_loc
where location_id = 100 and primary_bin = 'NOBIN'

update inv_loc
set primary_bin = 'NO_PRIMARY'
where location_id = 100 and primary_bin = 'NOBIN'

select count(*)[NumOF]
from inv_loc
where location_id = 100 and primary_bin = 'NOBIN'

select count(*)[NumOF]
from inv_loc
where location_id = 100 and primary_bin = 'NO_PRIMARY'
*/


select count(primary_bin)[NumOfBefore]
from inv_loc
where primary_bin = 'NO PRIMARY' and location_id = 100

Update dbo.inv_loc
set primary_bin = 'NO_PRIMARY'
where primary_bin = 'NO PRIMARY' and location_id = 100

select count(primary_bin)[NumOfAfter]
from inv_loc
where primary_bin = 'NO PRIMARY' and location_id = 100

select COUNT(bin)[numOf]
from dbo.inv_bin 
where bin = 'NOBIN' and location_id = 100

update dbo.inv_bin
set bin = 'NO_PRIMARY'
where bin = 'NOBIN' and location_id = 100

select COUNT(bin)[numOf]
from dbo.inv_bin 
where bin = 'NOBIN' and location_id = 100