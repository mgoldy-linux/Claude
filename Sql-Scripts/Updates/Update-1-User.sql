/*
select display_open_quote_lines_cd,	*
from users
where id = 'DVARELLA'
go
*/
update users
set name = 'Al Concepcion', default_branch = 400,default_quote_order = 'N',create_customers = 'N',create_ship_tos = 'Y',
default_location_id = 150,prompt_before_clearing = 'N',create_items_at_oe = 'N',role_uid = 23,
auto_generate_transfer_in_oe = 'N',email_address = 'aconcepcion@bearingslimtied.com',default_to_advanced_search = 'N',
link_stock_item_to_po = 'N',order_cost_basis_comm_cost = 'N',order_cost_basis_other_cost = 'N',
allow_nonstock_tbo = 'N',create_contract_from_oe = 'N',cnvrt_prospect_to_customer_oe = 'N',
display_purchaseprice_breaks = 'N',make_items_sellable_in_oe_flag = 'N',add_item_locations_in_oe_flag = 'N',
display_open_quote_lines_cd = '',default_item_search_in_imi = 'N',add_customer_part_number_in_oe = 'N',
oe_change_customer_with_items = 'N',rebuild_drill_security_flag = 'Y'    
where id = 'ACONCEPCION'
