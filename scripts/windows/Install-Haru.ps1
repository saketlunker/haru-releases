<#
.SYNOPSIS
Installs Haru into %LOCALAPPDATA%\Haru.

.DESCRIPTION
Wrapper around Haru.ps1 install for repository-local use and easy help output.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Repository,
    [string]$Tag,
    [string]$InstallRoot,
    [string]$PackagePath,
    [string]$AssetName,
    [string]$AssetPattern,
    [string]$ConfigPath,
    [string]$GitHubToken,
    [switch]$Force,
    [switch]$NoLaunch,
    [switch]$NoShortcut,
    [switch]$NoPathUpdate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$dispatcher = Join-Path -Path $PSScriptRoot -ChildPath 'Haru.ps1'
if (-not (Test-Path -LiteralPath $dispatcher -PathType Leaf)) {
    throw "Haru dispatcher not found: $dispatcher"
}

& $dispatcher 'install' @PSBoundParameters
