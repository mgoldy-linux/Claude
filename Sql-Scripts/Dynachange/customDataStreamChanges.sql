  SELECT dwobject.dwobject_uid,   
                      dwobject.object_name,   
                      dwobject.description,
                      dwobject.delete_flag
                    , dwobject.date_last_modified
                    , dwobject.last_maintained_by
                    , dwobject.date_created
                    , dwobject.created_by
                    , dwobject_syntax.dwobject_syntax_uid,  
                      dwobject_syntax.cust_config_id,  
                      dwobject_syntax.[columns],
                      dwobject_syntax.[join],
                      dwobject_syntax.script_col_syntax  
                   , ' '
              FROM     dwobject
                      JOIN dwobject_syntax on (dwobject_syntax.dwobject_uid = dwobject.dwobject_uid)              
               ORDER BY dwobject.object_name ASC, dwobject_syntax.cust_config_id ASC