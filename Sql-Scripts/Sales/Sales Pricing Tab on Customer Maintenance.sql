--Sales Pricing Tab on Customer Maintenance: 13845 (INTERSTATE BEARING SYSTEMS-BUTLER  WI)*
SELECT price_library_x_cust_x_cmpy.price_lib_x_cust_x_cmpy_uid
      ,price_library_x_cust_x_cmpy.company_id
      ,price_library_x_cust_x_cmpy.customer_id
      ,price_library_x_cust_x_cmpy.price_library_uid
      ,price_library_x_cust_x_cmpy.sequence_number
      ,price_library_x_cust_x_cmpy.row_status_flag
      ,price_library_x_cust_x_cmpy.date_last_modified
      ,price_library_x_cust_x_cmpy.date_created
      ,price_library_x_cust_x_cmpy.last_maintained_by
      ,price_library.price_library_id
      ,price_library.description
      ,price_library.row_status_flag
FROM price_library_x_cust_x_cmpy
INNER JOIN price_library ON price_library_x_cust_x_cmpy.price_library_uid = price_library.price_library_uid
WHERE price_library.row_status_flag <> 700
