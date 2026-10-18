---
name: log-task
description: Quickly log something you did yourself (not through a Claude session) into Work-Log.md. Use when the user says "log this", "add this to the work log", or describes a task they finished/started on their own that they want tracked.
---

# Log a Self-Done Task

Fast path for getting a task the user did **on their own** into `C:\Claude\Work-Log.md`, without
the full `/wrapup` ceremony (no daily-tasks-summary append, no deploy guide, no memory pass, no
commit). This is for tracking, not session close-out.

Do **not** invent detail. Only record what the user actually tells you.

## 1. Get the essentials

If the user's message doesn't already give you these, ask briefly:
- **What** was done (short title).
- **Status** — is it finished, or still in progress/parked?
- Anything worth a one-line note (why, what's next, a gotcha hit).

Don't interrogate for a full write-up — this command exists because it's supposed to be fast.

## 2. Flag kb_/js_ if mentioned

If the task description references `kb_` or `js_` objects, flag it per
[[feedback_flag_kb_js_and_perf]] the same as any other touched code — even here, even briefly.

## 3. Write the row

Open `C:\Claude\Work-Log.md`.

- **Finished** → add a row to the **Completed** table (top of the table = newest), columns
  `Date | Task | Detail`. Use today's date. Leave `Detail` blank (or a file path if the user
  named one) — don't fabricate a memory file reference that doesn't exist.
- **Still in progress / parked** → add a row to the **Active** table (top = newest), columns
  `Last touched | Task | Status | Where it stands / next step | Detail`. Pick the status emoji
  from the key at the top of the file (🟡🔵⏸🔴🟢).
- If a row for this task **already exists** (self-done follow-up on something already tracked),
  update that row in place — don't duplicate it.

## 4. Don't touch anything else

No daily-tasks-summary append, no deploy guide, no memory write, no git commit. If the user
wants any of those too, they'll ask — or point them at `/wrapup` for the full version.

## 5. Confirm

One line: what row you added/updated and where (Active vs Completed).
