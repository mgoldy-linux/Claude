use WQMetaData;

Select * from schedulelog
where UserName = 'mchandler'
 order by rundate desc, runtime desc

 Select * from schedulelog
where ReportName like '%Lost%'
 order by rundate desc, runtime desc

 Select * from schedulelog
where RunDate > '2024-02-06'
 