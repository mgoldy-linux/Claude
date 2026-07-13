---
name: wrapup
description: End-of-session wrap-up — append the session to the daily tasks log, refresh the deploy guide and memory if anything changed, then commit. Use when the user says wrap up, log this, or we're done for the day.
---

# Session Wrap-Up

Close out the session so it survives into the performance review and the next session. Work through these in order.

Do **not** invent progress. Only record what actually happened. If something was left broken, unverified, or parked, say so — a wrap-up that overstates status is worse than none.

## 1. Append to the daily tasks log

File: `C:\_P25\Daily-Tasks-Summary.md` (running accomplishments log, used for the performance review).

- Append; never rewrite existing entries.
- Start a new `## YYYY-MM-DD` section if today's isn't there yet. If it is, add a `###` subsection under it.
- Head each work item with the **ticket number** (`### SA 48732 — <short title>`) when there is one.

Write it so it's useful to someone six months from now who wasn't here. That means **decisions and reasoning, not a diff summary**:

- What was asked, and what was actually found (these often differ — say so when they do).
- Decisions taken **and why**, including options rejected and the evidence that rejected them.
- Hard numbers where they exist — row counts, logical reads, before/after.
- Traps discovered, so they aren't re-hit.
- **Status**, honestly: deployed / verified / pending UAT / parked / blocked, and on what.

## 2. Update the deploy guide

If the session produced or changed a deployable artifact (view, business rule, portal `.srd`, report, script), its guide in `C:\Claude\Deploy-Guides\` must reflect reality — not the plan.

- One markdown per ticket; start from `_TEMPLATE.md`.
- Update the row in `Deploy-Guides/README.md` with the current status.
- Make sure deploy **order** and **rollback** are right. If a view now backs a `.srd`, the view deploys first.

## 3. Update memory

`C:\Users\mgoldyn\.claude\projects\C--Claude\memory\`

- **Session/project file** — current state and where to resume.
- **New `feedback` memory** for any durable lesson (a trap, a convention, a "never do X again").
- Add the one-line pointer to `MEMORY.md`.
- Prefer updating an existing file over creating a near-duplicate.

## 4. Commit

- Stage the work; don't sweep in unrelated modified files. Check `git status` first and say what you're leaving out.
- Write a message that explains **why**, not just what. The commit is the durable record — the reasoning belongs in it.
- Follow the repo convention: end with `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- Branch first if on the default branch and the change warrants it. Do not push unless asked.

## 5. Report back

Lead with status. Then:
- What was written where (daily log, guide, memory) and the commit SHA.
- **What is still open** — the next action, and anything blocked on someone else.
- Anything you could not verify, stated plainly.
