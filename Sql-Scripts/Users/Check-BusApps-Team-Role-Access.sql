-- Verify Business Apps team ROLE / ACCESS in each environment (Todo-BusApps #11, follow-up to
-- Check-BusApps-Team-Not-Deleted.sql which only checks delete_flag).
-- Run in each of: P21Play, P21BusinessRules, P21Dev, P21Training (DB_NAME() labels the output).
-- MGOLDYN is the reference: he has full access in every DB, so "missing vs MGOLDYN" = gap.
--
-- Tables/columns (all used by asi_proc_compare_p21_users.sql, so already proven in this shop):
--   users.role_uid -> roles.role ; users_x_company.user_id/company_id ;
--   users_x_application_security.users_id/application_security_uid -> application_security.display_name
-- Menu denies: role-level rows from custom_objects (type 'R'), see reference_p21_menu_security_role_compare.
-- Team: CSKELTON, EREYES, MLEARNED, MMUNSON, JVADAKKEL, TTHOUSAND (CIO) + MGOLDYN reference.

DECLARE @Team TABLE (login_id varchar(30));
INSERT @Team VALUES ('MGOLDYN'), ('CSKELTON'), ('EREYES'), ('MLEARNED'), ('MMUNSON'), ('JVADAKKEL'), ('TTHOUSAND');

-- 1) Summary per login: role, company access, app-security rows, role-level menu denies
SELECT DB_NAME() AS db, t.login_id, u.name AS user_name, u.delete_flag,
       r.role,
       (SELECT COUNT(*) FROM users_x_company c WHERE c.user_id = t.login_id)              AS companies,
       (SELECT COUNT(*) FROM users_x_application_security s WHERE s.users_id = t.login_id) AS app_security_rows,
       (SELECT COUNT(*)
          FROM custom_objects co
          JOIN custom_objects_detail cod ON cod.custom_objects_uid = co.custom_objects_uid
         WHERE co.object_type = 'M' AND co.type = 'R' AND co.role_id = u.role_uid
           AND cod.attribute_name = 'enabled' AND cod.attribute_value IN ('N', 'false'))   AS role_menu_denies
FROM @Team t
LEFT JOIN users u ON u.id = t.login_id
LEFT JOIN roles r ON r.role_uid = u.role_uid
ORDER BY (CASE WHEN t.login_id = 'MGOLDYN' THEN 0 ELSE 1 END), t.login_id;

-- 2) Company access MGOLDYN has that a team member lacks
SELECT DB_NAME() AS db, t.login_id, ref.company_id AS missing_company_id
FROM @Team t
JOIN users_x_company ref ON ref.user_id = 'MGOLDYN'
WHERE t.login_id <> 'MGOLDYN'
  AND NOT EXISTS (SELECT 1 FROM users_x_company c WHERE c.user_id = t.login_id AND c.company_id = ref.company_id)
ORDER BY t.login_id, ref.company_id;

-- 3) Application-security settings MGOLDYN has that a team member lacks
SELECT DB_NAME() AS db, t.login_id, aps.display_name AS missing_app_security
FROM @Team t
JOIN users_x_application_security ref ON ref.users_id = 'MGOLDYN'
JOIN application_security aps ON aps.application_security_uid = ref.application_security_uid
WHERE t.login_id <> 'MGOLDYN'
  AND NOT EXISTS (SELECT 1 FROM users_x_application_security s
                  WHERE s.users_id = t.login_id
                    AND s.application_security_uid = ref.application_security_uid)
ORDER BY t.login_id, aps.display_name;
