select *
from p21_inventory_rebuild
where item_id = '2101004723'

select *
from p21_view_qty_in_process_rebuild

exec P21_InventoryIssuesMain @from_location_id=100,@to_location_id=100,@from_item_id='2101004723',@to_item_id='2101004723',@company_id='1',@ai_TestUID=75, @INCLUDE_DEBUG_SQL = 1

EXEC p21_rebuild_inventory_master_driver @as_ItemId_Start = '2101004723', @as_ItemID_End = '2101004723', @ai_LocationID_Start = 100, @ai_LocationID_End = 100, @as_CompanyID = '1', @ab_AllowInventoryValueChange = 1, @ab_AllowInvLocQOHUpdate = 0, @PB = 1, @rebuild_run = 1883

EXEC p21_rebuild_inv_bin_allocation '2101004723', 100