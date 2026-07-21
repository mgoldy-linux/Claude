# SA 47981 — Item Description on WWMS Sales Order Picking — Status Update (2026-07-21)

**Status: Working — final polish and one quick test remain.**

## What was requested
Show the item's **description** next to the Item ID on the WWMS (warehouse) Sales Order Picking screen. Today pickers see only the Item ID, not what the item actually is.

## Good news — it works
We got the description to **appear on the picking screen.** In testing, item `CRA197` correctly displayed **"Crain 197 "Comfort Knees" Knee Pads"** in a new field on the screen. (We have a screenshot on file.)

An earlier update said this might not be possible without help from Prophet 21's vendor (Epicor). **That is no longer the case** — we found the piece that was missing and the description now shows up. No outside support is needed.

## What was actually going on
The description was always being looked up correctly. The only problem was **timing** — the screen was being told the description *before* it knew which item the picker was on, so it came up blank. Once the picker selects a bin, the screen refreshes with the item loaded, and at that moment the description fills in correctly. So the feature works; we just need to make sure it fills in at the most useful moment for the picker.

## The one thing left to check
We need to confirm **when** the description appears as a picker moves through a pick ticket:

- If it fills in automatically for **every line** as the picker advances — we're essentially done.
- If it only fills in **after the picker selects a bin** — we'll add a small action (a button) so the description shows up **before** the bin step, when it's most useful for deciding the pick.

This is a quick test on the picking screen, then a small adjustment if needed.

## Recommended next step
Run the pick-through test above and confirm the timing. Depending on the result, either close the ticket as-is or add the button, then move to the live environment.

## Notes
All work and findings are documented internally. Nothing left running affects live picking — this is all in the test/business-rules environment.
