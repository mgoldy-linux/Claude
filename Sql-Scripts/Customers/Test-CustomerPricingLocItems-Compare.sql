-- Test-CustomerPricingLocItems-Compare.sql
-- Compares asi_proc_customer_pricing_loc_items vs kb_proc_customer_pricing_loc_items
-- Customer: 1212756 | Location: 106 | Item: MAP50501
-- Run against: P21BusinessRules

DECLARE @comp_id        VARCHAR(8)      = '1'
DECLARE @cust_id        DECIMAL(19,0)   = 1212756
DECLARE @loc            DECIMAL(19,0)   = 106
DECLARE @one_off_only   VARCHAR(1)      = 'N'
DECLARE @grp_by_class   VARCHAR(1)      = 'N'

-- ============================================================
-- asi_ version
-- ============================================================
PRINT '--- asi_proc_customer_pricing_loc_items ---'

DECLARE @items_asi AS dbo.asi_TableTypeItemDec
INSERT INTO @items_asi (item_id) VALUES ('MAP50501')

EXEC dbo.asi_proc_customer_pricing_loc_items
    @comp_id         = @comp_id,
    @cust_id         = @cust_id,
    @loc             = @loc,
    @items           = @items_asi,
    @one_off_only    = @one_off_only,
    @group_by_mfg_class = @grp_by_class

-- ============================================================
-- kb_ version
-- ============================================================
PRINT '--- kb_proc_customer_pricing_loc_items ---'

DECLARE @items_kb AS dbo.kb_TableTypeItemDec
INSERT INTO @items_kb (item_id) VALUES ('MAP50501')

EXEC dbo.kb_proc_customer_pricing_loc_items
    @comp_id         = @comp_id,
    @cust_id         = @cust_id,
    @loc             = @loc,
    @items           = @items_kb,
    @one_off_only    = @one_off_only,
    @group_by_mfg_class = @grp_by_class
