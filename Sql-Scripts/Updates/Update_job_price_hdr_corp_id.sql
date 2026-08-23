-- need add in 54210 for import 23 for play - 22 for live
--use P21Play;
use P21;

select corp_address_id,contract_no
from job_price_hdr
where job_price_hdr_uid = 22

Update dbo.job_price_hdr
set corp_address_id = 54210
where job_price_hdr_uid = 22

select corp_address_id
from job_price_hdr
where job_price_hdr_uid = 22
