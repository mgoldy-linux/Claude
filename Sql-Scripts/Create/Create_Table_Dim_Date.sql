CREATE TABLE dbo._Dim_Date
(	Calendar_Date DATE NOT NULL CONSTRAINT PK_Dim_Date PRIMARY KEY CLUSTERED, -- The date addressed in this row.
	Calendar_Date_String VARCHAR(10) NOT NULL, -- The VARCHAR formatted date, such as 07/03/2017
	Calendar_Month TINYINT NOT NULL, -- Number from 1-12
	Calendar_Day TINYINT NOT NULL, -- Number from 1 through 31
	Calendar_Year SMALLINT NOT NULL, -- Current year, eg: 2017, 2025, 1984.
	Calendar_Quarter TINYINT NOT NULL, -- 1-4, indicates quarter within the current year.
	Day_Name VARCHAR(9) NOT NULL, -- Name of the day of the week, Sunday...Saturday
	Day_of_Week TINYINT NOT NULL, -- Number from 1-7 (1 = Sunday)
	Day_of_Week_in_Month TINYINT NOT NULL, -- Number from 1-5, indicates for example that it's the Nth saturday of the month.
	Day_of_Week_in_Year TINYINT NOT NULL, -- Number from 1-53, indicates for example that it's the Nth saturday of the year.
	Day_of_Week_in_Quarter TINYINT NOT NULL, -- Number from 1-13, indicates for example that it's the Nth saturday of the quarter.
	Day_of_Quarter TINYINT NOT NULL, -- Number from 1-92, indicates the day # in the quarter.
	Day_of_Year SMALLINT NOT NULL, -- Number from 1-366
	Week_of_Month TINYINT NOT NULL, -- Number from 1-6, indicates the number of week within the current month.
	Week_of_Quarter TINYINT NOT NULL, -- Number from 1-14, indicates the number of week within the current quarter.
	Week_of_Year TINYINT NOT NULL, -- Number from 1-53, indicates the number of week within the current year.
	Month_Name VARCHAR(9) NOT NULL, -- January-December
	First_Date_of_Week DATE NOT NULL, -- Date of the first day of this week.
	Last_Date_of_Week DATE NOT NULL, -- Date of the last day of this week.
	First_Date_of_Month DATE NOT NULL, -- Date of the first day of this month.
	Last_Date_of_Month DATE NOT NULL, -- Date of the last day of this month.
	First_Date_of_Quarter DATE NOT NULL, -- Date of the first day of this quarter.
	Last_Date_of_Quarter DATE NOT NULL, -- Date of the last day of this quarter.
	First_Date_of_Year DATE NOT NULL, -- Date of the first day of this year.
	Last_Date_of_Year DATE NOT NULL, -- Date of the last day of this year.
	Is_Holiday BIT NOT NULL, -- 1 if a holiday
	Is_Holiday_Season BIT NOT NULL, -- 1 if part of a holiday season
	Holiday_Name VARCHAR(50) NULL, -- Name of holiday, if Is_Holiday = 1
	Holiday_Season_Name VARCHAR(50) NULL, -- Name of holiday season, if Is_Holiday_Season = 1
	Is_Weekday BIT NOT NULL, -- 1 if Monday-->Friday, 0 for Saturday/Sunday
	Is_Business_Day BIT NOT NULL, -- 1 if a workday, otherwise 0.
	Previous_Business_Day DATE NULL, -- Previous date that is a work day
	Next_Business_Day DATE NULL, -- Next date that is a work day
	Is_Leap_Year BIT NOT NULL, -- 1 if current year is a leap year.
	Days_in_Month TINYINT NOT NULL -- Number of days in the current month.
);
 