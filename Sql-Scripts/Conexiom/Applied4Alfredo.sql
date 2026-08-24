/*
	Finding the applied information for Alferdo
*/

use p21;
-- ship 2 info
select distinct ship2_name,ship2_add1,ship2_add2,ship2_add3,ship2_city,ship2_state,ship2_zip,o.address_id[ship_2_id],contact_id,location_id[branch_id]
from oe_hdr o
where ship2_name like 'APPLIED%' and contact_id is not null and (source_location_id = 100 or source_location_id = 300)
order by ship2_name
-- bill 2 info
select distinct bill2_name,bill2_address1,bill2_address2,bill2_state,bill2_postal_code
from invoice_hdr
where bill2_name like 'APPLIED%' and bill2_address1 is not NULL