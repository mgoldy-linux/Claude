# P21.Extensions.BusinessRule SDK — Class-by-Class Analysis

**Source:** `C:\Business_Rules\JetBrains-Export\P21.Extensions\BusinessRule\` (JetBrains/dotPeek decompile of `P21.Extensions.dll`, Assembly Version 2.0.0.0)
**Analyzed:** 2026-08-10
**Why this matters:** every `asi_*` C# business rule (e.g. `ASI_IM_Gen_Discontinued_Check.cs`) compiles against these types. This is Epicor's own SDK, not our code — nothing here is `kb_`/`js_`-prefixed, so the standing kb_/js_ retirement flag does not apply to this folder. Nothing here should be edited; it's documented for reference when writing or debugging our rules.

## Terminology note

You asked "how we call the function" for each file. Most of these aren't standalone functions — they're **classes**. There are three different calling patterns in this SDK, and it matters which one applies to a given file:

1. **You inherit from it.** Only `Rule` — your business rule class (e.g. `ASI_IM_Gen_Discontinued_Check`) extends `P21.Extensions.BusinessRule.Rule` and overrides its abstract members.
2. **You use it via `this.Data...` / `this.Session` / `this.Log` inside `Execute()`.** Most of the "Data*" and "Response*" classes fall here — P21 hands you an already-constructed instance; you call methods/read properties on it, you never `new` it up yourself (with a couple of narrow exceptions noted below).
3. **P21's runtime uses it; you never touch it.** The `Rule*Host*`, `RuleWorker`, `RuleManager`, `RuleEntry*`, `RuleMetadataResult`, `ExecuteRuleRequest` classes are the plumbing that discovers your DLL, loads it into an AppDomain, and invokes `Execute()`. They're documented here for completeness/debugging (e.g. "why isn't my rule showing up in the picker") but a rule author never calls them.

---

## 1. Rule lifecycle — what you write against

### `Rule.cs` — **inherit from this**
Abstract base class every business rule extends. P21 calls `Initialize(xml, credentials)` (parses the inbound XML into `Data`/`Session`/`RuleState`/`Log`), then calls your override of `Execute()`, which must return a `RuleResult`.

Also exposes:
- `P21SqlConnection` — lazy-opened `SqlConnection` to the P21 database, for rules that need direct SQL (avoid unless the field-level API can't do it).
- `RulePopupService` — see below.
- `HideData`/`UnhiddeData` — wrap `P21.Extensions.DataAccess` encrypt/decrypt (used for things like storing tokenized values).

**Example (real, from `ASI_IM_Gen_Discontinued_Check.cs`):**
```csharp
public class ASI_IM_Gen_Discontinued_Check : P21.Extensions.BusinessRule.Rule
{
    public override RuleResult Execute()
    {
        RuleResult ruleResult = new RuleResult();
        string val = this.Data.Fields["ufc_inv_mast_ud_discontinued"].FieldValue;
        // ...
        return ruleResult;
    }
    public override string GetName() => "ASI_IM_Gen_Discontinued_Check";
    public override string GetDescription() => "...";
}
```
You never call `Initialize()` yourself — P21's `RuleWorker.ExecuteRule` does that.

### `RuleResult.cs` / `RuleResultData.cs` — **return this from `Execute()`**
`RuleResult` is what `Execute()` must return: `Success`, `Message` (shown to the user as a popup/warning), `Keystroke`, and optionally `ShowResponse`/`ResponseAttributes` to launch a custom response dialog. `RuleResultData` is the superset `RuleWorker` actually builds internally (adds `Xml`, `Data`, `MessageTitleOverride`) — you won't construct one of these yourself; `RuleResult` is what you hand back.

```csharp
RuleResult r = new RuleResult();
r.Message = "EDI Discontinued Date is blank...";
return r;
```

### `RuleState.cs` — **read via `this.RuleState`**
Read-only snapshot of *which* rule is executing and *why*: `Name`, `Type`, `ApplyOn`, `MultiRow`, `EventName` (e.g. "Form Datastream Created"), `TriggerWindowName`, `CascadeInProgress`, `IsCallbackRule`. Useful for a rule that behaves differently depending on trigger context.
```csharp
if (this.RuleState.EventName == "BeforeSave") { /* ... */ }
```

### `Session.cs` — **read via `this.Session`**
Read-only snapshot of the logged-in user/environment: `UserID`, `Server`, `Database`, `Language`, `ID` (session id), `RFLocationID`/`RFBinID` (WWMS scanner context), `ApplicationDisplayMode`, `ClientPlatform`.
```csharp
string user = this.Session.UserID;
string db   = this.Session.Database;   // useful to branch logic per-environment
```

---

## 2. Data access — reading/writing the fields on screen

### `DataCollection.cs` — **use via `this.Data`**
The central object. Wraps the inbound XML and exposes exactly one of three access modes depending on rule type (throws `ApplicationException` if you use the wrong one — this is the mechanism behind the memory note *"multi-row rules use `Data.Set` not `Data.Fields`"*):
- `Data.Fields` (`DataFields`) — single-row window/event rules.
- `Data.Set` (`System.Data.DataSet`) — multi-row rules (grids).
- `Data.XMLDatastream` — form rules (triggered on "Form Datastream Created").

Other members you'll actually call:
- `Data.TriggerTable` / `Data.TriggerColumn` / `Data.TriggerRow` / `Data.TriggerOriginalValue` — which field fired the rule.
- `Data.IsTriggerField(table, row, col)` / `IsTriggerTable` / `IsTriggerRow` — convenience guards.
- `Data.AddNewRow(tableName)` — add a grid row (multi-row rules; requires `allow_new_rows` to be set upstream).
- `Data.SetFocus(column)` / `SetFocus(column, rowID)` — move cursor after validation failure.
- `Data.SetCascade(...)` overloads — control whether a field change cascades to trigger other rules.
- `Data.GetFieldAttributes(table, col, rowID)` — metadata (title, read-only, alias) for multi-row fields.
- `Data.GetActiveRowForTable(tableName)` / `GetActiveRowIDForTable` — which grid row is currently selected.
- `Data.SetFieldUpdateOrder(columns)` / `UpdateByOrderCoded` — control the order fields are written back (matters when one field's setter depends on another already being applied).

```csharp
if (this.Data.IsTriggerField("inv_mast", 0, "ufc_inv_mast_ud_discontinued"))
{
    this.Data.SetFocus("ufc_inv_mast_ud_edi_discontinued_date");
}
```

### `DataField.cs` — **the object you read/write per field**
One field's value plus metadata. `FieldValue` get/set is *the* API for reading/writing a field — confirms the memory note *"Use `.FieldValue`, not `.Value`/`.ToString()`"*. Setting `FieldValue` marks `Modified = true` so P21 writes it back.
```csharp
string v = this.Data.Fields["ufc_inv_mast_ud_edi_updated"].FieldValue;
this.Data.Fields["ufc_inv_mast_ud_edi_updated"].FieldValue = "Y";
```
Other read-only metadata on the same object: `TableName`, `ColumnName`, `RowID`, `DataType`, `ReadOnly`, `FieldOriginalValue`, `AllowCascade`, `TriggerColumn`/`TriggerRow`.

### `DataFields.cs` — **the indexer behind `Data.Fields[...]`**
Collection wrapper you index three ways: by field name (`Data.Fields["column_name"]`, case-insensitive), by numeric position (`Data.Fields[0]`), or by full key (`Data.Fields[tableName, columnName, rowID]` — used in multi-row/grid contexts via `GetFieldAttributes`). Also `GetFieldByAlias(alias)` for `ufc_`-style user-defined column aliases. You don't construct this — `Data.Fields` returns it.

### `DataFieldAttributes.cs` — **returned by `Data.GetFieldAttributes(...)`**
Read-only metadata bundle (`Title`, `Name`, `Alias`, `DataType`, `ReadOnly`, `AllowCascade`, `Key`) for a specific field in a multi-row grid, where you can't index `Data.Fields` directly. Not something you construct — only consumed from `GetFieldAttributes`'s return value.

### `DataFieldKey.cs` / `DataFieldKeyEnumerator.cs` — **internal identity/iteration helpers**
`DataFieldKey` is the `(TableName, ColumnName, RowID)` triple used to identify a field in multi-row contexts; `DataFieldKeyEnumerator` lets `DataUpdateSequence` (below) be iterated with `foreach`. You'll encounter `DataFieldKey` as the `.Key` property on `DataFieldAttributes`, but you're not expected to `new` either of these up in rule code.

### `DataUpdateSequence.cs`
Indexable/enumerable list of `DataFieldKey`s representing the order fields were changed (either explicitly via `Data.SetFieldUpdateOrder` or implicitly tracked). Niche — only relevant if you need to inspect or reason about write order beyond just setting it.

---

## 3. Form/XML datastream — used only by "form rules"

### `XMLDatastream.cs` — **use via `Data.XMLDatastream`** (form rules only, e.g. order entry printable forms)
Wraps a `System.Xml.Linq.XDocument` representing a whole form (header/lines/totals structure: `FORMXXXDEF`/`HDRXXXXDEF`/`LINEXXXDEF`/`TOTALSXDEF`). Methods: `GetForms()`, `GetHeaders()`, `GetHeader(form)`, `GetLines()`/`GetLinesBy(elementName, value)`, `GetTotals()`, `GetGroup(groupName, fromElement)`, `AddGroup(...)`, `SortLines(...)`, `SortLineGroup(...)`.
```csharp
foreach (var line in this.Data.XMLDatastream.GetLines())
{
    var qty = line.Element("quantity")?.Value;
}
this.Data.XMLDatastream.SortLines("item_id", numeric: false, descending: false);
```
We have no `asi_*` form rules currently (all our rules are single-row/multi-row window/event rules per the memory notes), so this is likely unused today — flag if a form-triggered rule is ever built.

### `P21XDocument.cs` — **internal wrapper, not called directly**
Thin subclass of `XDocument` that guards `Save(filePath)` against invalid/nonexistent paths. `XMLDatastream.Document` returns the base `XDocument` view of it; you'd only touch `P21XDocument` directly if working at the raw datastream level, which none of our rules currently do.

---

## 4. Response / popup dialogs

### `ResponseAttributes.cs` / `RuleResult.ResponseAttributes` — **construct and attach to `RuleResult`**
Defines a custom response popup: `ResponseTitle`, `ResponseText`, `CallbackRule` (name of the rule to invoke when the user responds), `Fields[]`, `Buttons[]`, `CallbackDataTableName`.
```csharp
RuleResult result = new RuleResult();
result.ShowResponse = true;
result.ResponseAttributes = new ResponseAttributes(
    "Confirm Discontinue", "This item has open POs. Continue?", "ASI_IM_DiscontinueConfirm_Callback")
{
    Buttons = new[] { new ResponseButton("yes","Yes","Y"), new ResponseButton("no","No","N") }
};
return result;
```

### `ResponseField.cs` / `ResponseFieldType.cs` — **build the `Fields[]` array above**
`ResponseField` defines one input on a custom popup (`Name`, `Label`, `DataType`, `DataTypeLength`, optional dropdown values via `DropDownListDisplayValues`/`DropDownListDataValues`). `DataType` is constrained to the three constants in `ResponseFieldType`: `Alphanumeric` ("char"), `Numeric` ("long"), `Decimal` ("decimal") — passing anything else throws.

### `ResponseButton.cs` — **build the `Buttons[]` array above**
Simple `(ButtonName, ButtonText, ButtonValue)` triple for a response-dialog button.

### `DefinedResponseAttributes.cs` / `DefinedResponseWindowTypes.cs` — **specialized `ResponseAttributes` subclass**
For launching a *predefined* P21 response window instead of a custom one — currently only `EPFHOSTEDTOKEN` ("EPFHostedTokenPage", presumably an EFT/payment tokenization capture window) is supported; any other value throws. Adds `RequestString`/`ResponseString`. Niche — only relevant if a rule needs to launch that specific hosted-payment page.

### `RulePopupService.cs` — **use via `this.RulePopupService`**
Launches P21's built-in field lookup popups (the little magnifying-glass/search windows), not custom dialogs. `ShowPopup(fieldName)` or `ShowPopup(fieldName, additionalWhereClause)` to pre-filter the lookup.
```csharp
string selectedItemId = this.RulePopupService.ShowPopup("item_id", "class_type = 'C1'");
```

---

## 5. Rule discovery/hosting infrastructure — P21's runtime, not rule-author code

These exist so P21 can find your compiled DLL, list it in the business-rule picker, and invoke it. You'll never instantiate any of these in an `asi_*` rule — documented here mainly so that if a rule "isn't showing up" or throws a loader error, you know where to look.

### `RuleWorker.cs`
Does the actual work: scans a plugin folder for `*.dll`s (or, for `\InternalRules\`, reads an explicit `ruleDlls.txt` allow-list), reflects over each assembly for public, non-abstract classes deriving from `Rule`, and registers them as `RuleEntry` objects (`LoadRules`). `ExecuteRule(request)` looks up the rule by `RuleTypeName`, instantiates it, calls `Initialize()` then `Execute()`, and packages the result. Runs inside its own AppDomain via `MarshalByRefObject`.

### `RuleManager.cs`
The top-level entry point P21's client/server process talks to. `Initialize(pluginPath)`/`AddPath` register folders (internal rules under `\InternalRules\` vs. external plugin folders are tracked separately); `Init()` decides *how* to host external rules — in-process (`RuleHostSameDomain`), a separate AppDomain (`RuleHostSeparateDomain`, if `RunRulesInSeparateDomain=true` in config), or a remote rules service over HTTP (`RuleHostRemote`, if `RulesServiceURL` is configured). `InvokeRule(ruleTypeName, xml)` is what actually triggers a specific rule by name.

### `RuleHost.cs` (abstract) / `RuleHostSameDomain.cs` / `RuleHostSeparateDomain.cs` / `RuleHostRemote.cs`
Three strategies for the same `LoadRules`/`ExecuteRule`/`UnloadRules` contract:
- **SameDomain** — runs rules in the calling process's own AppDomain (fastest, least isolation).
- **SeparateDomain** — creates an isolated `AppDomain` ("BusinessRuleDomain") so a bad rule DLL can be unloaded/reloaded without recycling the whole process (relevant to the memory note about AHI-API1 stale cache — this is the mechanism an IIS app-pool recycle is resetting).
- **Remote** — POSTs JSON (`Newtonsoft.Json`) to `{RulesServiceURL}/api/rules`, `/api/rules/execute`, `/api/rules/unload` — for a rules microservice deployment topology we don't currently use.

### `RuleEntry.cs` / `RuleEntryValue.cs` / `RuleMetadataResult.cs` / `ExecuteRuleRequest.cs`
Plain data-transfer objects the above use internally: `RuleEntry` (full metadata incl. `PrivateRule` flag and file path — one per discovered rule class), `RuleEntryValue` (trimmed-down public view, presumably what populates the rule picker UI), `RuleMetadataResult` (the list of `RuleEntry` + any load errors from a `LoadRules` call — this is where "DLL didn't load" messages originate), `ExecuteRuleRequest` (the request payload passed into `ExecuteRule`).

### `PrivateRule.cs` — **attribute you *can* apply to your rule class**
`[AttributeUsage(AttributeTargets.Class)]` marker attribute. If present on a `Rule` subclass, `RuleWorker`/`RuleManager` exclude it from `GetRules()` (the picker list) while still allowing it to be invoked directly by name (e.g. as a `CallbackRule` target for a `ResponseAttributes` popup). This is the one piece of "infrastructure" code you would actually write:
```csharp
[PrivateRule]
public class ASI_IM_DiscontinueConfirm_Callback : Rule { ... }
```

---

## 6. Utility

### `LogString.cs` — **use via `this.Log`**
Simple rolling file logger, capped at `MaxFileMb` (default 1MB), writing to `{assembly path}\logs\{RuleClassName}.log`. `Add(msg)` buffers in memory; `AddAndPersist(msg)` writes immediately; `Persist()`/`Clear()` round it out.
```csharp
this.Log.AddAndPersist($"Discontinued check fired for item {itemId} at {DateTime.Now}");
```
**Flag:** this is a *different* logging mechanism than our established convention — per memory, `asi_*` rules log errors to the `business_rule_log` SQL table, not `kb_table_br_error_log` or a file. `LogString` writes to a flat file per rule class on the app server's local disk, which nobody centrally monitors and isn't queryable across environments. Fine for local ad-hoc debugging during development, but don't use it in place of the `business_rule_log` SQL insert for anything that needs to be reviewed later — file logs on AHI-API1/AHI-API2 aren't in any of our routine review scripts.

---

## Summary table

| File | Category | Called by rule author? |
|---|---|---|
| Rule.cs | Base class | Yes — inherit |
| RuleResult.cs | Return type | Yes — construct & return |
| RuleResultData.cs | Internal superset | No |
| RuleState.cs | Context | Yes — read `this.RuleState` |
| Session.cs | Context | Yes — read `this.Session` |
| DataCollection.cs | Data access | Yes — `this.Data` |
| DataField.cs | Data access | Yes — via indexer |
| DataFields.cs | Data access | Yes — `Data.Fields[...]` |
| DataFieldAttributes.cs | Data access | Yes — via `GetFieldAttributes` |
| DataFieldKey.cs | Internal helper | Rarely direct |
| DataFieldKeyEnumerator.cs | Internal helper | No |
| DataUpdateSequence.cs | Data access (niche) | Rarely |
| XMLDatastream.cs | Form rules only | Yes, if form rule |
| P21XDocument.cs | Internal wrapper | No |
| ResponseAttributes.cs | Popup UI | Yes — construct |
| ResponseField.cs | Popup UI | Yes — construct |
| ResponseFieldType.cs | Popup UI constants | Yes — reference |
| ResponseButton.cs | Popup UI | Yes — construct |
| DefinedResponseAttributes.cs | Popup UI (niche) | Rarely |
| DefinedResponseWindowTypes.cs | Popup UI constants | Rarely |
| RulePopupService.cs | Lookup popups | Yes — `this.RulePopupService` |
| LogString.cs | Logging | Yes — `this.Log` (see flag above) |
| PrivateRule.cs | Attribute | Yes — `[PrivateRule]` on callback rules |
| RuleWorker.cs | Runtime infra | No |
| RuleManager.cs | Runtime infra | No |
| RuleHost.cs / *SameDomain / *SeparateDomain / *Remote | Runtime infra | No |
| RuleEntry.cs / RuleEntryValue.cs / RuleMetadataResult.cs / ExecuteRuleRequest.cs | Runtime infra DTOs | No |

## Performance note

Nothing here is SQL, so the usual "measure logical reads via plan-cache DMVs" guidance doesn't apply. The one perf-relevant observation: `RuleWorker.LoadRules` does a full `Assembly.LoadFile` + reflection scan over **every DLL** in each plugin folder on every load (not cached beyond the current AppDomain's lifetime), and `RuleHostSeparateDomain.LoadRules` tears down and recreates the entire AppDomain each time it's called — consistent with the memory note that AHI-API1 caches this at the IIS app-pool level and needs a recycle to pick up new/changed rule DLLs. If we ever see rule-load latency complaints, that reflection scan (not the rule's own `Execute()` logic) is the first place to look.
