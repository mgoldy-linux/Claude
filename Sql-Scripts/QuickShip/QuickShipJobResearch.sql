select *
from IntegrationJob
where Status != 'Success'
order by StartDateTime desc

select *
from IntegrationJobLog
--where LogDateTime > '2021-07-07 13:10' and Message like '%Insert%'
where LogDateTime > '2021-07-07 13:10' and TypeName = 'Error'
order by LogDateTime 

select *
from IntegrationJobParameter
where Value = '2146026'

select *
from IntegrationJobDefinitionStepFieldMap
