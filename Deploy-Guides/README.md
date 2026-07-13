# Deploy-Guides

Deployment guides for deployable artifacts (views, business rules, portals/.srd, reports, scripts).

**Practice:** every task that produces a deployable artifact gets its **own** guide here, written *during development*. One markdown per task/ticket — not one master file. Start from [`_TEMPLATE.md`](_TEMPLATE.md).

Each guide covers: artifact(s) & ticket · target environments · dependency & deploy order · backward-compat notes · deploy steps · verification · rollback.

## Guides

| Ticket | Title | Status |
|--------|-------|--------|
| SA-49504 | [asi_view_edi_855_po_ack (EDI PO-Ack Exceptions portal)](SA-49504-edi-855-view.md) | Deployed to Prod 2026-07-13 — awaiting user feedback |
