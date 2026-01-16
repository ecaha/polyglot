function Get-OpsComputerUtilizationReport {
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(ParameterSetName = 'ComputerName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Computer')]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter(ParameterSetName = 'Session', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Session')]
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession,

        [Parameter()]
        [double]$DiskUtilizationThreshold = 85,

        [Parameter()]
        [double]$MemoryUtilizationThreshold = 90,

        [Parameter()]
        [double]$CpuUtilizationThreshold = 80
    )

    begin {
        $targetComputers = New-Object System.Collections.Generic.List[string]
        $targetSessions  = New-Object System.Collections.Generic.List[System.Management.Automation.Runspaces.PSSession]
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Session' {
                foreach ($session in @($PSSession)) {
                    if ($session) {
                        $targetSessions.Add($session)
                    }
                }
            }
            default {
                foreach ($computer in @($ComputerName)) {
                    if ($computer) {
                        $targetComputers.Add($computer)
                    }
                }
            }
        }
    }

    end {
        $utilizationParams = @{}
        if ($targetSessions.Count -gt 0) {
            $utilizationParams['PSSession'] = $targetSessions.ToArray()
        }
        else {
            if ($targetComputers.Count -eq 0) {
                $targetComputers.Add($env:COMPUTERNAME)
            }
            $utilizationParams['ComputerName'] = $targetComputers.ToArray()
        }

        $utilizationData = Get-OpsComputerUtilization @utilizationParams
        if (-not $utilizationData) {
            Write-Verbose 'No utilization data returned from Get-OpsComputerUtilization.'
            return
        }

        foreach ($entry in $utilizationData) {
            $diskPercent   = $entry.'DiskUtilization(%)'
            $memoryPercent = $entry.'MemoryUtil(%)'
            $cpuPercent    = $entry.'CpuUtil(%)'

            if ($diskPercent -ne $null -and $diskPercent -gt $DiskUtilizationThreshold) {
                [pscustomobject]@{
                    Hostname          = $entry.Hostname
                    Timestamp         = $entry.Date
                    Metric            = 'Disk'
                    Target            = $entry.DeviceID
                    ObservedPercent   = $diskPercent
                    ThresholdPercent  = $DiskUtilizationThreshold
                    Detail            = "Disk $($entry.DeviceID) utilization is $diskPercent% (threshold $DiskUtilizationThreshold%)."
                    Raw               = $entry
                }
            }

            if ($memoryPercent -ne $null -and $memoryPercent -gt $MemoryUtilizationThreshold) {
                [pscustomobject]@{
                    Hostname          = $entry.Hostname
                    Timestamp         = $entry.Date
                    Metric            = 'Memory'
                    Target            = 'System'
                    ObservedPercent   = $memoryPercent
                    ThresholdPercent  = $MemoryUtilizationThreshold
                    Detail            = "Memory utilization is $memoryPercent% (threshold $MemoryUtilizationThreshold%)."
                    Raw               = $entry
                }
            }

            if ($cpuPercent -ne $null -and $cpuPercent -gt $CpuUtilizationThreshold) {
                [pscustomobject]@{
                    Hostname          = $entry.Hostname
                    Timestamp         = $entry.Date
                    Metric            = 'CPU'
                    Target            = 'System'
                    ObservedPercent   = $cpuPercent
                    ThresholdPercent  = $CpuUtilizationThreshold
                    Detail            = "CPU utilization is $cpuPercent% (threshold $CpuUtilizationThreshold%)."
                    Raw               = $entry
                }
            }
        }
    }
}
