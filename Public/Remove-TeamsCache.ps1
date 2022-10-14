function Remove-TeamsCache {
    param(
        [Switch] $Force
    )
    
    begin {
        # Get all user folders, exclude administrators and default users
        $Users = Get-UserFolders

        # Folders to clean up
        $Folders = @(
            'AppData\Roaming\Microsoft\teams\blob_storage',
            'AppData\Roaming\Microsoft\teams\databases',
            'AppData\Roaming\Microsoft\teams\cache',
            'AppData\Roaming\Microsoft\teams\gpucache',
            'AppData\Roaming\Microsoft\teams\Indexeddb',
            'AppData\Roaming\Microsoft\teams\Local Storage',
            'AppData\Roaming\Microsoft\teams\tmp'
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
        Write-Output "Starting Teams Cache cleanup process..."
        if ($Force) {
            $Confirmed = $true
        }
        else {
            $Confirmation = Read-Host -Prompt "This will close ALL running Teams processes. Are you sure?? [Y/N]"
            if ( $Confirmation -match "[yY]" ) { 
                $Confirmed = $true
            }
            else {
                $Confirmed = $false
            }
        }

        if ($Confirmed -eq $true) {
            # Kill Teams process(es)
            try {
                Write-Verbose "Killing Teams process(es)..."
                Get-Process -ProcessName 'Teams' -ErrorAction 'SilentlyContinue' | Stop-Process -Force
            }
            catch {
                Write-Error $_
            }

            # Start cleaning files
            ForEach ($Username In $Users) {
                ForEach ($Folder In $Folders) {
                    If (Test-Path -Path "C:\Users\$Username\$Folder") {
                        try {
                            Get-ChildItem -Path "C:\Users\$Username\$Folder" @CommonParams | Remove-Item @CommonParams
                            Write-Verbose "Removed Teams Cache files for $Username."
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