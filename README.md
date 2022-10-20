# Computer Cleanup

`IMPORTANT: This module is still a work in progress!`

General description

# Functions\Private

- [Assert-RunAsAdministrator]() 
    - Verifies if script/function is running with Administrator privileges.
- [Get-DiskSpace]()
    - Gets available disk space. Used for reporting.
- [Get-UserFolders]()
    - Gets all user folders, excluding Administrators and Default/Public users
- [Start-Logging]()
    - Logging function.

# Functions\Public

- [Invoke-ComputerCleanup]() 
    - Main controller function to invoke one or multiple cleanup functions included in this module.
- [Clear-BrowserCache]()
	- Removes browser cache files for all users.
    - Browsers: Microsoft Edge, Internet Explorer, Google Chrome and Firefox.
- [Clear-FontCache]()
	- Removes user font cache files located in "C:\Windows\ServiceProfiles\LocalService\AppData\Local\"
- [Clear-SoftwareDistribution]()
    - Clears the "C:\Windows\SoftwareDistribution\Downloads" folder.
- [Clear-TeamsCache]() 
    - Removes Microsoft Teams cache files for all users.
- [Invoke-CleanManager]() 
    - Runs the Windows Disk Cleanup tool with predefined options.
- [Optimize-SystemFiles]() 
    - Removes common system-wide temporary files and folders older than $Days old.
    - OPTIONAL: Clears Windows Recycle Bin
- [Optimize-UserProfiles]() 
    - Removes common temporary files and folders older than $Days days old from user profiles.

