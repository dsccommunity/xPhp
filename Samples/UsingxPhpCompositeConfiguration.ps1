# This configuration will, via the xPHP composite configuration:
# 1) Make sure IIS is installed
# 2) Make sure PHP is present
# 3) Make sure that PHP is registered with IIS
# 4) Make sure PHP is in the path
#
# ********* NOTE ***********
# PHP changes their download URLs frequently.  Please verify the URL.
# The VC Redist URL changes less frequently, but should still be verified.
# After verifying the download URLs for the products and update them appropriately.
# **************************
$scriptRoot = Split-Path $MyInvocation.MyCommand.Path
$phpIniPath = (Join-Path $scriptRoot 'phpConfigTemplate.txt')

if (-not (Test-Path $phpIniPath))
{
    $message = "Missing required file $phpIniPath"
    # This file is in the samples folder of the resource
    throw $message
}

Configuration SamplePhp
{
    # Import composite resources
    Import-DscResource -Module xPhp

    Node 'localhost'
    {
        File PackagesFolder
        {
            DestinationPath = 'C:\package'
            Type = 'Directory'
            Ensure = 'Present'
        }

        # Make sure PHP is installed in IIS
        xPhpProvision php
        {
            InstallMySqlExt = $true
            PackageFolder =  'C:\package'
            # Update with the latest "VC14 x64 Non Thread Safe" from http://windows.php.net/download/
            DownloadURI = 'http://windows.php.net/downloads/releases/php-7.1.4-nts-Win32-VC14-x64.zip'
            DestinationPath = 'C:\php'
            ConfigurationPath = $phpIniPath
            Vc2012RedistDownloadUri = 'https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x64.exe'

            # Removed because this dependency does not work in Windows Server 2012 R2 and below
            # This should work in WMF v5 and above
            # DependsOn = "[IisPreReqs_WordPress]Iis"
        }
    }
}

SamplePhp

Start-DscConfiguration -Path .\SamplePhp -Wait -Verbose
