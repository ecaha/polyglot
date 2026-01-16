function Get-OpsLogEntry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('Trace', 'Debug', 'Info', 'Warn', 'Error', 'Fatal')]
        [string]$LogLevel,

        [Parameter(Mandatory)]
        [string]$Message,

        [string]$Hostname = $env:COMPUTERNAME,
        [datetime]$Timestamp = (Get-Date).ToUniversalTime()
    )

    $normalizedLevel = $LogLevel.ToUpperInvariant()
    $logEntry = "{0} {1} {2} {3}" -f $Timestamp.ToString('o'), $normalizedLevel, $Hostname, $Message.Trim()
    return $logEntry
}

function Write-OpsLog {
    [CmdletBinding(DefaultParameterSetName = 'Components')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'Components')]
        [ValidateSet('Trace', 'Debug', 'Info', 'Warn', 'Error', 'Fatal')]
        [string]$LogLevel,

        [Parameter(Mandatory, ParameterSetName = 'Components')]
        [string]$Message,

        [Parameter(Mandatory, ParameterSetName = 'Entry')]
        [string]$LogEntry,

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

        if ($PSCmdlet.ParameterSetName -eq 'Components') {
            $entryToWrite = Get-OpsLogEntry -LogLevel $LogLevel -Message $Message
        }
        else {
            $entryToWrite = $LogEntry
        }

        Add-Content -Path $LogFile -Value $entryToWrite
        return $entryToWrite
    }
    catch {
        Write-Warning "Failed to write log entry: $_"
        return $null
    }
}
