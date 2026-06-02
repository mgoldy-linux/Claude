# Daily Accomplishments Log

---

## 2026-05-08

- **Created `C:\PowerShell-Scripts\Create-Excel\Create-B2BMetricsReport.ps1`** — PowerShell script that generates the WFCA fcB2B quarterly 810/850 metrics report in Excel. Prompts for fiscal year and quarter (FY starts Oct 1; Q1=Oct-Dec, Q2=Jan-Mar, Q3=Apr-Jun, Q4=Jul-Sep). Queries P21 Prod (`invoice_hdr` for 810, `oe_hdr` for 850), builds formatted Excel matching the WFCA template, and saves to `C:\_P25\Data-Out\Excel\fcB2B Quarterly 810-850 Metrics Data Request - FYQ{Q} {YYYY}.xlsx`. Overwrites existing file for the same quarter automatically.
- **Resolved `oe_hdr` source column** — `source_cd` does not exist; correct fields are `invoice_batch_uid = 2` (B2B/EDI) and `source_code_no IN (709=web portal, 931=eStore, 3067=P21 SOA)` for supplier-website keying; all others = phone/email/fax/manual.
- **Matched WFCA Excel format** — yellow fill on count rows only (not % rows), bold+underline on headers (no colored fills), `#,##0` number format, `0%` percentage format, rich-text footer with selective bold on "Manufacturers"/"all Orders received and Invoices sent"/"Distributors".
- **Created `C:\Claude\PowerShell\Refresh-P21BusinessRules.ps1`** — PowerShell script to refresh P21BusinessRules (Prod→Dev restore), modeled after `Refresh-P21Training.ps1`. Phases: capture app users/branches/locations/label_definition_x_loc/roles/permissions into timestamped .sql files in `C:\_P25\Data-Out\SQL\`, pause for manual SSMS restore, replay captured scripts, fix orphaned users (`ALTER USER WITH LOGIN`), verification checks. Key differences from Training script: extra capture phases for branches/locations/label_definition_x_loc; no sanitation phase; permission principals are `AHI\AHI-API1$`, `AHI\ASP21API01$`, `AHI\ASP21WEB01$`, `websvc`, `Crystal`.
- **Diagnosed SQL orphaned users** — after Prod→Dev copy, database user SIDs no longer match server login SIDs. Fix: `ALTER USER [x] WITH LOGIN = [x]` re-links them. Detection: `sys.database_principals dp LEFT JOIN sys.server_principals sp ON dp.sid = sp.sid WHERE dp.type IN ('S','U') AND sp.sid IS NULL`.

---

## 2026-05-07

- **Fixed LOGISTICS SURCHARGE qty=2 bug on pick ticket cancel** — root cause was `apc_fe_val_update_surcharge_price` Path A unconditionally setting surcharge `unit_quantity=2` when P21 zeroed shipping qtys during cancel. Added early exit when trigger item `unit_quantity <= 0`. Tested on P21Training — confirmed working.
- **Cleaned up `apc_od_apply_surcharge_shipping.sql`** — removed debug logging table inserts added during troubleshooting.
- **Created `C:\Business_Rules\Troubleshooting-Surcharge-Cancel-Bug.md`** — full 8-step troubleshooting write-up with root cause analysis, fix rationale, and reference guide for similar surcharge bugs.
- **Created `C:\Business_Rules\Troubleshooting-Index.md`** — index of all past TS sessions (active write-ups, archive investigations, related reports) with a `business_rule_log` quick-reference section.
- **Updated business rules standardization memory** — saved pointers to pre-work analysis docs so future sessions pick up where the deficiency review left off.
