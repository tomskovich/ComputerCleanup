<#
    .SYNOPSIS
    Removes common system-wide temporary files and folders older than $Days old.
    OPTIONAL: Clears Windows Recycle Bin
    Folders:
        "$env:SystemRoot\Temp"
        "$env:SystemRoot\Logs\CBS"
        "$env:SystemRoot\Downloaded Program Files"
        "$env:ProgramData\Microsoft\Windows\WER"

    .NOTES
    Author:   Tom de Leeuw
    Website:  https://ucsystems.nl / https://tech-tom.com
#>
function Optimize-SystemFiles {
    [CmdletBinding()]
    param(
        # Only remove files and folders older than $Days old. 
        [Parameter(Mandatory = $true, Position = 0)]
        [int] $Days,

        # Removes common system-wide temporary files and folders older than $Days old.
        [switch] $TempFiles = $true,

        # Clears Windows Recycle Bin
        [switch] $RecycleBin
    )

    begin {
        # Get disk space for comparison afterwards
        $Before = Get-DiskSpace

        # Folders to clean up
        $Folders = @(
            "$env:SystemRoot\Temp",
            "$env:SystemRoot\Logs\CBS",
            "$env:SystemRoot\Downloaded Program Files",
            "$env:ProgramData\Microsoft\Windows\WER"
        )

        # Parameters for Get-ChildItem and Remove-Item
        $CommonParams = @{
            Recurse       = $true
            Force         = $true
            Verbose       = $true
            ErrorAction   = 'SilentlyContinue'
            WarningAction = 'SilentlyContinue'
        }
    }

    process {
        # Common temp files
        if ($TempFiles -eq $true) {
            Write-Verbose "Cleaning SYSTEM folders/files older than $Days days old..."
            foreach ($Folder in $Folders) {
                if (Test-Path -Path $Folder) {
                    try {
                        Get-ChildItem -Path $Folder @CommonParams |
                            Where-Object { ($_.CreationTime -and $_.LastWriteTime -lt $(Get-Date).AddDays(-$Days)) } |
                                Remove-Item @CommonParams
                    }
                    catch {
                        Write-Error $_
                    }
                }
            }
        }

        # Empty Recycle Bin
        if ($RecycleBin -eq $true) {
            try {
                Write-Verbose 'Clearing Recycle Bin'
                Clear-RecycleBin -Force
            }
            catch {
                Write-Error $_
            }
        }
    } # end Process

    end {
        # Get disk space again and calculate difference
        $After        = Get-DiskSpace
        $TotalCleaned = "$(($After.FreeSpace - $Before.FreeSpace).ToString('00.00')) GB"

        # Report
        if ($null -ne $script:CleanupReport -and $TempFiles -eq $true) {
            $script:CleanupReport.SystemFiles = $TotalCleaned
        }
        elseif ($null -ne $script:CleanupReport -and $RecycleBin -eq $true) {
            $script:CleanupReport.RecycleBin = $TotalCleaned
        }
        else {
            Write-Output "Total space cleaned: $TotalCleaned"
        }
    }
}