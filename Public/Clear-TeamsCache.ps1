function Clear-TeamsCache {
    param(
        # Enabling this parameter will skip confirmation.
        [Switch] $Force
    )

    begin {
        # Get disk space for comparison afterwards
        $Before = Get-DiskSpace

        # Get all user folders, exclude administrators and default users
        $Users = Get-UserFolders

        # Folders to clean up
        $Folders = @(
            'AppData\Roaming\Microsoft\teams\blob_storage',
            'AppData\Roaming\Microsoft\teams\databases',
            'AppData\Roaming\Microsoft\teams\cache',
            'AppData\Roaming\Microsoft\teams\gpucache',
            'AppData\Roaming\Microsoft\teams\Indexeddb',
            'AppData\Roaming\Microsoft\teams\Local Storage',
            'AppData\Roaming\Microsoft\teams\tmp'
        )

        # Parameters for Get-ChildItem and Remove-Item
        $CommonParams = @{
            Recurse       = $true
            Force         = $true
            Verbose       = $true
            ErrorAction   = 'SilentlyContinue'
            WarningAction = 'SilentlyContinue'
        }
    } # end Begin

    process {
        Write-Verbose "Starting Teams Cache cleanup process..."
        if ( -not ($Force)) {
            # Prompt for user verification before continuing
            $Confirmation = Read-Host -Prompt "Are you sure you want to run the cleanup with above settings? [Y/N]"
            while (($Confirmation) -notmatch "[yY]") {
                switch -regex ($Confirmation) {
                    "[yY]" {
                        continue
                    }
                    "[nN]" {
                        throw "Script aborted by user input."
                    }
                    default {
                        throw "Script aborted."
                    }
                }
            }
        }

        # Kill Teams process(es)
        try {
            Write-Verbose "Killing Teams process(es)..."
            Get-Process -ProcessName 'Teams' -ErrorAction 'SilentlyContinue' | Stop-Process -Force
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
                        Write-Verbose "Removed Teams Cache files for $Username."
                    }
                    catch {
                        Write-Error $_
                    }
                }
            }
        }
    } # end Process

    end {
        # Get disk space again and calculate difference
        $After        = Get-DiskSpace
        $TotalCleaned = "$(($After.FreeSpace - $Before.FreeSpace).ToString('00.00')) GB"

        # Add to report
        $script:CleanupReport.TeamsCache = $TotalCleaned
    }
}