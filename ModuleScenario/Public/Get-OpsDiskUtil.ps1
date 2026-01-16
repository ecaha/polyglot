function Get-OpsDiskUtil {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Computer')]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    process {
        foreach ($computer in $ComputerName) {
            try {
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $hostname  = $computer

                Get-WmiObject -Class Win32_LogicalDisk -ComputerName $computer -ErrorAction Stop |
                    Where-Object { $_.DriveType -eq 3 } |
                    Select-Object @{
                        Name = "Hostname";
                        Expression = { $hostname }
                    }, @{
                        Name = "Date";
                        Expression = { $timestamp }
                    },
                    DeviceID,
                    VolumeName,
                    @{
                        Name = "Size(GB)";
                        Expression = { [math]::Round($_.Size / 1GB, 2) }
                    },
                    @{
                        Name = "FreeSpace(GB)";
                        Expression = { [math]::Round($_.FreeSpace / 1GB, 2) }
                    },
                    @{
                        Name = "Utilization(%)";
                        Expression = { [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2) }
                    }
            }
            catch {
                Write-Error "Failed to retrieve disk utilization information from $computer. Error: $_"
            }
        }
    }
}
