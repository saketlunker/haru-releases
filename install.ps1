#requires -Version 5.1
#
# One-line installer for Haru.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/saketlunker/haru-releases/main/install.ps1 | iex"
#
# Downloads the latest signed Haru installer, verifies its SHA-256 against the
# checksums published with the release, and installs it.
#
# After this runs once, Haru keeps itself updated on launch through the signed
# Tauri updater. There is no manual update step.
#
# NOTE: this script is fetched and piped to iex, so it must avoid <# #> block
# comments. PowerShell's parser mis-handles them in that path.

$ErrorActionPreference = 'Stop'

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {
    # Newer PowerShell negotiates TLS on its own.
}

$repo    = 'saketlunker/haru-releases'
$headers = @{ 'User-Agent' = 'HaruInstaller/1.0' }

if (-not [Environment]::Is64BitOperatingSystem) {
    throw 'Haru requires 64-bit Windows.'
}

Write-Host ''
Write-Host '  Installing Haru...' -ForegroundColor Cyan
Write-Host ''

# Resolve the latest release.
try {
    $release = Invoke-RestMethod -UseBasicParsing -Headers $headers -Uri "https://api.github.com/repos/$repo/releases/latest"
} catch {
    throw "Could not reach the Haru release feed. $($_.Exception.Message)"
}

$version = $release.tag_name -replace '^v', ''
$asset   = $release.assets | Where-Object { $_.name -like '*-setup.exe' } | Select-Object -First 1

if (-not $asset) {
    throw "Release $($release.tag_name) has no Windows installer attached."
}

Write-Host "  Found Haru $version" -ForegroundColor Gray

$workDir   = Join-Path $env:TEMP ('haru-install-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $workDir -Force | Out-Null
$installer = Join-Path $workDir $asset.name

try {
    Write-Host '  Downloading...' -ForegroundColor Gray
    Invoke-WebRequest -UseBasicParsing -Headers $headers -Uri $asset.browser_download_url -OutFile $installer

    # Verify against the published checksums before running anything.
    $checksumAsset = $release.assets | Where-Object { $_.name -eq 'haru-checksums.txt' } | Select-Object -First 1

    if ($checksumAsset) {
        $list = (Invoke-WebRequest -UseBasicParsing -Headers $headers -Uri $checksumAsset.browser_download_url).Content
        $line = $list -split "`n" | Where-Object { $_ -match [regex]::Escape($asset.name) } | Select-Object -First 1
        $expected = ($line -split '\s+' | Select-Object -First 1)

        if (-not $expected) {
            throw "No checksum published for $($asset.name); refusing to install."
        }

        $actual = (Get-FileHash $installer -Algorithm SHA256).Hash.ToLower()

        if ($actual -ne $expected.ToLower()) {
            throw "Checksum mismatch for $($asset.name). Expected $expected but got $actual."
        }

        Write-Host '  Checksum verified' -ForegroundColor Gray
    } else {
        Write-Warning 'No checksum file published with this release; skipping verification.'
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
Write-Host "  Haru $version installed." -ForegroundColor Green
Write-Host '  Find it in the Start Menu. It updates itself from now on.' -ForegroundColor Gray
Write-Host ''
