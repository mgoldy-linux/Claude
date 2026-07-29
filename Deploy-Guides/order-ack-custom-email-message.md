# Deployment Guide — Order Acknowledgment Custom Email Message (no ticket)

> Produced during development. Update as the artifact changes; commit with the code.

## Artifact(s)
- `CSharp\asi_oe_order_ack_custom_message_t3.cs` — On-Event business rule (current version)
- Superseded: `asi_oe_order_ack_custom_message_t1.cs` (caused a live-customer incident — see below, do not reuse), `asi_oe_order_ack_custom_message_t2.cs` (confirmed working, superseded by t3's blank-line change)
- Ticket: none

## Target environments
- **P21 Business Rules** (mgoldyn's own testing) → **Play** (user-facing testing) → Prod
- Currently registered: `t2` **active** in P21 Business Rules only (`business_rule.row_status_flag = 704`). Nothing registered in Play or Prod.

## Dependencies & deploy order
1. Register as an On-Event rule on **Form Printing Pre-Email Response Window** (`FormPreEmail`, `business_rule_event_uid = 24`).
2. Field Selector: under `EmailDataMisc`, select `form_type`, `memo`, `document_nos` (document_nos is log-context only).
3. No other artifact depends on this or must deploy first — it's a standalone on-event rule.

## Backward-compatibility notes
- None — new rule, no prior version in production use.
- **Do not re-register `t1`.** It suppresses the Email Order Acknowledgment window (`display_response_window = "N"`) so the email sends automatically with no human review — this is what caused the 2026-07-28 incident (see below).

## ⚠️ Known incident — read before testing again
Testing `t1` in **P21 Business Rules** (`P21BusinessRules` DB) sent the placeholder test message to **4 real customers on real live orders** (Carpet One Inc, JSN Enterprises/My House of Carpets, Turner Ceramic Tile Inc, Carpet Weavers Inc of East Peoria — orders 6032097/6032117/6032208/6032267). Root cause: that database is refreshed from Prod with real customer data and **still has a working outbound SMTP path** — it is not a safe sandbox for email-sending rules by default. Apology emails were sent to all 4 recipients 2026-07-28 — incident response closed.

**Before testing t3 (or any future version):** pick an order where you personally control the recipient email address (edit the To: field in the window before clicking OK), not a live/ecommerce customer order. See `feedback_p21_test_env_live_email.md`.

## Deploy steps
1. In P21 Rule Manager (target environment), deregister the currently active version (`t2`) and register `asi_oe_order_ack_custom_message_t3.cs` on the `FormPreEmail` event with the Field Selector fields above.
2. Build/rebuild the DLL and deploy per the normal Business Rules DLL process for that environment.
3. Before promoting past P21 Business Rules: swap the placeholder `CustomMessage` constant (currently the test joke text) for the real message.

## Verification
- Print/email an Order Acknowledgment for a controlled test order → confirm:
  - The Email Order Acknowledgment window **displays normally** (not suppressed).
  - `memo` box opens with a few blank lines at the top, then the custom message below.
  - `business_rule_log WHERE rule_name = 'asi_oe_order_ack_custom_message_t3'` shows an `Info` row with `form_type='Order Acknowledgement' matched=True` for that order's `document_nos`.
- Confirm the exact match still holds: `form_type` is checked against the literal string `'Order Acknowledgement'` (confirmed exact value via t1's test run).

## Rollback
- Deregister the rule entirely in P21 Rule Manager (On-Event rules are additive — removing the registration removes the behavior; no other artifact depends on it).
- Prior file versions (`t1`, `t2`) are kept in `CSharp\` for reference/diff only — do not re-register `t1`.
