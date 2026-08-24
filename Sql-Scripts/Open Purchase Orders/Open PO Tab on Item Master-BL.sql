--Open PO Tab on Item Master Inquiry: 22201 (0-99999999)
-- need format the dates
SELECT
   po_hdr.location_id,
   po_hdr.po_no,
   po_hdr.order_date,
   po_hdr.supplier_id,
   supplier.supplier_name,
   po_line.unit_quantity,
   po_line.unit_of_measure,
   po_line.unit_size,
   po_line.unit_price_display,
   po_line.pricing_unit,
   po_line.pricing_unit_size,
   po_line.qty_received,
   po_line.required_date,
   po_line.date_due,
   COALESCE(po_line.line_type, po_hdr.po_type) po_type,
   po_hdr.approved,
   contacts.last_name + ', ' + contacts.first_name + ' ' + contacts.mi contact_name,
   po_line.line_no,
   po_line.po_line_uid,
   contacts.id contact_id,
   po_hdr.currency_id,
   0 qty_in_vessel,
   COALESCE(item_revision.revision_level, '') revision_level,
   COALESCE(po_line.expedite_notes, '')[expedite_notes],
   m.item_id,m.item_desc,
   po_line.expected_ship_date
FROM  po_line
   INNER JOIN po_hdr ON po_hdr.po_no = po_line.po_no
   INNER JOIN supplier ON supplier.supplier_id = po_hdr.supplier_id
   INNER JOIN contacts ON contacts.id = po_hdr.requested_by
   LEFT JOIN revision_transaction ON revision_transaction.transaction_no = po_line.po_no
   AND revision_transaction.transaction_line_no = po_line.line_no
   AND revision_transaction.transaction_code_no = 916
   LEFT JOIN item_revision ON item_revision.item_revision_uid = revision_transaction.item_revision_uid
   join inv_mast m
   on po_line.inv_mast_uid = m.inv_mast_uid
WHERE
   po_line.complete = 'N'
   AND po_line.delete_flag = 'N'
   AND po_line.cancel_flag = 'N'
   AND po_hdr.po_type NOT IN ('Q', 'X') and po_hdr.location_id like '4%'