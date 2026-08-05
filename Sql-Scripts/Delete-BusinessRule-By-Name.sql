/*
Deletes a business_rule and its dependent rows, mirroring exactly what the P21 client does
via its "Rules" maintenance screen (confirmed via Extended Events trace against P21BusinessRules,
2026-08-05, deleting business_rule_uid 44 / OrderLineSalesRepAddition_LIVE).

Cascade confirmed complete via sys.foreign_keys (only 3 tables reference business_rule.business_rule_uid):
  business_rule_data_element, business_rule_x_roles, business_rule_x_users, then business_rule itself.

Run against each target DB: `USE [<db>]` first.
*/
Use [P21BusinessRules]

DECLARE @RuleName varchar(100) = 'OrderLineSalesRepAddition_LIVE';
DECLARE @Uid int;

SELECT @Uid = business_rule_uid FROM business_rule WHERE rule_name = @RuleName;

IF @Uid IS NULL
BEGIN
    PRINT 'No business_rule row found for rule_name = ''' + @RuleName + '''. Nothing to do.';
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
