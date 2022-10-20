<#
    .SYNOPSIS
    Main controller function to invoke one or multiple cleanup functions included in this module.

    .LINK
    https://tech-tom.com

    .EXAMPLE
    Invoke-ComputerCleanup -Days 30 -UserTemp -SystemTemp -CleanManager -SoftwareDistribution -RecycleBin 

    Will do the following:
        - Run the Windows Disk Cleanup tool
        - Remove temp files in User profiles that are older than 30 days old.
        - Remove temp files in system that are older than 30 days old.
        - Clean the "C:\Windows\SoftwareDistribution\Downloads" folder.
        - Empty Recycle Bin.

    .NOTES
    Author:   Tom de Leeuw
    Website:  https://tech-tom.com / https://ucsystems.nl
#>
function Invoke-ComputerCleanup {
    [CmdletBinding()]
    param (
        # Only remove files and folders older than $Days old. 
        # This does NOT apply for parameters: -BrowserCache, -TeamsCache, -SoftwareDistribution, -FontCache
        [Parameter(Mandatory = $true, Position = 0)]
        [int] $Days,

        # Runs the Windows Disk Cleanup tool with predefined options.
        [switch] $CleanManager,

        # Removes common system-wide temporary files and folders older than $Days old.
        [switch] $SystemTemp,

        # Clears the "C:\Windows\SoftwareDistribution\Downloads" folder. 
        [switch] $SoftwareDistribution,

        # Clears user font cache files located in "C:\Windows\ServiceProfiles\LocalService\AppData\Local\"
        [switch] $FontCache,

        # Clears browser cache files for all users.
        # Browsers: Microsoft Edge, Internet Explorer, Google Chrome and Firefox.
        # WARNING: This will stop ALL running browser processes. Running outside of working hours is advised.
        [Parameter(ParameterSetName = 'User')]
        [switch] $BrowserCache,

        # Clears Microsoft Teams cache files for all users.
        # WARNING: This will stop ALL running Teams processes. Running outside of working hours is advised.
        [Parameter(ParameterSetName = 'User')]
        [switch] $TeamsCache,

        # Enabling this parameter will skip confirmation for parameters -Teams and -BrowserCache.
        # WARNING: Please use with caution!
        [Parameter(ParameterSetName = 'User')]
        [switch] $Force,

        # Removes common temporary files and folders older than $Days days old from user profiles.
        [Parameter(ParameterSetName = 'User')]
        [switch] $UserTemp,

        # Removes .ZIP, .RAR and .7z (default) files larger than (default) 500MB and more than $Days days old from users' downloads folder.
        [Parameter(ParameterSetName = 'User')]
        [switch] $UserDownloads,

        # List of filetypes to remove when parameter "-UserDownloads" is used. Default: .ZIP, .RAR, .7z, .ISO.
        [Parameter(ParameterSetName = 'User')]
        [array] $ArchiveTypes = @('zip', 'rar', '7z', 'iso'),

        # Clears the Windows Recycle Bin
        [switch] $RecycleBin
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

        # Initialize hashtables/arrays for reporting
        $script:CleanupReport = [ordered]@{}
        $ParamReport          = [ordered]@{}
        $RiskyParamReport     = [ordered]@{}
    }

    process {
        # Report parameter information to console
        switch ($PSBoundParameters.Keys) {
            'Days' {
                $ParamReport.Days = "Files older than $Days days will be removed. This DOES NOT apply to options 'Teams'!"
            }
            'CleanManager' {
                $ParamReport.CleanManager = "Runs the Windows Disk Cleanup tool with predefined options."
            }
            'SystemTemp' {
                $ParamReport.SystemTemp = "Removes common system-wide temporary files and folders older than $Days old."
            }
            'UserTemp' {
                $ParamReport.UserTemp = "Removes common temporary files and folders older than $Days days old from user profiles."
            }
            'UserDownloads' {
                $ParamReport.UserDownloads = "Removes .ZIP, .RAR and .7z (default) files larger than (default) 500MB and older than $Days days old from users' downloads folder."
            }
            'BrowserCache' {
                $ParamReport.BrowserCache      = "Clears cache files for all browsers."
                $RiskyParamReport.BrowserCache = "This will stop ALL running browser processes. Running outside of working hours is advised."
            }
            'SoftwareDistribution' {
                $ParamReport.SoftwareDistribution = "Cleans the 'C:\Windows\SoftwareDistribution\Download' folder."
            }
            'FontCache' {
                $ParamReport.FontCache = "Removes font cache files in 'C:\Windows\ServiceProfiles\LocalService\AppData\Local\'"
            }
            'TeamsCache' {
                $ParamReport.TeamsCache      = "Clears Microsoft Teams cache files for all users."
                $RiskyParamReport.TeamsCache = "This will stop ALL running Teams processes. Running outside of working hours is advised."
            }
            'RecycleBin' {
                $ParamReport.RecycleBin = "Clears the Windows Recycle Bin"
            }
        }

        if (($PSBoundParameters.Keys).Count -gt 0) {
            Write-Output ''.PadLeft(76, '-')
            Write-Output "=== SCRIPT OPTIONS SUMMARY:" 
            $ParamReport.keys | Select-Object @{l='Parameter';e={$_}},@{l='Description';e={$ParamReport.$_}} | Format-Table
            # Report risky parameters
            if ($RiskyParamReport.Count -gt 0) {
                Write-Warning "Some commands are dangerous to execute on a live environment. Please review:" 
                $RiskyParamReport.keys | Select-Object @{l='Parameter';e={$_}},@{l='Warning';e={$RiskyParamReport.$_}} | Format-Table
            }
            Write-Output ''.PadLeft(76, '-')
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

        if ($CleanManager -eq $true) {
            try {
                Write-Output '=== STARTED : Windows Disk Cleanup'
                Invoke-CleanManager
                Write-Output '=== FINISHED: Windows Disk Cleanup'
            }
            catch {
                Write-Error $_
            }
        }

        if ($UserTemp -eq $true) {
            $UserParams = @{
                Days      = $Days
            }
            $UserParams.TempFiles = $true
            if ($UserDownloads -eq $true) {
                $UserParams.Downloads    = $true
                $UserParams.ArchiveFiles = $true
            }
            try {
                Write-Output '=== STARTED : Cleaning User Profiles'
                Optimize-UserProfiles @UserParams
                Write-Output '=== FINISHED: Cleaning User Profiles'
            }
            catch {
                Write-Error $_
            }
        }

        if ($SystemTemp -eq $true) {
            $SystemParams = @{
                Days      = $Days
                TempFiles = $true
            }
            try {
                Write-Output '=== STARTED : Cleaning System files'
                Optimize-SystemFiles @SystemParams
                Write-Output '=== FINISHED: Cleaning System files'
            }
            catch {
                Write-Error $_
            }
        }

        if ($SoftwareDistribution -eq $true) {
            Write-Output '=== STARTED : Cleaning SoftwareDistribution Download folder'
            Clear-SoftwareDistribution
            Write-Output '=== FINISHED: Cleaning SoftwareDistribution Download folder'
        }

        if ($FontCache -eq $true) {
            Write-Output '=== STARTED : Cleaning Font Cache'
            Clear-FontCache
            Write-Output '=== FINISHED: Cleaning Cleaning Font Cache'
        }

        if ($BrowserCache -eq $true) {
            try {
                Write-Output '=== STARTED : Cleaning Browser Cache'
                Clear-BrowserCache
                Write-Output '=== FINISHED: Cleaning Browser Cache'
            }
            catch {
                Write-Error $_
            }
        }

        if ($TeamsCache-eq $true) {
            $TeamsParams = @{}
            if ($Force -eq $true) {
                $TeamsParams.Force = $true
            }
            try {
                Write-Output '=== STARTED : Cleaning Teams cache'
                Clear-TeamsCache @TeamsParams
                Write-Output '=== FINISHED: Cleaning Teams cache'
            }
            catch {
                Write-Error $_
            }
        }

        if ($RecycleBin -eq $true) {
            try {
                Write-Output '=== STARTED : Cleaning Recycle Bin'
                Optimize-SystemFiles $Days -RecycleBin 
                Write-Output '=== FINISHED: Cleaning Recycle Bin'
            }
            catch {
                Write-Error $_
            }
        }
    } # end Process

    end {
        # Get time again, calculate total run time
        $EndTime      = (Get-Date)
        $TotalSeconds = [int]$(($EndTime - $StartTime).TotalSeconds)
        $TotalMinutes = [int]$(($EndTime - $StartTime).TotalMinutes)

        # Get disk space again and calculate difference
        $After        = Get-DiskSpace
        $TotalCleaned = "$(($After.FreeSpace - $Before.FreeSpace).ToString('00.00')) GB"

        # Report
        Write-Output ''.PadLeft(76, '-')
        Write-Output '=== SCRIPT FINISHED'
        Write-Output ''.PadLeft(76, '-')
        Write-Output '=== PER-SECTION BREAKDOWN'
        $script:CleanupReport.TOTAL = $TotalCleaned
        $script:CleanupReport
        Write-Output ''.PadLeft(76, '-')
        Write-Output ''.PadLeft(76, '-')
        Write-Output "Current Time          : $(Get-Date | Select-Object -ExpandProperty DateTime)"
        Write-Output "Elapsed Time          : $TotalSeconds seconds / $TotalMinutes minutes"
        Write-Output "Free space BEFORE     : $(($Before.FreeSpace).ToString()) GB"
        Write-Output "Free space AFTER      : $(($After.FreeSpace).ToString()) GB"
        Write-Output "Total space cleaned   : $TotalCleaned"
        Write-Output ''.PadLeft(76, '-')

        # Stop logging
        Stop-Transcript
    } # end End
}