function Write-OpsLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('Trace', 'Debug', 'Info', 'Warn', 'Error', 'Fatal')]
        [string]$LogLevel,

        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter(Mandatory)]
        [string]$LogFile
    )

    try {
        $logDirectory = Split-Path -Path $LogFile -Parent
        if ($logDirectory -and -not (Test-Path -Path $logDirectory)) {
            New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
        }

        if (-not (Test-Path -Path $LogFile)) {
            New-Item -ItemType File -Path $LogFile -Force | Out-Null
        }

        $timestamp = (Get-Date).ToUniversalTime().ToString('o')
        $normalizedLevel = $LogLevel.ToUpperInvariant()
        $hostIdentity = $env:COMPUTERNAME
        $logEntry = "{0} {1} {2} {3}" -f $timestamp, $normalizedLevel, $hostIdentity, $Message.Trim()

        Add-Content -Path $LogFile -Value $logEntry
    }
    catch {
        Write-Warning "Failed to write log entry: $_"
    }
}
