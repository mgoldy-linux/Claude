-- Active salesreps (primary rep on at least one order) whose linked P21 login
-- has been marked deleted. Continuation of the alert_queued_mail 1060/1063 thread
-- (2026-09-16) -- same "active salesrep" population definition used there.
--
-- CAVEAT: users.delete_flag is known NOT representative on P21Play (refresh flags
-- most accounts as deleted regardless of real Prod status). That specific claim
-- hasn't been verified for P21BusinessRules -- it's a separate, less-frequently-
-- refreshed test env -- so treat this run as a candidate list too and cross-check
-- anything it returns against Prod before acting on it.
use [P21BusinessRules]

;WITH active_salesreps AS (
    SELECT DISTINCT ohs.salesrep_id
    FROM oe_hdr_salesrep ohs
    WHERE ohs.primary_salesrep = 'Y'
)
SELECT
    c.id                              AS contact_id,
    c.first_name + ' ' + c.last_name  AS salesrep_name,
    c.email_address,
    u.id                              AS user_login_id,
    u.name                            AS user_name,
    u.active                          AS user_active,
    u.delete_flag                     AS user_delete_flag,
    CASE WHEN u.name LIKE '%** LEFT%' THEN 'MARKED DEPARTED' ELSE NULL END AS departed_marker,
    order_counts.orders_as_primary_rep_all_time
FROM active_salesreps a
JOIN contacts c ON c.id = a.salesrep_id
JOIN users u ON u.contact_id = c.id
CROSS APPLY (
    SELECT COUNT(*) AS orders_as_primary_rep_all_time
    FROM oe_hdr_salesrep ohs2
    WHERE ohs2.salesrep_id = a.salesrep_id
      AND ohs2.primary_salesrep = 'Y'
) order_counts
WHERE u.delete_flag = 'Y'
ORDER BY order_counts.orders_as_primary_rep_all_time DESC;
