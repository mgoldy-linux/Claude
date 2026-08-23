 select a.name[IDC_Name],c.customer_id--,cet.edi_transaction
        from customer c	
        join address a
        on c.customer_id = a.id
        --join customer_edi_transaction cet
        --on c.customer_id = cet.customer_id 
        where c.customer_id = 35988

select max(customer_edi_transaction_uid)
from customer_edi_transaction
--where customer_id = 35780
where customer_id = 35988

INSERT INTO customer_edi_transaction ( "customer_edi_transaction_uid", "company_id", "customer_id", "edi_transaction", "row_status_flag", "date_created", "date_last_modified", "last_maintained_by" )
VALUES ( 5632, '1', 35988, 942, 2709, '2021-03-16 15:35:02.963', '2021-03-16 15:35:02.963', 'MGOLDYN' )

INSERT INTO "customer_edi_transaction" ( "customer_edi_transaction_uid", "company_id", "customer_id", "edi_transaction", "row_status_flag", "date_created", "date_last_modified", "last_maintained_by" ) VALUES ( 5460, '1', 35988, 945, 2709, '2021-03-16 15:41:16.896', '2021-03-16 15:41:16.896', 'MGOLDYN' ).

select max(customer_edi_trans_detail_uid)[DMax]
from customer_edi_trans_detail

select *
from customer_edi_trans_detail
where customer_edi_transaction_uid = 5440

insert into customer_edi_trans_detail (customer_edi_trans_detail_uid,customer_edi_transaction_uid,name,value,data_type_cd,data_type_length,data_type_scale,date_created,date_last_modified)
            values($detuv,$cetuv,'transaction_map_name','7','851','255','0',GETDATE(),GETDATE()),
            ($d2,$cetuv,'override_trading_partner_flag','N','851','255','0',GETDATE(),GETDATE()),
            ($d3,$cetuv,'edi_interchange_id_qualifier','','851','255','0',GETDATE(),GETDATE()),
            ($d4,$cetuv,'edi_interchange_id','','851','255','0',GETDATE(),GETDATE()),
            ($d5,$cetuv,'application_code','','851','255','0',GETDATE(),GETDATE()),
            ($d6,$cetuv,'override_your_edi_id_flag','N','851','255','0',GETDATE(),GETDATE()),
            ($d7,$cetuv,'your_edi_interchange_id_qual','','851','255','0',GETDATE(),GETDATE()),
            ($d8,$cetuv,'your_edi_interchange_id','','851','255','0',GETDATE(),GETDATE()),
            ($d9,$cetuv,'your_application_code','','851','255','0',GETDATE(),GETDATE());

INSERT INTO customer_edi_transaction ( "customer_edi_transaction_uid", "company_id", "customer_id", "edi_transaction", "row_status_flag", "date_created", "date_last_modified", "last_maintained_by" )
VALUES ( 5633, '1', 35988, 945, 2709, '2021-03-16 15:56:25.307', '2021-03-16 15:56:25.307', 'MGOLDYN' )

INSERT INTO "customer_edi_trans_detail" ( "customer_edi_trans_detail_uid", "customer_edi_transaction_uid", "name", "value", "data_type_cd", "data_type_length", "data_type_scale", "date_created", "date_last_modified", "last_maintained_by" ) 
VALUES ( 27093, 5633, 'transaction_map_name', '6', 851, 255, 0, '2021-03-16 15:59:57.483', '2021-03-16 15:59:57.483', 'MGOLDYN')