<#
    .SYNOPSIS
    Gets available disk space. Used for reporting.

    .NOTES
    Author:   Tom de Leeuw
    Website:  https://ucsystems.nl / https://tech-tom.com
#>
function Get-DiskSpace {
    $Disk = Get-Volume | Where-Object { $_.DriveLetter -eq 'C' } | Select-Object DriveLetter, FriendlyName, Size, SizeRemaining

    $Disk | Foreach-Object {
        $TotalSize = @{
            Expression = { [math]::round($_.Size / 1GB, 2) };
            Name       = 'TotalSize';
        }
        $FreeSpace = @{
            Expression = { [math]::round($_.SizeRemaining / 1GB, 2) };
            Name       = 'FreeSpace';
        }
        return $Disk | Select-Object DriveLetter, $TotalSize, $FreeSpace
    }
}