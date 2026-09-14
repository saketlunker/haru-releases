<#
.SYNOPSIS
    One-line installer for Haru.

.DESCRIPTION
    Intended to be run directly from the web:

        powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/saketlunker/haru-releases/main/install.ps1 | iex"

    It fetches the Haru bootstrap script from this repository and runs the
    install flow. After this runs once, Haru keeps itself updated on launch
    via the signed Tauri updater - there is no manual update step.
#>

$ErrorActionPreference = 'Stop'

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {
    # Modern PowerShell negotiates TLS on its own; ignore when unavailable.
}

$bootstrapUri = 'https://raw.githubusercontent.com/saketlunker/haru-releases/main/scripts/windows/Haru.ps1'

Write-Host 'Installing Haru...' -ForegroundColor Cyan

try {
    $bootstrap = Invoke-WebRequest -UseBasicParsing -Uri $bootstrapUri -Headers @{ 'User-Agent' = 'HaruInstaller/1.0' }
} catch {
    throw "Could not download the Haru bootstrap from $bootstrapUri. $($_.Exception.Message)"
}

& ([scriptblock]::Create($bootstrap.Content)) install @args
