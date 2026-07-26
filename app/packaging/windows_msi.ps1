# Windows MSI/ZIP packaging script for flit (ticket P9-08).
#
# Builds the Flutter Windows release and attempts to create an MSI installer
# via WiX Toolset. Falls back to a ZIP archive if WiX is not available.
#
# Prerequisites: WiX Toolset v3 (optional, for MSI creation).
# Code signing is out of scope.

$ErrorActionPreference = "Stop"

Set-Location (Join-Path $PSScriptRoot "..")

Write-Host "==> Building Flutter Windows release..."
flutter build windows --release

$ReleaseDir = "build\windows\x64\runner\Release"

if (-Not (Test-Path $ReleaseDir)) {
    Write-Error "Error: Release directory not found at $ReleaseDir"
    exit 1
}

# Check if WiX is available
$candleExe = Get-Command candle.exe -ErrorAction SilentlyContinue
$lightExe = Get-Command light.exe -ErrorAction SilentlyContinue

if ($candleExe -and $lightExe) {
    Write-Host "==> WiX detected. Creating MSI installer..."
    Write-Host "NOTE: WiX-based MSI creation is a placeholder. A full WiX configuration"
    Write-Host "      (WXS file, component refs, etc.) is required for production."
    Write-Host "      Falling back to ZIP packaging."
    Write-Host ""
}

# Fallback: create a ZIP archive
Write-Host "==> Creating ZIP archive..."
$OutputZip = "build\windows\flit-windows-x64.zip"
if (Test-Path $OutputZip) {
    Remove-Item $OutputZip -Force
}

Compress-Archive -Path "$ReleaseDir\*" -DestinationPath $OutputZip -CompressionLevel Optimal

Write-Host ""
Write-Host "==> ZIP created successfully: $OutputZip"
Write-Host ""
Write-Host "NOTE: This package is unsigned. Code signing is out of scope."
Write-Host ""
Write-Host "To create an MSI installer:"
Write-Host "  1. Install WiX Toolset v3 from https://wixtoolset.org/"
Write-Host "  2. Create a .wxs file defining the installer structure"
Write-Host "  3. Run: candle.exe your-installer.wxs"
Write-Host "  4. Run: light.exe -out flit.msi your-installer.wixobj"
