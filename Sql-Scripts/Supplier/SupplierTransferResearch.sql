-- test update switching suppliers
-- failed The UPDATE statement conflicted with the FOREIGN KEY constraint "fk_inv_suplr_divi". The conflict occurred in database "P21Play", table "dbo.division".
-- The statement has been terminated.
use P21Play;

update inventory_supplier
set supplier_id = 46926
where inv_mast_uid = 65863