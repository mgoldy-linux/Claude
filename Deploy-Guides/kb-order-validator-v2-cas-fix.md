# Deployment Guide — kb_Order_Validator_v2 CAS / security-transparency fix (v1.0.1.0 → v1.0.2.0)

> Produced during development 2026-08-31. Interim fix that keeps the `kb_`-named rule
> running; the full `asi_` rebuild is Phase 2 (`project_2026_06_23_kb_order_validator_v2.md`).

## Artifact(s)
- `kb_Order_Validator_v2.dll` **v1.0.2.0** — P21 business-rule assembly bundling two rules:
  - `kb_Order_Validator_v2` — synchronous, before-save order validator (`w_order_entry_sheet`, `apply_during_save_flag='Y'`, `run_type_cd 3424`)
  - `kb_Order_Workflow_v2` — asynchronous after-save note writer
- Source project: `C:\Business_Rules\JetBrains-Export\kb_Order_Validator_v2\` (NOT in the C:\Claude repo — repo holds a reference copy at `CSharp\kb_Order_Validator_v2.cs`)
- No ticket (folds into the BR-cleanup backlog; unblocks the SA 52768 / 6-23 `asi_` migration)

## What changed and why
`kb_Order_Validator_v2.Execute()` calls `Atlas.CrownSurcharge5011348.Utility.GetP21Context()` when
`kb_fnt_br_order_validator_v2` returns `atlas_surcharge_on = 'Y'`. The **v1.0.1.0** rebuild
(JetBrains-export project, 2026-06-24 deploy-mechanics test) shipped with
`[assembly: AllowPartiallyTrustedCallers]` and TFM v4.8. The working **v1.0.0.0** has **neither**
attribute. Under .NET Framework 4's default **Level 2** security-transparency model, APTCA forces
every method in the assembly `SecurityTransparent`, and a transparent method may not call the
implicitly-`SecurityCritical` Atlas method → `System.MethodAccessException` on every order that
hits the surcharge branch (logged to `business_rule_log`, `rule_name = 'kb_Order_Validator_v2'`).

**Fix** — `AssemblyInfo.cs`:
```csharp
using System.Security;
...
[assembly: SecurityRules(SecurityRuleSet.Level1)]   // legacy CAS model: full-trust methods
                                                    // are effectively critical, may call Atlas
// (no [assembly: AllowPartiallyTrustedCallers])
[assembly: AssemblyFileVersion("1.0.2.0")]
[assembly: AssemblyVersion("1.0.2.0")]
```
Rebuilt with VS2022 MSBuild:
`MSBuild kb_Order_Validator_v2.csproj -p:Configuration=Release -p:ReferencePath="C:\Business_Rules\References"`
Output verified: v1.0.2.0, **no APTCA**, `SecurityRules(Level1)` present, TFM v4.7.2 (matches the
working original and the `Atlas.CrownSurcharge5011348` dep's v4.7).

## Target environments
- **P21BusinessRules (BRR)** — DONE 2026-08-31, verified.
- **P21Play, P21Dev, P21Training** — pending. Same stale v1.0.1.0 DLL is active in all three
  (`business_rule` rule active, identical 2026-02-01 mod date).
- **Prod** — do **not** deploy blind. First confirm which version Prod runs
  (`\\asp21fs1.ahi.local\Prod\BusinessRulesDLL\kb_Order_Validator_v2.dll` file version). If Prod
  still has v1.0.0.0 it is unaffected and needs nothing until the Phase 2 `asi_` build.

## Dependencies & deploy order
No DB objects change. `business_rule` binds the rule by DLL **name**, not version — a same-name
version bump needs only file-replace + middleware recycle, no Rule Manager re-registration.

## Deploy steps (per environment)
1. Copy the built `bin\Release\kb_Order_Validator_v2.dll` (v1.0.2.0) to the env's rule-DLL share,
   e.g. `\\asp21fs1.ahi.local\BusinessRules\BusinessRulesDLL\` for BRR. Save the existing file
   aside first (BRR backup was renamed `kb_Order_Validator_v2_kb.dll`).
2. **Recycle the middleware app pools** on the env's middleware host (BRR = **AHI-API1**) — the
   P21 SOA / UIServer worker process caches loaded rule assemblies; the file swap alone does
   nothing. Elevated PowerShell on the host:
   ```powershell
   $appcmd = "$env:windir\System32\inetsrv\appcmd.exe"
   & $appcmd list apppool /text:name |
     Where-Object { $_ -like 'API-P21BusinessRules - P21 SOA*' } |
     ForEach-Object { & $appcmd recycle apppool /apppool.name:"$_"; "recycled: $_" }
   ```
   (`WebAdministration` module / `IIS:` drive was not present in that session — `appcmd` is
   dependency-free. Adjust the `API-<env> - P21 SOA*` prefix per environment.)

## Verification
- Create an order that hits the surcharge branch (NORMAL-credit customer + stock item is enough —
  `atlas_surcharge_on` is conditional). Fastest: `Postman\P21-V2Transaction-Orders-BRR.postman_collection.json`
  request **`2 - Create Order`** → expect `<Status>Passed</Status>`, `<Succeeded>1</Succeeded>`,
  a real `order_no`. BRR proof: **order 6109022**, 2026-08-31.
- `SELECT TOP 5 date_created, rule_name FROM business_rule_log WHERE rule_name = 'kb_Order_Validator_v2' ORDER BY business_rule_log_uid DESC`
  → no new `Error` rows after the deploy.
- The error text's `Assembly '... Version=x.x.x.x'` token is the litmus if it still fails —
  `1.0.1.0` = the recycle didn't take or a second copy is being loaded (check the env's
  `BusinessRulesDistribution` folder).

## Rollback
1. Restore the previous DLL: on BRR, copy `kb_Order_Validator_v2_kb.dll` back over
   `kb_Order_Validator_v2.dll` (or restore the env's saved-aside copy).
2. Recycle the same app pools (step 2 above).
- Reverts to v1.0.1.0 — i.e. back to the `MethodAccessException` on surcharge orders, but no
  worse than pre-fix.
