--Vendor Order Acknowledgements 
SELECT 
	hdr.supplier_id
	,COUNT(DISTINCT hdr.po_no) AS purchase_orders
	,COUNT(DISTINCT line.po_line_uid) AS po_lines
FROM 
	p21_view_po_hdr hdr
	INNER JOIN p21_view_po_line line ON line.po_no = hdr.po_no 
WHERE 
	ISNULL(hdr.cancel_flag,'N') <> 'Y'
	AND ISNULL(hdr.delete_flag,'N') <> 'Y'
	AND ISNULL(line.cancel_flag,'N') <> 'Y'
	AND ISNULL(line.delete_flag,'N') <> 'Y'
	AND hdr.date_created > DATEADD(yy,-1,GETDATE())
	AND hdr.po_type in ('R','X','D','P','S','B','N')
	AND ISNULL(transmission_method,0) <> 708
GROUP BY
	hdr.supplier_id
ORDER BY
	purchase_orders DESC


--Note: the above SQL excludes POs from EDI based on this line (AND ISNULL(transmission_method,0) <> 708)
