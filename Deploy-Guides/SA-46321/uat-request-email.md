To: Jere, Pamela, Mike Learned, Chad
Subject: SA 46321 — PO Required Date — Ready for User Acceptance Testing in P21Play

Hi all,

The PO Required Date rule (SA 46321) is built and fully tested on our side — it's live in **P21Play** now and ready for your review before we move it to production.

**Quick recap of what it does:**
- Each PO line's Required Date is now set automatically to PO Date + that item/location's Published Lead Time (falling back to Average Lead Time if Published isn't set), sliding forward if the math lands on a weekend or company holiday.
- The PO header's Required Date is set once, to the latest of all its line dates, and then locked — it won't drift from later edits, EDI updates, or new lines.
- Applies to new POs/lines going forward only — existing open POs are untouched.

**Mike** — could you coordinate the testing below across the team and let us know once everyone's had a chance to go through it?

**Recommended tests:**

*Chad — EDI-driven POs:*
- Create/receive a PO via EDI and confirm the Required Date computes correctly on both the line(s) and the header, same as a manually entered PO.
- After that initial computation, trigger a subsequent EDI update to the PO (e.g. an Expected Date change) and confirm the Required Date does **not** move.

*Pamela — manual PO creation:*
- Create a few real-world test POs by hand in P21Play across different vendors/items, and confirm the Required Dates come out as expected.
- If you know of any items with a lead time that would land on a weekend or a company holiday, that's a good one to include — the date should slide to the next business day.
- Try a PO with multiple lines that have different lead times, and confirm each line gets its own date and the header picks up the latest one.
- Edit something on an already-saved PO (an Expected Date, add a new line) and confirm the header Required Date doesn't change.

*PORG testing:*
- Confirm a PO created through PORG gets its Required Date computed correctly on both the line(s) and the header, the same as a manually entered or EDI-created PO.
- Confirm a later PORG-driven update to the PO doesn't move the Required Date once it's set.

Are there any other tests we're missing, based on how POs actually get created and updated day to day? You all know the real-world PO paths better than we do, so flag anything we haven't covered above.

**Jere** — once the above is confirmed, we're ready for your sign-off to move this to production.

Let us know if anything looks off or doesn't match expectations — happy to walk through it together if that's easier.

Thanks,
Mark
