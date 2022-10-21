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
        [Switch] $Force,

        [ValidateNotNullOrEmpty()]
        [ValidateSet("All","Chrome","Edge","IE","Firefox")]
        [Alias('Browser')]
        [string[]] $Browsers = "All"
    )

    begin {
        # Verify if running as Administrator
        Assert-RunAsAdministrator

        # Get disk space for comparison afterwards
        $Before = Get-DiskSpace

        # Get all user folders, exclude administrators and default users
        $Users = Get-UserFolders

        # Initialize empty array to add folders to
        $Folders = @()

        # Edge (Chromium)
        $EdgeFolders = @(
            '\AppData\Local\Microsoft\Microsoft\Edge\User Data\Default\Cache'
        )

        # Internet Explorer
        $IEFolders = @(
            '\AppData\Local\Microsoft\Windows\Temporary Internet Files',
            '\AppData\Local\Microsoft\Windows\WebCache',
            '\AppData\Local\Microsoft\Windows\INetCache',
            '\AppData\Local\Microsoft\Internet Explorer\DOMStore'
        )

        # Google Chrome
        $ChromeFolders = @(
            '\AppData\Local\Google\Chrome\User Data\Default\Cache',
            '\AppData\Local\Google\Chrome\User Data\Default\Cache2\entries',
            '\AppData\Local\Google\Chrome\User Data\Default\Media Cache'
        )

        # Firefox
        $FireFoxFolders = @(
            '\AppData\Local\Mozilla\Firefox\Profiles\*.default\cache',
            '\AppData\Local\Mozilla\Firefox\Profiles\*.default\cache2\entries',
            '\AppData\Local\Mozilla\Firefox\Profiles\*.default\thumbnails',
            '\AppData\Local\Mozilla\Firefox\Profiles\*.default\webappsstore.sqlite',
            '\AppData\Local\Mozilla\Firefox\Profiles\*.default\chromeappsstore.sqlite'
        )

        switch ($Browsers) {
            { $_ -match 'All' } { 
                # Add all folders
                $Folders = $EdgeFolders + $IEFolders + $ChromeFolders + $FireFoxFolders
                # Change variable value from "All" to list of all browsers
                $Browsers = @("Chrome","Edge","IE","Firefox")
            }
            { $_ -match 'Edge' } { 
                $Folders = $Folders + $EdgeFolders
            }
            { $_ -match 'IE' } { 
                $Folders = $Folders + $IEFolders
            }
            { $_ -match 'Chrome' } {
                $Folders = $Folders + $ChromeFolders
            }
            { $_ -match 'Firefox' } { 
                $Folders = $Folders + $FireFoxFolders
            }
        }

        # Parameters for Get-ChildItem and Remove-Item
        $CommonParams = @{
            Recurse       = $true
            Force         = $true
            Verbose       = $true
            ErrorAction   = 'Continue'
            WarningAction = 'SilentlyContinue'
        }
    }

    process {
        Write-Verbose "Starting browser cache cleanup process..."
        if ( -not ($Force)) {
            # Prompt for user verification before continuing
            Get-UserConfirmation -WarningMessage "This will stop all running Browser processes!"
        }

        # Kill browser process(es)
        foreach ($Browser in $Browsers) {
            try {
                Write-Verbose "Killing $Browser process(es)..."
                Get-Process -ProcessName $Browser -ErrorAction 'Stop' | Stop-Process
            }
            catch [Microsoft.PowerShell.Commands.ProcessCommandException] {
                Write-Information "No running $($_.Exception.ProcessName) processes."
            }
        }

        # Start cleaning files
        ForEach ($Username In $Users) {
            ForEach ($Folder In $Folders) {
                $FolderToClean = "$env:SYSTEMDRIVE\Users\$Username\$Folder"
                If (Test-Path -Path $FolderToClean) {
                    try {
                        Get-ChildItem -Path $FolderToClean -Recurse -Force -Verbose -ErrorAction 'SilentlyContinue' | Remove-Item @CommonParams
                    }
                    catch [System.IO.IOException] {
                        Write-Error "File in use: $($_.TargetObject)"
                    }
                    catch [System.UnauthorizedAccessException] {
                        Write-Error "Access denied for path: $($_.TargetObject)"
                    }
                }
            }
            Write-Verbose "Removed browser cache files for $Username."
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
