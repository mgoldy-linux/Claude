/*
	column names - UPC Number,Item Number,Published List Price,Special Invoice Price Mult,	Special Net Invoice Price,Published Distributor Price Mult,Published Distributor Invoice Price,Pub OEM Price Mult,Pub OEM Invoice Price,Jobber/Reseller Price Mult,Jobber/Reseller Invoice Price,Pub End User Price Mult,Pub End User Invoice Price,Pricing Disc Grp1,Pricing Disc Grp2,	Description1,Description2 (Product Line),Selling U/M,Units in Pkg
*/

select upc_or_ean_id[UPC Number],item_id[Item Number],price1[Published List Price],''[Special Invoice Price Mult],''[Special Net Invoice Price],''[Published Distributor Price Mult],''[Published Distributor Invoice Price],''[Pub OEM Price Mult],''[Pub OEM Invoice Price],''[Jobber/Reseller Price Mult],''[Jobber/Reseller Invoice Price],''[Pub End User Price Mult],''[Pub End User Invoice Price],''[Pricing Disc Grp1],''[Pricing Disc Grp2],item_desc[Description1],p.product_group_desc[Description2 (Product Line)],''[Selling U/M],sales_pricing_unit_size[Units in Pkg],net_weight[Weight],'LB'[Unit of Weight]
from inv_mast m
join product_group p
on m.default_product_group = p.product_group_id
--where item_id = 'HC204-12'
where item_id = 'HCF210-30'
/*
select *
from inv_mast
--where item_id = 'HC204-12'
where item_id = '22220MBC3W33RMBP'

select *
from price_page
where product_group_id = 'KS'

select upc_code
from inventory_supplier
where inv_mast_uid = 4691

select *
from item_uom
where inv_mast_uid = 4691

select *
from item_conversion
*/