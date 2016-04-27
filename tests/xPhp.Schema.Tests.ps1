<# 
    .SUMMARY
    Test suite for ExportToHtml.psm1
#>
[CmdletBinding()]
param ()

$xPhpModuleRoot = "${env:ProgramFiles}\WindowsPowerShell\Modules\xPhp"

if (!(Test-Path $xPhpModuleRoot))
{
    md $xPhpModuleRoot > $null
}
Copy-Item -Recurse  $PSScriptRoot\..\* $xPhpModuleRoot -Force -Exclude '.git'

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

Describe 'xPhpProvision' 
{
    It 'Should import without error' 
    {
        { Import-Module "$xPhpModuleRoot\DscResources\xPhpProvision\xPhpProvision.Schema.psm1" } | Should Not throw
    }

    It 'Should return from Get-DscResource' 
    {
        $xphp = Get-DscResource -Name xPhpProvision
        $xphp.ResourceType | Should Be 'xPhpProvision'
        $xphp.Module | Should Be 'xPhp'
        $xphp.FriendlyName | Should BeNullOrEmpty
        $xphp.ImplementedAs | Should Be 'Composite'
    }
}
