
/* -- not working
Msg 102, Level 15, State 1, Line 87
Incorrect syntax near '?'.
Msg 102, Level 15, State 1, Line 108
Incorrect syntax near '?'.
Msg 102, Level 15, State 1, Line 124
Incorrect syntax near '?'.
Msg 102, Level 15, State 1, Line 140
Incorrect syntax near '?'.
*/
SELECT B.*,ISNULL(P.budget_1,0)   budget_1
FROM
(SELECT 
	A.Account
	,A.account_number
	,A.account_desc
	,A.Group1
	,A.Group1Sort
	,A.Group2
	,SUM(A.amount) amount
	,A.branch_id
	,A.company_no
	,A.Mth
	,A.Year
FROM
(select LEFT(account_number,2) Account,account_number,
CASE 
	when LEFT(account_number,2) IN(41) THEN 'Product Sales'
	when LEFT(account_number,2) IN(42) THEN 'Less: Returns'
    WHEN LEFT(account_number,2) between 43 and 45 THEN 'Miscellaneous Sales & Allowances'
	when LEFT(account_number,5) = 50010 THEN 'Direct Product COGS'
	when LEFT(account_number, 5) between 50011 and 57020 then 'Miscellaneous COGS'
	when LEFT(account_number,5) = 60010 then 'Commissions'
	when LEFT(account_number,5) IN(60020,60030) then 'Advertising, Marketing, Tradeshows'
	when LEFT(account_number,5) between 61010 and 61899 then 'Salaries, Wages & Benefits'
	when LEFT(account_number,5) between 62010 and 62020 then 'Rents'
	when LEFT(account_number,5) between 62510 and 62530 then 'Insurance'
	when LEFT(account_number,5) between 62110 and 62130 then 'Utilities'
	when LEFT(account_number,5) = 62210 THEN 'Repairs & Maintenance'
	when LEFT(account_number,5) = 63010 THEN 'Bank Fees'
	when LEFT(account_number,5) between 63100 and 63120 then 'Professional Fees'
	when LEFT(account_number,5) between 64010 and 64010 then 'Supplies'
	when LEFT(account_number,5) between 65010 and 65050 then 'Travel'
	when LEFT(account_number,5) between 60000 and 68999 then 'Other Operating Expenses'
	when LEFT(account_number,5) between 69010 and 69999 then 'EBITDA ADJUSTMENTS'
	when LEFT(account_number,5) between 70000 and 79999 then 'Depreciation & Amortization'
	when LEFT(account_number,5) = 80010 then 'Interest Expense' 
	when LEFT(account_number,5) = 80020 then 'Interest Exp.-SWAP FMV' 
	when LEFT(account_number,5) between 80030 and 80050 then 'Other Income (Expense)'
	when LEFT(account_number,5) = 80100 then 'Acquisition Transaction Costs'
	when LEFT(account_number,5) between 90001 and 90010 then 'Provisions for Income Taxes'
ELSE 'Other Operating Expenses' END Group1,
CASE 
	when LEFT(account_number,2) IN(41) THEN 1
	when LEFT(account_number,2) IN(42) THEN 2
    WHEN LEFT(account_number,2) between 43 and 45 THEN 3
	when LEFT(account_number,5) = 50010 THEN 4
	when LEFT(account_number, 5) between 50011 and 57020 then 5
	when LEFT(account_number,5) = 60010 then 6
	when LEFT(account_number,5) IN(60020,60030) then 7
	when LEFT(account_number,5) between 61010 and 61899 then 8 
	when LEFT(account_number,5) between 62010 and 62020 then 9
	when LEFT(account_number,5) between 62510 and 62530 then 10
	when LEFT(account_number,5) between 62110 and 62130 then 11
	when LEFT(account_number,5) = 62210 THEN 11.1
	when LEFT(account_number,5) = 63010 THEN 11.2
	when LEFT(account_number,5) between 63100 and 63120 then 12
	when LEFT(account_number,5) between 64010 and 64010 then 13
	when LEFT(account_number,5) between 65010 and 65050 then 14
	when LEFT(account_number,5) between 60000 and 68999 then 15
	when LEFT(account_number,5) between 69010 and 69999 then 16
	when LEFT(account_number,5) between 70000 and 79999 then 17
	when LEFT(account_number,5) = 80010 then 18 
	when LEFT(account_number,5) = 80020 then 19
	when LEFT(account_number,5) between 80030 and 80050 then 20
	when LEFT(account_number,5) = 80100 then 21
	when LEFT(account_number,5) between 90001 and 90010 then 22
ELSE 23 END Group1Sort,
CASE 
	when LEFT(account_number,1) = 4 THEN 'SALES'
	when LEFT(account_number,1) = 5 THEN 'COST OF GOODS SOLD'
	when LEFT(account_number,5) between 60010 and 68999 then 'Sales, General & Admin. Expenses'
	when LEFT(account_number,5) between 90001 and 90010 then 'Provisions for Income Taxes'
	--when LEFT(account_number,5) between 69010 and 69999 then 'Reported EBITDA' 
	--when LEFT(account_number,5) between 70000 and 80100 then 'EBT (Earnings Before Income Tax)'
 
ELSE '' END Group2,
	

account_desc,g.amount,a.branch_id,a.company_no
,Month(transaction_date) Mth, Year(transaction_date) Year
FROM gl g Inner join chart_of_accts a 
ON g.account_number = a.account_no and g.company_no = a.company_no

where account_type IN('R','X') 
and a.company_no = 1
and ((transaction_date >= '7/1/' + CONVERT(varchar(4),CASE WHEN Month({?StartDate}) between 1 and 6 THEN Year({?StartDate})-1 else Year({?StartDate}) END) 
and transaction_date <= {?zEndDate})
OR (transaction_date >= DateAdd(YYYY,-1, '7/1/' + CONVERT(varchar(4),CASE WHEN Month({?StartDate}) between 1 and 6 THEN Year({?StartDate})-1 else Year({?StartDate}) END)) 
and transaction_date <= DateAdd(YYYY,-1,{?zEndDate}))
OR (transaction_date >= DateAdd(YYYY,-1,{?StartDate}) and transaction_date <= {?zEndDate})

)

UNION ALL

SELECT

90 as Account
,'90010000100' account_number
,'Provisions for Income Taxes' Group1
,22 Group1Sort
,'Provisions for Income Taxes' Group2
,'Provisions for Income Taxes' account_desc
,0 amount
,'100' branch_id
,1 company_no
,Month({?StartDate}) Mth
,Year({?StartDate}) Year

UNION ALL

SELECT

90 as Account
,'90010000100' account_number
,'Provisions for Income Taxes' Group1
,22 Group1Sort
,'Provisions for Income Taxes' Group2
,'Provisions for Income Taxes' account_desc
,0 amount
,'200' branch_id
,1 company_no
,Month({?StartDate}) Mth
,Year({?StartDate}) Year

UNION ALL

SELECT

90 as Account
,'90010000100' account_number
,'Provisions for Income Taxes' Group1
,22 Group1Sort
,'Provisions for Income Taxes' Group2
,'Provisions for Income Taxes' account_desc
,0 amount
,'300' branch_id
,1 company_no
,Month({?StartDate}) Mth
,Year({?StartDate}) Year
--ORDER BY account_number

)A

GROUP BY A.Account
	,A.account_number
	,A.account_desc
	,A.Group1
	,A.Group1Sort
	,A.Group2	
	,A.branch_id
	,A.company_no
	,A.Mth
	,A.Year
) B  LEFT OUTER JOIN balances P 
ON B.account_number = P.account_no and B.company_no = P.company_no
and B.Mth = CASE 
				
				WHEN p.period = 7 THEN 1
				WHEN P.period = 8 THEN 2
				WHEN p.period = 9 THEN 3
				WHEN p.period = 10 THEN 4
				WHEN p.period = 11 THEN 5
				WHEN p.period = 12 THEN 6
				WHEN p.period = 1 THEN 7
			    WHEN p.period = 2 THEN 8
				WHEN p.period = 3 THEN 9
				WHEN p.period = 4 THEN 10
				WHEN p.period = 5 THEN 11
				WHEN p.period = 6 THEN 12
			ELSE 0 END
and B.Year = CASE WHEN p.period between 1 and 6 THEN P.year_for_period -1 else P.year_for_period  end

