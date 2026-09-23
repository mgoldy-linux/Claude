-- P21 blocked deleting salesrep 1045 (Anthony Basic / TBASIC) in Salesrep Maintenance:
-- "This salesrep is set up as the primary salesrep of one or more ship-to records."
-- customer.salesrep_id was already found/reassigned (6 live customers) -- this is the
-- second, separate assignment layer P21 checks before allowing a delete.
--
-- Confirmed schema: ship_to_salesrep (company_id, ship_to_id, salesrep_id,
-- primary_salesrep, delete_flag) links to ship_to via (company_id, ship_to_id).
-- ship_to has no name column -- pulling customer_name via customer_id for context.
-- ship_to_salesrep_location (a separate, location-scoped table) also exists --
-- checked in query 3 in case P21's block is actually keyed off that one instead.

-- 1) Ship-to salesrep assignments currently pointing at 1045.
SELECT
    sts.company_id, sts.ship_to_id,
    st.customer_id, c.customer_name,
    sts.salesrep_id, sts.primary_salesrep, sts.delete_flag AS assignment_delete_flag,
    st.delete_flag AS ship_to_delete_flag
FROM ship_to_salesrep sts
JOIN ship_to st ON st.company_id = sts.company_id AND st.ship_to_id = sts.ship_to_id
JOIN customer c ON c.customer_id = st.customer_id
WHERE sts.salesrep_id = 1061--1045
ORDER BY sts.delete_flag, st.delete_flag, c.customer_name;

-- 2) Split by delete_flag on both the assignment row and the ship_to itself --
--    same "is this actually live" question as the customer check.
SELECT
    sts.delete_flag AS assignment_delete_flag,
    st.delete_flag AS ship_to_delete_flag,
    COUNT(*) AS ship_tos_assigned_to_1045
FROM ship_to_salesrep sts
JOIN ship_to st ON st.company_id = sts.company_id AND st.ship_to_id = sts.ship_to_id
WHERE sts.salesrep_id = 1045
GROUP BY sts.delete_flag, st.delete_flag;

-- 3) Same check against the location-scoped variant, in case P21's delete-block
--    validation is actually reading this table instead of/in addition to ship_to_salesrep.
