# Composite configuration to install the IIS pre-requisites for php
Configuration IisPreReqs_php
{
    param
    (
        [Parameter(Mandatory = $true)]
        [Validateset("Present","Absent")]
        [System.String]
        $Ensure
    )

    foreach ($feature in @("Web-Server", "Web-Mgmt-Tools", "Web-Default-Doc", `
            "Web-Dir-Browsing", "Web-Http-Errors", "Web-Static-Content", `
            "Web-Http-Logging", "Web-Stat-Compression", "Web-Filtering", `
            "Web-CGI", "Web-ISAPI-Ext", "Web-ISAPI-Filter"))
    {
        WindowsFeature "$feature"
        {
            Ensure = $Ensure
            Name = $feature
        }
    }
}

# Composite configuration to install PHP on IIS
Configuration xPhpProvision
{
    param
    (
        [Parameter(Mandatory = $true)]
        [Switch]
        $InstallMySqlExt,

        [System.String]
        $PackageFolder = 'c:\package',

        [Parameter(Mandatory = $true)]
        [System.String]
        $DownloadUri,

        [System.String]
        $Vc2012RedistDownloadUri = 'https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x64.exe',

        [System.String]
        $DestinationPath = 'C:\php',

        [Parameter(Mandatory = $true)]
        [System.String]
        $ConfigurationPath
    )

    Import-DscResource -ModuleName xWebAdministration
    Import-DscResource -ModuleName xPsDesiredStateConfiguration

    # Make sure the IIS Prerequisites for PHP are present
    IisPreReqs_php Iis
    {
        Ensure = "Present"

        # Removed because this dependency does not work in Windows Server 2012 R2 and below
        # This should work in WMF v5 and above
        # DependsOn = "[File]PackagesFolder"
    }

    # Download and install Visual C++ Redist 2015 from microsoft.com
    Package vcRedist
    {
        Path = $Vc2012RedistDownloadUri
        ProductId = "{0D3E9E15-DE7A-300B-96F1-B4AF12B96488}"
        Name = "Microsoft Visual C++ 2015 x64 Minimum Runtime - 14.0.23026"
        Arguments = "/install /passive /norestart"
    }

    $phpZip = Join-Path $PackageFolder "php.zip"

    $phpDownloadUri = New-Object -TypeName System.Uri $DownloadURI
    $archiveDependsOn = @()
    if ($phpDownloadUri.scheme -ieq "http")
    {
        # Make sure the PHP archive is in the package folder
        xRemoteFile phpArchive
        {
            uri             = $DownloadURI
            DestinationPath = $phpZip
        }
        $archiveDependsOn += "[xRemoteFile]phpArchive"
    }
    else
    {
        $phpZip = $DownloadURI
    }

    # Make sure the content of the PHP archive is in the PHP path
    Archive php
    {
        Path         = $phpZip
        Destination  = $DestinationPath
        DependsOn    = $archiveDependsOn
    }

    if ($InstallMySqlExt)
    {
        # Make sure the MySql extention for PHP is in the main PHP path
        File phpMySqlExt
        {
            SourcePath = "$($DestinationPath)\ext\php_mysqli.dll"
            DestinationPath = "$($DestinationPath)\php_mysqli.dll"
            Ensure = "Present"
            DependsOn = @("[Archive]PHP")
            MatchSource = $true
        }
    }

    # Make sure the php.ini is in the Php folder
    File PhpIni
    {
        SourcePath = $ConfigurationPath
        DestinationPath = "$($DestinationPath)\php.ini"
        DependsOn = @("[Archive]PHP")
        MatchSource = $true
    }

    # Make sure the php cgi module is registered with IIS
    xIisModule phpHandler
    {
       Name = "phpFastCgi"
       Path = "$($DestinationPath)\php-cgi.exe"
       RequestPath = "*.php"
       Verb = "*"
       Ensure = "Present"
       DependsOn = @("[Package]vcRedist","[File]PhpIni") 

       # Removed because this dependency does not work in Windows Server 2012 R2 and below
       # This should work in WMF v5 and above
       # "[IisPreReqs_php]Iis" 
    }

    # Make sure the php binary folder is in the path
    Environment PathPhp
    {
        Name = "Path"
        Value = ";$($DestinationPath)"
        Ensure = "Present"
        Path = $true
        DependsOn = "[Archive]PHP"
    }
}
