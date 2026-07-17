# Deploy-Guides

Deployment guides for deployable artifacts (views, business rules, portals/.srd, reports, scripts).

**Practice:** every task that produces a deployable artifact gets its **own** guide here, written *during development*. One markdown per task/ticket — not one master file. Start from [`_TEMPLATE.md`](_TEMPLATE.md).

Each guide covers: artifact(s) & ticket · target environments · dependency & deploy order · backward-compat notes · deploy steps · verification · rollback.

## Guides

| Ticket | Title | Status |
|--------|-------|--------|
| SA-50249 | [Five Way Report Acceleration (ASI_ReportCache columnstore)](SA-50249-five-way-report-acceleration.md) | Built + proven in Play & on the DW (149s→125ms). DB/synonyms/compute view live on `asdwdb01`; one-time build+verify job scheduled 2026-07-17 23:00. **GO-LIVE pending BuildLog review** — nothing live swapped yet |
| SA-49504 | [asi_view_edi_855_po_ack (EDI PO-Ack Exceptions portal)](SA-49504-edi-855-view.md) | Deployed to Prod 2026-07-13 — awaiting user feedback |
| SA-48732 | [CSR Open Order Team portal](SA-48732-csr-open-order-team-portal.md) | On Play 2026-07-13 — ready for user acceptance testing; Prod pending UAT sign-off |
| *(none)* | [Low Margin Alert (Evan Jenkins)](low-margin-alert.md) | **Built + tested in Play 2026-07-14** (emails verified end-to-end). Prod blocked on Evan's sign-off (design deviates from his spec) + Pam Dundas / Alex Boeve addresses |
