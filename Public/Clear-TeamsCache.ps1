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
        [Parameter(ValuefromPipeline = $True)]
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

        # Prompt for user verification before continuing
        if ( -not ($Force)) {
            Get-UserConfirmation -WarningMessage "This will stop all running Teams processes!"
        }

        # Kill Teams process(es)
        try {
            Write-Verbose "Killing Teams process(es)..."
            Get-Process -ProcessName 'Teams' -ErrorAction 'Stop' | Stop-Process -Force -Confirm:$false
        }
        catch [Microsoft.PowerShell.Commands.ProcessCommandException] {
            Write-Information "No running $($_.Exception.ProcessName) processes."
        }
        catch {
            Write-Error "$($_.Exception.Message)"
        }

        # Start cleaning files
        ForEach ($UserName In $Users) {
            ForEach ($FolderName In $Folders) {
                If (Test-Path -Path "$env:SYSTEMDRIVE\Users\$UserName\$FolderName") {
                    try {
                        Get-ChildItem -Path "$env:SYSTEMDRIVE\Users\$UserName\$FolderName" @CommonParams | Remove-Item @CommonParams
                    }
                    catch {
                        Write-Error $_
                    }
                }
            }
            Write-Verbose "Removed Teams Cache files for $UserName."
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

