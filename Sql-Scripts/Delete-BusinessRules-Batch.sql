/*
Deletes a batch of confirmed-dead business_rule rows and their dependents, matching what was
manually deleted (and traced) against P21BusinessRules on 2026-08-05. Uses business_rule_uid
directly rather than rule_name, since several of these rules share duplicate names
(e.g. two rows both named 'kb_Order_SaleDay_202005') - uid is unambiguous and confirmed
consistent across environments (verified via P21Dev).

Cascade confirmed complete via sys.foreign_keys (only 3 tables reference business_rule.business_rule_uid):
  business_rule_data_element, business_rule_x_roles, business_rule_x_users, then business_rule itself.

Run against each target DB: `USE [<db>]` first.
*/
DECLARE @Uids TABLE (business_rule_uid int);
INSERT INTO @Uids VALUES
    (44),   -- OrderLineSalesRepAddition_LIVE
    (109),(110),                 -- kb_Order_SaleDay_202005
    (113),(114),                 -- kb_Order_Sale_202006
    (116),(117),                 -- kb_Order_SaleDay_202009_InsApp
    (122),(123),(129),(130),     -- kb_Order_SaleDay_202105
    (124),                       -- kb_Order_SaleDay_202105_JobName
    (131),(132),                 -- kb_Order_SaleDay_202305
    (146);                       -- kb_Order_SaleDay_202405

DECLARE @Uid int, @RuleName varchar(100);
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT business_rule_uid FROM @Uids;
OPEN cur;
FETCH NEXT FROM cur INTO @Uid;

WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @RuleName = rule_name FROM business_rule WHERE business_rule_uid = @Uid;

    IF @RuleName IS NULL
    BEGIN
        PRINT 'business_rule_uid ' + CAST(@Uid AS varchar(10)) + ' not found. Skipping.';
    END
    ELSE
    BEGIN
        PRINT 'Deleting business_rule_uid ' + CAST(@Uid AS varchar(10)) + ' (' + @RuleName + ')';

        DELETE FROM business_rule_data_element WHERE business_rule_uid = @Uid;
        PRINT '  business_rule_data_element rows deleted: ' + CAST(@@ROWCOUNT AS varchar(10));

        DELETE FROM business_rule_x_roles WHERE business_rule_uid = @Uid;
        PRINT '  business_rule_x_roles rows deleted: ' + CAST(@@ROWCOUNT AS varchar(10));

        DELETE FROM business_rule_x_users WHERE business_rule_uid = @Uid;
        PRINT '  business_rule_x_users rows deleted: ' + CAST(@@ROWCOUNT AS varchar(10));

        DELETE FROM business_rule WHERE business_rule_uid = @Uid;
        PRINT '  business_rule rows deleted: ' + CAST(@@ROWCOUNT AS varchar(10));
    END

    FETCH NEXT FROM cur INTO @Uid;
END

CLOSE cur;
DEALLOCATE cur;
