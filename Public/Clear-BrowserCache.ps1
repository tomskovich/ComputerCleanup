<#
    .SYNOPSIS
    Clears browser cache files for all users.
    Browsers: Microsoft Edge, Internet Explorer, Google Chrome and Firefox.

    .NOTES
    Author:   Tom de Leeuw
    Website:  https://ucsystems.nl / https://tech-tom.com
#>
function Clear-BrowserCache {
    [CmdletBinding(ConfirmImpact='Medium', SupportsShouldProcess = $true)]
    param(
        # Enabling this parameter will skip confirmation.
        [Parameter(ValuefromPipeline = $True)]
        [Switch] $Force,

        [ValidateNotNullOrEmpty()]
        [ValidateSet("All", "Chrome", "Edge", "IE", "Firefox")]
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
        $BrowserProcesses = @()

        # Edge (Chromium)
        $EdgeFolders = @(
            'AppData\Local\Microsoft\Edge\User Data\Default\Cache',
            'AppData\Local\Microsoft\Edge\User Data\Default\Cache\Cache_Data'
        )

        # Internet Explorer
        $IEFolders = @(
            'AppData\Local\Microsoft\Windows\Temporary Internet Files',
            'AppData\Local\Microsoft\Windows\WebCache',
            'AppData\Local\Microsoft\Windows\INetCache\Content.IE5',
            'AppData\Local\Microsoft\Windows\INetCache\Low\Content.IE5',
            'AppData\Local\Microsoft\Internet Explorer\DOMStore'
        )

        # Google Chrome
        $ChromeFolders = @(
            'AppData\Local\Google\Chrome\User Data\Default\Cache',
            'AppData\Local\Google\Chrome\User Data\Default\Cache2\entries',
            'AppData\Local\Google\Chrome\User Data\Default\Media Cache',
            'AppData\Local\Google\Chrome\User Data\Default\Code Cache'
        )

        # Firefox
        $FireFoxFolders = @(
            'AppData\Local\Mozilla\Firefox\Profiles\*.default\cache',
            'AppData\Local\Mozilla\Firefox\Profiles\*.default\cache2\entries',
            'AppData\Local\Mozilla\Firefox\Profiles\*.default\thumbnails',
            'AppData\Local\Mozilla\Firefox\Profiles\*.default\webappsstore.sqlite',
            'AppData\Local\Mozilla\Firefox\Profiles\*.default\chromeappsstore.sqlite'
        )

        switch ($Browsers) {
            { $_ -match 'All' } { 
                # Add all folders
                $Folders = $EdgeFolders + $IEFolders + $ChromeFolders + $FireFoxFolders
                # Change variable value from "All" to list of all browsers
                $Browsers = @("Chrome","Edge","IE","Firefox")
                $BrowserProcesses = @('msedge', 'iexplore', 'chrome', 'firefox')
            }
            { $_ -match 'Edge' } { 
                $Folders = $Folders + $EdgeFolders
                $BrowserProcesses = $BrowserProcesses + 'msedge'
            }
            { $_ -match 'IE' } { 
                $Folders = $Folders + $IEFolders
                $BrowserProcesses = $BrowserProcesses + 'iexplore'
            }
            { $_ -match 'Chrome' } {
                $Folders = $Folders + $ChromeFolders
                $BrowserProcesses = $BrowserProcesses + 'chrome'
            }
            { $_ -match 'Firefox' } { 
                $Folders = $Folders + $FireFoxFolders
                $BrowserProcesses = $BrowserProcesses + 'firefox'
            }
        }
    }

    process {
        Write-Verbose "Starting browser cache cleanup process..."

        # Prompt for user verification before continuing
        if ( -not ($Force)) {
            Get-UserConfirmation -WarningMessage "This will stop all running Browser processes!"
        }

        # Kill browser process(es)
        foreach ($Browser in $BrowserProcesses) {
            try {
                Write-Verbose "Killing $Browser process(es)..."
                Get-Process -ProcessName $Browser -ErrorAction 'Stop' | Stop-Process -Force -Confirm:$false
            }
            catch [Microsoft.PowerShell.Commands.ProcessCommandException] {
                Write-Information "No running $($_.Exception.ProcessName) processes."
            }
            catch {
                Write-Error "$($Browser): $($_.Exception.Message)"
            }
        }

        # Start cleaning files
        ForEach ($Username In $Users) {
            $FilesToClean = ForEach ($Folder In $Folders) {
                $FolderToClean = "$env:SYSTEMDRIVE\Users\$Username\$Folder"
                If (Test-Path -Path $FolderToClean) {
                    Write-Host "Cleaning $($FolderToClean)"
                    try {
                        Get-ChildItem -Path $FolderToClean -File -Recurse -Force -Verbose -ErrorAction 'SilentlyContinue'
                    }
                    catch [System.IO.IOException] {
                        Write-Error "File in use: $($_.TargetObject)"
                    }
                    catch [System.UnauthorizedAccessException] {
                        Write-Error "Access denied for path: $($_.TargetObject)"
                    }
                    catch {
                        Write-Error "$($Username): $($_.Exception.Message)"
                    }
                }
            }
            $FilesToClean | Remove-Item -Recurse -Force -Verbose -ErrorAction 'SilentlyContinue'
            Write-Information "Removed browser cache files for $Username."
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

