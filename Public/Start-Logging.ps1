function Start-Logging {
    param (
        # Name of logging file
        [Parameter(Mandatory=$true)]
        [Alias('Name')]
        [String] $LogName
    )

    begin {
        $LogName = $LogName + '_' + (Get-Date -Format 'yyyy-MM-ddTHHmmss') + '.log'
        $LogFile = "$env:SystemRoot\Temp\$LogName"
    }

    process {
        try {
            # Start Logging / Transcript
            Write-Host (Start-Transcript -Path $LogFile) -ForegroundColor Green
        }
        catch {
            Write-Error $_
        }
    }
}