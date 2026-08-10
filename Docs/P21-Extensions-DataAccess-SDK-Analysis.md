# P21.Extensions.DataAccess SDK — Class-by-Class Analysis

**Source:** `C:\Business_Rules\JetBrains-Export\P21.Extensions\DataAccess\` (JetBrains/dotPeek decompile of `P21.Extensions.dll`, Assembly Version 2.0.0.0 — same assembly as `P21.Extensions.BusinessRule`, see [P21-Extensions-BusinessRule-SDK-Analysis.md](P21-Extensions-BusinessRule-SDK-Analysis.md))
**Analyzed:** 2026-08-10
**Why this matters:** this is the plumbing behind `Rule.P21SqlConnection` and `Rule.HideData`/`UnhiddeData` from the `BusinessRule` namespace. Only 4 files, all Epicor's own SDK — no `kb_`/`js_` references, so the retirement flag doesn't apply here. Two of the four classes (`ConnectionManager`, `P21Encryption`) are marked `internal` and are **not directly callable** from an `asi_*` rule DLL (different assembly) — you only reach them indirectly through `Rule`'s public wrapper members.

## Terminology note

As with the `BusinessRule` folder, these are classes, not free functions. Only two of the four (`DBCredentials`, `P21Connection`) are `public` and could theoretically be `new`'d up directly by rule code — but in practice a rule author never constructs any of these; P21 builds a `DBCredentials` internally from the session's login and hands `Rule.Initialize()` the credentials, and `Rule.P21SqlConnection` does the rest.

---

## `ConnectionManager.cs` — **internal; reached only via `Rule.P21SqlConnection` / `Rule.HideData` / `Rule.UnhiddeData`**

The class that actually opens the SQL connection a business rule uses. Not `public`, so you can't call it directly from an external rule assembly — Epicor's `Rule` base class (in the same assembly) is the only caller.

`GetP21Connection(DBCredentials)`:
1. Builds a connection string (`GetP21ConnectionString`) — prefers `credentials.ConnectionString` if set; otherwise builds one from `Server`/`Database`/`UserID`, using `Trusted_Connection=True` if `UserPassword` is empty, or decrypting `UserPassword` via `P21Encryption.Decrypt(pw, UserID)` and using SQL auth if not. `Application Name=DynachangeRules` is hardcoded into the connection string — useful to know if you're ever hunting rule-originated connections in `sys.dm_exec_sessions`/Extended Events by `program_name`.
2. Opens the `SqlConnection`.
3. **Applies a SQL Server application role** (`ApplyApplicationRole`) — runs `sp_setapprole @rolename='p21_application_role', @password=<fetched>, @fcreatecookie=1`, capturing the `@cookie` output param, and wraps the connection + cookie in a `P21Connection`.

`CloseP21Connection(P21Connection)` reverses it: `sp_unsetapprole @cookie` (`DisableApplicationRole`), then closes the connection.

`GetAppRolePassword(credentials)` — opens a *separate* connection (without the app role applied) and queries `p21_view_get_approle_info` for the `p21_application_role` row's encrypted password value and its `p21_application_role_password_edited` flag. If the password was never edited from Epicor's default, it just returns the literal string `"changeme"`; otherwise it decrypts the stored value using the fixed key `"admin"`.

**This directly explains an existing finding** (memory note *"P21 New-Object EXECUTE Grant"*): every business-rule SQL connection runs under `p21_application_role`, not the login's own permissions. That's *why* a new stored proc needs `EXECUTE` granted to `p21_application_role` (or `PxxiUser`) specifically — the login-level grant is irrelevant once `sp_setapprole` succeeds, because SQL Server's application-role semantics drop the calling login's own permissions for the duration of the session and substitute the role's. Worth remembering next time a "grant looks right but the rule still gets permission denied" ticket comes up: check `p21_application_role`'s grants, not the login's.

```csharp
// Not callable directly — shown for how Rule.P21SqlConnection resolves internally:
public SqlConnection P21SqlConnection
{
    get
    {
        if (this.p21SqlConnection == null && this.dbCredentials != null)
        {
            this.P21Connection = ConnectionManager.GetP21Connection(this.dbCredentials); // internal, same assembly
            this.p21SqlConnection = this.P21Connection.Connection;
        }
        return this.p21SqlConnection;
    }
}
```
What a rule author actually writes:
```csharp
using (SqlCommand cmd = new SqlCommand("SELECT item_id FROM inv_mast WHERE inv_mast_uid = @uid", this.P21SqlConnection))
{
    cmd.Parameters.AddWithValue("@uid", someUid);
    var itemId = cmd.ExecuteScalar();
}
// Rule.CloseConnection() is called for you by RuleWorker.ExecuteRule after Execute() returns.
```

`ConnectionManager.Decrypt`/`Encrypt` are also the internal targets of `Rule.UnhiddeData`/`Rule.HideData` — thin one-line pass-throughs to `P21Encryption` (below), which is where the real logic lives.

---

## `DBCredentials.cs` — **public DTO; consumed via `Rule.Initialize(xml, credentials)`**

Plain data holder: `ConnectionString` (if set, wins outright), `UserID`, `UserPassword` (expected pre-encrypted — see `P21Encryption` below), `Server`, `Database`. Two constructors: parameterized and parameterless (property-initializer style). `RuleManager.SetDBCredentials(userID, userPassword, server, database)` — from the `BusinessRule` folder — is what actually builds one of these; `Rule.Initialize` just stores whatever `RuleWorker.ExecuteRule` hands it via `request.DBCredentials`. Not something an `asi_*` rule constructs itself.

---

## `P21Connection.cs` — **public DTO; you never construct one, but you interact with what it wraps**

Simple pair: `Connection` (the open `SqlConnection`) + `Cookie` (the app-role cookie object needed to later call `sp_unsetapprole`). `Rule.P21SqlConnection` returns `.Connection` from the one it holds; `Rule.CloseConnection()` passes the whole `P21Connection` back into `ConnectionManager.CloseP21Connection` to unwind the app role and close cleanly. Nothing to call here directly.

---

## `P21Encryption.cs` — **internal; reached only via `Rule.HideData(value, key)` / `Rule.UnhiddeData(value, key)`**

Epicor's home-rolled symmetric cipher for things like the stored application-role password and any rule-level "hidden" field values. **This is not real cryptography** — it's a keyed byte-arithmetic scheme:
- `ScrambleKey(key)` — reverses the key string and interleaves it with a fixed 10-character pad (`"A3ko&1%Mv Z..."` built char-by-char, only applied for the first 10 characters of the key — keys longer than 10 chars fall through unscrambled past index 9).
- `Encrypt(value, key)` — converts both `value` and the scrambled key to codepage 1252 bytes, then does byte-wise **addition modulo 256** (`result1 += result2`, wrapping via subtracting 255 — note: it subtracts 255 not 256, a mild off-by-one in the vendor's own wraparound logic) between the value bytes and a cyclically-repeated key.
- `Decrypt(originalvalue, key)` — same scramble, then byte-wise **subtraction** to reverse it.

```csharp
// What Rule exposes (protected, so only inside your Rule subclass):
protected string HideData(string originalvalue, string key) => ConnectionManager.Encrypt(originalvalue, key);
protected string UnhiddeData(string originalvalue, string key) => ConnectionManager.Decrypt(originalvalue, key);

// Usage inside a rule:
string tokenized = this.HideData(sensitiveValue, this.Session.UserID);
// ...later, in a rule that reads it back...
string original = this.UnhiddeData(storedValue, this.Session.UserID);
```

**Flag (security, not kb_/js_):** this is a fixed, reversible, non-salted, non-standard cipher shipped inside the vendor SDK — effectively obfuscation, not encryption (no IV, no authentication, small effective keyspace once the scramble pattern is known, classic additive/XOR-style construction). It's what protects the `p21_application_role` password at rest in `p21_view_get_approle_info` and whatever any `asi_*` rule chooses to run through `HideData`/`UnhiddeData`. This is vendor code we can't change, but it's worth knowing before using `HideData`/`UnhiddeData` for anything genuinely sensitive (e.g. a rule that tokenizes something beyond internal app-role bookkeeping) — treat it as **obfuscation for casual viewing, not protection against a motivated reader with access to the DLL and the key**. If a future rule needs to protect something sensitive (API keys, PII), prefer real encryption (`System.Security.Cryptography` AES) over `HideData`, or better, keep the secret out of P21 fields entirely (e.g. Azure Key Vault / server-side config) and reference it indirectly.

---

## Summary table

| File | Category | Called by rule author? |
|---|---|---|
| ConnectionManager.cs | Internal — SQL connection + app-role plumbing | No — indirectly via `Rule.P21SqlConnection`/`HideData`/`UnhiddeData` |
| DBCredentials.cs | Public DTO | No — built by `RuleManager`/`RuleWorker`, consumed by `Rule.Initialize` |
| P21Connection.cs | Public DTO | No — held internally by `Rule` |
| P21Encryption.cs | Internal — cipher | No — indirectly via `Rule.HideData`/`UnhiddeData` |

## Performance note

Every `GetP21Connection` call does **two round trips** before your rule's own query even runs: (1) open the connection, (2) a *separate* connection + query against `p21_view_get_approle_info` just to fetch/decrypt the app-role password (unless the password was never edited, in which case it short-circuits to the literal `"changeme"`), (3) `sp_setapprole` on the original connection. None of this is something we control (vendor code, and `Rule.P21SqlConnection` is lazy — only pays this cost if a rule actually touches the property), but it's useful context if a rule that does raw SQL via `this.P21SqlConnection` ever looks slower to first-query than expected: the app-role handshake is fixed overhead on top of your query, not your query being slow. Rules that only use `Data.Fields`/`Data.Set` (the field-level API, no direct SQL) never pay this cost at all.
