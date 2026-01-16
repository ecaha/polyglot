# ModuleScenario Documentation

## Overview
ModuleScenario is a minimal PowerShell module that currently exposes a single public cmdlet, `Get-OpsDiskUtil`, for retrieving logical disk utilization data from the local or a remote Windows host. It also contains private helpers responsible for structured logging so future public commands can emit consistent telemetry.

```
ModuleScenario/
├── ModuleScenario.psm1          # Module entry point
├── ModuleScenario.psd1          # Module manifest metadata
├── Public/
│   └── Get-OpsDiskUtil.ps1      # Public cmdlet exported to consumers
└── Private/
    └── Write-OpsLog.ps1         # Private helpers (Get-OpsLogEntry, Write-OpsLog)
```

## Prerequisites
- Windows PowerShell 5.1+ or PowerShell 7+
- Execution policy permitting script/module execution (`Set-ExecutionPolicy RemoteSigned` for development)
- Network access to remote hosts when using `-ComputerName`

## Build Workflow
1. **Restore workspace**
  ```powershell
  git clone -b ec-module https://github.com/ecaha/polyglot.git
  cd polyglot/ModuleScenario
  ```
2. **Run module tests (optional)** – add Pester tests under `tests/` when available.
3. **Package the module**
  ```powershell
  $moduleRoot = (Resolve-Path .).Path
  $distPath   = Join-Path $moduleRoot 'dist'

  New-Item -ItemType Directory -Force -Path $distPath | Out-Null
  Copy-Item -Path (Join-Path $moduleRoot 'ModuleScenario.psd1'), \
              (Join-Path $moduleRoot 'ModuleScenario.psm1'), \
              (Join-Path $moduleRoot 'Public'), \
              (Join-Path $moduleRoot 'Private') \
         -Destination $distPath -Recurse

  Compress-Archive -Path (Join-Path $distPath '*') -DestinationPath (Join-Path $moduleRoot 'ModuleScenario.zip') -Force
  ```
4. **Increment version** – update `ModuleVersion` inside `ModuleScenario.psd1` prior to publishing.

## Deployment
- **Local import for testing**
  ```powershell
  Import-Module -Name (Resolve-Path .\ModuleScenario) -Force
  Get-Command -Module ModuleScenario
  ```
- **Per-user installation**
  ```powershell
  $target = Join-Path $env:USERPROFILE 'Documents\PowerShell\Modules\ModuleScenario'
  Copy-Item -Path .\ModuleScenario -Destination $target -Recurse -Force
  ```
- **System-wide installation** (requires elevation)
  ```powershell
  $target = 'C:\Program Files\PowerShell\7\Modules\ModuleScenario'
  Copy-Item -Path .\ModuleScenario -Destination $target -Recurse -Force
  ```

## Internal Architecture
```mermaid
flowchart TD
    A(Get-OpsDiskUtil) -->|Collects WMI data| B[Win32_LogicalDisk]
    A --> C{Logging Needed?}
    C -->|Yes| D(Get-OpsLogEntry)
    D --> E(Write-OpsLog)
    E --> F[Log File]
```

### Public Component
- **Get-OpsDiskUtil**
  - Parameters: `-ComputerName` (array, pipeline-aware) **or** `-PSSession` (accepts session objects from the pipeline).
  - Central script block collects `Win32_LogicalDisk` data (local disks only) and formats hostname, timestamp, capacity, free space, and utilization.
  - Emits per-target errors so failed computers/sessions are clearly identified while successful targets continue streaming results.
  - Ready for future logging calls (e.g., wrap WMI calls with `Write-OpsLog`).

### Usage Examples
```powershell
# Query two servers directly by name
Get-OpsDiskUtil -ComputerName 'srv-core-01','srv-db-02'

# Pipe computers from another cmdlet
'srv-core-01','srv-db-02' | Get-OpsDiskUtil

# Use existing remote sessions
Get-PSSession -Name 'Prod*' | Get-OpsDiskUtil
```

### Private Components
- **Get-OpsLogEntry**
  - Inputs: `-LogLevel`, `-Message`, optional `-Hostname`, `-Timestamp`.
  - Normalizes level to upper case, formats ISO 8601 UTC timestamp, and concatenates into `"<timestamp> <level> <host> <message>"` for ingestion by log processors.
- **Write-OpsLog**
  - Parameter sets:
    - `Components`: accepts `-LogLevel`, `-Message`, `-LogFile` and internally calls `Get-OpsLogEntry`.
    - `Entry`: accepts pre-built `-LogEntry` with `-LogFile` for reuse across commands.
  - Ensures target directory/file exists, then appends the entry. Returns the written text for downstream validation.

## Extending the Module
1. Place future public cmdlets inside `Public/` and ensure they call logging helpers when emitting diagnostic data.
2. Private utilities (formatting, network helpers, etc.) belong in `Private/` to keep the exported surface minimal.
3. Update `ModuleScenario.psd1` with new metadata (dependencies, tags, description) as the module grows.
4. Add Pester tests to `tests/` and wire into CI.

## References & Useful Links
- [PowerShell Modules Overview](https://learn.microsoft.com/powershell/scripting/developer/module/ps-modules)
- [Create a PowerShell Module Manifest](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/new-modulemanifest)
- [Publish-Module to PowerShell Gallery](https://learn.microsoft.com/powershell/scripting/gallery/how-to/publishing-packages/publish-module)


## Future Enhancements
- Add centralized configuration for log paths and retention.
- Replace deprecated `Get-WmiObject` with `Get-CimInstance` for cross-platform support.
- Introduce telemetry toggles (verbose, quiet modes) and unit tests verifying logging side-effects.
