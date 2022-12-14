<#
    .SYNOPSIS
    Runs the Windows Disk Cleanup tool with predefined options.
    If you want to enable- or disable some options, you can comment or uncomment lines in $Sections.

    .DESCRIPTION
    Default enabled options are:
        'Active Setup Temp Folders',
        'BranchCache',
        'Device Driver Packages',
        'Downloaded Program Files',
        'GameNewsFiles',
        'GameStatisticsFiles',
        'GameUpdateFiles',
        'Memory Dump Files',
        'Offline Pages Files',
        'Old ChkDsk Files',
        'Previous Installations',
        'Service Pack Cleanup',
        'Setup Log Files',
        'System error memory dump files',
        'System error minidump files',
        'Temporary Files',
        'Temporary Setup Files',
        'Thumbnail Cache',
        'Update Cleanup',
        'Upgrade Discarded Files',
        'Windows Defender',
        'Windows ESD installation files',
        'Windows Error Reporting Archive Files'
        'Windows Error Reporting Queue Files',
        'Windows Error Reporting System Archive Files',
        'Windows Error Reporting System Queue Files',
        'Windows Upgrade Log Files'

    Default disabled options:
        "User file versions"
        'Recycle Bin',
        'Temporary Sync Files',
        "DownloadsFolder",

    .NOTES
    Author:   Tom de Leeuw
    Website:  https://tech-tom.com / https://ucsystems.nl
#>
function Invoke-CleanManager {
    begin {
        # Get disk space for comparison afterwards
        $Before = Get-DiskSpace

        # Checks if Disk Cleanup is installed, if not; install it (For Server 2008 R2 without Cleanmgr preinstalled)
        if ( ! (Test-Path "$env:SystemRoot\System32\cleanmgr.exe")) {
            Write-Warning 'Windows Cleanup NOT installed! Trying installation...'
            try {
                if (Test-Path "$env:SystemRoot\Winsxs\amd64_microsoft-windows-cleanmgr_31bf3856ad364e35_6.1.7600.16385_none_c9392808773cd7da\cleanmgr.exe") {
                    Copy-Item "$env:SystemRoot\Winsxs\amd64_microsoft-windows-cleanmgr_31bf3856ad364e35_6.1.7600.16385_none_c9392808773cd7da\cleanmgr.exe" -Destination "$env:SystemRoot\System32"
                }
                if (Test-Path "$env:SystemRoot\Winsxs\amd64_microsoft-windows-cleanmgr.resources_31bf3856ad364e35_6.1.7600.16385_en-us_b9cb6194b257cc63\cleanmgr.exe.mui") {
                    Copy-Item "$env:SystemRoot\Winsxs\amd64_microsoft-windows-cleanmgr.resources_31bf3856ad364e35_6.1.7600.16385_en-us_b9cb6194b257cc63\cleanmgr.exe.mui" -Destination "$env:SystemRoot\System32\en-US"
                }
                elseif ( ! (Get-WindowsFeature 'Desktop-Experience')) {
                    Write-Verbose 'Manual file copy failed. Installing Desktop Experience feature...'
                    Install-WindowsFeature 'Desktop-Experience'
                }
            }
            catch {
                Write-Error $_
            }
        }

        # Check if Disk Cleanup is available again before continuing
        if ( ! (Test-Path "$env:SystemRoot\System32\cleanmgr.exe")) {
            throw "Windows Disk Cleanup tool not installed! Aborting..."
        }

        # Enabled sections to be used by Disk Cleanup
        $Sections = @(
            'Active Setup Temp Folders',
            'BranchCache',
            'Device Driver Packages',
            'Downloaded Program Files',
            #"DownloadsFolder",
            'GameNewsFiles',
            'GameStatisticsFiles',
            'GameUpdateFiles',
            #'Memory Dump Files',
            'Offline Pages Files',
            'Old ChkDsk Files',
            'Previous Installations',
            #'Recycle Bin',
            'Service Pack Cleanup',
            'Setup Log Files',
            #'System error memory dump files',
            #'System error minidump files',
            'Temporary Files',
            'Temporary Setup Files',
            #'Temporary Sync Files',
            'Thumbnail Cache',
            'Update Cleanup',
            'Upgrade Discarded Files',
            #"User file versions"
            'Windows Defender',
            'Windows ESD installation files',
            'Windows Error Reporting Archive Files'
            'Windows Error Reporting Queue Files',
            'Windows Error Reporting System Archive Files',
            'Windows Error Reporting System Queue Files',
            'Windows Upgrade Log Files'
        )
    }

    process {
        # Clear current registry entries
        Write-Verbose 'Clearing current CleanMgr.exe automation settings...'
        $RegistryParams = @{
            Path        = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\*'
            Name        = 'StateFlags0001'
            ErrorAction = 'SilentlyContinue'
        }
        [void] (Get-ItemProperty @RegistryParams | Remove-ItemProperty -Name 'StateFlags0001' -ErrorAction SilentlyContinue)

        # Add registry entries according to $Sections defined above
        Write-Verbose 'Adding enabled disk cleanup sections'
        foreach ($key in $Sections) {
            $newItemParams = @{
                Path         = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\$key"
                Name         = 'StateFlags0001'
                Value        = 1
                PropertyType = 'DWord'
                ErrorAction  = 'SilentlyContinue'
            }
            [void] (New-ItemProperty @newItemParams)
        }

        try {
            Write-Verbose 'Running CleanMgr.exe...'
            Start-Process -FilePath "$env:systemroot\system32\Cleanmgr.exe" -ArgumentList '/sagerun:1' -NoNewWindow -Wait

            Write-Verbose 'Waiting for CleanMgr and DismHost processes.'
            Get-Process -Name cleanmgr, dismhost -ErrorAction SilentlyContinue | Wait-Process
        }
        catch {
            Write-Error $_
        }
    }

    end {
        # Get disk space again and calculate difference
        $After        = Get-DiskSpace
        $TotalCleaned = "$(($After.FreeSpace - $Before.FreeSpace).ToString('00.00')) GB"

        # Report
        if ($null -ne $script:CleanupReport) {
            $script:CleanupReport.CleanManager = $TotalCleaned
        }
        else {
            Write-Output "Total space cleaned: $TotalCleaned"
        }
    }
}