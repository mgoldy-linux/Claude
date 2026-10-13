# SA 54321 - Technical reference (moved out of the requirements document 2026-10-13)

Removed from the reviewer-facing requirements document because it is only useful to Business Applications. Text is verbatim.

For IT reference only. Nothing in this appendix is needed in order to review or approve the behavior described above.


## Why two rules are needed

The email window (w_email_response) is shared by every emailed document and exposes neither the form type nor the order number. Both are available at the earlier FormPreEmail event (business_rule_event_uid 24), so they are recorded there and read back when the OK button is clicked.

| Component | Type | Purpose |
|---|---|---|
| asi_email_context_flag | On-Event rule, FormPreEmail | Fires for every emailed document. Writes form_type and document_nos for the current user. Writes on every send so a stale value cannot be read later. |
| dbo.asi_email_context_flag | SQL table | One row per user_id: is_order_ack, form_type, document_nos, updated_at. Needs SELECT, INSERT and UPDATE for PxxiUser and p21_application_role. |
| asi_oe_order_ack_email_subject | On-Demand rule, multi-row, cb_ok on w_email_response | Reads the flag row and, where it is an Order Acknowledgment, composes and writes d_dw_email_info.subject. |

The table and asi_email_context_flag are shared with SA 53475, which appends the ASAP message to the body of the same email. Both features must be re-tested together after any change to either.


## Field constraints

d_dw_email_info.subject is char(60) and holds only the free-text portion. P21 generates the "All Surfaces - Acknowledgement# nnnnnnn" prefix at send time and appends this field; the prefix does not count against the 60 characters. oe_hdr.job_name is varchar(40) and oe_hdr.po_no is varchar(50), both unvalidated free text.


## Implementation constraints

- Business rules on this platform are limited to C# 7.3.
- Saving a rule in the Rule Manager replaces its registered data element list rather than merging it, and a lost field is indistinguishable at run time from an empty one. Verify by query after every Rule Manager change.
- Multi-row must be selected when the registration is created; it cannot be changed afterwards.
- The Rule Manager Test Business Rule pane cannot exercise a multi-row rule attached to a window control. The error it reports comes from its own result grid, not from the rule.
- P21BusinessRules is refreshed from Production periodically and rule registrations are not preserved. Re-register and re-check the table after every refresh.
- A rule description containing an apostrophe fails Rule Manager import validation.
- Create-asi-email-context-flag.sql has not been run against Production, so the document_nos column is lost on each P21BusinessRules refresh until it is.