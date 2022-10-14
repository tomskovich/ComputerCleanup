function Get-UserFolders {
    # Get all user folders, exclude administrators and default users
    $Users = Get-ChildItem -Directory -Path 'C:\Users' | Where-Object { 
        $_.Name -NotLike '*administrator*' -and 
        $_.Name -NotLike '*admin*' -and 
        $_.Name -NotLike 'Public' -and 
        $_.Name -NotLike 'Default'
    } | Select-Object -ExpandProperty Name

    return $Users
}