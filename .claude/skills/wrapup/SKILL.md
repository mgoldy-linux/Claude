---
name: wrapup
description: End-of-session wrap-up — append the session to the daily tasks log, refresh the deploy guide and memory if anything changed, draft starter queries/questions for tomorrow's open items, then commit. Use when the user says wrap up, log this, or we're done for the day.
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

## 2. Update the Work Log

File: `C:\Claude\Work-Log.md` — the at-a-glance task register (newest first, one row per task).

- Find the **existing row** for this task and update it in place — do **not** append a new row per session.
- Set the **Status** honestly (🟡 awaiting feedback/testing · 🔵 in progress · ⏸ parked · 🔴 blocked · 🟢 done)
  and rewrite the "Where it stands / next step" cell so a reader knows exactly where to pick up.
- When a task is accepted/shipped, **move it** from the Active table down to Completed.
- If it's a brand-new task with no row yet, add one at the top of the Active table.
- Keep the `Detail` cell pointing at the memory file that has the full story.

## 3. Update the deploy guide

If the session produced or changed a deployable artifact (view, business rule, portal `.srd`, report, script), its guide in `C:\Claude\Deploy-Guides\` must reflect reality — not the plan.

- One markdown per ticket; start from `_TEMPLATE.md`.
- Update the row in `Deploy-Guides/README.md` with the current status.
- Make sure deploy **order** and **rollback** are right. If a view now backs a `.srd`, the view deploys first.

## 4. Update P21-Env-Status-Customizations.txt

File: `C:\Claude\Docs\P21-Env-Status-Customizations.txt` — per-environment mirror of the
"Customizations / Open Items" the user hand-copies into OneNote.

If the session added, changed, or closed a customization in any P21 environment (SQL,
business rule, portal, DynaChange, view, user setup, alert, etc.), update the matching
environment section:

- Keep the STANDARD FORMAT: `<short title> - <detail>  [STATUS]`, STATUS one of
  OPEN | IN TEST | ON HOLD | BROKEN | DONE | RETIRED | REFERENCE.
- Update the existing line in place if the item is already tracked there; otherwise add a
  new line at the bottom of the correct environment's section.
- Bump the `Last updated:` date at the top of the file.
- If nothing environment-facing changed this session, skip this step — don't add a line for
  its own sake.

## 5. Update memory

`C:\Users\mgoldyn\.claude\projects\C--Claude\memory\`

- **Session/project file** — current state and where to resume.
- **New `feedback` memory** for any durable lesson (a trap, a convention, a "never do X again").
- Add the one-line pointer to `MEMORY.md`.
- Prefer updating an existing file over creating a near-duplicate.

## 6. Draft tomorrow's starters

File: `C:\_P25\Tomorrow-Starters.md` — **overwrite** it each run; this is a scratch list for
the next morning, not an accumulating log (`Daily-Tasks-Summary.md` is the permanent record).

Walk Work-Log's Active table plus anything in `Lists\Todo-BusApps.md` / `Lists\Todo-Private.md`
that isn't tracked there yet. For each item with a clear next action, draft one concrete
starting point — not a status recap:

- A specific, paste-ready SQL query (a few lines) when the next step is "find out X"
- A specific question when the next step is "ask Y" or "decide Z"
- Skip items with no clear next action rather than forcing one

Keep each entry to 2–4 lines: item name, the starter itself, and the memory `project_*` file
to open for full context. Note at the top of the file: **these are starting points to skim and
adjust, not a queue — check for anything urgent first.**

## 7. Commit

- Stage the work; don't sweep in unrelated modified files. Check `git status` first and say what you're leaving out.
- Write a message that explains **why**, not just what. The commit is the durable record — the reasoning belongs in it.
- Follow the repo convention: end with `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- Branch first if on the default branch and the change warrants it. Do not push unless asked.

## 8. Report back

Lead with status. Then:
- What was written where (daily log, guide, customizations tracker, memory, tomorrow's starters) and the commit SHA.
- **What is still open** — the next action, and anything blocked on someone else.
- Anything you could not verify, stated plainly.
