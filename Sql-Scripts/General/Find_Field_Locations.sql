/*
   update @searchTerm for column name i'm looking for
*/

--Declare @searchTerm varchar(30) = 'name'; -- Declare @searchTerm varchar(30) = '%freight%'; -- Declare @searchTerm varchar(30) = '%class_id5%'; %90%
--Declare @searchTerm varchar(30) = '%_EDI_%'; -- Declare @searchTerm varchar(30) = '%territory_uid%'; '%qty_compl%''%Receipt_T%'
--Declare @searchTerm varchar(30) = '%Date_Last_p%'; -- not much help
--Declare @searchTerm varchar(30) = '%last_Purchase_date%';   -- found in inv_loc
--Declare @searchTerm varchar(30) = '%sort_code%'; --Declare @searchTerm varchar(30) = '%log%'
--Declare @searchTerm varchar(30) = 'reserved_before_trans'; -- Declare @searchTerm varchar(30) = '%freight%';
--Declare @searchTerm varchar(30) = 'oe_hdr_uid'; -- Declare @searchTerm varchar(30) = '%PO_no%';
--Declare @searchTerm varchar(30) = '%reason%';
--Declare @searchTerm varchar(30) = 'bill2_name';
--Declare @searchTerm varchar(30) = '%lead%';
--Declare @searchTerm varchar(30) = 'country_of_origin';
--Declare @searchTerm varchar(30) = 'inventory_supplier_uid';
--Declare @searchTerm varchar(30) = '%_state%';

Declare @searchTerm varchar(30) = '%purchase_class%'; 

SELECT t.name AS table_name, SCHEMA_NAME(schema_id) AS schema_name, c.name AS column_name
 FROM sys.tables AS t
 INNER JOIN sys.columns c ON t.object_id = c.object_id
 WHERE c.name LIKE @searchTerm
 order by schema_name, table_name