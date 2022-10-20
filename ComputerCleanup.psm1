#Get public and private function definition files.
$Private = (Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private') -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue) 
$Public = (Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter *.ps1 -Recurse)

# Load private scripts first 
($Private + $Public) | ForEach-Object {
    try {
        Write-Verbose "Loading $($_.FullName)"
        . $_.FullName
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}

Export-ModuleMember -Function $Private.Basename -ErrorAction SilentlyContinue
Export-ModuleMember -Function $Public.Basename 