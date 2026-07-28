-- SA-48124 2026-07-27: Vendor Invoice Receiving Report shows freight only, not
--   the other EDI 810 SAC charges (drop charge, pallet, restocking, etc.).
--   This custom view itemizes those charges for a Crystal SUBREPORT so the
--   baseline P21 view (p21_view_vendor_invoice_report) and report stay untouched.
--
--   Grain : one row per SAC charge per vendor invoice header.
--   Link  : vendor_invoice_hdr_uid  <- subreport parameter from the main report.
--   Source: vendor_invoice_edi   (SAC charge amounts; header-level, not per line)
--           chart_of_accts_edi   (sac_id -> human-readable charge description)
--
--   Notes:
--    - sac_id is UNIQUE in chart_of_accts_edi (verified in P21Play, no dupes),
--      so the description join is on sac_id alone.
--    - Filter is amt <> 0 (NOT on sac_id): the only blank-sac rows carry a 0
--      amount, and driving off amt guarantees we never hide a real charge even
--      if a future charge arrives with a blank/unmapped sac_id.
--    - Unmatched / blank sac_id falls back to 'Other Charge' so the amount still
--      prints with a label.
--    - The report's COMBINED total should be driven off the authoritative
--      vendor_invoice_hdr.invoice_amount, not by summing displayed pieces
--      (avoids double-counting the ~0.1% legacy "freight in both" invoices).
--    - No kb_/js_ dependencies in this object or its source tables.
USE [P21] --[P21Play]  -- 
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER VIEW [dbo].[asi_view_vendor_invoice_edi_charges]
AS
SELECT
    e.vendor_invoice_hdr_uid,
    e.sac_id,
    charge_description = ISNULL(NULLIF(LTRIM(RTRIM(c.sac_desc)), ''), 'Other Charge'),
    charge_amount      = e.amt,
    -- Authoritative payable total (lines + freight + charges). The baseline
    -- report view p21_view_vendor_invoice_report does NOT expose it, so we carry
    -- it here for the subreport footer's "Invoice Total (incl. charges)" line.
    -- Repeats identically across a given invoice's charge rows (header value).
    invoice_amount     = h.invoice_amount
FROM dbo.vendor_invoice_edi        AS e
JOIN dbo.vendor_invoice_hdr        AS h
       ON h.vendor_invoice_hdr_uid = e.vendor_invoice_hdr_uid
LEFT JOIN dbo.chart_of_accts_edi   AS c
       ON c.sac_id = e.sac_id
WHERE e.amt <> 0;
GO

-- Grants: match the asi_view standard (e.g. asi_view_edi_855_po_ack) so the P21
-- report service (AHI-API1) can read it. A brand-new view has NO grants, which
-- makes the Crystal subreport fail server-side. Do NOT grant to the kb_ViewReader/
-- kb_ViewDefinitions roles that the baseline P21 views still use (kb_ = retiring).
GRANT SELECT ON dbo.asi_view_vendor_invoice_edi_charges TO p21_application_role;
GRANT SELECT ON dbo.asi_view_vendor_invoice_edi_charges TO PxxiUser;
GO
