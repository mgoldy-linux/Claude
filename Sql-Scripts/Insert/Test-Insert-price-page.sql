--use [P21Play2021.1.4420Local];

insert into dbo.price_page
("price_page_uid","price_page_type_cd","description","pricing_method_cd","source_price_cd","effective_date","expiration_date","calculation_method_cd","calculation_value1",
"calculation_value2","calculation_value3","calculation_value4","calculation_value5","calculation_value6","calculation_value7","calculation_value8","calculation_value9",
"calculation_value10","calculation_value11","calculation_value12","calculation_value13","calculation_value14","calculation_value15","break1","break2","break3","break4",
"break5","break6","break7","break8","break9","break10","break11","break12","break13","break14","totaling_method_cd","totaling_basis_cd","row_status_flag","date_last_modified","date_created","last_maintained_by","other_cost_type_cd","cost_calculation_method_cd",
"commission_cost_type_cd","created_by","calculator_type","apply_pp_to_mro_cd","price_family_uid","strategic_price_applies_to_cd","on_contract_flag","apply_freight_factor",
"freight_factor_source_cd","no_charge_flag","non_stock_items_only_flag","apply_pp_to_sop_cd","price_override")
Values (1418,2339,'TRITAN B4 1.00 LIST PRICE LEVEL',220,101,'2023-01-04 00:00:00.000','2049-12-31 00:00:00.000',211,1.000000,0.000000,0.000000,0.000000,0.000000,0.000000,
0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000000,0.000000000,0.000000000,0.000000000,0.000000000,0.000000000,0.000000000,
0.000000000,0.000000000,0.000000000,0.000000000,0.000000000,0.000000000,0.000000000,212,223,704,GetDate(),Getdate(),'mgoldyn',
222,211,222,'PTIDOM\mgoldyn','P',1104,40,2636,'N','N',202,'N','N',1103,'N')


 select max(price_page_uid)[MaxRecord]
 from dbo.price_page

 exec p21_set_counter @counter_id='price_page',@counter_num = 1487


select *
from price_book
where description like 'Trit%'

select *
from price_page_x_book
where price_book_uid = 116