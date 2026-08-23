use QuickShip;

select top 100 *
from Logs
where Level = 'Error'
order by TimeStamp desc

select top 50 *
from Logs
order by TimeStamp desc

-- has information but not helpful
select *
from ApplicationLog
--where Source = 'WebServiceHandler.GetIntegrationJob'
order by LogDate desc

select *
from ApplicationMessage

-- returned no information
select *
from CustomMessages

select top 60 *
from IntegrationJobLog
--where TYPEName = 'Error'
order by LogDateTime desc