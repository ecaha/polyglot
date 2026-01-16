function Get-OpsDiskUtil {
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
        $diskQuery = {
            param(
                [string]$TargetComputer
            )

            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $hostname  = if ($TargetComputer) { $TargetComputer } else { $env:COMPUTERNAME }

            $wmiParams = @{
                Class       = 'Win32_LogicalDisk'
                ErrorAction = 'Stop'
            }
            if ($TargetComputer) {
                $wmiParams['ComputerName'] = $TargetComputer
            }

            Get-WmiObject @wmiParams |
                Where-Object { $_.DriveType -eq 3 } |
                Select-Object @{
                    Name = 'Hostname'
                    Expression = { $hostname }
                }, @{
                    Name = 'Date'
                    Expression = { $timestamp }
                },
                DeviceID,
                VolumeName,
                @{
                    Name = 'Size(GB)'
                    Expression = { [math]::Round($_.Size / 1GB, 2) }
                },
                @{
                    Name = 'FreeSpace(GB)'
                    Expression = { [math]::Round($_.FreeSpace / 1GB, 2) }
                },
                @{
                    Name = 'Utilization(%)'
                    Expression = { [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2) }
                }
        }
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Session' {
                foreach ($session in @($PSSession)) {
                    if (-not $session) { continue }
                    try {
                        Invoke-Command -Session $session -ScriptBlock $diskQuery -ArgumentList $null -ErrorAction Stop
                    }
                    catch {
                        $sessionName = if ($session.ComputerName) { $session.ComputerName } else { $session.Name }
                        Write-Error "Failed to retrieve disk utilization information via session '$sessionName'. Error: $_"
                    }
                }
            }
            default {
                foreach ($computer in @($ComputerName)) {
                    if (-not $computer) { continue }
                    try {
                        & $diskQuery -TargetComputer $computer
                    }
                    catch {
                        Write-Error "Failed to retrieve disk utilization information from $computer. Error: $_"
                    }
                }
            }
        }
    }
}
