# SA 47981 — Item Description on WWMS Sales Order Picking — Status Update (2026-07-21)

**Status: On hold / needs a different approach.**

## What was requested
Show the item's **description** next to the Item ID on the WWMS (warehouse) Sales Order Picking screen. Today pickers see only the Item ID, not what the item actually is.

## Where things stand
We got the **data half working**: the system can correctly find the right item description for each pick line and hand it to the screen. We confirmed this repeatedly — the correct description is retrieved every time.

The blocker is the **display half**: the Prophet 21 WWMS handheld/picking screen does not provide a supported way to place a new custom field on that particular screen. We tried every available tool the P21 customization menu offers for this screen, and none of them can make a new description field actually appear there:

- One method gets the description into the screen's data but the screen won't show it in a custom box.
- Another method can look up the description but only "attaches" its result to an existing field, not to a new one, and only runs at moments when the pick line isn't loaded yet.
- The event-based method has no trigger for "a pick line was just displayed," so it can't run at the right time.

In plain terms: **the description is ready and correct — Prophet 21 just won't let us paint it onto this specific screen using the built-in customization tools.**

## Why we're pausing
We've reached the limit of what can be done with the standard P21 customization tools on this screen. Continuing to try variations of the same tools is unlikely to succeed and would burn more time.

## Recommended next step
Open a question with **Epicor / Prophet 21 support**: *"What is the supported way to display a custom column (item description) on the WWMS Sales Order Picking screen?"* This screen appears to require a type of customization (an RF-screen change) that isn't exposed through the normal business-rule menu we have access to. Epicor can confirm whether it's possible and how.

## Effort protection
All work, findings, and the exact technical dead-ends are documented internally, so if this is revisited (by us or Epicor), no time is lost re-discovering what we already learned. Nothing is left running that affects live picking.
