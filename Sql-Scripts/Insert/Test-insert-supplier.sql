use P21Dev3;

Declare @max_isxl as int,
		@max_is as int,
		@counter_is as int,
		@counter_isxl as int,
		@suid as int,
		@is_uid as int,
		@loc_id as int;

set @loc_id = 100
select @max_is = max(inventory_supplier_uid) from dbo.inventory_supplier
set @counter_is = @max_is + 1
select @counter_is[inventory_supplier_counter]

INSERT INTO "inventory_supplier" ( "supplier_id", "division_id", "delete_flag", "date_created", "date_last_modified", "last_maintained_by", "list_price", "cost", "backhaul_amount", "backhaul_type", "lead_time_days", "inv_mast_uid", "inventory_supplier_uid" ) VALUES ( 115718, 115718, 'N', GETDATE(), GETDATE(), 'MGOLDYN-SQL', 0, 0, 0, 'R', 0, 1150, @counter_is)

select @max_isxl = max(inventory_supplier_x_loc_uid) from dbo.inventory_supplier_x_loc
set @counter_isxl = @max_isxl + 1
select  @counter_isxl[isxl_counter]

select @suid = inventory_supplier_uid
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
where item_id = '2101001148' and supplier_id = 115718

insert into  dbo.inventory_supplier_x_loc (inventory_supplier_x_loc_uid,inventory_supplier_uid,location_id,primary_supplier,average_lead_time,row_status_flag,date_created,date_last_modified,
last_maintained_by,override_vmi_status_flag,key_vmi_indicator_changed_flag)
values (@counter_isxl,@suid,@loc_id,'N',0,704,Getdate(),GETDATE(),'MGOLDYN-SQL','N','N') 

/*

select m.inv_mast_uid
from dbo.inv_mast m
where item_id = '2101001148'



select *
from inventory_supplier s
where inv_mast_uid = 1150

select inventory_supplier_uid
from inventory_supplier s
where supplier_id = 16013
*/