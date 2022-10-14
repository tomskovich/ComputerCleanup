function Optimize-BrowserCache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [int] $Days
    )
    
    begin {
        # Get all user folders, exclude administrators and default users
        $Users = Get-ChildItem -Directory -Path 'C:\Users' | Where-Object { 
            $_.Name -NotLike '*administrator*' -and 
            $_.Name -NotLike '*admin*' -and 
            $_.Name -NotLike 'Public' -and 
            $_.Name -NotLike 'Default'
        } | Select-Object -ExpandProperty Name

        # Folders to clean up
        $Folders = @(
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
        ForEach ($Username In $Users) {
            ForEach ($Folder In $Folders) {
                If (Test-Path -Path "$UsersFolder\$Username\$Folder") {
                    try {
                        Get-ChildItem -Path "$UsersFolder\$Username\$Folder" @CommonParams |
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
}