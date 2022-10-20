<#
    .SYNOPSIS
    Clears browser cache files for all users.
    Browsers: Microsoft Edge, Internet Explorer, Google Chrome and Firefox.

    .NOTES
    Author:   Tom de Leeuw
    Website:  https://ucsystems.nl / https://tech-tom.com
#>
function Clear-BrowserCache {
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
            # Edge
            '\AppData\Local\Microsoft\Microsoft\Edge\User Data\Default\Cache',
            # Internet Explorer
            '\AppData\Local\Microsoft\Windows\Temporary Internet Files',
            '\AppData\Local\Microsoft\Windows\WebCache',
            '\AppData\Local\Microsoft\Windows\INetCache',
            '\AppData\Local\Microsoft\Internet Explorer\DOMStore',
            # Google Chrome
            '\AppData\Local\Google\Chrome\User Data\Default\Cache',
            '\AppData\Local\Google\Chrome\User Data\Default\Cache2\entries',
            '\AppData\Local\Google\Chrome\User Data\Default\Media Cache',
            # Firefox
            '\AppData\Local\Mozilla\Firefox\Profiles\*.default\cache',
            '\AppData\Local\Mozilla\Firefox\Profiles\*.default\cache2\entries',
            '\AppData\Local\Mozilla\Firefox\Profiles\*.default\thumbnails',
            '\AppData\Local\Mozilla\Firefox\Profiles\*.default\webappsstore.sqlite',
            '\AppData\Local\Mozilla\Firefox\Profiles\*.default\chromeappsstore.sqlite'
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
        Write-Verbose "Starting browser cache cleanup process..."
        if ( -not ($Force)) {
            # Prompt for user verification before continuing
            Write-Warning "This will stop all running browser processes!"
            $Confirmation = Read-Host -Prompt "Are you sure you want to continue? [Y/N]"
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

        # Kill browser process(es)
        try {
            Write-Verbose "Killing browser process(es)..."
            Get-Process -ProcessName 'Chrome', 'Firefox', 'iexplore' -ErrorAction 'SilentlyContinue' | Stop-Process
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
                        Write-Verbose "Removed browser cache files for $Username."
                    }
                    catch {
                        Write-Error $_
                    }
                }
            }
        }
    }

    end {
        # Get disk space again and calculate difference
        $After        = Get-DiskSpace
        $TotalCleaned = "$(($After.FreeSpace - $Before.FreeSpace).ToString('00.00')) GB"

        # Report
        if ($null -ne $script:CleanupReport) {
            $script:CleanupReport.BrowserCache = $TotalCleaned
        }
        else {
            Write-Output "Total space cleaned: $TotalCleaned"
        }
    }
}
