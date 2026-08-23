--- 05/27/2022 - need to use new item_ids 
--- 05/31/2022 - use inv_loc for product code, missing some items

select upc_or_ean_id[UPC Number],item_id[Item Number],m.price1[Published List Price],''[Special Invoice Price Mult],''[Special Net Invoice Price],'0.420'[Published Distributor Price Mult],(m.price1 * 0.420)[Published Distributor Invoice Price],'0.530'[Pub OEM Price Mult],(m.price1 * 0.530)[Pub OEM Invoice Price],''[Rebate Amt],''[Jobber/Reseller Price Mult],''[Jobber/Reseller Invoice Price],'0.840'[Pub End User Price Mult],(m.price1 * 0.840)[Pub End User Invoice Price],''[Pricing Disc Grp1],''[Pricing Disc Grp2],item_desc[Description1],p.product_group_desc[Description2 (Product Line)],u.unit_of_measure [Selling U/M],sales_pricing_unit_size[Units in Pkg],net_weight[Weight],'LB'[Unit of Weight],''[Cubic Inches],'' [Stock Flag],''[Return Code],'Y'[Obsolete/New Flag],m.item_desc[NewSuperceded Number],''[New UPC Number],''[Estimated Lead Time],''[Substitute Item#],''[Substitute UPC Number],''[Distributor Part No],''[MSDS ID No],'07/11/2022'[Effective Date],''[Expiration Date],''[Special Pricing Flag],m.class_id1 [Brand],''[Next Higher Package],m.commodity_code [UNSPSC],''[User Defined],''[User Defined],''[User Defined],''[User Defined],''[User Defined],''[Dimension U/M],''[Length],''[Width],''[Height],''[User Defined],''[User Defined],''[User Defined],''[User Defined],''[User Defined],''[User Defined],''[User Defined],''[User Defined],''[User Defined],''[User Defined],''[User Defined],''[Min Order Qty],''[POR Flag],''[Conditional Price Mult],''[Conditional Invoice Price],''[Country of Origin 1],''[Country of Origin 2],''[Country of Origin 3],''[Country of Origin 4],''[Country of Origin 5],''[Image File Name],''[Image URL],''[Harmonized Tarriff Code],''[Green Product],''[Green Cert., Regulation or Std. Met],''[Additional Green Attributes],''[Green Validation Details],''[ECCN],(m.price1 * 0.840)[Min Advertised Price]
from inv_mast m
join inv_loc il
on m.inv_mast_uid = il.inv_mast_uid
join product_group p
on il.product_group_id = p.product_group_id
join item_uom u
on u.inv_mast_uid = m.inv_mast_uid
where m.class_id1 = 'PTI' and class_id2 = 'EPL' and sellable = 'Y' and location_id = 100  and upc_or_ean_id is not null --and m.item_id = 'SUCSFL212-39'
-- and upc_or_ean_id = '80067532814' --and m.item_id like 'SAF207%' --and default_product_group is null 