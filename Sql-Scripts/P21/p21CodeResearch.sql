-- list all p21 codes
Select *
FROM code_p21  
order by code_description

-- unsure what this is telling me
select *
from code_x_code_group_p21

-- edi transactions 
Select *
FROM code_p21  
where code_no > 705 and code_no like '70%' or code_no = '989'

-- some bun codes
Select *
FROM code_p21  
where code_no like '103%' or code_no like '143%'

-- row staus flag
Select *
FROM code_p21  
where code_no <= 705 and code_no like '70%'


Select *
FROM code_p21  
where code_description like '%dep%'

Select *
FROM code_p21  
where code_description like '%cancel%'

-- row status
Select code_no, code_description
FROM code_p21  
where code_no between 700 and 705 

Select code_no, code_description
FROM code_p21  
where code_no in (1941, 1881)