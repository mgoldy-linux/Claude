-- Jet Qry =NL("filter","po_hdr","po_no","datasource=","p21live","vendor_id",$C$4,"po_type","*","order_date",$C$5,"expected_date",$C$6)


select po_no,po_type,order_date,expected_date
from po_hdr
where vendor_id = 15966

-- Jet Qry =NL("Rows","po_line",,"datasource=","p21live","po_no",Options!$D$4,"inv_mast_uid",Options!$D$5,"complete","N","cancel_flag","N")