Use Datastore;

select *
from PrintJobsSummaryView

select top 5*
from PrintJobsDetailsView
where CurrentJobStateFallbackValue = 'Error' and JobName like 'IPTCI%'
order by PrintJobID desc

select *
from PrintMessagesView
where PrintJobID = '-2147244080'

-- object string is text going to the label
select top 5 *
from ObjectsView
where PrintJobID = '-2147244080'
order by PrintedLabelID desc

-- ObjectNameID to field on label
select top 5*
from ObjectNameView

-- BL by-item-print jobs
select PrintJobID,IdenticalCopies,TotalLabels,JobName,USERNAME,PrinterName,PrinterModel,FormatModifiedDateTime
from PrintJobsDetailsView
where JobName like 'IPTCI_Label%' and FormatModifiedDateTime > '2024-02-19'
order by PrintJobID desc

select distinct PrinterName,PrinterPort
from PrintJobsDetailsView
where  FormatModifiedDateTime > '2023-05-24'
order by PrinterName

select JobName,FormatModifiedDateTime,PrintJobID,IdenticalCopies,TotalLabels,USERNAME,PrinterName,PrinterModel,PrinterPort
from PrintJobsDetailsView
where PrinterName in ('\\NY-BL-JMCHAYLE-WORKPC.bearings.local\ET788C7712498F','\\NY-BL-JMCHAYLE-WORKPC.bearings.local\Lexmark MS430 IT')
and FormatModifiedDateTime > '2023-05-24'

-- need to find away to find Bartener queries to DB
SELECT TOP (1000) [MessageEventID]
      ,[Number]
      ,[EventDateTime]
      ,[UTC]
      ,[InstanceId]
      ,[SeverityID]
      ,[MessageTypeID]
      ,[ResponseID]
      ,[ApplicationID]
      ,[ServerID]
      ,[Text]
  FROM [Datastore].[dbo].[MessagesView]
  where Text like '%Records%'


  Select  *
  from MessageStrings
  where Text like 'No records%'