#
# One-line installer for Wispling.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/saketlunker/wispling-releases/main/install.ps1 | iex"
#
# Reads releases/install.json, downloads the signed installer named there,
# verifies its SHA-256, and installs it.
#
# After this runs once, Wispling keeps itself updated on launch through the signed
# Tauri updater. There is no manual update step.
#
# Design notes, each of which is a bug this script already hit:
#   - No <# #> block comments. PowerShell mis-parses them when a script is
#     piped from Invoke-RestMethod into Invoke-Expression.
#   - No api.github.com. Unauthenticated API allows 60 requests/hour per IP,
#     which is shared behind corporate NAT, so it returns 403 unpredictably.
#     raw.githubusercontent.com is not limited that way.
#   - No Get-FileHash. Module autoloading can fail under iex.
#   - Decode Byte[] before parsing. PowerShell 5.1 returns Byte[] from
#     Invoke-WebRequest .Content for application/octet-stream downloads.

$ErrorActionPreference = 'Stop'

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {
    # Newer PowerShell negotiates TLS on its own.
}

$manifestUrl = 'https://raw.githubusercontent.com/saketlunker/wispling-releases/main/releases/install.json'
$headers     = @{ 'User-Agent' = 'WisplingInstaller/1.0' }

if (-not [Environment]::Is64BitOperatingSystem) {
    throw 'Wispling requires 64-bit Windows.'
}

Write-Host ''
Write-Host '  Installing Wispling...' -ForegroundColor Cyan
Write-Host ''

try {
    $manifest = Invoke-RestMethod -UseBasicParsing -Headers $headers -Uri $manifestUrl
} catch {
    throw "Could not reach the Wispling release manifest. $($_.Exception.Message)"
}

$entry = $manifest.'windows-x64'

if (-not $entry -or -not $entry.url) {
    throw 'The Wispling release manifest has no Windows x64 build.'
}

$version  = $manifest.version
$expected = "$($entry.sha256)".ToLower()
$fileName = $entry.url.Split('/')[-1]

Write-Host "  Found Wispling $version" -ForegroundColor Gray

$workDir = Join-Path $env:TEMP ('wispling-install-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $workDir -Force | Out-Null
$installer = Join-Path $workDir $fileName

try {
    Write-Host '  Downloading...' -ForegroundColor Gray
    Invoke-WebRequest -UseBasicParsing -Headers $headers -Uri $entry.url -OutFile $installer

    if (-not $expected) {
        throw 'No checksum published for this build; refusing to install.'
    }

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $stream = [System.IO.File]::OpenRead($installer)
        try {
            $actual = ([System.BitConverter]::ToString($sha.ComputeHash($stream)) -replace '-', '').ToLower()
        } finally {
            $stream.Dispose()
        }
    } finally {
        $sha.Dispose()
    }

    if ($actual -ne $expected) {
        throw "Checksum mismatch for $fileName. Expected $expected but got $actual."
    }

    Write-Host '  Checksum verified' -ForegroundColor Gray

    # Invoke-WebRequest tags downloads with Mark-of-the-Web, which makes
    # Windows refuse to execute them ("Access is denied"). Strip the zone
    # stream now that the checksum has proven the file is the one we expect.
    try {
        Unblock-File -Path $installer -ErrorAction Stop
    } catch {
        Remove-Item -LiteralPath "$installer`:Zone.Identifier" -Force -ErrorAction SilentlyContinue
    }

    Write-Host '  Running installer...' -ForegroundColor Gray

    $process = Start-Process -FilePath $installer -ArgumentList '/S' -Wait -PassThru

    if ($process.ExitCode -ne 0) {
        throw "Installer exited with code $($process.ExitCode)."
    }
}
finally {
    Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host "  Wispling $version installed." -ForegroundColor Green
Write-Host '  Find it in the Start Menu. It updates itself from now on.' -ForegroundColor Gray
Write-Host ''
