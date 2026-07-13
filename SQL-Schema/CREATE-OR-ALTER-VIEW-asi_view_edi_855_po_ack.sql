-- 47715  change from supplier buyer id to po_hdr.requested_by   - need update srd too
-- 49504 2026-07-13: keep BOTH supplier.buyer_id (V3 srd) AND po_hdr.requested_by (V4 srd)
--             so both portals resolve. buyer contact_name still joins on requested_by.
USE [P21Play]  -- P21
GO

/****** Object:  View [dbo].[asi_view_edi_855_po_ack]    Script Date: 6/16/2026 5:43:08 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER VIEW [dbo].[asi_view_edi_855_po_ack]  
AS  
WITH non_edi_pos AS (  
    SELECT DISTINCT ackh.po_number, ackl.line_number  
    FROM po_acknowledgement_hdr AS ackh  
    INNER JOIN po_acknowledgement_line AS ackl   
        ON ackl.po_acknowledgement_hdr_uid = ackh.po_acknowledgement_hdr_uid  
    INNER JOIN po_hdr   
        ON ackh.po_number = po_hdr.po_no  
    INNER JOIN po_line   
        ON po_line.po_no = ackh.po_number AND ackl.line_number = po_line.line_no  
    WHERE ISNULL(po_hdr.transmission_method,0) <> 708 -- Non-EDI  
      AND po_hdr.delete_flag = 'N'  
      AND COALESCE(po_hdr.cancel_flag,'N') = 'N'  
      AND po_line.delete_flag = 'N'  
      AND COALESCE(po_line.cancel_flag,'N') = 'N'  
),  
  
-- Aggregated quantities received per PO/line  
ir_agg AS (  
    SELECT  
        irh.po_number,  
        irl.po_line_number AS po_line_no,  
        SUM(irl.qty_received) AS qty_received  
    FROM inventory_receipts_hdr irh  
    JOIN inventory_receipts_line irl ON irh.receipt_number = irl.receipt_number  
    WHERE irh.delete_flag = 'N'  
    GROUP BY irh.po_number, irl.po_line_number  
),  
  
-- Count acknowledgements per PO/line and track distinct ship dates  
ack_agg AS (  
    SELECT  
        p1.po_number,  
        p2.line_number,  
        COUNT(*) AS rec_ct,  
        COUNT(DISTINCT p2.date_due) AS diff_dates  
    FROM po_acknowledgement_hdr AS p1  
    LEFT JOIN po_acknowledgement_line AS p2  
        ON p1.po_acknowledgement_hdr_uid = p2.po_acknowledgement_hdr_uid  
    GROUP BY p1.po_number, p2.line_number  
),  
  
-- Latest acknowledgement header per PO/line  
recent_ack_line AS (  
    SELECT  
        ah.po_number,  
        al.line_number,  
        al.quantity,  
        al.unit_of_measure,  
        al.date_due,  
        al.date_last_modified,  
        al.unit_price,  
        al.pricing_unit,  
        al.row_status_flag,  
        ah.external_po_no AS ack_external_po_no,  
        ROW_NUMBER() OVER (PARTITION BY ah.po_number, al.line_number ORDER BY ah.po_acknowledgement_hdr_uid DESC) AS rn  
    FROM po_acknowledgement_hdr ah  
    INNER JOIN po_acknowledgement_line al   
        ON al.po_acknowledgement_hdr_uid = ah.po_acknowledgement_hdr_uid  
)  
, recent_ack_line_top AS (  
    SELECT *  
    FROM recent_ack_line  
    WHERE rn = 1  
)  
  
SELECT  
    buyer.contact_name AS buyer,
    po_hdr.requested_by,
    supplier.buyer_id,
    supplier.supplier_id,
    supplier.supplier_name,  
    po_hdr.po_no,  
    po_hdr.date_created AS hdr_date_created,  
    COALESCE(po_hdr.complete,'N') AS hdr_complete,  
    po_line.line_no,  
    po_line.complete AS line_complete,  
    ic.item_id,  
    ic.extended_desc,  
    po_line.qty_ordered,  
    ic.base_unit AS uom,  
  
    pc.converted_qty AS acknowledgement_quantity_base,  
    ral.quantity AS ack_qty,  
    ral.unit_of_measure AS ack_uom,  
    CASE   
        WHEN ROUND(pc.converted_qty,2) <> ROUND(po_line.qty_ordered,2) THEN 'QUANTITY MISMATCH'  
        ELSE 'match'  
    END AS quantity_comparison,  
  
    COALESCE(ir_agg.qty_received,0) AS qty_received,  
    po_line.expected_ship_date AS line_exp_ship_date,  
    CASE   
        WHEN ral.date_due IS NULL THEN 'n/a'  
        WHEN po_line.expected_ship_date <> ral.date_due THEN 'SUPPLIER DATE MISMATCH'  
        ELSE 'match'  
    END AS ship_date_comparison,  
  
    ral.date_due AS po_ack_expected_ship_date,  
    ack_agg.diff_dates AS times_supplier_set_ship_date,  
    po_line.date_due_last_modified,  
    rsf.code_description AS ack_line_status,  
    ack_agg.rec_ct AS po_acks_received,  
  
    po_hdr.external_po_no AS po_hdr_external_po_no,  
    CASE   
        WHEN ral.ack_external_po_no IS NULL THEN 'n/a'  
        WHEN po_hdr.external_po_no <> ral.ack_external_po_no   
             AND 'RM0' + po_hdr.external_po_no <> ral.ack_external_po_no THEN 'EXTERNAL PO# MISMATCH'  
        ELSE 'match'  
    END AS po_no_comparison,  
  
    ral.ack_external_po_no AS po_ack_external_po_no,  
    ral.date_last_modified AS ack_line_received,  
  
    ral.unit_price AS ack_line_unit_price,  
    ral.pricing_unit AS ack_line_pricing_unit,  
    po_line.unit_price AS po_line_unit_price,  
    po_line.pricing_unit AS po_line_pricing_unit,  
  
    CASE   
        WHEN ral.pricing_unit IS NULL OR ral.unit_price IS NULL THEN 'Cannot Determine'  
        WHEN ROUND(pc_price.converted_price,2) <> ROUND(po_line.unit_price,2) THEN 'UNIT PRICE MISMATCH'  
        ELSE 'match'  
    END AS unit_price_comparison  
  
FROM po_hdr  
INNER JOIN po_line ON po_hdr.po_no = po_line.po_no  
INNER JOIN supplier ON supplier.supplier_id = po_hdr.supplier_id  
LEFT JOIN p21_view_contacts AS buyer ON buyer.id = po_hdr.requested_by  
LEFT JOIN p21_view_inv_mast AS ic ON ic.inv_mast_uid = po_line.inv_mast_uid  
LEFT JOIN non_edi_pos ON non_edi_pos.po_number = po_hdr.po_no AND non_edi_pos.line_number = po_line.line_no  
  
LEFT JOIN ir_agg ON ir_agg.po_number = po_hdr.po_no AND ir_agg.po_line_no = po_line.line_no  
LEFT JOIN recent_ack_line_top AS ral ON ral.po_number = po_hdr.po_no AND ral.line_number = po_line.line_no  
LEFT JOIN ack_agg ON ack_agg.po_number = po_hdr.po_no AND ack_agg.line_number = po_line.line_no  
LEFT JOIN p21_view_codes AS rsf ON rsf.code_group_no = 1037 AND ral.row_status_flag = rsf.code_no  
  
-- CHANGED: CROSS APPLY -> OUTER APPLY to preserve rows with no acknowledgement data  
OUTER APPLY dbo.asi_fn_packaging_convert_itvf(  
    ic.item_id,  
    ISNULL(ral.quantity, 0),  
    ral.unit_of_measure,  
    ic.base_unit  
) AS pc  
  
-- CHANGED: CROSS APPLY -> OUTER APPLY to preserve rows with no acknowledgement data  
OUTER APPLY dbo.asi_fn_pricing_convert_itvf(  
    ic.item_id,  
    ISNULL(ral.unit_price, 0),  
    ral.pricing_unit,  
    po_line.pricing_unit  
) AS pc_price  
  
WHERE  
    (po_hdr.transmission_method = 708 OR non_edi_pos.po_number IS NOT NULL)  
    AND po_hdr.delete_flag = 'N'  
    AND COALESCE(po_hdr.cancel_flag,'N') = 'N'  
    AND po_line.delete_flag = 'N'  
    AND COALESCE(po_line.cancel_flag,'N') = 'N';
GO


