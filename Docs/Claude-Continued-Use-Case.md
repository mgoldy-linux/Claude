# Continued Use of Claude at AllSurfaces — Business Case & Data-Security Overview
**Date:** 2026-08-21
**Prepared by:** Mark Goldyn
**Trigger:** 2026-08-20 claude.ai/Claude Desktop black-screen ticket to IT (Tony Neuman) turned out to be a security-proxy issue, not a device fault; while resolving it, IT raised a broader question about what data Claude can see. This doc lays out what Claude is actually used for, what it can and can't access, and what controls are already in place, so IT can make an informed call rather than a default "block it" call.

---

## What Claude Is Being Used For

Claude Code / Claude Desktop is used as a development and diagnostic tool against the P21 ERP environment — the same category of tool as SSMS, PowerShell ISE, or Visual Studio, not a customer-facing or data-processing service. Recent concrete output:

| Item | What it delivered |
|---|---|
| EDI 855 view fix (SA-49504) | Deployed to Prod, resolved a live order-acknowledgment defect |
| KB/JS retirement initiative | Ongoing 2026 goal — auditing and replacing legacy objects owned by departed employees (`kb_`/`js_` prefix) |
| Low Margin Alert + PAD | Built and deployed an automated margin-exception alert system |
| Portal cleanup initiative | 2026 goal — removing stale/orphaned portal elements, tracked against a 6/30 target |
| SSRS performance work (Five Way report, etc.) | Measured, DMV-based query rewrites — logical-reads/CPU reductions, not guesswork |
| User-provisioning automation | `asi_proc_copy_p21_user` rollout and deleted-users sync across all 6 environments |

This is internal engineering work on AllSurfaces' own ERP codebase and infrastructure — the kind of work that was happening anyway, done faster and with better documentation because Claude is in the loop.

---

## What Data Claude Can Actually See

**No standing access of its own.** Claude Code runs locally on my laptop under my own Windows/AD identity. It has no service account, no stored database credentials, and no VPN or network access that I don't already have. Every SQL connection it makes uses the same SQL logins and AD permissions already granted to me for this job — it cannot reach anything I couldn't already reach with SSMS or PowerShell.

**What it does see, in the course of normal work:**
- SQL query text, table/view schema, and C# business-rule source code — none of this is customer PII, it's AllSurfaces' own internal logic and structure.
- Query *result sets* when I run a diagnostic query through it — this can include order, item, or customer records when a Prod issue specifically requires looking at Prod data to diagnose it. Where a fix can be developed and tested against non-Prod (P21Play, P21Dev, P21Training), that's the default; Prod is used only when the issue is Prod-specific.

**What it will never do:** enter passwords, API keys, or account credentials anywhere; create accounts; or send data to any destination other than Anthropic's own API and the tools I explicitly point it at. This is a hard rule the tool enforces on every session, not a policy I have to remember to follow.

**Network path:** all of this traffic already flows through AllSurfaces' existing security stack — the same SWG/proxy that was 403-blocking claude.ai's assets on 8/20. Nothing about how Claude is used bypasses IT's existing visibility or DLP controls; if anything, this incident proved that stack is inspecting Claude's traffic already.

---

## Vendor Security Posture (for IT to verify directly, not take my word for)

Anthropic publishes its security and compliance documentation at **trust.anthropic.com**, including its SOC 2 Type II report, sub-processor list, and data-handling commitments. Two points worth IT confirming directly against that source rather than my summary:

1. **Commercial/API and Team/Enterprise usage is not used to train Anthropic's models by default** — this is documented in Anthropic's commercial terms, and is a different (stricter) default than the consumer claude.ai Free/Pro tier's retention policy.
2. **Which plan AllSurfaces is actually on matters.** If this account is a personal/consumer login rather than a Team or Enterprise plan with a signed data-processing agreement, that's a real gap worth closing — not because anything has gone wrong, but because it's the cleanest way to get contractual guarantees (zero/limited retention, no training use, audit logs, admin-level controls) instead of relying on default policy.

**Recommended action:** confirm which Anthropic plan this login is under, and if it's not already Team/Enterprise, that's the actual lever to pull for stronger guarantees — not blocking the tool.

---

## Context on the 8/20 Incident

Worth noting: the black-screen wasn't IT choosing to block Claude — it was a local security-proxy 403-ing Claude's asset bundles as a side effect of a broader policy (likely HVCI/GPO-related), not a deliberate decision to restrict this specific tool. By contrast, Gemini on the same machine shows an explicit "blocked by your administration" message — proof that when AllSurfaces *does* intend to block an AI tool, it already has the mechanism to do so cleanly. Claude's outage was accidental collateral, not policy.

---

## Proposed Guardrails Going Forward

If IT wants tighter controls without removing access entirely:
- Confirm/move to a Claude Team or Enterprise plan with a signed DPA and defined data-retention terms.
- Default to non-Prod environments (Play/Dev/Training) for development and testing; reserve Prod queries for issues that require it.
- No credentials ever entered into Claude (already enforced today).
- Existing SWG/proxy continues to have full visibility into this traffic — no additional exception needed.

---

## Summary for Leadership

| Question | Answer |
|---|---|
| Does Claude have its own access to P21 or AllSurfaces systems? | No — it only uses my existing, already-approved AD/SQL permissions |
| Does it ever see customer data? | Only in query results, when diagnosing a Prod-specific issue; non-Prod is the default |
| Does it ever handle credentials? | No — hard rule, enforced every session |
| Is traffic visible to IT's existing security stack? | Yes — same SWG/proxy path as everything else |
| What's the actual open item? | Confirm the Anthropic plan tier (Team/Enterprise vs. consumer) and get a DPA in place if not already |
