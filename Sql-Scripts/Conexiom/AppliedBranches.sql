/*
	select count(*) from p21_view_customer where class_2id = 'APPLIED' and delete_flag = 'N'
*/

with getBranches(Zip_Code,City,Street_Addr,customer_name,PTI_Default_Branch,customer_id,shipTo_ID)
as
(
	select left(a.phys_postal_code,5),a.phys_city,a.phys_address1, customer_name,default_branch_id,customer_id,customer_id 
	from customer c
	join address a
	on c.customer_id = a.id
	where class_2id = 'Applied' and customer_name not like '%Bill TO%' and customer_name not like '%DO NOT USE%' and c.delete_flag = 'N'
)
select Zip_Code,City,Street_Addr,customer_name,PTI_Default_Branch,customer_id,shipTo_ID,co.id,co.first_name,co.last_name
from getBranches gb
join contacts co
on gb.customer_id = co.address_id
--where gb.PTI_Default_Branch = 300
where co.first_name = 'Primary'
order by Zip_Code

--customers with only one branch with primary for 300
/*
with getBranches(Zip_Code,City,Street_Addr,customer_name,PTI_Default_Branch,customer_id,shipTo_ID)
as
(
	select left(a.phys_postal_code,5),a.phys_city,a.phys_address1, customer_name,default_branch_id,customer_id,customer_id 
	from customer c
	join address a
	on c.customer_id = a.id
	where class_2id = 'Applied' and customer_name not like '%Bill TO%' and customer_name not like '%DO NOT USE%' and c.delete_flag = 'N'
)
select Zip_Code,City,Street_Addr,customer_name,PTI_Default_Branch,customer_id,shipTo_ID,co.id,co.first_name,co.last_name
from getBranches gb
join contacts co
on gb.customer_id = co.address_id
--where gb.PTI_Default_Branch = 300
where Zip_Code in (04210,04730,13362,13850,14814,15205,15931,17015,19604,20877,21502,21704,22602,25198,25303,29625,31907,36609,
38901,41042,43701,44115,44483,47635,49735,49801,53151,58103,61109,67401,70634,70669,71601,71701,72315,74145,776712,77023,
77434,77477,77590,77630,79763,0906,81505,81625,82601,82716,86001,90248,92880,94010,94538,97230) and gb.PTI_Default_Branch = 300
order by Zip_Code
*/

--customers with only one branch with primary for 100
/*
with getBranches(Zip_Code,City,Street_Addr,customer_name,PTI_Default_Branch,customer_id,shipTo_ID)
as
(
	select left(a.phys_postal_code,5),a.phys_city,a.phys_address1, customer_name,default_branch_id,customer_id,customer_id 
	from customer c
	join address a
	on c.customer_id = a.id
	where class_2id = 'Applied' and customer_name not like '%Bill TO%' and customer_name not like '%DO NOT USE%' and c.delete_flag = 'N'
)
select Zip_Code,City,Street_Addr,customer_name,PTI_Default_Branch,customer_id,shipTo_ID,co.id,co.first_name,co.last_name
from getBranches gb
join contacts co
on gb.customer_id = co.address_id
--where gb.PTI_Default_Branch = 300
where Zip_Code in (30241,31206,49802,67901,71602,78217,81501,86004,94534) and gb.PTI_Default_Branch = 100
order by Zip_Code
*/