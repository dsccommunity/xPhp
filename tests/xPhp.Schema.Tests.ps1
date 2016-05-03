<# 
    .SUMMARY
    Test suite for xPhp.Schema.psm1. This must be run from an elevated PowerShell session.
#>
[CmdletBinding()]
param ()

$xPhpModuleRoot = "${env:ProgramFiles}\WindowsPowerShell\Modules\xPhp"

if (-not (Test-Path $xPhpModuleRoot))
{
    md $xPhpModuleRoot > $null
}
Copy-Item -Recurse  $PSScriptRoot\..\* $xPhpModuleRoot -Force -Exclude '.git'

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$requiredModules = @( 'xPSDesiredStateConfiguration', 'xWebAdministration')

function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [string[]] $RequiredModules
    )

    foreach ($requiredModule in $RequiredModules) {
        if (-not (Get-Module $requiredModule -ListAvailable)) {
            Write-Verbose "Installing  required module $requiredModule..."
            Install-Module $requiredModule -Force
        }

        if (-not (Get-Module $requiredModule)) {
            Write-Verbose "Importing required module $requiredModule..."
            Import-Module $requiredModule
        }
    }
}

Install-RequiredModules -RequiredModules $requiredModules

Describe 'xPhpProvision' {
    It 'Should have required modules' {
        foreach ($requiredModule in $requiredModules) {
            Get-Module $requiredModule | Should Not Be $null
        }
    }

    It 'Should import without error' {
        { Import-Module "$xPhpModuleRoot\DscResources\xPhpProvision\xPhpProvision.psd1" -Force } | Should Not throw
    }

    It 'Should return from Get-DscResource' {
        $xphp = Get-DscResource -Name xPhpProvision
        $xphp.ResourceType | Should Be 'xPhpProvision'
        $xphp.Module | Should Be 'xPhp'
        $xphp.FriendlyName | Should BeNullOrEmpty
        $xphp.ImplementedAs | Should Be 'Composite'
    }
}
