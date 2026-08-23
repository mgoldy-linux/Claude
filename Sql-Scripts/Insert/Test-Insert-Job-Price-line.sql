-- test insert  27891 - worked missing fields
use Play2
/* test 1
insert into job_price_line (job_price_line_uid,job_price_hdr_uid,inv_mast_uid,uom,pricing_method,source_price,price,qty_ordered,qty_maximum,other_cost_type_cd,other_cost_value,other_cost_calc_method_cd,
other_cost_calc_value,commission_cost_type_cd,commission_cost_value,commission_cost_calc_method_cd,commission_cost_calc_value,row_status_flag,date_last_modified,date_created,last_maintained_by,
multiplier,line_no,expiration_date,po_cost,line_start_date,all_discount_groups_flag,pocosting_method)
values(27892,4,69843,'EA',221,101,'900.53',0,0,222,1,211,1,222,1,211,1,704,GetDate(),GETDATE(),'mgoldyn',0,7512,'2049-12-31 23:59:59.997',0,'2022-05-01 00:00:00.000','N',300)
*/

-- test 2
insert into job_price_line (job_price_line_uid,job_price_hdr_uid,inv_mast_uid,uom,pricing_method,source_price,price,qty_ordered,qty_maximum,other_cost_type_cd,
other_cost_value,other_cost_calc_method_cd,other_cost_calc_value,commission_cost_type_cd,commission_cost_value,commission_cost_calc_method_cd,commission_cost_calc_value,
row_status_flag,date_last_modified,date_created,last_maintained_by,multiplier,line_no,expiration_date,po_cost,line_start_date,all_discount_groups_flag,
pocosting_method)
values(27893,4,69844,'EA',221,101,'1038.38',0,0,222,1,211,1,222,1,211,1,704,GetDate(),GETDATE(),'mgoldyn',0,7513,'2049-12-31 23:59:59.997',0,
'2022-05-01 00:00:00.000','N',300)

