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
WHERE   xml_document.root_element = 'GetPriceBreaks'

Select *
FROM   xml_document
where document_desc like '%orderimport%'


select *
from xml_document
where document_template like '%locationid%'

select *
from xml_document
where document_template like '%Pdf%'

Select distinct document_desc
FROM xml_document

exec sp_help xml_document

select *
from dbo.transaction_set
order by transaction_set_id


exec sp_help transaction_set

select *
from trans_set_x_xml_dataobject

Select *
FROM xml_document
order by date_last_modified desc

Select *
FROM xml_document
where major_version = 5 and minor_version = 11

select *
from xml_document
where document_template like '%B2B%'