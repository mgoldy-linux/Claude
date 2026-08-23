select customer_name,*
from customer
where customer_id = 11820


select *
from price_library_x_cust_x_cmpy
where customer_id = 11820
order by sequence_number

select *
from price_library
where price_library_uid = 114

select *
from price_page_x_book

select unit_price, item_id,inv_mast_uid,*
from p21_sales_analysis_view
where customer_id = 11820 and item_id = '2101077771' and period = 9 and year_for_period = 2023

select price1,*
from inv_mast 
where item_id = '2101077771'

execute  dbo.p21_price_engine   @customer_id = 11820, @company_id = '1', @inv_mast_uid = '75886', @supplier_id = NULL, @disc_group_id = NULL, @prod_group_id = NULL, @mfr_class_id = NULL, @customer_part_no = '2101075648', @tran_date = {ts '2023-06-01 10:41:50.000'}, @oe_sales_unit_size = '1.000000000', @oe_qty_ordered = '2.000000000', @source_location_id = 400, @oe_pricing_unit_size = '1.000000000', @sales_cost = 0, @debug_mode = 0, @summary_price = 1, @order_type = 706, @rollup_component_price = 'N', @calculator_type = 'B', @udl_list = NULL, @configuration_id = 4585, @oe_source_location_id = 100, @limit_by_location_id = 'N', @forced_price_value = NULL, @check_inventory = 'N', @use_web_based_pricing = 'N', @sales_location_id = 300, @ship_to_id = 60216, @base_price_library_uid = NULL, @selected_price_library_uid = NULL, @customer_sensitivity_value = NULL, @customer_category_uid = NULL, @data_service_level = NULL, @data_services_exp_date_is_valid = NULL, @audit = 'N', @carrier_contract_line_uid = NULL, @carrier_calc_type = NULL, @carrier_forced_price = NULL, @future_price_date = NULL, @use_distributor_net_library = 'N', @return_all_revisions = 'N', @arg_item_revision_level_list = '', @rolled_item_pricing_type_cd = '3548', @service_labor_uid = NULL 

select *
from p21_view_oe_hdr_rfq_control_no