/* =============================================================================
   SA 56290 - Which roles / users are assigned the Open Quotes portals?
   Matt's question (10/8/2026): "which roles have access to these Portals?"
   Instance : Prod (P21.allsurfaces.com) - read only, SELECTs only.
   Chain    : portal_element (the quote tab) -> portal_x_portal_element -> portal
              -> portal_assignment (role_uid = by role, user_id = direct)
   Elements : 3 Open quotes | 7 Open service quotes (standard P21)
              147 CRM MY OPEN QUOTES | 188 MY OPEN QUOTES | 212 BR SAL OPEN QUOTE
              229 OPEN QUOTES SEARCH (custom, datawindow = portal_user_defined)
   NOTE     : portal_element_uid is NOT aligned across instances - re-resolve by
              name if this is run on Play.
   ============================================================================= */
USE P21;
SET NOCOUNT ON;

/* ---- Q1: Role-level assignments, with active-user head count --------------- */
SELECT  pe.portal_element_name                       AS quote_element,
        p.portal_name,
        r.role,
        COUNT(DISTINCT u.id)                         AS active_users_in_role
FROM    portal_element pe
JOIN    portal_x_portal_element pxe ON pxe.portal_element_uid = pe.portal_element_uid
JOIN    portal p                    ON p.portal_uid = pxe.portal_uid AND p.row_status_flag = 704
JOIN    portal_assignment pa        ON pa.portal_uid = p.portal_uid
                                   AND pa.row_status_flag = 704
                                   AND pa.role_uid IS NOT NULL
JOIN    roles r                     ON r.role_uid = pa.role_uid AND r.delete_flag = 'N'
LEFT JOIN users u                   ON u.role_uid = r.role_uid AND u.delete_flag = 'N'
WHERE   pe.portal_element_uid IN (3, 7, 147, 188, 212, 229)
  AND   pe.row_status_flag = 704
GROUP BY pe.portal_element_name, p.portal_name, r.role
ORDER BY pe.portal_element_name, p.portal_name, r.role;

/* ---- Q2: Direct (per-user) assignments of the same portals ----------------- */
SELECT  pe.portal_element_name                       AS quote_element,
        p.portal_name,
        u.id                                         AS user_id,
        u.name,
        r.role                                       AS users_role
FROM    portal_element pe
JOIN    portal_x_portal_element pxe ON pxe.portal_element_uid = pe.portal_element_uid
JOIN    portal p                    ON p.portal_uid = pxe.portal_uid AND p.row_status_flag = 704
JOIN    portal_assignment pa        ON pa.portal_uid = p.portal_uid
                                   AND pa.row_status_flag = 704
                                   AND pa.role_uid IS NULL
JOIN    users u                     ON u.id = pa.user_id AND u.delete_flag = 'N'
LEFT JOIN roles r                   ON r.role_uid = u.role_uid
WHERE   pe.portal_element_uid IN (3, 7, 147, 188, 212, 229)
  AND   pe.row_status_flag = 704
ORDER BY pe.portal_element_name, p.portal_name, u.id;
