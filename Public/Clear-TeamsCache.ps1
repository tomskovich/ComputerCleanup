<#
    .SYNOPSIS
    Clears Microsoft Teams cache files for all users.

    .NOTES
    Author:   Tom de Leeuw
    Website:  https://ucsystems.nl / https://tech-tom.com
#>
function Clear-TeamsCache {
    [CmdletBinding(ConfirmImpact='Medium', SupportsShouldProcess = $true)]
    param(
        # Enabling this parameter will skip confirmation.
        [Switch] $Force
    )

    begin {
        # Verify if running as Administrator
        Assert-RunAsAdministrator

        # Get disk space for comparison afterwards
        $Before = Get-DiskSpace

        # Get all user folders, exclude administrators and default users
        $Users = Get-UserFolders

        # Folders to clean up
        $Folders = @(
            'AppData\Roaming\Microsoft\Teams\blob_storage',
            'AppData\Roaming\Microsoft\Teams\databases',
            'AppData\Roaming\Microsoft\Teams\cache',
            'AppData\Roaming\Microsoft\Teams\gpucache',
            'AppData\Roaming\Microsoft\Teams\Indexeddb',
            'AppData\Roaming\Microsoft\Teams\Local Storage',
            'AppData\Roaming\Microsoft\Teams\tmp'
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
        Write-Verbose "Starting Teams Cache cleanup process..."
        if ( -not ($Force)) {
            # Prompt for user verification before continuing
            Get-UserConfirmation -WarningMessage "This will stop all running Teams processes!"
        }

        # Kill Teams process(es)
        try {
            Write-Verbose "Killing Teams process(es)..."
            Get-Process -ProcessName 'Teams' -ErrorAction 'SilentlyContinue' | Stop-Process
        }
        catch {
            Write-Error $_
        }

        # Start cleaning files
        ForEach ($Username In $Users) {
            ForEach ($Folder In $Folders) {
                If (Test-Path -Path "$env:SYSTEMDRIVE\Users\$Username\$Folder") {
                    try {
                        Get-ChildItem -Path "$env:SYSTEMDRIVE\Users\$Username\$Folder" @CommonParams | Remove-Item @CommonParams
                    }
                    catch {
                        Write-Error $_
                    }
                }
            }
            Write-Verbose "Removed Teams Cache files for $Username."
        }
    }

    end {
        # Get disk space again and calculate difference
        $After        = Get-DiskSpace
        $TotalCleaned = "$(($After.FreeSpace - $Before.FreeSpace).ToString('00.00')) GB"

        # Report
        if ($null -ne $script:CleanupReport) {
            $script:CleanupReport.TeamsCache = $TotalCleaned
        }
        else {
            Write-Output "Total space cleaned: $TotalCleaned"
        }
    }
}

