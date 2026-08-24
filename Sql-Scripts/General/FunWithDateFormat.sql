select replace(convert(varchar(12), getdate(), 107),'-','/') as [Date] -- Sep 29, 2021
select replace(convert(varchar(12), getdate(), 110),'-','/') as [Date] -- 09/29/2021
select replace(convert(varchar(11), getdate(), 120),'-','/') as [Date] -- 2021/09/29 
select convert(varchar(10), getdate(), 120) as [Date120] -- 2021-09-29  
select convert(varchar(35), getdate(), 127) as [Date127] -- 2021-09-29T13:58:40.627  

select  getdate(), 120) as [Date120] -- 2021-09-29  
--return yyyymm
Left(CONVERT(varchar(8),h.invoice_date,112),6)[YearMM]

-- Get Month Name
Declare @monthName as varchar(20)
select @monthName = DATENAME(MONTH,GetDate())
 
select @monthName

select DATEPART(WEEK, getdate())
-- End of Month Name

--Get Week of the Year
Declare @WeekNum as int;

select @WeekNum =  DATEPART(WEEK,DATEADD(day,datediff(day,0,Getdate())-7,0))
Select (@WeekNum)[Week of Year]

-- End of Get Week Num

--full date
Declare @dayDate as varchar(3),
		@monthName as varchar(20),
		@dayYear as varchar(5),
		@fullDate as varchar(35);

select @dayDate = DATENAME(DAY,GetDate())
select @monthName = DATENAME(MONTH,GetDate())
select @dayYear = DATENAME(YEAR,GetDate())

Select @fullDate = @monthName + ' ' + @dayDate + ', ' + @dayYear

select @fullDate

--- Test month Sort chronologically
select distinct DATENAME(MONTH,clockindate),DATEPART(M,clockindate)
from LaborDtl
Order by DATEPART(M,clockindate)

--- select cases created in the last 365 days
Select HDCaseNum,CreatedDate, DatePart(Week,CreatedDate)WeekNum
from HDCase
Where CreatedDate > DATEADD(DAY,-365,GetDate())
Order by HDCaseNum 

-- Order Weeks By Created Date
Select Distinct DATEPART(WEEK,CreatedDate)WeekNum,(DATEPART(Week,CreatedDate)+ YEAR(CreatedDate)*100)WeekOrder
from HDCase
order by WeekOrder desc

-- Quotes created before today
declare @Yest as date,
		@StartDate as date;
select @Yest =  dateadd(day,datediff(day,1,GETDATE()),0)
Select @StartDate = dateadd(day,datediff(day,15,GETDATE()),0)
select EntryDate,QuoteNum
from QuoteHed 
where EntryDate between @StartDate and @Yest
--where EntryDate > DATEADD(day,-15, Dateadd(day,0,@Yest))

-- get today
SELECT dateadd(day,datediff(day,0,GETDATE()),0)

-- get yesterday
SELECT dateadd(day,datediff(day,1,GETDATE()),0)

-- get 15 days before
SELECT dateadd(day,datediff(day,15,GETDATE()),0)

-- get 730
SELECT dateadd(DAY,datediff(day,730,GETDATE()),0)

--- get next 7 days
Select DATEADD(day,7,Getdate())


-- Don't select witn todays date
select convert(varchar(12),EntryDate,110),QuoteNum
from QuoteHed 
where convert(varchar(12),EntryDate,110) != convert(varchar(12),GETDATE(),110)


-- Get 3 work days of the Year
Declare @DayOfYear As int,
		@PreviousWD as int,
		@NextWD as int,
		@DaySPlus as int,
		@DaysSub as int,
		@DayName as varchar(10);

Select @DayName = DATEName(DW,GETDATE())
Select @DayOfYEar = DATEPART(Dy,GetDate())
--Select @PreviousWD = DATEPART(dy,dateadd(day,datediff(day,1,GETDATE()),0)) 
Select @NextWD = DATEPART(dy,DATEADD(day,1,Getdate()))

Begin
if @DayName = 'Monday'
Begin
SET @PreviousWD = DATEPART(dy,dateadd(day,datediff(day,3,GETDATE()),0))
End
Else SET @PreviousWD = DATEPART(dy,dateadd(day,datediff(day,1,GETDATE()),0))

if @DayName = 'Friday'
Begin 
	SET @NextWD = DATEPART(dy,DATEADD(day,3,Getdate()))
End
Else SET @NextWD = DATEPART(dy,DATEADD(day,1,Getdate()))
End
 
Select @DayOfYear,SchedDate,CallNum,@PreviousWD,@NextWD
from FSCallhd 
where (Year(SchedDate) = YEAR(Getdate())  and  DATEPART(DY,SchedDate) = @DayOfYear) or
(Year(SchedDate) = YEAR(Getdate()) and  DATEPART(DY,SchedDate) = @PreviousWD) or
(Year(SchedDate) = YEAR(Getdate()) and  DATEPART(DY,SchedDate) = @NextWD) 

--select DATEName(DW,GETDATE())

-- format as MM/DD/YYYY
select convert(varchar(2),(datepart(MONTH,LastDate)))+ '/' + convert(varchar(2),(datepart(DAY,LastDate)))+'/'
+ convert(varchar(4),(datepart(YEAR,LastDate)))
from CRMCall
where RelatedToFile = 'HDcase' and Key1 = '12'

-- this year
select Year(invoice_date) = YEAR(getdate())
	
-- last year
YEAR(DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) - 1, 0))

-- two years
YEAR(DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) - 2, 0))


-- leap year testing
declare @date as datetime,
		@Date2yr as date;

set  @date = GetDate()

if @date between '2024-02-29' and '2025-03-01'
 set @Date2yr = dateadd(DAY,datediff(day,731,GETDATE()),0)
else
set @Date2yr = dateadd(DAY,datediff(day,730,GETDATE()),0)

select @Date2yr[2yrs Ago]