update dbo.invoice_hdr 
set ship2_state = TRIM(ship2_state)

update dbo.invoice_hdr 
set bill2_state = TRIM(bill2_state)