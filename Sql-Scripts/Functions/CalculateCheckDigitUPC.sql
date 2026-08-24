/*
		Number each digit in the UPC from left to right, up to but not including the check digit.
		Multiply each odd-numbered digit by three and add them together.
		Add the total of #2 to the sum of the even-numbered digits.
		Divide the total of #3 by 10 and subtract the remainder to get the check digit. If the remainder was 0, subtracting from 10 gives you 10, so 0 is the check digit.
		Reference: https://www.red-gate.com/simple-talk/sql/t-sql-programming/calculating-and-verifying-check-digits-in-t-sql/
*/
-- check if function exist, if true drop function
if object_id('CalculateCheckDigitUPC') is not NULL
   DROP FUNCTION CalculateCheckDigitUPC
go

-- create function
CREATE FUNCTION dbo.CalculateCheckDigitUPC
(
    @StringToCheck VARCHAR(8000)
)
RETURNS TABLE WITH SCHEMABINDING
RETURN
-- Calculate the check digit for a UPC
WITH Tally (n) AS
(
    SELECT TOP (LEN(@StringToCheck))
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
    -- 8,000 row tally table
    FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0)) a(n)
    CROSS JOIN (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) b(n)
    CROSS JOIN (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) c(n)
    CROSS JOIN (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) d(n)
)
SELECT CheckDigit = (10 -
        SUM(CASE n%2 
            WHEN 1 THEN 3 
            ELSE 1 END * SUBSTRING(@StringToCheck, n, 1))
        % 10
        ) % 10 -- When check digit is 10 (remainder=0) use 0 as the check digit
FROM Tally;
 