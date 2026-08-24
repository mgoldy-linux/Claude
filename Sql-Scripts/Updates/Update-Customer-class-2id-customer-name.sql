-- Quick update of BRGDIST to class id 2 APPLIED, remove AD- from name
-- both Name and Class_2id
select class_2id,class_3id,customer_name
from dbo.customer
where customer_id in (11602,11603,11604,11605,11614,11615,11616,11617,11622,11623,11630,11631,11645,57955)

Update dbo.customer
set class_2id = 'APPLIED', customer_name = replace(customer_name,'AD-', '')
where customer_id in (11602,11603,11604,11605,11614,11615,11616,11617,11622,11623,11630,11631,11645,57955)

select class_2id,class_3id,customer_name
from dbo.customer 
where customer_id in (11602,11603,11604,11605,11614,11615,11616,11617,11622,11623,11630,11631,11645,57955)
-- address name
select name
from address
where id in (11602,11603,11604,11605,11614,11615,11616,11617,11622,11623,11630,11631,11645,57955)

update dbo.address
set name = replace(name,'AD-', '')
where id in (11602,11603,11604,11605,11614,11615,11616,11617,11622,11623,11630,11631,11645,57955)

select name
from address
where id in (11602,11603,11604,11605,11614,11615,11616,11617,11622,11623,11630,11631,11645,57955)

-- just class_2id
select class_2id
from dbo.customer
where customer_id in (11602,11603,11604,11605,11614,11615,11616,11617,11622,11623,11630,11631,11645,57955)

Update dbo.customer
set class_2id = 'APPLIED'
where customer_id in (11602,11603,11604,11605,11614,11615,11616,11617,11622,11623,11630,11631,11645,57955)

select class_2id,class_3id,customer_name
from dbo.customer 
where customer_id in (11602,11603,11604,11605,11614,11615,11616,11617,11622,11623,11630,11631,11645,57955)