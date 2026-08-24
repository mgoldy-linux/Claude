 Use P21Sand;

 Declare	@inv_bin_uid int,
			@inventory_supplier_x_loc_uid int,
			@inv_loc_msp_uid int;

 Select @inv_bin_uid = max(inv_bin_uid)
 from inv_bin
 EXEC p21_set_counter @counter_id='inv_bin' ,@counter_num = @inv_bin_uid

 Select @inventory_supplier_x_loc_uid = max(inventory_supplier_x_loc_uid)
 from inventory_supplier_x_loc
 EXEC p21_set_counter @counter_id='inventory_supplier_x_loc' ,@counter_num = @inventory_supplier_x_loc_uid

 select @inv_loc_msp_uid = MAX(inv_loc_msp_uid)
 from inv_loc_msp
 EXEC p21_set_counter @counter_id = 'inv_loc_msp', @counter_num = @inv_loc_msp_uid