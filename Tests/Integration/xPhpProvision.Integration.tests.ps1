$script:DSCModuleName      = 'xPhp'
$script:DSCResourceName    = 'xPhpProvision'

#region HEADER
# Integration Test Template Version: 1.1.1
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration

#endregion

$backupName = "$($script:DSCResourceName)_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# Using try/finally to always cleanup.
try
{
    #region Integration Tests

    Backup-WebConfiguration -Name $backupName | Out-Null

    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $configFile

    $DSCConfig = Import-LocalizedData -BaseDirectory $PSScriptRoot -FileName "$($script:DSCResourceName).config.psd1"

    Describe "$($script:DSCResourceName)_Integration"
    {
        #region DEFAULT TESTS
        It 'Should compile and apply the MOF without throwing'
        {
            {
                & "$($script:DSCResourceName)_Config" -ConfigurationData $DSCConfig -OutputPath $TestDrive
                Start-DscConfiguration -Path $TestDrive `
                    -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing'
        {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should have set the resource and all the parameters should match'
        {
            $currentConfiguration = Get-DscConfiguration

            # Visual C++ Runtime should be installed
            $vcredist = Get-WmiObject -Class Win32_Product | Where-Object { `
                $_.IdentifyingNumber -eq '{0D3E9E15-DE7A-300B-96F1-B4AF12B96488}' }
            $vcredist | Should Not BeNullOrEmpty

            (Join-Path $DSCConfig.AllNodes.PackageFolder 'php.zip') | Should Exist

            $DSCConfig.AllNodes.PhpInstallFolder | Should Exist
            $phpFiles = Get-ChildItem -Path $DSCConfig.AllNodes.PhpInstallFolder
            $phpFiles | Where-Object { $_.Name -eq 'php.exe' } | Should Not BeNullOrEmpty
            $phpFiles | Where-Object { $_.Name -eq 'php_mysqli.dll' } | Should Not BeNullOrEmpty
            $phpFiles | Where-Object { $_.Name -eq 'php.ini' } | Should Not BeNullOrEmpty
            $phpFiles | Where-Object { $_.Name -eq 'php-cgi.exe' } | Should Not BeNullOrEmpty

            $env:Path | Should Match ([regex]::Escape("$($DSCConfig.AllNodes.PhpInstallFolder)"))

            $phpCgiPath = Join-Path $DSCConfig.AllNodes.PhpInstallFolder 'php-cgi.exe'
            { Get-WebConfigurationProperty `
                -PSPath 'MACHINE/WEBROOT/APPHOST' `
                -Filter "system.webServer/fastCgi/application[@fullPath='$phpCgiPath']" `
                -Name '.' `
            } | Should Not BeNullOrEmpty

            foreach ($feature in @("Web-Server", "Web-Mgmt-Tools", "Web-Default-Doc", `
                    "Web-Dir-Browsing", "Web-Http-Errors", "Web-Static-Content", `
                    "Web-Http-Logging", "Web-Stat-Compression", "Web-Filtering", `
                    "Web-CGI", "Web-ISAPI-Ext", "Web-ISAPI-Filter"))
            {
                (Get-WindowsFeature -Name $feature).Installed | Should Be $True
            }
        }
    }
    #endregion

}
finally
{
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    #endregion

    Restore-WebConfiguration -Name $backupName
    Remove-WebConfigurationBackup -Name $backupName
}
