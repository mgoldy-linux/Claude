# SA 46321 — PO Required Date (Line + Header) — Status Update (2026-08-06)

**Status: Built and fully tested — ready for your review before it goes live.**

## What was requested
1. **Line level**: when a PO is created, each line's Required Date should default to the PO Date plus that item/location's Published Lead Time (not Average), with no shipping days added on top since lead time already covers that. Once set, it should never change.
2. **Header level**: the PO's own Required Date should be set once, to the latest of all its lines' Required Dates, and then stay put — even if a line's Expected Date changes later, or EDI updates something.

## What was built
Both pieces are done:
- New POs now get their line Required Dates calculated automatically — PO Date + Published Lead Time, falling back to Average Lead Time if Published isn't set (per your reply), and sliding forward to the next business day if the math lands on a weekend or a company holiday.
- The header Required Date is set once, to the latest line date, and locked in after that — later edits, EDI updates, or new lines added to the PO won't move it.

This only applies going forward, per what we agreed — existing open POs are untouched.

## What's been tested
We ran this against real POs in our test environment (not live) and confirmed:
- Line and header dates compute correctly on save
- Dates don't drift on re-saves, edits, or simulated EDI updates
- A new line added to an already-saved PO gets its own date without disturbing the header
- The fallback to Average Lead Time works when Published isn't set
- Weekend and holiday sliding both work correctly, including a case where two holidays fall back-to-back
- A PO with several lines, each on a different lead time, computes each one independently and the header correctly picks the latest

## Next step: user acceptance testing
Before this goes live, we'd like you (or whoever's best positioned on the Purchasing side) to create a few real-world test POs in our test environment and confirm the Required Dates come out the way you'd expect — different vendors, different lead times, maybe one you know should land on a weekend or holiday. Once you're comfortable it's behaving correctly, we'll move it to production.

Let us know if you'd like to walk through it together or if you'd rather test on your own first.
