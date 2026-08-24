-- jet function: =NL("first","invoice_hdr","po_no","DataSource=","P21LIVE","invoice_no",$K$7)


select po_no, terms_desc,(carrier_name + '-' + carrier_name)[Shipping Method],h.order_no,h.invoice_no,invoice_date,net_due_date,ship2_name,bill2_address1,bill2_address2,(bill2_city + ', ' + bill2_postal_code)[CityandPostalCode],item_id,customer_part_number,item_desc,qty_shipped,extended_price
from invoice_hdr h
join invoice_line l
on h.invoice_no = l.invoice_no
where h.invoice_no = '3144754'

-- jet function: =NL("first","invoice_line",,"DataSource=","P21LIVE","invoice_no",Options!$C$3,"invoice_line_type","0","qty_shipped","<>0")

select item_id,customer_part_number,item_desc,qty_shipped,extended_price
from invoice_line
where invoice_no = '3187687' and invoice_line_type = 0 and qty_shipped <> 0

select *
from invoice_hdr
where customer_id = 10100 and amount_paid = 0 and invoice_date > '2021-05-01'