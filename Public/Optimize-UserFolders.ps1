function Optimize-UserFolders {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int] $Days,

        [Parameter(Mandatory = $false, ParameterSetName = 'Downloads')]
        [switch] $Downloads,

        [Parameter(Mandatory = $false, ParameterSetName = 'Downloads')]
        [switch] $ArchiveFiles,

        [Parameter(Mandatory = $false, ParameterSetName = 'Downloads')]
        [array] $ArchiveTypes = @('zip', 'rar', '7z', 'iso'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Downloads')]
        [string] $ArchiveSize = '500MB',

        [Parameter(Mandatory = $false, ParameterSetName = 'Downloads')]
        [switch] $GenericFiles,

        [Parameter(Mandatory = $false, ParameterSetName = 'Downloads')]
        [array] $GenericTypes = @('msi', 'exe', 'mkv'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Downloads')]
        [string] $GenericSize = '5MB'
    )

    begin {
        # Get all user folders, exclude administrators and default users
        $Users = Get-UserFolders

        # Folders to clean up
        $TempFolders = @(
            '\AppData\Local\Microsoft\Windows\Temporary Internet Files',
            '\AppData\Local\Microsoft\Windows\WebCache',
            '\AppData\Local\Microsoft\Windows\WER',
            '\AppData\Local\Microsoft\Internet Explorer\Recovery',
            '\AppData\Local\Microsoft\Terminal Server Client\Cache',
            '\AppData\Local\CrashDumps',
            '\AppData\Local\Temp'
        )

        # Parameters for Get-ChildItem and Remove-Item
        $CommonParams = @{
            Recurse       = $true
            Force         = $true
            Verbose       = $true
            ErrorAction   = 'SilentlyContinue'
            WarningAction = 'SilentlyContinue'
        }
    } # end Begin
    
    process {
        Write-Output "Deleting USER temp folders/files older than $Days days old."
        ForEach ($Username In $Users) {
            # Folders with temp files
            ForEach ($Folder In $TempFolders) {
                If (Test-Path -Path "C:\Users\$Username\$Folder") {
                    try {
                        Get-ChildItem -Path "C:\Users\$Username\$Folder" @CommonParams |
                            Where-Object { ($_.CreationTime -and $_.LastAccessTime -lt $(Get-Date).AddDays(-$Days)) } | 
                                Remove-Item @CommonParams
                    }
                    catch {
                        Write-Error $_
                    }
                }
            }
            # Downloads folder
            if ($Downloads -eq $true) { 
                If (Test-Path -Path "C:\Users\$Username\Downloads") {
                    # Compressed files larger than $ArchiveSize
                    if ($ArchiveFiles -eq $true) {
                        ForEach ($Ext In $ArchiveTypes) {
                            try {
                                Get-ChildItem -Path "C:\Users\$Username\Downloads\*.$Ext" @CommonParams |
                                    Where-Object { ($_.CreationTime -and $_.LastAccessTime -lt $(Get-Date).AddDays(-$Days) -and $_.Length -gt $ArchiveSize) } | 
                                        Remove-Item @CommonParams
                            }
                            catch {
                                Write-Error $_
                            }
                        }
                    }
                    # Generic files larger than $GenericSize
                    if ($GenericFiles -eq $true) {
                        ForEach ($Ext In $GenericTypes) {
                            try {
                                Get-ChildItem -Path "C:\Users\$Username\Downloads\*.$($Ext)" @CommonParams |
                                    Where-Object { ($_.CreationTime -and $_.LastAccessTime -lt $(Get-Date).AddDays(-$Days) -and $_.Length -gt $GenericSize) } | 
                                        Remove-Item @CommonParams
                            }
                            catch {
                                Write-Error $_
                            }
                        }
                    }
                }
            }
        }
    } # end Process
}
