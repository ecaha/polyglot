# Ops.LabToolkit — Detailed specifications, implementation hints, and documentation links

This expands the student tasks defined in `README.md` (module name, required commands, output contract, and topic list). fileciteturn0file0

---

## 0) Common ground for all tasks (do first)

### Module layout and loading
**Goal:** One importable module `Ops.LabToolkit` with public functions in `Public\` and helpers in `Private\`.

**Recommended structure**
- `Ops.LabToolkit\Ops.LabToolkit.psd1` (manifest)
- `Ops.LabToolkit\Ops.LabToolkit.psm1` (module entry)
- `Ops.LabToolkit\Public\*.ps1` (exported commands)
- `Ops.LabToolkit\Private\*.ps1` (helpers)
- `Ops.LabToolkit\Data\*.json` (baselines/allowlists/rules)

**Implementation hints**
- In `Ops.LabToolkit.psm1`, dot-source `Private` first, then `Public`, then `Export-ModuleMember` only for public functions.
- Add `Set-StrictMode -Version Latest` (optional but educational) and rely on `-ErrorAction Stop` inside collectors so failures are catchable.
- Build topic functions to work **locally by default**; add optional `-CimSession` support for remote extension later.

**Docs**
- PowerShell script modules: https://learn.microsoft.com/powershell/scripting/developer/module/how-to-write-a-powershell-script-module  
- Module manifests: https://learn.microsoft.com/powershell/scripting/developer/module/how-to-write-a-powershell-module-manifest  
- about_Modules: https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_modules  
- Comment-based help: https://learn.microsoft.com/powershell/scripting/core-powershell/learn/ps101/04-help  

---

### Output contract (applies to every topic function)
Every topic function returns a single object like:

- `ComputerName`
- `Topic`
- `Timestamp`
- `Data` (raw collected data)
- `Findings` (array of standardized findings)

**Implementation hints**
- Use `[pscustomobject]@{}` consistently.
- Keep `Data` “machine readable” (objects/arrays), not formatted strings.

---

### Helper functions (Private\)
#### `New-OpsFinding`
**Purpose:** Standardize findings so the orchestrator can summarize them.

**Recommended fields**
- `Severity` (Info/Warning/Critical)
- `Code` (stable identifier, e.g., `DISK_LOW_SPACE`)
- `Message` (human-readable)
- `Hint` (what to check / how to fix)
- Optional: `Evidence` (small object with numbers/paths/ids)

**Docs**
- PSCustomObject patterns: https://learn.microsoft.com/powershell/scripting/learn/deep-dives/everything-about-pscustomobject  

#### `Invoke-OpsSafe`
**Purpose:** Wrap a topic call so a single failure does not break the report.

**Behavior**
- Accept a scriptblock and “topic metadata”
- Catch exceptions and return a valid topic result with a `Critical` or `Warning` finding describing failure.

**Docs**
- try/catch: https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_try_catch_finally  

#### `Export-OpsReport`
**Purpose:** Export report to JSON (optionally HTML/text later).

**Implementation hints**
- Use `ConvertTo-Json -Depth 6` (or higher if needed).
- Use `Set-Content -Encoding UTF8` (or `Out-File -Encoding utf8`).

**Docs**
- ConvertTo-Json: https://learn.microsoft.com/powershell/module/microsoft.powershell.utility/convertto-json  

#### Optional: `New-OpsCimSession`
**Purpose:** Centralize remote connectivity with CIM (cleaner than WMI).

**Docs**
- New-CimSession: https://learn.microsoft.com/powershell/module/cimcmdlets/new-cimsession  
- Get-CimInstance: https://learn.microsoft.com/powershell/module/cimcmdlets/get-ciminstance  

---

## 1) Orchestrator (mandatory): `New-OpsLabReport`

### Objective
Produce a functional report even if only 2–3 topics are implemented, aggregating sections and a severity summary. fileciteturn0file0

### Suggested parameters
- `-ComputerName [string[]]` (default: `localhost`)
- `-IncludeTopic [string[]]` (optional)
- `-OutputPath [string]` (required for lab deliverable)
- Optional: `-AsObject` (return object without exporting), `-PassThru` (return object + export)

### Topic discovery strategy (recommended)
Avoid hard dependency on *all* topic functions:
- Create a mapping table of `TopicName -> FunctionName`
- When building the run list, only call functions that exist: `Get-Command $fn -EA SilentlyContinue`

### Report structure (recommended)
- `ComputerName`
- `GeneratedAt`
- `Sections` (array of topic outputs)
- `Summary`:
  - `InfoCount`, `WarningCount`, `CriticalCount`
  - Optional: counts by topic

### Implementation hints
- Run topics in easiest→hardest order (as in README).
- Wrap each call with `Invoke-OpsSafe`.
- Compute summary via `Sections.Findings | Group-Object Severity`.

**Docs**
- Advanced functions / parameters: https://learn.microsoft.com/powershell/scripting/developer/cmdlet/writing-a-windows-powershell-cmdlet  
- about_Functions_Advanced: https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_functions_advanced  

---

## 2) Topic: Inventory — `Get-OpsInventory` (easy)

### Objective
Collect core system inventory (OS/CPU/RAM/disks/boot time) and emit at least one useful finding.

### Suggested parameters
- `-ComputerName [string]` (optional if orchestrator passes it)
- Optional: `-CimSession`
- Optional thresholds:
  - `-MinDiskFreePercent` (default e.g., 10)
  - `-MaxUptimeDays` (default e.g., 30)

### Data to collect (minimal set)
- OS: caption, version/build, install date, last boot
- CPU: name, cores/logical processors
- RAM: total physical memory
- Disks: logical disks (C:, D:…), size, free, free%

**Implementation hints**
- Prefer CIM for structured data:
  - `Win32_OperatingSystem` (boot time, OS caption)
  - `Win32_ComputerSystem` (memory)
  - `Win32_Processor` (CPU)
  - `Win32_LogicalDisk` (disk free/size)
- For disks: filter to `DriveType = 3` (local disks).
- Create findings like:
  - `Warning` if any disk free% < threshold
  - `Info` if uptime > threshold (or make it `Warning`, your call)

**Docs**
- Win32_OperatingSystem: https://learn.microsoft.com/windows/win32/cimwin32prov/win32-operatingsystem  
- Win32_LogicalDisk: https://learn.microsoft.com/windows/win32/cimwin32prov/win32-logicaldisk  
- CIM cmdlets: https://learn.microsoft.com/powershell/module/cimcmdlets/  

---

## 3) Topic: Pending reboot — `Test-OpsPendingReboot` (easy→medium)

### Objective
Detect whether Windows has a pending reboot and explain **which indicator(s)** triggered.

### Suggested reboot indicators (pick 3+)
Common, registry-based indicators:
1. **Component Based Servicing**: `...\Component Based Servicing\RebootPending`
2. **Windows Update**: `...\WindowsUpdate\Auto Update\RebootRequired`
3. **Pending file rename operations**: `HKLM\SYSTEM\...\Session Manager\PendingFileRenameOperations`
Optional extras:
- Pending computer rename (`ActiveComputerName` vs `ComputerName`)
- SCCM/ConfigMgr client indicators (if present)

### Data output
- `IndicatorsChecked` (array)
- `IndicatorsMatched` (array)
- `IsRebootPending` (bool)

### Implementation hints (two levels)
**Level 1 (local-first, simplest)**
- Use `Test-Path` / `Get-ItemProperty` on `Registry::HKEY_LOCAL_MACHINE\...`
- Make sure missing keys don’t throw: `-EA SilentlyContinue`

**Level 2 (remote-ready, more advanced)**
- Use `StdRegProv` through CIM (`root\default`) to read registry remotely without WinRM script execution.
- Store evidence per indicator (key name + value name).

**Docs**
- Registry provider: https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_registry_provider  
- CIM Invoke method: https://learn.microsoft.com/powershell/module/cimcmdlets/invoke-cimmethod  

---

## 4) Topic: Local identity posture — `Get-OpsLocalIdentityStatus` (medium)

### Objective
Enumerate local users + local Administrators membership and compare Administrators to an allowlist.

### Inputs / data files
- `Data\LocalAdmins.AllowList.json` containing allowed principals
  - Example schema: `{ "Allowed": ["BUILTIN\\Administrators", "CONTOSO\\IT-Admins", "LocalAdminUser"] }`

### Data to collect
- Local users: name, enabled/disabled, last logon (if available), password settings (if available)
- Local Administrators group members (including domain groups if present)

### Findings
- `Warning/Critical`: any Administrators member not in allowlist
- Optional:
  - `Info/Warning`: built-in Administrator enabled
  - `Info`: unexpected local users enabled (depending on your policy)

### Implementation hints
- Use `Get-LocalUser`, `Get-LocalGroupMember -Group Administrators` when available.
- Normalize identities:
  - Some entries return as `Name`, some as `SID`, some as `Domain\Name`
  - Convert to a consistent string before comparison.
- Handle nested membership:
  - For the lab, it’s OK to report direct members only.
  - Stretch goal: detect if a member is a group and optionally expand it.

**Docs**
- Get-LocalUser: https://learn.microsoft.com/powershell/module/microsoft.powershell.localaccounts/get-localuser  
- Get-LocalGroupMember: https://learn.microsoft.com/powershell/module/microsoft.powershell.localaccounts/get-localgroupmember  

---

## 5) Topic: Service baseline drift — `Get-OpsServiceBaselineStatus` (medium)

### Objective
Compare current service state/start mode against a baseline JSON file and report drift.

### Inputs / data files
- `Data\ServiceBaseline.json`, e.g.:
  ```json
  [
    {"Name":"W32Time","ExpectedStatus":"Running","ExpectedStartMode":"Auto"},
    {"Name":"Spooler","ExpectedStatus":"Stopped","ExpectedStartMode":"Disabled"}
  ]
  ```

### Data to collect
For each baseline service:
- Actual status (Running/Stopped)
- Actual start mode (Auto/Manual/Disabled)
- “Installed?” flag if not found

### Findings
- `Warning`: status mismatch
- `Warning`: start mode mismatch
- Optional: `Info/Warning`: baseline service not present (depending on environment expectations)

### Implementation hints
- Use `Win32_Service` via CIM to get both `State` and `StartMode`.
- Map values carefully:
  - `Win32_Service.StartMode` values are typically `Auto`, `Manual`, `Disabled`
- Validate the baseline file at load time (missing fields, duplicates).
- Treat baseline as “data-driven”: collectors shouldn’t hardcode service names.

**Docs**
- Win32_Service: https://learn.microsoft.com/windows/win32/cimwin32prov/win32-service  
- Get-Service: https://learn.microsoft.com/powershell/module/microsoft.powershell.management/get-service  

---

## 6) Topic: SMB share audit — `Get-OpsSmbShareAudit` (medium→hard)

### Objective
Enumerate SMB shares and identify risky ACL patterns (e.g., Everyone/Anonymous Full Control), with optional allowlists.

### Data to collect
- Shares: name, path, description, type
- Share permissions: identity, access right, access control type

### Finding rules (starter set)
- `Critical`: `Everyone` has `Full`
- `Critical`: `ANONYMOUS LOGON` or `Guest` has any access
- `Warning`: non-allowlisted principal has `Change`/`Full`

### Implementation hints
- Enumerate shares with `Get-SmbShare`.
- Enumerate access with `Get-SmbShareAccess -Name <share>`.
- Decide what to do with default/admin shares:
  - Either exclude (`C$`, `ADMIN$`, `IPC$`) or tag them separately.
- Optional allowlist file:
  - `Data\SmbShares.AllowList.json` could map share name → allowed principals.
- Provide remediation hints:
  - Use `Revoke-SmbShareAccess` / `Grant-SmbShareAccess` (don’t auto-fix in lab unless explicitly asked).

**Docs**
- Get-SmbShare: https://learn.microsoft.com/powershell/module/smbshare/get-smbshare  
- Get-SmbShareAccess: https://learn.microsoft.com/powershell/module/smbshare/get-smbshareaccess  
- Grant/Revoke-SmbShareAccess: https://learn.microsoft.com/powershell/module/smbshare/  

---

## 7) Topic: Event log triage — `Get-OpsEventTriage` (hardest)

### Objective
Time-box event collection (default 24h), apply JSON-defined rules, and output findings with counts + sample events.

### Inputs / data files
- `Data\EventTriage.Rules.json` (data-driven)
  - Recommended rule fields:
    - `RuleId`
    - `LogName` (System/Application/Security)
    - `ProviderName` (optional)
    - `EventId` (single or array)
    - `Level` (optional)
    - `MessageRegex` (optional)
    - `MinCount` (default 1)
    - `Severity`
    - `Hint`

### Data to collect
Per rule:
- `MatchedCount`
- `SampleEvents` (e.g., up to 3: TimeCreated, Id, ProviderName, Message snippet)

### Implementation hints (performance matters)
- Always use `-FilterHashtable` for server-side filtering (avoid piping massive logs):
  - `@{ LogName='System'; StartTime=(Get-Date).AddHours(-24); Id=... }`
- Cap samples:
  - `-MaxEvents 200` (or similar) per rule/log/time window
- Two viable designs:
  1. **Per-rule query** (simpler, potentially more queries)
  2. **Per-log query then filter in memory** (fewer queries, more RAM)
- Make rules resilient:
  - If log doesn’t exist / access denied, emit a safe topic result + finding (via `Invoke-OpsSafe`).

**Docs**
- Get-WinEvent: https://learn.microsoft.com/powershell/module/microsoft.powershell.diagnostics/get-winevent  
- FilterHashtable usage: https://learn.microsoft.com/powershell/module/microsoft.powershell.diagnostics/get-winevent#examples  

---

## Suggested “done” criteria (per topic)
For each topic function:
- Returns an object matching the output contract (always).
- Produces at least one finding in a realistic scenario (or at least an Info “collector succeeded” finding).
- Works when called via `New-OpsLabReport`.
