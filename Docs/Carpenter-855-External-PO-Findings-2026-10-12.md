# Carpenter 855 and PO External PO Number - Findings and Fix

**Date:** 2026-10-12
**Requested by:** Chad Skelton (Comparatio ticket, Carpenter 2000692)
**Question:** Why doesn't Carpenter's 855 update `po_hdr.external_po_no`, when Roppe (3003400) and Schluter (3012610) do?

## Answer

P21 is not treating Carpenter differently. The 855 import fills `external_po_no` only when the field is empty, and it does not overwrite a value that is already there. Roppe and Schluter POs are created with the field blank, so the import fills it. Carpenter POs usually have a number typed in at creation, so the 855 leaves it alone.

## Evidence (Prod, POs created in the last 90 days)

| Supplier | POs with an 855 | Header matches the 855 | Header differs | POs with no 855 |
|---|---|---|---|---|
| Roppe (3003400) | 2,268 | 2,267 | 1 | 199 |
| Schluter (3012610) | 1,322 | 1,320 | 2 | 81 |
| Carpenter Elkhart (3003676) | 121 | 39 exact, 76 differ only by leading zeros | 6 | 544 |

- Carpenter POs that did not take the 855 number have a typed value, last maintained by the buyer, and the header modified time does not change after the 855 arrives.
  - 4327858: `CMH0000164`, 855 sent `0096925949`
  - 4327795: `Pad Stock - Tim`, 855 sent `0096921994`
  - 4327672: `F100926`, 855 sent `0096862828`
- Carpenter POs where the import did write the number show `import` as the last maintainer (for example 4327856 and 4327088).
- 76 Carpenter POs differ only by leading zeros. The buyer typed `96905334`, and the 855 carried `0096905334`.
- Roppe and Schluter POs are almost all filled by `import`.

- Roppe and Schluter POs that have not received an 855 yet show a blank `external_po_no` (for example Roppe 4327866, created by `lochoa` with the field empty). So those POs start out blank, and the import is what fills them.

Limit of the evidence: `audit_trail` does not record `external_po_no` changes (for the sample POs it only has date_due, required_date, expected_date and inv_mast_uid), so the old value at the moment of the 855 cannot be shown directly. The conclusion rests on the PO header values, last-modified user and times, and the fill-only-if-blank behavior Chad described from P21.

## Second finding for Comparatio

About 82% of Carpenter Elkhart POs (544 of about 665) have no 855 at all, compared with 8% for Roppe and 6% for Schluter. Some are non-EDI or stock POs, but the share is high enough to ask Comparatio.

## Fix (agreed: process change)

1. On Carpenter EDI POs, the buyer leaves `external_po_no` blank so the 855 can fill it.
2. If a note is needed on a pad stock PO, put it in a different field such as PO notes.
3. If the buyer must type a Carpenter number, include the leading zeros so it matches the 855 (`0096905334`, not `96905334`).

Optional follow-up: add the leading-zero comparison to `asi_view_edi_855_po_ack` so zero-padding is not reported as `EXTERNAL PO# MISMATCH`.

## Files

- `Sql-Scripts/EDI/Carpenter-855-External-PO-Compare.sql`
- `Sql-Scripts/EDI/Carpenter-855-External-PO-Audit-Trail.sql` (ran it; audit_trail has no external_po_no rows, so it adds nothing)
