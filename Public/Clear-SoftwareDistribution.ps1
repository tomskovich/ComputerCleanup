function Clear-SoftwareDistribution {
    begin {
        # Get disk space for comparison afterwards
        $Before = Get-DiskSpace
    }

    process {
        # Stop required services
        try {
            Write-Verbose 'Stopping Windows Update & Background Intelligent Transfer services...'
            Get-Service -Name 'wuauserv', 'bits' | Stop-Service
        }
        catch {
            Write-Warning $_
        }

        # Rename SoftwareDistribution\Download folder
        try {
            Write-Verbose 'Renaming "SoftwareDistribution\Download" folder to "Download.old"...'
            Rename-Item -Path "$env:SystemRoot\SoftwareDistribution\Download" -NewName 'Download.old' -ErrorAction 'SilentlyContinue' -WarningAction 'SilentlyContinue'
        }
        catch {
            Write-Error $_
        }

        # Clear SoftwareDistribution\Download folder
        try {
            Write-Verbose 'Clearing SoftwareDistribution\Download folder...'
            Remove-Item -Path "$env:SystemRoot\SoftwareDistribution\Download.old" -Force -Verbose -Confirm:$false -Recurse -ErrorAction 'SilentlyContinue' -WarningAction 'SilentlyContinue'
        }
        catch {
            try {
                Write-Warning "Seems some filepaths are too long for PowerShell. Trying RoboCopy to remove files/folders..."
                # Create (temporary) empty folder
                New-Item -ItemType Directory -Path ".\Empty" -ErrorAction SilentlyContinue
                # Mirror the empty directory to the folder to delete; this will effectively empty the folder.
                robocopy /MIR ".\Empty" "$env:SystemRoot\SoftwareDistribution\Download.old" /njh /njs /ndl /nc /ns /np /nfl #>nul 2>&1
                # Delete the folder now that it's empty
                Remove-Item "$env:SystemRoot\SoftwareDistribution\Download.old" -Force
                # Delete our temporary empty folder
                Remove-Item ".\Empty" -Force
            }
            catch {
                Write-Error $_
            }
        }

        # Start services again
        try {
            Write-Verbose 'Starting  Windows Update & Background Intelligent Transfer services...'
            Get-Service -Name 'wuauserv', 'bits' | Start-Service
        }
        catch {
            Write-Warning $_
        }
    }

    end {
        # Get disk space again and calculate difference
        $After = Get-DiskSpace
        $TotalCleaned = "$(($After.FreeSpace - $Before.FreeSpace).ToString('00.00')) GB"
        # Add to report
        $script:CleanupReport.SoftwareDistribution = $TotalCleaned
    }
}