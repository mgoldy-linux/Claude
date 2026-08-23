select Buyer, buyer_name, RequiredDate, PONumber,LineNumber, *
from vwPO
where qty_open > 0 and LineComplete = 'N'  and Buyer = 8978

select *
from inv_xref
where their_item_id = '35309533'
order by date_created desc

select item_id, item_desc, extended_desc
from inv_mast
where inv_mast_uid = 64228

select trading_partner_name
from customer_edi_setting
where customer_id = 13155

select company_id,customer_id,trading_partner_name,
                        ,,element_separator,
                        segment_terminator,functional_ack_flag,validate_x12_document_flag,testing_mode_flag
                        from customer_edi_setting
                        where customer_id = 13155

update customer_edi_setting
set trading_partner_name = '866572025', edi_interchange_id_qualifier = '12',edi_interchange_id = '866572025',application_code = '866572025', element_separator = '*'
where customer_id =

select *
from customer_edi_setting
where trading_partner_name = '027197458M'

select *
from inv_xref
where their_item_id = '35397850'