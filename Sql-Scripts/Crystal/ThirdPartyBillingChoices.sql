/*
	07/16/2020 third billing choices
	B = Bill Recipient
	C = Consignee
	F = Fedex Consignee
	S = Standard
	T = Third Party
*/

select distinct third_party_billing_flag
from oe_hdr

select Order_no
from oe_hdr
where third_party_billing_flag is null