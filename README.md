[![Build status](https://ci.appveyor.com/api/projects/status/4umfdsbj520bmely/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xphp/branch/master)

# xPhp

The xPhp module contains the xPhp DSC Resource. This DSC Resource allows you to Setup PHP in IIS and optionally register the MySql extention.

## Resources
* xPhp resource has following properties:
    - PackageFolder: The folder to download the PHP and Visual C++ 2012 packages to. Note: this must already exist.
    - DownloadUri:The URL/URI for the PHP package.
    - VcRedistDownloadUri:The URL/URI for the Visual Studio C++ 2012 Redistributiable package.
    - DestinationPath:The path to install PHP to.
    - ConfigurationPath:The path to the file to use as PHP.ini
    - InstallMySqlExt:A bool indicating if the MySql extesion should be installed.
    - Renaming Requirements
    - When making changes to these resources, we suggest the following practice:

## Versions

## 1.0.1

Initial release with xPhp resource.


## Examples

### Setup a Php Server on a single node
This configuration will setup a Php Server on a sigle node.
Note: this requires the following other modules: xWebAdministration, and xPsDesiredStateConfiguration. (see Example: Install xPhp Module and the other required modules).

```powershell
# This configuration will, via the xPHP composite configuration: 
# 1) Make sure IIS is installed 
# 2) Make sure PHP is present 
# 3) Make sure that PHP is registered with IIS 
# 4) Make sure PHP is in the path 
# 
# ********* NOTE *********** 
# PHP changes their download URLs frequently.  Please verify the URL. 
# the VC Redist URL changes less frequently, but should still be verified. 
# After verifying the download URLs for the products and update them appropriately. 
# ************************** 
$scriptRoot = Split-Path $MyInvocation.MyCommand.Path 
$phpIniPath = (Join-Path $scriptRoot "phpConfigTemplate.txt") 
if (-not (Test-Path $phpIniPath)) 
{ 
    $message = "Missing required file $phpIniPath" 
    # This file is in the samples folder of the resource 
    throw $message 
} 
Configuration SamplePhp 
{ 
    # Import composite resources 
    Import-DscResource -module xPhp 
    Node "localhost" 
    { 
        File PackagesFolder 
        { 
            DestinationPath = "C:\package" 
            Type = "Directory" 
            Ensure = "Present" 
        } 
        # Make sure PHP is installed in IIS 
        xPhp  php 
        { 
            InstallMySqlExt = $true 
            PackageFolder =  "C:\package" 
            # Update with the latest "VC11 x64 Non Thread Safe" from http://windows.php.net/download/ 
            DownloadURI = "http://windows.php.net/downloads/releases/php-5.5.14-nts-Win32-VC11-x64.zip" 
            DestinationPath = "C:\php" 
            ConfigurationPath = $phpIniPath 
            Vc2012RedistDownloadUri = "http://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe" 
            # Removed because this dependency does not work in Windows Server 2012 R2 and below 
            # This should work in WMF v5 and above 
            # DependsOn = "[IisPreReqs_WordPress]Iis" 
        } 
    } 
} 
SamplePhp 
Start-DscConfiguration -path .\SamplePhp -wait -verbose
``` 

### Install xPhp Module and the other required modules
Note: This require a version of WMF 5 see the Powershell Resource Gallery for more details

```powershell
# This Script installs the required modules for the PHP Sample
# It uses the PowerShell Resource Gallery, see https://powershellgallery.com/
# This requires WMF 5.   If you don't have WMF 5, Please install the modules manually.
Write-Host "Installing required modules..."
Install-Module xWebAdministration -MinimumVersion 1.3.2 -Force 
Install-Module xPSDesiredStateConfiguration -MinimumVersion 3.0.1 -Force 
Install-Module xPhp -MinimumVersion 1.0.1 -Force
```

## Contributing
Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).
