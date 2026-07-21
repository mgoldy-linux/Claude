# Deploy-Guides

Deployment guides for deployable artifacts (views, business rules, portals/.srd, reports, scripts).

**Practice:** every task that produces a deployable artifact gets its **own** guide here, written *during development*. One markdown per task/ticket — not one master file. Start from [`_TEMPLATE.md`](_TEMPLATE.md).

Each guide covers: artifact(s) & ticket · target environments · dependency & deploy order · backward-compat notes · deploy steps · verification · rollback.

## Guides

| Ticket | Title | Status |
|--------|-------|--------|
| SA-50249 | [Five Way Report Acceleration (ASI_ReportCache columnstore)](SA-50249-five-way-report-acceleration.md) | Built + proven in Play & on the DW (149s→125ms). DB/synonyms/compute view live on `asdwdb01`; one-time build+verify job scheduled 2026-07-17 23:00. **GO-LIVE pending BuildLog review** — nothing live swapped yet |
| SA-49504 | [asi_view_edi_855_po_ack (EDI PO-Ack Exceptions portal)](SA-49504-edi-855-view.md) | Deployed to Prod 2026-07-13 — awaiting user feedback |
| SA-47981 | [WWMS Sales Order Picking: Item Description](SA-47981-wwms-pick-item-desc.md) | ⏸ **Parked (2026-07-21).** Data lookup works; no DynaChange rule type can render a custom column on the RF picking screen. Recommend Epicor support question (RF-screen customization). Non-technical ticket update in `SA-47981/ticket-update.md` |
| SA-48732 | [CSR Open Order Team portal](SA-48732-csr-open-order-team-portal.md) | On Play 2026-07-13 — ready for user acceptance testing; Prod pending UAT sign-off |
| *(none)* | [Low Margin Alert (Evan Jenkins)](low-margin-alert.md) | **Evan signed off 2026-07-17** on the audience split. Fired live in Play; fixed Outlook line-break mangling (blank-line fields), price-page `(no price page)` fallback, latent 705→704 activation-flag bug. Recipients all known. **Awaiting Evan's OK on the re-fired sample**, then Prod (real recipients + `USE P21`) |
