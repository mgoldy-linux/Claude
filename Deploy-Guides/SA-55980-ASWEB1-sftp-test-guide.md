# SA 55980 - ASWEB1 SFTP key setup and test guide

Working-session cheat sheet (Tony Neuman + Mark). **Session 1 (60 min) = Parts 0-4. Session 2 = Parts 5-7.**
Target: Play > Dev only (`/Dev/SalesRepImport/`). Prod is out of scope until Matt approves and the lower envs pass.

**Rules:** install and download nothing (only `ssh-keygen.exe` and `sftp.exe`, both in `C:\Windows\System32\OpenSSH\`).
Never paste a password or private key into a file, chat, or ticket. The `.pub` file is the only thing that leaves the server.

Placeholders used below - fill these in at the session:
- `<JOBACCT>` = Windows account that runs the scheduled task (decision, Part 0)
- `<SFTPUSER>` = Serv-U user that holds the public key (decision, Part 0)
- Host `ftp.allsurfaces.com`, port 22. Key folder `D:\SalesRepExport\ssh\` (change if Tony prefers).

---

## Part 0 - Decisions (10 min, do first)

- [ ] Windows account that runs the task: `<JOBACCT>` = ______  (Matt said `pimsvc`; Tony unsure it is the right one)
- [ ] How the job gets the `orosvc` SQL password at run time (DPAPI-encrypted credential file made as `<JOBACCT>`, or what the existing MindHarbor jobs use): ______
- [ ] Serv-U user: separate key-only user limited to the 4 `SalesRepImport` folders (recommended) or reuse `OroUser`: `<SFTPUSER>` = ______
- [ ] **MUST: the Serv-U user is KEY-ONLY (no password).** Found 10/8 on ASWEB1: the `tneuman` account accepts the key ("Server accepts key") but then returns "partial success" and still asks for a password, i.e. Serv-U is set to require key AND password. An unattended job cannot answer that. Ask Tony to create the dedicated user with the "also require password" option OFF. Test: `Connect` shows no `password:` prompt.
- [ ] Serv-U facts (from the verbose log 10/8): version **15.5.4.108**; accepts **RSA** (rsa-sha2-256/512) and ECDSA; **no ssh-ed25519** in its signature list, so use **RSA 4096**. Host key: ssh-rsa `SHA256:AN5QJ5ATsaUu+gdLAnAkLGkqDmbeSHJsx1BrCKKc8fc` (compare with Tony's server side).
- [ ] Who owns key rotation and `orosvc` password rotation: ______

## Part 1 - Prepare as the job account (5 min)

All commands in this guide run **as `<JOBACCT>`** so the key and `known_hosts` land in the right profile. Use whatever Tony's team allows (RDP as the account, or `runas /user:AHI\<JOBACCT> powershell`). Confirm who you are:

```powershell
whoami
```

- [ ] `whoami` shows `<JOBACCT>`

```powershell
$dir = 'D:\SalesRepExport\ssh'
New-Item -ItemType Directory -Force $dir | Out-Null
```

## Part 2 - Generate the key pair (10 min)

```powershell
$key = 'D:\SalesRepExport\ssh\salesrep_export_rsa'
ssh-keygen -t rsa -b 4096 -f $key -N '""' -C "SalesRepExport@ASWEB1"
```

- RSA 4096, because Serv-U 15.5.4.108 does not offer ed25519 (verified 10/8).
- `-N '""'` = no passphrase (unattended job). Tony must approve that; lock the file down in the next step instead.
- Creates `salesrep_export_rsa` (PRIVATE - never leaves this account) and `salesrep_export_rsa.pub` (send to Tony).
- Or run `.\Test-SftpKeySetup.ps1 -Action Generate` (defaults to RSA).

**If Serv-U rejects the one-line OpenSSH format**, export RFC 4716 (the multi-line "BEGIN SSH2 PUBLIC KEY" form):
```powershell
ssh-keygen -e -f "$key.pub" -m RFC4716 > "$key.rfc4716.pub"
```

Lock the private key down (OpenSSH refuses keys other accounts can read):

```powershell
icacls $key /inheritance:r
icacls $key /grant:r "${env:USERDOMAIN}\${env:USERNAME}:(R)"
icacls $key          # verify: ONLY <JOBACCT> listed (add SYSTEM/Administrators only if Tony requires it)
```

- [ ] Private key readable only by `<JOBACCT>`
- [ ] Show the `.pub` fingerprint (read it to Tony so he can match it on the Serv-U side):
```powershell
ssh-keygen -lf "$key.pub"
Get-Content "$key.pub"    # send THIS to Tony
```
- [ ] `.pub` sent to Tony; he attaches it to `<SFTPUSER>` (Serv-U: user properties > public key path) and confirms the user's home/root is limited to `/Dev/SalesRepImport/` (plus the other three env folders later)

## Part 3 - First connection and host fingerprint (10 min)

The first connect must be **interactive** so the server's host key is saved in `<JOBACCT>`'s `known_hosts`. Batch mode (`BatchMode=yes`) fails on an unknown host.

```powershell
sftp -i $key -P 22 <SFTPUSER>@ftp.allsurfaces.com
```

- [ ] The prompt shows the server's host key fingerprint. **Do not just type yes.** Tony reads the real fingerprint from the Serv-U side (or compare with `ssh-keyscan -t rsa ftp.allsurfaces.com | ssh-keygen -lf -`); they must match, then type `yes`.
- [ ] You get an `sftp>` prompt with **no password prompt**. A password prompt after "Server accepts key ... partial success" = the Serv-U user still requires key AND password: press Ctrl+C, do NOT type a password, have Tony turn that option off. (No "Server accepts key" at all = key not attached or wrong format.) Diagnose with `sftp -v -o BatchMode=yes -o IdentitiesOnly=yes -i $key <SFTPUSER>@ftp.allsurfaces.com` - options go BEFORE user@host, and `-i` must be followed directly by its path.
- [ ] `pwd` and `ls` show the expected folder; `cd /Dev/SalesRepImport/` works
- [ ] `exit`

## Part 4 - Batch-mode test, then failure drill (15 min)

Make a dummy file and a batch file (no real data, no credentials):

```powershell
$work = 'D:\SalesRepExport\ssh'
"test $(Get-Date -Format s)" | Set-Content "$work\sftp_test.txt"
@(
 'cd /Dev/SalesRepImport/'
 'put D:/SalesRepExport/ssh/sftp_test.txt sftp_test_delete_me.txt'
 'ls -l sftp_test_delete_me.txt'
) | Set-Content -Encoding ascii "$work\upload.batch"

sftp -i $key -P 22 -o BatchMode=yes -b "$work\upload.batch" <SFTPUSER>@ftp.allsurfaces.com
"exit code: $LASTEXITCODE"
```

- [ ] Exit code 0, and the `ls -l` line shows the file with the **same byte size** as the local file (`(Get-Item "$work\sftp_test.txt").Length`)
- [ ] Remove the test file: batch with `rm /Dev/SalesRepImport/sftp_test_delete_me.txt` (or ask Tony)

**Failure drills** (each must give a **non-zero** exit code and no hang; if time is short, do only the first):
- [ ] Wrong key: point `-i` at a different/dummy private key file -> expect permission denied, non-zero exit
- [ ] Wrong folder: `cd /Dev/DoesNotExist/` in the batch -> expect failure, non-zero exit
- [ ] Wrong host/port (`-P 2222`) -> expect timeout/refused, non-zero exit

**Do not trust the exit code alone** in the real script: also confirm the remote `ls -l` size equals the local size (PuTTY's psftp is known to hide batch errors; OpenSSH sftp is better but verify here).

## Session 1 wrap-up (5 min)

- [ ] What worked / what Tony still has to do: ______
- [ ] Date for session 2: ______
- [ ] Private key location and owner noted for the handoff doc (path only, never contents)

---

## Part 5 - Export dry run (Session 2)

Prerequisite: `Export-SalesRepSftp.ps1` rewritten for `sftp.exe -i <key> -o BatchMode=yes -b <batch>` and for the `orosvc` SQL credential (encrypted file made as `<JOBACCT>`). **As of 2026-10-07 neither is done.**

```powershell
Unblock-File D:\SalesRepExport\Export-SalesRepSftp.ps1     # RemoteSigned policy
.\Export-SalesRepSftp.ps1 -Instance Play-Dev -SkipUpload
```

- [ ] File built in `out\`, row counts match the Play cross-check (checks 1-9 clean)

## Part 6 - Real Play > Dev run (Session 2)

```powershell
.\Export-SalesRepSftp.ps1 -Instance Play-Dev
```

- [ ] File lands in `/Dev/SalesRepImport/` as `sales_rep_export_YYYY_MM_DDThhmmss.csv`
- [ ] Remote size = local size; SHA256 backup in `sent\`; run record written
- [ ] Failure drills from Part 4 run through the script (bad key, bad folder): it logs and exits non-zero, nothing is marked sent

## Part 7 - Schedule and hand off (Session 2)

- [ ] Task Scheduler job registered under `<JOBACCT>`, Play > Dev only; action `powershell.exe -NoProfile -ExecutionPolicy Bypass -File ... -Instance <name>`
- [ ] Trigger a manual run of the task and confirm it succeeds
- [ ] Owner named for key rotation and `orosvc` password rotation (the `orosvc` login is shared with the live Oro sync - a rotation breaks the export silently unless someone updates the credential file)
- [ ] Next steps agreed: Sandbox, Stage, then Prod (Prod only after Matt approves)

## If something goes wrong

| Symptom | Likely cause |
|---|---|
| `UNPROTECTED PRIVATE KEY FILE` | Key readable by other accounts - redo the `icacls` step |
| Password prompt instead of key login | Public key not attached/wrong path/format on Serv-U; try RSA or RFC 4716 |
| `Host key verification failed` in batch mode | First connect was not done as `<JOBACCT>`, so no `known_hosts` entry |
| `Permission denied (publickey)` | Wrong user, wrong key file, or key type not accepted |
| Connection timeout | Firewall/port; port 22 was reachable from ASWEB1 on 2026-10-05 |
| Script blocked | `Unblock-File` (execution policy is RemoteSigned) |
