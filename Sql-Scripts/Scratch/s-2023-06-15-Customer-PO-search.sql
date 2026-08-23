select po_no, ship2_add1,ship2_add2
from po_hdr
where po_no in ('4009567','4009413')

select po_no
from po_hdr 
where ship2_add1 like '%4501860527%' or ship2_add2 like '%4501860527%'