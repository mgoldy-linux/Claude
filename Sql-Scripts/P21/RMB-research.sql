SELECT users_x_application_security.users_x_app_security_uid,              users.id,              application_security.application_security_uid,             COALESCE(users_x_application_security.code_value, application_security.default_code_value),             COALESCE(users_x_application_security.decimal_value, application_security.default_decimal_value),            COALESCE(users_x_application_security.string_value, application_security.default_string_value),            users_x_application_security.date_created,              users_x_application_security.created_by,              users_x_application_security.date_last_modified,              users_x_application_security.last_maintained_by,     application_security.internal_name,     application_security.display_name,     application_security.scope_type_cd,     application_security.value_type_cd,     application_security.default_code_value,     application_security.default_decimal_value,     application_security.default_string_value,     application_security.configuration_id,    CASE WHEN value_type_cd = 3832 THEN COALESCE(users_x_application_security.code_value, application_security.default_code_value) ELSE NULL END cc_report_code_value 
FROM users          cross join application_security       left join users_x_application_security on      users_x_application_security.application_security_uid = application_security.application_security_uid     and     users_x_application_security.users_id = users.id WHERE application_security.value_type_cd = 2309 AND application_security.configuration_id IN (0, 4585) AND users.id = 'TGLIGANIC'

select *
from application_security

Select *
from users_x_application_security
where users_id = 'Mgoldyn' and application_security_uid = 1

Select *
from users_x_application_security
where users_id = 'lstallone' and application_security_uid = 1