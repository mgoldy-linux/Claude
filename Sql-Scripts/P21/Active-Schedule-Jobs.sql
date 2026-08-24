select sim.scheduled_import_master_uid,iscr.impexp_source_desc,ts.transaction_set_id,sim.transaction_sum_path,sim.transaction_sus_path,sim.transaction_err_path,sim.transaction_log_path,sim.active
from dbo.scheduled_import_master sim
join dbo.impexp_source iscr
on sim.impexp_source_uid  = iscr.impexp_source_uid
join transaction_set ts
on sim.transaction_set_uid = ts.transaction_set_uid
where active = 'Y'

/*
--Setup Form View Tab on Scheduled Import Setup: *
SELECT
   scheduled_import_master.scheduled_import_master_uid,
   scheduled_import_master.impexp_source_uid,
   scheduled_import_master.transaction_set_uid,
   scheduled_import_master.polling_path,
   scheduled_import_master.transaction_sum_path,
   scheduled_import_master.transaction_sus_path,
   scheduled_import_master.transaction_err_path,
   scheduled_import_master.transaction_log_path,
   scheduled_import_master.active,
   scheduled_import_master.date_created,
   scheduled_import_master.date_last_modified,
   scheduled_import_master.last_maintained_by,
   scheduled_import_master.file_format_cd,
   scheduled_import_master.xml_document_uid,
   xml_document.document_desc,
   'N' enable_xml
FROM
   scheduled_import_master
   LEFT OUTER JOIN xml_document on (
      xml_document.xml_document_uid = scheduled_import_master.xml_document_uid
   )

   select *
   from scheduled_import_def
   where transaction_set_uid = 1 and impexp_source_uid  = 9

   select *
   from impexp_source

   select *
   from transaction_set
   */