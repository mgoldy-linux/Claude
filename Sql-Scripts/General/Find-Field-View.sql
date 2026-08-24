--use WQMetaData;
--use P21;
-- Declare @searchTerm varchar(30) = '%pick_ticket_no%'; Declare @searchTerm varchar(30) = '%price;Declare @searchTerm varchar(30) = '%class_id5%';
-- Declare @searchTerm varchar(30) = '%packing_basis%'; Declare @searchTerm varchar(30) = 'country_of_origin'; '%pricing_unit_size%';  = '%90%'
-- Declare @searchTerm varchar(30) = '%qty_shipped%'; Declare @searchTerm varchar(30) = '%class_id%';
-- Declare @searchTerm varchar(30) = '%qty_on_hand%'; Declare @searchTerm varchar(30) = '%stock';
-- Declare @searchTerm varchar(30) = '%container_name%'; Declare @searchTerm varchar(30) = '%Report_Name%';
---Declare @searchTerm varchar(30) = '%Days%'; Declare @searchTerm varchar(30) = '%pick_ticket%';
-- Declare @searchTerm varchar(30) = 'Bill2_Name%';Declare @searchTerm varchar(30) = '%prod_order_number%';

Declare @searchTerm varchar(30) = 'qty_on_hand';

SELECT v.name AS view_name, SCHEMA_NAME(schema_id) AS schema_name, c.name AS column_name
FROM sys.views AS v
INNER JOIN sys.columns c ON v.object_id = c.object_id
WHERE c.name LIKE @searchTerm
order by view_name, column_name
--order by schema_name, view_name
-- order by column_name

go