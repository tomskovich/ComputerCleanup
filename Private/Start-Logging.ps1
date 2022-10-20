<#
    .SYNOPSIS
    Logging function

    .NOTES
    Author:   Tom de Leeuw
    Website:  https://ucsystems.nl / https://tech-tom.com
#>
function Start-Logging {
    param (
        # Name of logging file - date and time will be appended.
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
            Write-Output (Start-Transcript -Path $LogFile)
        }
        catch {
            Write-Error $_
        }
    }
}