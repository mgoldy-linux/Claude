SELECT xml_document.xml_document_uid,
       xml_document.document_version,
       xml_document.document_schema,
       xml_document.schema_source_cd,
       xml_document.template_filename,
       xml_document.transaction_set_uid,
       xml_document.document_desc,
       xml_document.default_document,
       xml_document.document_template,
       xml_document.row_status_flag,
       xml_document.date_created,
       xml_document.date_last_modified,
       xml_document.last_maintained_by,
       xml_document.root_element,
       xml_document.document_section_prefix,
       xml_document.major_version,
       xml_document.minor_version,
       xml_document.build_no
FROM   xml_document
where document_schema = 'GetPDFDocument'

select document_template from xml_document where document_schema = 'GetPDFDocument'

select * from system_setting where name = 'p21_api_enabled_key'


