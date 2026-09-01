/*  Business-Rule-Roles-Users-By-Rule.sql
    --------------------------------------------------------------------------
    Who does each ACTIVE business rule run for?  Feeds the "Roles / Users
    Affected" section (#4) of the BR one-pager docs.
    See memory: project_2026_08_24_br_documentation_sharepoint.md

    business_rule.run_for_all_flag = 'Y'  -> rule runs for EVERYONE; no role
                                            or user restriction applies.
                                            (Doc wording: "All users. Rule is
                                            configured to run for everyone
                                            -- run_for_all_flag = 'Y'.")

    run_for_all_flag <> 'Y'               -> restricted; the actual scope is in
                                            business_rule_x_roles (-> roles.role)
                                            and business_rule_x_users (users_id).

    TRAPS
    -----
    * run-for-all rules STILL keep stale business_rule_x_roles rows -- P21
      ignores them. Do not read the role rows as authoritative; the flag wins.
    * Several restricted rules list a P21 role literally named "ALL". That is
      NOT the same as run_for_all_flag='Y' -- it is a catch-all role users are
      individually assigned to. Word the docs so the two "all"s don't blur.
    * roles table PK/label cols are role_uid / role  (there is no "role_name",
      and no table literally called "role").
    * business_rule has business_rule_uid (not _id), no assembly_name.

    P21 Prod snapshot 2026-09-01:  30 distinct active rule_names run-for-all,
                                    9 distinct active rule_names restricted.
    --------------------------------------------------------------------------  */

------------------------------------------------------------------------------
-- 1. Rules that RUN FOR EVERYONE  (run_for_all_flag = 'Y', row_status 704)
------------------------------------------------------------------------------
SELECT   rule_name,
         COUNT(*)          AS binding_rows,   -- one per event/window/DataWindow
         MIN(rule_type_cd) AS rule_type_cd
FROM     business_rule
WHERE    run_for_all_flag = 'Y'
  AND    row_status_flag  = 704
GROUP BY rule_name
ORDER BY rule_name;


------------------------------------------------------------------------------
-- 2. ACTIVE rules NOT run-for-all: consolidated role + named-user list
------------------------------------------------------------------------------
;WITH act AS (
    SELECT DISTINCT rule_name
    FROM   business_rule
    WHERE  row_status_flag = 704
      AND  ISNULL(run_for_all_flag, 'N') <> 'Y'
)
SELECT  a.rule_name,
        (SELECT STUFF((SELECT ', ' + rr FROM (
             SELECT DISTINCT r.role AS rr
             FROM   business_rule br
             JOIN   business_rule_x_roles xr ON xr.business_rule_uid = br.business_rule_uid
             JOIN   roles r                  ON r.role_uid          = xr.role_uid
             WHERE  br.rule_name = a.rule_name AND br.row_status_flag = 704
           ) t ORDER BY rr FOR XML PATH('')), 1, 2, '')) AS roles,
        (SELECT STUFF((SELECT ', ' + uu FROM (
             SELECT DISTINCT xu.users_id AS uu
             FROM   business_rule br
             JOIN   business_rule_x_users xu ON xu.business_rule_uid = br.business_rule_uid
             WHERE  br.rule_name = a.rule_name AND br.row_status_flag = 704
           ) t ORDER BY uu FOR XML PATH('')), 1, 2, '')) AS named_users
FROM    act a
ORDER BY a.rule_name;

/*  Result captured 2026-09-01 (restricted rules):

    asi_fc_restore_msg_cust_id      ALL, Claims, Customer Service, Outside Sales, Sales Manager
    asi_fc_restore_msg_ship_to_id   ALL, Customer Service, Customer Service Manager, Outside Sales, Sales Manager
    asi_oe_order_sales_loc_id_up    ALL, Customer Service, Customer Service Manager, Outside Sales, Sales Manager
    asi_oe_suppress_oe_msgs         ALL, Customer Service, Customer Service Manager, Outside Sales, Sales Manager
    failsafe_correction             Accounting, Accounts Receivable Manager, ALL, System Admin, System Maintenace
    jsTextValidator                 Purchasing
    kb_Order_Validator_v2           Accounting, Accounts Payable, Accounts Receivable, Accounts Receivable Admin,
                                    Accounts Receivable Manager, ALL, Branch Manager, Claims, Customer Service,
                                    Customer Service Manager, IT Support, Management, Marketing, Outside Sales,
                                    Product Manager, Purchasing, Sales Manager, Vendor Maintenance, Warehouse,
                                    Warehouse Manager, Warehouse Office
    Reward_Commission_Cost          roles: ALL, Customer Service Manager    users: JDAUGHERTY, LGLENN
    Suppressor                      roles: (none)                          users: EDI, SHUTCHISON
*/
