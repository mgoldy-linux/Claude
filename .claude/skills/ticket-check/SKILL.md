---
name: ticket-check
description: Daily SysAid check - read the BusApps Open Tickets list in Chrome, flag tickets that need attention (New, overdue/due soon, awaiting reply too long, stale, new replies) and print a short summary. Read-only. Use when the user says "ticket check", "check my tickets", or "what needs attention in SysAid".
---

# Daily SysAid Ticket Check

A 5-minute morning triage of the **BusApps Open Tickets** view at
`https://allsurfaces.sysaidit.com/spaces`. **Read-only: never change a status, due date,
title, assignee, note, or anything else in SysAid.** Output is a short list in the terminal.
Nothing is posted, sent, or saved unless the user asks.

Tools: the Claude in Chrome tools (`mcp__claude-in-chrome__*`; load them in one ToolSearch call
and call `tabs_context_mcp` first). Work in a **new tab** and close it when done.

**Requirements:** Chrome running with the Claude extension connected, and signed in to SysAid
in that Chrome. SysAid does not have to be open already - the skill opens its own tab (on
10/8 the page loaded signed in with no tab open). If the login page appears, stop and tell the user.

## 1. Read the list (one page read - cheap)

1. Navigate a new tab to `https://allsurfaces.sysaidit.com/spaces`, wait ~8 s (the grid loads
   late; an early read returns headers only).
2. **The grid is virtualized - `get_page_text` is NOT reliable for the list.** On 10/8 it
   returned the IDs, statuses, requesters and assignees but **no Due Date values** and dropped
   the last row. Read the list from **screenshots** instead: take one, `scroll` down in the
   grid (scrolling is safe) in steps of ~3-5 ticks, and screenshot again until all rows
   (the "1 - N of N" count at the bottom) have been seen. The Due column shows e.g.
   `1d 9h 17m` (due in, yellow) or `-2d 22h 57m` (overdue, red); `Set Due Date` = none.
   Use `get_page_text` only to cross-check IDs/assignees.
3. Cross-check the count against the "All N" tab at the top.
4. The list has **no "last update" column**, so a ticket's last update needs step 3.

**Grid traps - learned the hard way:**
- The grid is **inline-editable**. Clicking a Status cell opens a status dropdown; clicking a
  Title cell turns it into an edit box. Never click cells in the grid. If one opens, press
  Escape and confirm nothing changed.
- Do not use the Jump-to-ID box (it did nothing). Open a ticket by URL instead:
  `https://allsurfaces.sysaidit.com/spaces/ticket?id=<ID>`.

## 2. Pick the tickets that need a closer look

Flag a ticket if **any** rule trips (from the list alone):

| Rule | Test |
|---|---|
| New | Status = New |
| Overdue | Due value starts with `-` |
| Due soon | Due within 2 days |
| Awaiting too long | Status = Awaiting user response (check the date in step 3) |
| Change requests | Skip type Change with no due date unless asked (43018, 43020 sit in approval) |

Ignore tickets that trip nothing. Say how many were skipped.

## 3. Open each flagged ticket (read-only)

For each flagged ticket: `navigate` to the ticket URL, wait ~8 s.

**Cost warning:** `get_page_text` on a ticket returns the *entire* journey, including every
quoted email thread. On 56558 that was ~8k tokens for one ticket. So **take a screenshot first**:
the Journey pane shows the newest entries (status change, due-date change, who, when) and that
is usually enough for "last update". Use `get_page_text` only when a reply's sender or content
is needed, and only for that ticket. Journey entries load late - wait a few more seconds and
re-screenshot if only a spinner or one entry shows.

From the Journey pull out:
- **Last update**: the newest dated entry, who made it, and what it was.
- **New reply**: the newest entry from someone other than the user (a Guest User entry or
  an incoming email) that is newer than the last entry made by the assignee.
- **Awaiting age**: when the status changed to Awaiting user response.

Change records show their Journey on a separate tab; skip them unless the user asks.
`get_page_text` can return a partly loaded journey - the newest entries are at the top and
are reliable, older ones may be missing.

Add these flags from the journey:
- **Stale**: In progress with no entry for 7+ days.
- **Waiting 5+ days**: Awaiting user response for 5 or more days.
- **Reply waiting**: new reply since the assignee last acted.

## 4. Print the summary

Keep it short. One line per flagged ticket, most urgent first:

```
SysAid check - <date>   <N> open, <M> flagged, <K> fine

OVERDUE
  56362  Handling Dropped Items in EDI 832 - Chad - New, P2, 2d over. No update since 10/6.
DUE <= 2 DAYS
  56558  Lost bin problem - Mark - due 1d. REPLY WAITING (Teresa 10/8 7:04a).
NEW
  ...
WAITING 5+ DAYS
  ...
STALE
  ...
```

- Group by the rule, put each ticket once (the most urgent group).
- Say who owns it. Default the focus to the user's (Mark Goldyn's) tickets and show the
  team's tickets in a second block labelled "Team".
- End with one line: the tickets that most need action today, no more than 3.

## 5. Do not

- Do not edit anything in SysAid. No status, due-date, note, or assignee changes.
- Do not send email or post a SysAid message. If the user wants a reply drafted, they will ask.
- Do not open every ticket - only the flagged ones. Reading one ticket takes about a minute.
- Do not leave the tab open: close the tab you created.

If the extension is not connected, or the page asks for a login, stop and tell the user -
do not retry.

## Optional (only if the user asks)

- Update the weekly sheet `C:\_P25\Data-Out\Excel\Weekly-SysAid-Review-<date>.xlsx`
  (tab per week, e.g. `Oct 08`): keep Mark's notes, refresh Status / Due / Last update.
- Add a Work-Log entry (use `/log-task`).
