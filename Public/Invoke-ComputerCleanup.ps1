function Invoke-ComputerCleanup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [int] $Days,

        [switch] $UserTemp,

        [switch] $UserDownloads,

        [array] $ArchiveTypes = @('zip', 'rar', '7z', 'iso'),

        [switch] $SystemTemp,

        [switch] $RecycleBin,

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
    }

    process {
        # Write all enabled script options to console
        Write-Host -ForegroundColor 'Cyan' "=== SCRIPT OPTIONS SUMMARY:" 
        switch ($PSBoundParameters.Keys) {
            'Days' {
                Write-Host "-Days"
                Write-Host  -ForegroundColor 'Cyan' "=== Files older than $Days old will be removed. This DOES NOT apply to options 'Teams'!"
            }
            'SystemTemp' {
                Write-Host "-SystemTemp"
                Write-Host -ForegroundColor 'Cyan' "=== This will remove general system-wide temporary files and folders."
            }
            'UserTemp' {
                Write-Host "-UserTemp"
                Write-Host -ForegroundColor 'Cyan' "=== This will remove temporary files and folders from user profiles."
            }
            'UserDownloads' {
                Write-Host "-UserDownloads"
                Write-Host -ForegroundColor 'Cyan' "=== This will remove .ZIP, .RAR and .7z files >200MB and >$Days days old from users' downloads folder!"
            }
            'BrowserCache' {
                Write-Host "-BrowserCache"
                Write-Host -ForegroundColor 'Cyan' "=== This will remove cache files for all browsers."
            }
            'CleanManager' {
                Write-Host "-CleanManager"
                Write-Host -ForegroundColor 'Cyan' "=== This will run the Windows Disk Cleanup tool with predefined options."
            }
            'Teams' {
                Write-Host "-BrowserCache"
                Write-Host -ForegroundColor 'Cyan' "=== This will remove cache files for all browsers."
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
                    throw "Script aborted by user input."
                }
                default {
                    throw "Script aborted by user input."
                }
            }
        }

        if ($UserTemp -eq $true) {
            $UserParams = @{
                Days      = $Days
                TempFiles = $true
            }
            if ($UserDownloads -eq $true) {
                $UserParams.Downloads    = $true
                $UserParams.ArchiveFiles = $true
            }
            if ($BrowserCache -eq $true) {
                $UserParams.BrowserCache = $true
            }
            try {
                Write-Host '=== STARTED : Cleaning User Profiles' -ForegroundColor Yellow
                Optimize-UserProfiles @UserParams
                Write-Host '=== FINISHED: Cleaning User Profiles' -ForegroundColor Green
            }
            catch {
                Write-Error $_
            }
        }

        if ($SystemTemp -eq $true) {
            $SystemParams = @{
                Days = $Days
            }
            if ($RecycleBin -eq $true) {
                $SystemParams.RecycleBin = $true
            }
            try {
                Write-Host '=== STARTED : Cleaning System files' -ForegroundColor Yellow
                Optimize-SystemFiles @SystemParams
                Write-Host '=== FINISHED: Cleaning System files' -ForegroundColor Green
            }
            catch {
                Write-Error $_
            }
        }

        if ($Teams -eq $true) {
            $TeamsParams = @{}
            if ($Force -eq $true) {
                $TeamsParams.Force = $true
            }
            try {
                Write-Host '=== STARTED : Cleaning Teams cache' -ForegroundColor Yellow
                Clear-TeamsCache @TeamsParams
                Write-Host '=== FINISHED: Cleaning Teams cache' -ForegroundColor Green
            }
            catch {
                Write-Error $_
            }
        }

        if ($CleanManager -eq $true) {
            try {
                Write-Host '=== STARTED : Windows Disk Cleanup' -ForegroundColor Yellow
                Invoke-CleanManager
                Write-Host '=== FINISHED: Windows Disk Cleanup' -ForegroundColor Green
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