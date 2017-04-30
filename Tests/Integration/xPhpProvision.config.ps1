<#
.Synopsis
   DSC Configuration testing if PHP can be provisioned using xPhpProvision
#>
Configuration xPhpProvision_Config {
    Import-DscResource -ModuleName 'xPhp'

    Node $AllNodes.NodeName {
        File PackagesFolder
        {
            DestinationPath = $Node.PackageFolder
            Type = 'Directory'
            Ensure = 'Present'
        }

        xPhpProvision Php
        {
            InstallMySqlExt = $true
            PackageFolder = $Node.PackageFolder
            DownloadURI = $Node.PhpDownloadUri
            DestinationPath = $Node.PhpInstallFolder
            ConfigurationPath = (Join-Path $Node.PhpInstallFolder 'php.ini')
            Vc2012RedistDownloadUri = $Node.VCDownloadUri
        }
    }
}
