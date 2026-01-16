function Get-OpsComputerUtilization {
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(ParameterSetName = 'ComputerName', Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Computer')]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter(ParameterSetName = 'Session', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Session')]
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession
    )

    begin {
        $resourceQuery = {
            param(
                [string]$TargetComputer
            )

            $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            $hostname  = if ($TargetComputer) { $TargetComputer } else { $env:COMPUTERNAME }

            $diskParams = @{ Class = 'Win32_LogicalDisk'; ErrorAction = 'Stop' }
            if ($TargetComputer) { $diskParams['ComputerName'] = $TargetComputer }

            $osParams = @{ Class = 'Win32_OperatingSystem'; ErrorAction = 'Stop' }
            if ($TargetComputer) { $osParams['ComputerName'] = $TargetComputer }

            $cpuParams = @{ Class = 'Win32_Processor'; ErrorAction = 'Stop' }
            if ($TargetComputer) { $cpuParams['ComputerName'] = $TargetComputer }

            $memory    = Get-WmiObject @osParams | Select-Object -First 1
            $cpuStats  = Get-WmiObject @cpuParams
            $disks     = Get-WmiObject @diskParams | Where-Object { $_.DriveType -eq 3 }

            $memoryTotalGb = if ($memory.TotalVisibleMemorySize) { [math]::Round(($memory.TotalVisibleMemorySize * 1KB) / 1GB, 2) } else { $null }
            $memoryFreeGb  = if ($memory.FreePhysicalMemory) { [math]::Round(($memory.FreePhysicalMemory * 1KB) / 1GB, 2) } else { $null }
            if ($memoryTotalGb -and $memoryTotalGb -ne 0) {
                $memoryUtil = [math]::Round((($memoryTotalGb - $memoryFreeGb) / $memoryTotalGb) * 100, 2)
            }
            else {
                $memoryUtil = $null
            }

            $cpuLoadValues = $cpuStats | Where-Object { $_.LoadPercentage -ne $null } | ForEach-Object { $_.LoadPercentage }
            if ($cpuLoadValues) {
                $cpuUtil = [math]::Round(($cpuLoadValues | Measure-Object -Average).Average, 2)
            }
            else {
                $cpuUtil = $null
            }
            $cpuTotal = 100
            $cpuFree  = if ($cpuUtil -ne $null) { [math]::Round($cpuTotal - $cpuUtil, 2) } else { $null }

            foreach ($disk in $disks) {
                $diskSizeGb = if ($disk.Size) { [math]::Round($disk.Size / 1GB, 2) } else { $null }
                $diskFreeGb = if ($disk.FreeSpace) { [math]::Round($disk.FreeSpace / 1GB, 2) } else { $null }
                if ($disk.Size -and $disk.Size -ne 0) {
                    $diskUtil = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 2)
                }
                else {
                    $diskUtil = $null
                }

                [pscustomobject]@{
                    Hostname            = $hostname
                    Date                = $timestamp
                    DeviceID            = $disk.DeviceID
                    VolumeName          = $disk.VolumeName
                    'DiskSize(GB)'      = $diskSizeGb
                    'DiskFree(GB)'      = $diskFreeGb
                    'DiskUtilization(%)'= $diskUtil
                    'MemoryTotal(GB)'   = $memoryTotalGb
                    'MemoryFree(GB)'    = $memoryFreeGb
                    'MemoryUtil(%)'     = $memoryUtil
                    'CpuTotal(%)'       = $cpuTotal
                    'CpuFree(%)'        = $cpuFree
                    'CpuUtil(%)'        = $cpuUtil
                }
            }
        }
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Session' {
                foreach ($session in @($PSSession)) {
                    if (-not $session) { continue }
                    try {
                        Invoke-Command -Session $session -ScriptBlock $resourceQuery -ArgumentList $null -ErrorAction Stop
                    }
                    catch {
                        $sessionName = if ($session.ComputerName) { $session.ComputerName } else { $session.Name }
                        Write-Error "Failed to retrieve computer utilization via session '$sessionName'. Error: $_"
                    }
                }
            }
            default {
                foreach ($computer in @($ComputerName)) {
                    if (-not $computer) { continue }
                    try {
                        & $resourceQuery -TargetComputer $computer
                    }
                    catch {
                        Write-Error "Failed to retrieve computer utilization from $computer. Error: $_"
                    }
                }
            }
        }
    }
}
