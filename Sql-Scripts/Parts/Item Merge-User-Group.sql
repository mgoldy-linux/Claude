/*
=================================================================================
-- File: Item Merge.sql
-- Name: 
-- Desc: Mass Item Merge
-- Auth: Kyle Rehner
-- Corp: Kroll International LLC.
-- Date: 2016-03-17
=================================================================================
-- Programming Notes:
--	Use Excel to create list for next step. Using this formula:
	="('"&A1&"','"&B1&"'),"
	Provided that you have the merged Item_ID values starting in cell A1 and
	the kept Item_ID values starting in cell B1.
	Drag the formula down for all items that will be merged.
	Highlight all values in the formula column and press Ctrl+C
	and Ctrl+Alt+V and select Values to paste the values.
	DELETE THE COMMA AFTER THE LAST RECORD TO INSERT!
	Paste the values from Excel into the insert statement below.
=================================================================================
-- Change History:
--	Date		Author			Description
--	----------	--------------	-------------------------------------------------
--	2016-03-17	Kyle Rehner		Created script.
=================================================================================
*/


IF OBJECT_ID('tempdb..#merge') IS NOT NULL
    DROP TABLE #merge

create table #merge 
(
	rownumber int Identity(1,1),
	merged varchar(max),
	kept varchar(max)
)

/*
Use Excel to create list for next step. Using this formula:
="('"&A1&"','"&B1&"'),"
Provided that you have the merged Item_ID values starting in cell A1 and
the kept Item_ID values starting in cell B1.
Drag the formula down for all items that will be merged.
Highlight all values in the formula column and press Ctrl+C
and Ctrl+Alt+V and select Values to paste the values.
DELETE THE COMMA AFTER THE LAST RECORD TO INSERT!
Paste the values from Excel into the insert statement below.
*/
insert into #merge (merged,kept)
values	('merged_id1','kept_id1'),--Insert values here form Excel
('merged_id2','kept_id2')

declare		@rownumber int,
			@stop int,
			@merged varchar(max),
			@kept varchar(max)

select		@rownumber = min(rownumber),
			@stop = max(rownumber)
from		#merge

while		@rownumber < @stop
begin
	select	@merged = merged,
			@kept = kept
	from	#merge
	where	rownumber = @rownumber

	exec	p21_merge_items_app @merged, @kept
	set		@rownumber = @rownumber + 1
end