-- Accounts Payable (AP) Invoices

SELECT
hdr.vendor_id
,COUNT(DISTINCT hdr.voucher_no) AS invoices
,COUNT(DISTINCT line.apinv_line_uid) AS lines
FROM
p21_view_apinv_hdr hdr
INNER JOIN p21_view_apinv_line line ON hdr.voucher_no = line.voucher_no
WHERE 
hdr.invoice_amount > 0
AND hdr.invoice_date > DATEADD(yy,-1,GETDATE())
AND ISNULL(hdr.reverse_flag,'N') <> 'Y'
AND ISNULL(hdr.voucher_type,'X') <> 'D'
AND ISNULL ( hdr.po_no , '0' ) <> '0' 
GROUP BY
hdr.vendor_id
ORDER BY
invoices DESC
