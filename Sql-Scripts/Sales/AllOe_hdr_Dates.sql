/*
  03/01/2020 - missing quote expiration date, that comes from quote_hdr.expiration_date

*/


select  order_date,date_created,date_last_modified,expedite_date,order_open_start_date,original_promise_date,promise_date,promise_date_edited_date,promise_date_extended_desc,requested_date,requested_ship_date,rma_expiration_date,route_override_date,routed_eta_date,second_route_override_date,tag_hold_cancel_date,user_defined_date,pm_date,acknowledgement_date,consolidate_per_order_flag,date_order_completed,document_capture_date,expected_completion_date,prebilling_date
from oe_hdr
where order_no = 1034384


