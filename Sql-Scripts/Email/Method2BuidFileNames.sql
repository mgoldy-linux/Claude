-- is null before trying to add together
Declare @f1023 as varchar(255),
		@f10659 as varchar(255),
		@fileNames as varchar(255);


IF OBJECT_ID('tempdb..#DirectoryTree')IS NOT NULL
      DROP TABLE #DirectoryTree;
CREATE TABLE #DirectoryTree (
       id int IDENTITY(1,1)
      ,subdirectory nvarchar(512)
      ,depth int
      ,isfile bit);
INSERT #DirectoryTree (subdirectory,depth,isfile)
EXEC master.sys.xp_dirtree 'C:\SQL_Out',1,1;
SELECT @f1023 = subdirectory FROM #DirectoryTree
WHERE isfile = 1 AND subdirectory like  '%1023%'

SELECT @f10659 = subdirectory FROM #DirectoryTree
WHERE isfile = 1 AND subdirectory like  '%10679%'

if @f1023 is not null 
begin
	set @f1023 = 'C:\SQL_Out\' + @f1023
end
else
begin
	set @f1023 = 'C:\SQL_Out\NoFileFound.txt'
end

if @f10659 is not null
begin
	set @f10659 = 'C:\SQL_Out\'  + @f10659
end
else
begin
set  @f10659 = 'C:\SQL_Out\NoFileFound.txt'
end

set  @fileNames = @f1023 + ';'  + @f10659

select @f1023[23]
select @f10659[659]
Select @fileNames[fn]