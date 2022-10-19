function Optimize-SystemFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [int] $Days
    )

    begin {
        # Folders to clean up
        $Folders = @(
            "$env:SystemRoot\Temp",
            "$env:SystemRoot\Logs\CBS",
            "$env:SystemRoot\Downloaded Program Files",
            "$env:ProgramData\Microsoft\Windows\WER"
        )

        # Parameters for Get-ChildItem and Remove-Item
        $CommonParams = @{
            Recurse       = $true
            Force         = $true
            Verbose       = $true
            ErrorAction   = 'SilentlyContinue'
            WarningAction = 'SilentlyContinue'
        }
    }

    process {
        Write-Output "Deleting SYSTEM folders/files older than $Days days old..."

        # General folders
        foreach ($Folder in $Folders) {
            if (Test-Path -Path $Folder) {
                try {
                    Get-ChildItem -Path $Folder @CommonParams |
                        Where-Object { ($_.CreationTime -and $_.LastWriteTime -lt $(Get-Date).AddDays(-$Days)) } |
                            Remove-Item @CommonParams
                }
                catch {
                    Write-Error $_
                }
            }
        }

        # Empty Recycle Bin
        try {
            Write-Verbose 'Clearing Recycle Bin'
            Clear-RecycleBin -Force
        }
        catch {
            Write-Error $_
        }
    } # end Process
}