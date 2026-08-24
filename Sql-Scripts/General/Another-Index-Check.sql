USE [P21Sand]
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON

SELECT [DatabaseName]
      ,[ObjectId]
      ,[ObjectName]
      ,[IndexId]
      ,[IndexDescription]
      ,CONVERT(DECIMAL(16,1)
                ,(SUM([avg_record_size_in_bytes] * [record_count])
                        / (1024.0 *1024))) AS  [IndexSize(MB)]
      ,[lastupdated] AS [StatisticLastUpdated]
      ,[AvgFragmentationInPercent] 
FROM (SELECT 
        DISTINCT DB_Name(Database_id) AS 'DatabaseName'
       ,OBJECT_ID AS ObjectId, Object_Name(Object_id) AS ObjectName
       ,Index_ID AS IndexId
       ,Index_Type_Desc AS IndexDescription
       ,avg_record_size_in_bytes 
       ,record_count
       ,STATS_DATE(object_id,index_id) AS 'lastupdated'
       ,CONVERT([varchar](512)
                 ,round(Avg_Fragmentation_In_Percent,3)) AS 'AvgFragmentationInPercent' 
      FROM sys.dm_db_index_physical_stats(db_id('PM_Db'), NULL, NULL, NULL, 'LIMITED') 
      WHERE OBJECT_ID IS NOT NULL 
        AND Avg_Fragmentation_In_Percent <> 0
		AND  DB_Name(Database_id) = '<DATABASENAME>'
		) T 
GROUP BY DatabaseName
        ,ObjectId
        ,ObjectName
        ,IndexId
        ,IndexDescription
        ,lastupdated
        ,AvgFragmentationInPercent