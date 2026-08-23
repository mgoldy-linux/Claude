select order_no,customer_id,ship2_name,ship2_add1,ship2_add2,ship2_city,ship2_state,ship2_zip,po_no,ship_to_phone,completed,carrier_id,address_id,contact_id,third_party_billing_flag,delivery_instructions
from oe_hdr
where taker = 'CXM'
order by date_created desc