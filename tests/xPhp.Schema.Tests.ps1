<# 
    .SUMMARY
    Test suite for xPhp.Schema.psm1. 
    This must be run from an elevated PowerShell session.
#>
[CmdletBinding()]
param ()

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$requiredModules = @( 'xPSDesiredStateConfiguration', 'xWebAdministration' )
$xPhpModuleRoot = "${env:ProgramFiles}\WindowsPowerShell\Modules\xPhp"

if (-not (Test-Path $xPhpModuleRoot))
{
    New-Item -Path $xPhpModuleRoot -ItemType Directory | Out-Null
}
Copy-Item -Recurse  $PSScriptRoot\..\* $xPhpModuleRoot -Force -Exclude '.git'

Describe 'xPhpProvision' {
    It 'Should have 1 available copy of all required modules in PS Module Path' {
        foreach ($requiredModule in $requiredModules) {
            $modulesFound = @()
            $modulesFound += Get-Module $requiredModule -ListAvailable
            $modulesFound.Count | Should Be 1
        }
    }

    It 'Should import without error' {
        { Import-Module "$xPhpModuleRoot\DscResources\xPhpProvision\xPhpProvision.psd1" -Force } | Should Not throw
    }

    It 'Should return from Get-DscResource' {
        $xPhp = Get-DscResource -Name xPhpProvision

        $xPhp.ResourceType  | Should Be 'xPhpProvision'
        $xPhp.Module        | Should Be 'xPhp'
        $xPhp.FriendlyName  | Should BeNullOrEmpty
        $xPhp.ImplementedAs | Should Be 'Composite'
    }
}
