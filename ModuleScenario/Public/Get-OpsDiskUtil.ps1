function Get-OpsDiskUtil {
    Param (
        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME
    )
    try {
        $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $hostname = $ComputerName
        $diskUtil = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $ComputerName -ErrorAction Stop |
            Where-Object { $_.DriveType -eq 3 } |
            Select-Object @{
                Name = "Hostname";
                Expression = { $hostname }
            }, @{
                Name = "Date";
                Expression = { $date }
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
                Name = "FreeSpace(%)";
                Expression = { [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2) }
            }
        return $diskUtil
    }
    catch {
        Write-Error "Failed to retrieve disk utilization information from $ComputerName. Error: $_"
    }
}
