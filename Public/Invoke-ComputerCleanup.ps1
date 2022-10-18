function Invoke-ComputerCleanup {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [ValidateNotNullOrempty()]
        [int] $Days = 15,

        [switch] $UserTemp,

        [switch] $UserDownloads,

        [switch] $SystemTemp,

        [switch] $CleanManager,

        [switch] $BrowserCache,

        [switch] $Teams,

        [switch] $Force
    )

    begin {
        # Start logging
        Start-Logging -LogName 'ComputerCleanup'
        # Verify if running as Administrator
        Assert-RunAsAdministrator
        # Start timer
        $StartTime = (Get-Date)
        # Get disk space for comparison afterwards
        $Before = Get-DiskSpace
    } # end Begin
    
    process {
        # Write all enabled script options to console
        Write-Host "=== SCRIPT OPTIONS SUMMARY:" -ForegroundColor Cyan
        switch ($PSBoundParameters.Keys) {
            'SystemTemp' {
                Write-Host "-Days"
                Write-Host "=== Files older than $Days old will be removed. (Default: 15) This DOES NOT apply to options 'Teams'!" -ForegroundColor 'Yellow'
            }
            'SystemTemp' {
                Write-Host "-SystemTemp"
                Write-Host "=== This will remove general system-wide temporary files and folders." -ForegroundColor 'Yellow'
            }
            'UserTemp' {
                Write-Host "-UserTemp"
                Write-Host "=== This will remove temporary files and folders from user profiles." -ForegroundColor 'Yellow'
            }
            'UserDownloads' {
                Write-Host "-UserDownloads"
                Write-Host "=== This will remove .ZIP, .RAR and .7z files >200MB and >$Days old from users' downloads folder!" -ForegroundColor 'Yellow'
            }
            'BrowserCache' {
                Write-Host "-BrowserCache"
                Write-Host "=== This will remove cache files for all browsers." -ForegroundColor 'Yellow'
            }
            'CleanManager' {
                Write-Host "-CleanManager"
                Write-Host "=== This will run the Windows Disk Cleanup tool with predefined options." -ForegroundColor 'Yellow'
            }
            'Teams' {
                Write-Host "-BrowserCache"
                Write-Host "=== This will remove cache files for all browsers." -ForegroundColor 'Yellow'
            }
        }

        # Prompt for user verification before continuing
        $Confirmation = Read-Host -Prompt "Are you sure you want to run the cleanup with above settings? [Y/N]"
        while (($Confirmation) -notmatch "[yY]") {
            switch -regex ($Confirmation) {
                "[yY]" {
                    continue
                }
                "[nN]" {
                    throw "Script aborted."
                }
                default {
                    throw "Script aborted."
                }
            }
        } 

        if ($UserTemp -eq $true) {
            $UserParams = @{
                Days      = $Days
                TempFiles = $true
            }
            if ($UserDownloads -eq $true) {
                $UserParams.Downloads = $true
                $UserParams.ArchiveFiles  = $true
            }
            if ($BrowserCache -eq $true) {
                $UserParams.BrowserCache = $true
            }
            try {
                Write-Host '===STARTED : Cleaning User Profiles' -ForegroundColor Yellow
                Optimize-UserFolders @UserParams
                Write-Host '===FINISHED: Cleaning User Profiles' -ForegroundColor Green
            }
            catch {
                Write-Error $_
            }
        }

        if ($SystemTemp -eq $true) {
            try {
                Write-Host '===STARTED : Cleaning System files' -ForegroundColor Yellow
                Optimize-SystemFolders -Days $Days
                Write-Host '===FINISHED: Cleaning System files' -ForegroundColor Green
            }
            catch {
                Write-Error $_
            }
        }

        if ($Teams -eq $true) {
            try {
                Write-Host '===STARTED : Cleaning Teams cache' -ForegroundColor Yellow
                if ($Force -eq $true) {
                    Optimize-TeamsCache -Force
                }
                else {
                    Optimize-TeamsCache
                }
                Write-Host '===FINISHED: Cleaning Teams cache' -ForegroundColor Green
            }
            catch {
                Write-Error $_
            }
        }

        if ($CleanManager -eq $true) {
            try {
                Write-Host '===STARTED : CleanMgr' -ForegroundColor Yellow
                Invoke-CleanManager
                Write-Host '===FINISHED: CleanMgr' -ForegroundColor Green
            }
            catch {
                Write-Error $_
            }
        }
    } # end Process
    
    end {
        # Get disk space again and calculate difference
        $After = Get-DiskSpace
        $TotalCleaned = "$(($After.FreeSpace - $Before.FreeSpace).ToString('00.00')) GB"

        # Get time again, calculate total run time
        $EndTime = (Get-Date)
        $TotalSeconds = [int]$(($EndTime - $StartTime).TotalSeconds)
        $TotalMinutes = [int]$(($EndTime - $StartTime).TotalMinutes)
    
        # Report
        Write-Host '=== SCRIPT FINISHED' -ForegroundColor GREEN -BackgroundColor Black
        Write-Host ''.PadLeft(76, '-') -ForegroundColor Green -BackgroundColor Black
        Write-Host "Current Time          : $(Get-Date | Select-Object -ExpandProperty DateTime)" -ForegroundColor Green -BackgroundColor Black
        Write-Host "Elapsed Time          : $TotalSeconds seconds / $TotalMinutes minutes" -ForegroundColor Green -BackgroundColor Black
        Write-Host "Free space BEFORE     : $(($Before.FreeSpace).ToString()) GB" -ForegroundColor Green -BackgroundColor Black
        Write-Host "Free space AFTER      : $(($After.FreeSpace).ToString()) GB" -ForegroundColor Green -BackgroundColor Black
        Write-Host "Total space cleaned   : $TotalCleaned" -ForegroundColor Green -BackgroundColor Black
        Write-Host ''.PadLeft(76, '-') -ForegroundColor Green -BackgroundColor Black
    
        # Stop logging
        Stop-Transcript
    } # end End
}