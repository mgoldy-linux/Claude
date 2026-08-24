-- Kill Training Jobs

Use P21Train;

update company set company_name = left('** Stacy Bins **', 40)
update alert_implementation set row_status_flag = 705

update company set company_name = left('** Stacy 20240315 **', 40)
update location set location_name = left('*** Stacy 20240315 **** ' + location.location_name + ' *** New ***', 255) where location_id = 100
update branch set branch_description = left('*** Stacy 20240315 **** ' + branch_description + ' ***  DC ***', 40)

update scheduled_import_master set polling_path = '\\PTI-SQL1\CXM\INBOUND\TEST' where scheduled_import_master_uid = 17

update scheduled_import_master 
set polling_path = replace(polling_path, '\TPCX\', '\TPCXT\')
, transaction_log_path = replace(transaction_log_path, '\TPCX\', '\TPCXT\')
, transaction_sum_path = replace(transaction_sum_path, '\TPCX\', '\TPCXT\')
, transaction_sus_path = replace(transaction_sus_path, '\TPCX\', '\TPCXT\')
, transaction_err_path = replace(transaction_err_path, '\TPCX\', '\TPCXT\')
where polling_path like '%\TPCX\%'

update company set edi_export_path = '\\PTI-EDI\P21Mappertest\P21ExportDirectory' where company_id = 1

update system_setting set value = '\\pti-sql21\P21Shares\APIShare_Train\Reports_Train' where system_setting_uid =111
update system_setting set value = '\\pti-sql21\P21Shares\APIShare_Train\P21Forms_Train' where system_setting_uid =166
update system_setting set value = '\\pti-sql21\P21Shares\APIShare_Train\MSGLog_Train' where system_setting_uid =138
update system_setting set value = '\\PTI-EDI\P21MapperTest\P21FFSchemas' where system_setting_uid = 1064
update system_setting set value = '\\PTI-EDI\P21MapperTest\P21ExportDirectory' where system_setting_uid = 1076

-- prevent printing extra pick tickets
update dbo.scheduled_job set active_flag = 'N'