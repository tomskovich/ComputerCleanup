function Optimize-UserFolders {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int] $Days,

        [switch] $TempFiles,

        [switch] $BrowserCache,

        [Parameter(Mandatory = $false, ParameterSetName = 'Downloads')]
        [switch] $Downloads,

        [Parameter(Mandatory = $false, ParameterSetName = 'Downloads')]
        [switch] $ArchiveFiles,

        [Parameter(Mandatory = $false, ParameterSetName = 'Downloads')]
        [array] $ArchiveTypes = @('zip', 'rar', '7z', 'iso'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Downloads')]
        [string] $ArchiveSize = '200MB',

        [Parameter(Mandatory = $false, ParameterSetName = 'Downloads')]
        [switch] $GenericFiles,

        [Parameter(Mandatory = $false, ParameterSetName = 'Downloads')]
        [array] $GenericTypes = @('msi', 'exe'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Downloads')]
        [string] $GenericSize = '5MB'
    )

    begin {
        # Get all user folders, exclude administrators and default users
        $Users = Get-UserFolders
    
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
        ForEach ($Username In $Users) {
            # General temp files/folders
            if ($TempFiles -eq $true) {
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
                ForEach ($Folder In $TempFolders) {
                    If (Test-Path -Path "$env:SYSTEMDRIVE\Users\$Username\$Folder") {
                        try {
                            Get-ChildItem -Path "$env:SYSTEMDRIVE\Users\$Username\$Folder" @CommonParams |
                                Where-Object { ($_.CreationTime -and $_.LastAccessTime -lt $(Get-Date).AddDays(-$Days)) } | 
                                    Remove-Item @CommonParams
                        }
                        catch {
                            Write-Error $_
                        }
                    }
                }
            }
            # Downloads folder
            if ($Downloads -eq $true) { 
                If (Test-Path -Path "$env:SYSTEMDRIVE\Users\$Username\Downloads") {
                    # Compressed files larger than $ArchiveSize
                    if ($ArchiveFiles -eq $true) {
                        ForEach ($Ext In $ArchiveTypes) {
                            try {
                                Get-ChildItem -Path "$env:SYSTEMDRIVE\Users\$Username\Downloads\*.$Ext" @CommonParams |
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
                                Get-ChildItem -Path "$env:SYSTEMDRIVE\Users\$Username\Downloads\*.$($Ext)" @CommonParams |
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
            if ($BrowserCache -eq $true) {
                # Folders to clean up
                $CacheFolders = @(
                    # Google Chrome
                    '\AppData\Local\Google\Chrome\User Data\Default\Cache',
                    '\AppData\Local\Google\Chrome\User Data\Default\Cache2\entries',
                    '\AppData\Local\Google\Chrome\User Data\Default\Cookies',
                    '\AppData\Local\Google\Chrome\User Data\Default\Media Cache',
                    '\AppData\Local\Google\Chrome\User Data\Default\Cookies-Journal'
                    # Firefox
                    '\AppData\Local\Mozilla\Firefox\Profiles\*.default\cache',
                    '\AppData\Local\Mozilla\Firefox\Profiles\*.default\cache2\entries',
                    '\AppData\Local\Mozilla\Firefox\Profiles\*.default\thumbnails',
                    '\AppData\Local\Mozilla\Firefox\Profiles\*.default\cookies.sqlite',
                    '\AppData\Local\Mozilla\Firefox\Profiles\*.default\webappsstore.sqlite',
                    '\AppData\Local\Mozilla\Firefox\Profiles\*.default\chromeappsstore.sqlite'
                )
                ForEach ($Folder In $CacheFolders) {
                    If (Test-Path -Path "$env:SYSTEMDRIVE\Users\$Username\$Folder") {
                        try {
                            Get-ChildItem -Path "$env:SYSTEMDRIVE\Users\$Username\$Folder" @CommonParams |
                                Where-Object { ($_.CreationTime -and $_.LastAccessTime -lt $(Get-Date).AddDays(-$Days)) } | 
                                    Remove-Item @CommonParams
                        }
                        catch {
                            Write-Error $_
                        }
                    }
                }
            }
        }
    } # end Process
}
