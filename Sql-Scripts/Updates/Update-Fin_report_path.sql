--find data want to change
select fin_report_id,fin_report_desc, path_and_file_name
from fin_report
where path_and_file_name like 'I:\2019-2020\%'

Update fin_report 
set path_and_file_name = replace(path_and_file_name,'I:','\\PTI-VS3\FP')
where path_and_file_name like 'I:\2019-2020\%'

-- verifying all are updated
select fin_report_id,fin_report_desc,path_and_file_name
from fin_report
where path_and_file_name like 'I:\2019-2020\%'

-- Update Reports results
select fin_report_id,fin_report_desc,path_and_file_name
from fin_report
where path_and_file_name like '\\PTI-VS3\FP%'