--DS d_ds_syscolumns_table
SELECT p21_view_syscolumns_table.table_name          ,p21_view_syscolumns_table.column_name       ,p21_view_syscolumns_table.colid    ,p21_view_syscolumns_table.datatype       ,p21_view_syscolumns_table.precision          ,p21_view_syscolumns_table.scale       ,p21_view_syscolumns_table.primary_key_column_flag       ,p21_view_syscolumns_table.alternate_key_column_flag    
FROM p21_view_syscolumns_table  
WHERE ( p21_view_syscolumns_table.table_name = 'inv_mast_ud' )   