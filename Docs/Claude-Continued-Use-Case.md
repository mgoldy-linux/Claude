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

## A Concrete Example: Claude vs. Microsoft Copilot

Ran the identical, plain-language request past both tools, side by side, on this laptop:

> *"Please look at `C:\Users\mgoldyn\OneDrive - All Surfaces Inc\Documents` — recommend a folder to move the files in the root folder to the sub folder."*

**Claude Code** read the folder and returned a table matching every loose root file to an existing topical subfolder, with a one-line reason for each — e.g., `business_rules_curriculum.md` → **Business Rules** ("Exact topical match — folder already holds Business Rule docs/notes"), `P21 TRAINING - Location-Supplier Item Order Cycle...xlsx` → **P21** ("Same naming/content pattern as existing P21 folder xlsx files"). Immediately usable output.

**Microsoft Copilot**, given the exact same request on the same machine, against a OneDrive folder — a Microsoft product — responded: *"I can't directly access folders on your computer, including: C:\Users\mgoldyn\OneDrive - All Surfaces Inc\Documents."* No attempt made.

This wasn't a contrived test — it's the kind of small, everyday task Claude actually gets used for. Two things worth drawing from it:
1. It's a real capability gap between AI tools already present in the org's toolset today — not something unique or novel about Claude.
2. It's a live example of the access model described below: Claude reading this folder isn't a hidden or automatic capability — it happened because I asked, in that session, and it's scoped to files I (mgoldyn) already have access to. Nothing Copilot couldn't also reach if it chose to attempt it.

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

1. **Commercial/API and Team/Enterprise usage is not used to train Anthropic's models by default** — this is documented in Anthropic's commercial terms, and is a different (stricter) default than the consumer claude.ai Free/Pro/Max tier's retention policy.
2. **Checked directly, 2026-08-21: this login is a personal Pro plan, not Team/Enterprise.** Under Anthropic's Aug 2025 consumer-terms update, Free/Pro/Max chats and coding sessions are eligible for model training by default (retained up to 5 years) unless the account's "Help improve our AI models" toggle (`claude.ai/settings/data-privacy-controls`) is switched off. Checked it directly — as of 8/21 it was **switched on**. This is a real, concrete gap, not a hypothetical.

**Recommended action, two parts:**
- **Immediate:** switch "Help improve our AI models" off on this account. One click, fully reversible, closes the training/retention exposure today.
- **Durable:** move this work to a Claude Team or Enterprise seat with a signed DPA. A personal privacy toggle isn't an IT-auditable, contractual control — an org-provisioned plan is, and it also unlocks admin console visibility, SSO, and audit logs that a Pro account doesn't have.

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
| What's the actual open item? | Confirmed this login is Pro (consumer), training toggle was on — switch it off immediately, then move to a Team/Enterprise seat with a DPA for a durable, IT-managed control |
