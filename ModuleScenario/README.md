# Ops.LabToolkit — Student Tasks (Compact Overview)

## Goal
Build **one PowerShell module** named **`Ops.LabToolkit`** that can run **`New-OpsLabReport`** and produce a **functional ops report** even if you complete only **2–3 topics**.

---

## Deliverables (minimum)
- Module imports cleanly: `Import-Module Ops.LabToolkit`
- `New-OpsLabReport -ComputerName localhost -OutputPath .\report.json` works
- Report contains at least:
  - **Inventory** 
  - **Pending reboot** 
  - Summary of findings (`Info/Warning/Critical` counts)

---

## Module skeleton (do first)

PowerShell module additional readings

    * [Learn](https://learn.microsoft.com/en-us/powershell/scripting/developer/module/how-to-write-a-powershell-script-module?view=powershell-7.5)
    * [Sample module skeleton on github](https://github.com/MSAdministrator/TemplatePowerShellModule)


1. Create module folder:
   - `Ops.LabToolkit\Ops.LabToolkit.psd1`
   - `Ops.LabToolkit\Ops.LabToolkit.psm1`
   - `Public\`, `Private\`, `Data\`
2. In `psm1`, dot-source all `Public\*.ps1` + `Private\*.ps1`
3. Create helpers in `Private\`:
   - `New-OpsFinding` (standard finding object)
   - `Invoke-OpsSafe` (try/catch wrapper to avoid report crash)
   - `Export-OpsReport` (write JSON, optional HTML/text)
   - Optional: `New-OpsCimSession` (remote CIM sessions)
4. Add comment-based help template to every **public** function.

---

## Consistent public command names

- `New-OpsLabReport` (orchestrator)
- `Get-OpsInventory` 
- `Test-OpsPendingReboot` 
- `Get-OpsLocalIdentityStatus` 
- `Get-OpsServiceBaselineStatus`
- `Get-OpsSmbShareAudit` 
- `Get-OpsEventTriage` 

---

## Output contract (all topic functions)
Each topic function returns:
- `ComputerName`, `Topic`, `Timestamp`
- `Data` (raw collected data)
- `Findings` (array of `{ Severity, Code, Message, Hint }`)

---

## Step plan (complete in this order)

### 1) Orchestrator (mandatory): `New-OpsLabReport`
- Parameters: `-ComputerName`, `-IncludeTopic`, `-OutputPath`
- Calls available topic functions and aggregates:
  - `Sections[]` (topic outputs)
  - `Summary` (counts by severity)
- Exports `report.json` (nested structure preserved)

---

## Topics (easiest → hardest)

### Inventory: `Get-OpsInventory` ✅ (recommended for everyone)
- Collect: OS, CPU, RAM, disks (free/size), last boot time
- Produce at least 1 finding (e.g., uptime too high, low disk optional)

### Pending reboot: `Test-OpsPendingReboot` ✅ (recommended for everyone)
- Check 3+ reboot indicators (registry-based)
- Output which indicator(s) triggered + one finding if reboot is pending

### Local identity posture: `Get-OpsLocalIdentityStatus`
- Get local users + local Administrators members
- Compare admins to allowlist file: `Data\LocalAdmins.AllowList.json`
- Finding: unexpected admin principal

### Service baseline drift: `Get-OpsServiceBaselineStatus`
- Baseline file: `Data\ServiceBaseline.json` (service name, expected state/start mode)
- Compare current to baseline
- Findings: mismatches (Running vs Stopped, Auto vs Manual)

### SMB share audit: `Get-OpsSmbShareAudit`
- Enumerate shares + share ACLs
- Finding rules: “Everyone/Anonymous has Full” or non-allowed principal
- Optional allowlist file: `Data\SmbShares.AllowList.json`

### Event log triage: `Get-OpsEventTriage` (hardest)
- Use `Get-WinEvent` with **FilterHashtable** (time-boxed default 24h)
- Data-driven rules: `Data\EventTriage.Rules.json`
- Findings: rule matched (count + sample event)

---

## Minimal track
Complete **only these 3**:
1. `New-OpsLabReport`
2. `Get-OpsInventory`
3. `Test-OpsPendingReboot`

---

## Quick validation checklist
- `Get-Command -Module Ops.LabToolkit` shows expected commands
- `Get-Help New-OpsLabReport -Examples` works
- `New-OpsLabReport -ComputerName localhost -OutputPath .\report.json` produces file
- JSON contains `Sections` + `Summary`
