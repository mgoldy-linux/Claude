--- Configuration = in (4585) 
 --++ ARCHIVE = FALSE
 -- Author: mgoldyn
 -- Purpose: Inserts or Updates dwobject and dwobject_syntax data for Custom Datastream 
 -- Date Created:  9/14/2020 13:42
 -- Warnings: This is SQL Server specific. 
 --           **YOU MUST CHANGE THE CONFIG ID FROM 4585 BEFORE EXPORTING SCRIPT!!!
 
 -- First, see if datastream already exist 
 
 
 DECLARE @dwobject_uid INT 
 DECLARE @dwobject_syntax_uid INT 
 
 SELECT @dwobject_uid = DWOBJECT_UID 
   FROM DWOBJECT 
   WHERE OBJECT_NAME = 'd_script_pick_ticket_hdr'  
 
 IF EXISTS(SELECT * FROM dwobject WHERE dwobject_uid = @dwobject_uid  
										AND delete_flag <> 'Y'  )
	  BEGIN 
		IF NOT EXISTS (SELECT * FROM db_sql where last_sql_executed = 'CDS_pick_ticket_hdr_4585' ) 
		    UPDATE DWOBJECT_SYNTAX 
    		   SET [columns] = Convert(varchar(8000),[columns]) + ' , oe_hdr.third_party_billing_flag' 
      		      , [join] = Convert(varchar(8000),[join]) + ' join oe_hdr on p21_fnt_all_pick_ticket_hdr.order_number = oe_hdr.order_no' 
        		 , script_col_syntax = Convert(varchar(8000), script_col_syntax) + ' + if(isnull(oe_hdr_third_party_billing_flag), ~"~t~", oe_hdr_third_party_billing_flag + ~"~t~")  
' 
         		 , date_last_modified = CURRENT_TIMESTAMP 
         		 , last_maintained_by = 'Activant_custom_group' 
     		WHERE DWOBJECT_UID = @dwobject_uid
 	  END 
 	
 ELSE 
 IF EXISTS(SELECT * FROM dwobject WHERE dwobject_uid = @dwobject_uid  
									AND delete_flag = 'Y'  )
    BEGIN 
       UPDATE DWOBJECT 
          SET delete_flag = 'N' 
        WHERE DWOBJECT_UID = @dwobject_uid 
 
       UPDATE DWOBJECT_SYNTAX 
          SET [columns] = ', oe_hdr.third_party_billing_flag' 
         , [join] =  ' join oe_hdr on p21_fnt_all_pick_ticket_hdr.order_number = oe_hdr.order_no' 
            , script_col_syntax =  ' + if(isnull(oe_hdr_third_party_billing_flag), ~"~t~", oe_hdr_third_party_billing_flag + ~"~t~")  
' 
            , date_last_modified = CURRENT_TIMESTAMP 
            , last_maintained_by = 'Activant_custom_group' 
        WHERE DWOBJECT_UID = @dwobject_uid
    END     
 
 ELSE 
    BEGIN 
       EXEC @dwobject_uid = p21_get_counter 'dwobject' 
       EXEC @dwobject_syntax_uid = p21_get_counter 'dwobject_syntax' 
 
       INSERT INTO dwobject (DWOBJECT_UID, OBJECT_NAME, DESCRIPTION, DELETE_FLAG ) 
        VALUES (@dwobject_uid, 'd_script_pick_ticket_hdr',    null, 'N' ) 
 
       INSERT INTO dwobject_syntax (DWOBJECT_SYNTAX_UID, DWOBJECT_UID, CUST_CONFIG_ID, [COLUMNS], [JOIN], SCRIPT_COL_SYNTAX ) 
       VALUES 
       ( @dwobject_syntax_uid, @dwobject_uid, 4585
       , ', oe_hdr.third_party_billing_flag' 
       , 'join oe_hdr on p21_fnt_all_pick_ticket_hdr.order_number = oe_hdr.order_no' 
       , '+ if(isnull(oe_hdr_third_party_billing_flag), ~"~t~", oe_hdr_third_party_billing_flag + ~"~t~")  
'  )
    END     
    ; 
EXECUTE ('p21_db_sql_ins ''CDS_pick_ticket_hdr_4585'', ''Inserts or Updates dwobject and dwobject_syntax data for Custom Datastream''' ) 
;