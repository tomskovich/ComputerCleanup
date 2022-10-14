function Invoke-ComputerCleanup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int] $Days,

        [switch] $UserFolders,

        [switch] $SystemFolders,

        [switch] $CleanManager,

        [switch] $BrowserCache,

        [switch] $Teams
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
        if ($UserFolders -eq $true) {
            try {
                Write-Host '[STARTED: Cleaning User folders]' -ForegroundColor Yellow
                Optimize-UserFolders -Days $Days -Downloads -GenericFiles -ArchiveFiles
                Write-Host '[FINISHED: Cleaning User Folders]' -ForegroundColor Green
            }
            catch {
                Write-Error $_
            }
        }

        if ($CleanManager -eq $true) {
            try {
                Write-Host '[STARTED: CleanMgr]' -ForegroundColor Yellow
                Invoke-CleanManager
                Write-Host '[FINISHED: CleanMgr]' -ForegroundColor Green
            }
            catch {
                Write-Error $_
            }
        }

        if ($SystemFolders -eq $true) {
            try {
                Write-Host '[STARTED: Cleaning System folders]' -ForegroundColor Yellow
                Optimize-SystemFolders -Days $Days
                Write-Host '[FINISHED: Cleaning System Folders]' -ForegroundColor Green
            }
            catch {
                Write-Error $_
            }
        }

        if ($Teams -eq $true) {
            try {
                Write-Host '[STARTED: Cleaning System folders]' -ForegroundColor Yellow
                Remove-TeamsCache
                Write-Host '[FINISHED: Cleaning System Folders]' -ForegroundColor Green
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
        Write-Host '############################## REPORT SECTION ##############################' -ForegroundColor Yellow -BackgroundColor Black
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