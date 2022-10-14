function Remove-SoftwareDistribution {
    # Clear C:\Windows\SoftwareDistribution
    try {
        Write-Verbose 'Stopping Windows Update service'
        Get-Service -Name 'wuauserv' | Stop-Service
    }
    catch {
        Write-Warning $_
    }

    Rename-Item -Path 'C:\Windows\SoftwareDistribution' -NewName 'SoftwareDistribution.old' -ErrorAction 'SilentlyContinue' -WarningAction 'SilentlyContinue'
    Remove-Item -Path 'C:\Windows\SoftwareDistribution.old' -Force -Verbose -Confirm:$false -Recurse -ErrorAction 'SilentlyContinue' -WarningAction 'SilentlyContinue'

    try {
        Write-Verbose 'Starting Windows Update service'
        Get-Service -Name 'wuauserv' | Start-Service
    }
    catch {
        Write-Warning $_
    }
}