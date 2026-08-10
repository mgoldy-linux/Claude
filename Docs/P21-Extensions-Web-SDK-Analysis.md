# P21.Extensions.Web SDK — Class-by-Class Analysis

**Source:** `C:\Business_Rules\JetBrains-Export\P21.Extensions\Web\` (JetBrains/dotPeek decompile of `P21.Extensions.dll`, Assembly Version 2.0.0.0 — same assembly as `P21.Extensions.BusinessRule` and `P21.Extensions.DataAccess`, see [P21-Extensions-BusinessRule-SDK-Analysis.md](P21-Extensions-BusinessRule-SDK-Analysis.md) and [P21-Extensions-DataAccess-SDK-Analysis.md](P21-Extensions-DataAccess-SDK-Analysis.md))
**Analyzed:** 2026-08-10
**Why this matters:** this is the infrastructure behind P21's **custom rule web page** feature — the `RulePageUrl` field seen on `RuleState` in the `BusinessRule` folder. Instead of (or in addition to) executing C# logic and returning a popup, a business rule can point at a full ASP.NET MVC page hosted inside the P21 client via iframe. This is a distinct mechanism from the plain `Rule` subclasses documented previously — it's how P21 embeds a whole web app, not just a message box. Vendor code, no `kb_`/`js_` references. We don't currently have any `asi_*` rules that use this mechanism (all our custom rules are standard `Rule` subclasses or SSRS/portal artifacts) — flagging that explicitly in case this ever becomes relevant for a richer custom UI than a popup can offer.

## Terminology note

This folder is genuinely ASP.NET MVC (`System.Web.Mvc`), so "calling a function" is more literal here than in the other two folders: `InitializeController` and `BaseRuleController` are real MVC **controllers** with **action methods** P21's client hits over HTTP, not classes you inherit into a business rule DLL. `WebBusinessRule` is the odd one out — it *does* inherit `Rule`, but not so you write business logic in it; it exists purely as a session-scoped state holder, as explained below.

---

## `WebBusinessRule.cs` — **session-scoped singleton; access via `WebBusinessRule.Current`**

Extends `P21.Extensions.BusinessRule.Rule`, but in a way that looks almost like an anti-pattern until you see why: `GetDescription()`, `GetName()`, and `Execute()` — the three members every real rule must implement — all just `throw new NotImplementedException()`. This class is never meant to be discovered by `RuleWorker`'s reflection scan or invoked as `Execute()`; it *reuses* `Rule`'s infrastructure (`Data`, `Session`, `P21SqlConnection`, `Initialize()`) purely as a convenient bag of already-built plumbing, one instance per ASP.NET session.

- **`Current`** — the actual access pattern: lazily creates one `WebBusinessRule` per session and stores it in `HttpContext.Current.Session["P21WebRules.SessionKey"]`. Every controller in this custom web-rule page reaches P21 state the same way: `WebBusinessRule.Current.Data`, `.Session`, `.P21SqlConnection`.
- **`init(brXML)`** — called once per session by `InitializeController` (below). Builds a `DBCredentials`, calls the inherited `Rule.Initialize(xml, credentials)` to populate `Data`/`Session`/`RuleState`, then decides how to connect: if a `P21ConnectionString` app setting exists in the web app's own `web.config`, use that directly; otherwise fall back to `Session.UserID`/`Database`/`Server` (trusted connection) — same connection-string logic documented in `ConnectionManager.GetP21ConnectionString`. Sets `RuleResult = new RuleResultData()` and flips `initComplete`.
- **`IsInitialized()`** — guards against using a session before `init()` ran.
- **`GetDatatableAsList(...)`** (three overloads — `DataTable`, table name string, or table index) — converts a `Data.Set` table (multi-row rule grid data) into a `List<object>` of `ExpandoObject`s keyed by column **Caption** (the field title, not the raw column name). This is the bridge from the strongly-typed `DataSet` the SDK gives you to something a custom MVC view/JSON API can serialize directly.
```csharp
// Inside a controller for a custom rule web page:
var lines = WebBusinessRule.Current.GetDatatableAsList("oe_line");
return Json(lines, JsonRequestBehavior.AllowGet);
```
- **`RuleResult`** — the `RuleResultData` this session will eventually hand back to P21 when the page closes (see `InitializeController.Close()`).

---

## `BaseRuleController.cs` — **inherit from this for your own MVC controllers**

If you were building a custom rule web page, this is the class your own controllers would extend (analogous to `Rule` being what you extend for a standard business rule). Three one-line convenience properties, all just forwarding to `WebBusinessRule.Current`:
```csharp
public class MyCustomRuleController : BaseRuleController
{
    public ActionResult Index()
    {
        var lines = this.Rule.GetDatatableAsList("oe_line"); // this.Rule => WebBusinessRule.Current
        this.Data.Fields... // if single-row
        using (var cmd = new SqlCommand("...", this.P21SqlConnection)) { ... }
        return View(lines);
    }
}
```

---

## `InitializeController.cs` — **P21's entry/exit points into the web rule page; not something we call, but worth understanding for debugging**

Two action methods that form the handshake between the P21 client and a custom rule web page:

**`Index(ruleController, ruleAction)`** (`[HttpPost]`) — the entry point P21 posts to when launching the page:
1. Reads three form fields: `vbrData` (base64-encoded business rule XML — same XML format `DataCollection` parses elsewhere), `token` (a bearer token), `soaURL` (the SOA/API host to validate the token against).
2. Decodes `vbrData` and calls `WebBusinessRule.Current.init(xml)`.
3. **Auth check, with a documented bypass**: if the session is already initialized *and* running in desktop display mode (`ApplicationDisplayMode` is `"sdi"` or `"mdi"`) *and* `ClientPlatform` is empty, it **skips token validation entirely** — the assumption being a request reaching this endpoint from the thick client's own embedded browser is already inside an authenticated desktop session. Otherwise, it requires both `token` and `soaURL`, and validates the token by calling `GET {soaURL}/api/users/ping` with `Authorization: Bearer {token}` — a failure (non-200, exception) returns `400 Bad Request`.
4. On success, redirects to whatever controller/action the rule specified (`ruleController`/`ruleAction`, defaulting to `Home`/`Index`) — i.e. your custom `BaseRuleController` subclass.

**`Close()`** — the exit point, called when the custom page is done and needs to hand control back to P21:
1. Pulls `WebBusinessRule.Current.RuleResult` (400 if the session was never initialized).
2. Closes the SQL connection (`Rule.CloseConnection()`), applies field update ordering if `Data.UpdateByOrderCoded`, serializes `Data` back to XML, and base64-encodes it into `ruleResult.Xml`.
3. Returns a tiny inline `<script>` page that does `window.parent.postMessage(<json>, '*')`.

That last step is the key architectural fact: **a custom rule web page runs inside an iframe embedded in the P21 client**, and the only contract for returning control/data to P21 is a `postMessage` back to the parent frame carrying the serialized `RuleResultData` JSON. Useful to know if a future custom rule page ever needs debugging — the "did my changes make it back to P21" question always resolves to "did `Close()` get hit and did the postMessage fire," not anything about the MVC action itself.

Note the `postMessage` target origin is `'*'` (any origin) — normal for this vendor pattern since the parent is always the P21 client shell, but worth knowing if this pattern is ever adapted for something more sensitive: `'*'` means any embedding page could receive that message, not just P21's.

---

## `SessionSingleton.cs` — **appears vestigial in this snapshot**

Structurally identical pattern to `WebBusinessRule.Current` — lazily creates one instance per ASP.NET session, stored under a different session key (`"P21WebRules.SessionManager"`), exposing a single settable `WebRule` property. Nothing else in this folder (or the `BusinessRule`/`DataAccess` folders) reads or writes `SessionSingleton.Current.WebRule` — `WebBusinessRule.Current` already does its own independent session-key management and none of the controllers here reference `SessionSingleton` at all. Possibly used by application-specific custom rule web projects built on top of this SDK to stash an additional session-scoped reference, but within what's actually shipped in `P21.Extensions.dll` it looks like dead/unused scaffolding. Not something to build against unless a concrete need for a second, independently-keyed session slot shows up.

---

## Summary table

| File | Category | Called by rule/page author? |
|---|---|---|
| WebBusinessRule.cs | Session state holder (misuses `Rule` base for plumbing reuse) | Yes — `WebBusinessRule.Current` |
| BaseRuleController.cs | MVC base controller | Yes — inherit for custom rule page controllers |
| InitializeController.cs | MVC entry/exit controller | No — P21 client calls it; you never call it yourself |
| SessionSingleton.cs | Session singleton (appears unused in this SDK) | No — no live callers found |

## Performance / architecture note

There's no SQL here to measure, but one thing worth flagging: `InitializeController.Index`'s non-desktop path does a **live HTTP round trip** (`WebClient.DownloadString` to `{soaURL}/api/users/ping`) synchronously, on every page load that isn't the SDI/MDI desktop bypass — i.e. any browser-based (non-thick-client) launch of a custom rule page pays a full auth-service round trip before the page even starts rendering. Not something we can change (vendor code), but worth knowing as the likely first suspect if a future custom rule web page feels slow to open specifically from a browser context but fast from the desktop client.
