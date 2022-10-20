<#
    .SYNOPSIS
    Clears user font cache files located in "C:\Windows\ServiceProfiles\LocalService\AppData\Local\"

    .NOTES
    Author:   Tom de Leeuw
    Website:  https://ucsystems.nl / https://tech-tom.com
#>
function Clear-FontCache {
    begin {
        # Get disk space for comparison afterwards
        $Before = Get-DiskSpace

        # Location of FontCache files
        $Folder = "C:\Windows\ServiceProfiles\LocalService\AppData\Local\"

        # Grab only the user cache files
        $Filter = "FontCache-S-*.dat"

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
        try {
            Write-Verbose 'Stopping Font Cache service...'
            Get-Service -Name 'fontcache' | Stop-Service
        }
        catch {
            Write-Warning $_
        }

        if (Test-Path -Path $Folder) {
            try {
                Get-ChildItem -Path $Folder -Filter $Filter @CommonParams | Remove-Item @CommonParams
            }
            catch {
                Write-Warning $_
            }
        }

        try {
            Write-Verbose 'Starting Font Cache service...'
            Get-Service -Name 'fontcache' | Start-Service
        }
        catch {
            Write-Warning $_
        }
    }
    
    end {
        # Get disk space again and calculate difference
        $After        = Get-DiskSpace
        $TotalCleaned = "$(($After.FreeSpace - $Before.FreeSpace).ToString('00.00')) GB"

        # Report
        if ($null -ne $script:CleanupReport) {
            $script:CleanupReport.FontCache = $TotalCleaned
        }
        else {
            Write-Output "Total space cleaned: $TotalCleaned"
        }
    }
}