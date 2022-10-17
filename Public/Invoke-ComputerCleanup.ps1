function Invoke-ComputerCleanup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int] $Days,

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