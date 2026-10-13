-- Branch Manager (role) menu access under Inventory Management (m_inv_frame)
-- Context: SA 56970 - Access to Convert Non-Stock to Stock. Run in P21Play (role baseline) AND Prod (may have drifted).
-- Menu security is deny-based: a node is accessible unless the ROLE has an enabled=N/false row in custom_objects/_detail
-- (object_type='M', type='R'; object_name = 'm_inv_frame/<class_name>') for the node OR ANY PARENT MENU.
-- A disabled parent (e.g. m_inv_frame/m_maintenance) hides every child, even children with no row of their own.
-- Role-level only; user (U) overrides ignored. Reads source tables, not the slow users x frame_menu view.

DECLARE @role varchar(100) = 'Branch Manager';
DECLARE @start int = (SELECT frame_menu_uid FROM frame_menu WHERE class_name = 'm_inv_frame' AND ISNULL(parent_class_name,'') = '');
DECLARE @end   int = ISNULL((SELECT MIN(frame_menu_uid) FROM frame_menu
                             WHERE frame_menu_uid > @start AND ISNULL(parent_class_name,'') = '' AND class_name LIKE 'm[_]%[_]frame'), 2147483647);

IF OBJECT_ID('tempdb..#disabled') IS NOT NULL DROP TABLE #disabled;
SELECT DISTINCT cod.object_name INTO #disabled
FROM custom_objects co
JOIN custom_objects_detail cod ON cod.custom_objects_uid = co.custom_objects_uid
JOIN roles r ON r.role_uid = co.role_id
WHERE co.object_type = 'M' AND co.type = 'R'
  AND cod.attribute_name = 'enabled' AND cod.attribute_value IN ('N','false')
  AND r.role = @role;

;WITH nodes AS (   -- every Inventory node; parent chain resolved within the Inventory range only
    SELECT frame_menu_uid, class_name, parent_class_name, text_label
    FROM frame_menu WHERE frame_menu_uid > @start AND frame_menu_uid < @end
), chain AS (      -- walk each node up to (not including) m_inv_frame; blocked_by = first disabled node on the way
    SELECT n.frame_menu_uid, n.class_name AS node_class, n.parent_class_name AS up, 0 AS lvl,
           CASE WHEN EXISTS (SELECT 1 FROM #disabled d WHERE d.object_name = 'm_inv_frame/' + n.class_name) THEN n.class_name END AS blocked_by
    FROM nodes n
    UNION ALL
    SELECT c.frame_menu_uid, c.node_class, p.parent_class_name, c.lvl + 1,
           COALESCE(c.blocked_by, CASE WHEN EXISTS (SELECT 1 FROM #disabled d WHERE d.object_name = 'm_inv_frame/' + p.class_name) THEN p.class_name END)
    FROM chain c
    JOIN nodes p ON p.class_name = c.up AND c.up <> 'm_inv_frame' AND c.lvl < 6
), resolved AS (
    SELECT frame_menu_uid, MAX(blocked_by) AS blocked_by FROM chain GROUP BY frame_menu_uid
)
SELECT @role AS role,
       CASE WHEN r.blocked_by IS NULL THEN 'Y' ELSE 'N' END AS access,
       ISNULL(p.text_label, n.parent_class_name) AS section,
       n.text_label, n.class_name,
       r.blocked_by AS disabled_at   -- which node (itself or a parent menu) turns it off
FROM nodes n
JOIN resolved r ON r.frame_menu_uid = n.frame_menu_uid
LEFT JOIN nodes p ON p.class_name = n.parent_class_name AND p.parent_class_name = 'm_inv_frame'
WHERE n.class_name NOT IN ('m_maintenance','m_transactions','m_inquiry','m_reports','m_system')
ORDER BY access DESC, section, n.text_label;

-- SA 56970 answer: does the role effectively have Convert Non-Stock to Stock?
SELECT @role AS role,
       CASE WHEN EXISTS (SELECT 1 FROM #disabled WHERE object_name IN ('m_inv_frame/m_convertnon-stocktostockmaintenance','m_inv_frame/m_maintenance'))
            THEN 'N - disabled (item or its Maintenance parent)' ELSE 'Y - has access' END AS convert_nonstock_to_stock;
