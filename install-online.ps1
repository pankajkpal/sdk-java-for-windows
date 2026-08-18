# =============================================================================
# Windows SDK Java Manager - Online Installer
# =============================================================================
# One-liner install:
#   irm https://raw.githubusercontent.com/pankajkpal/sdk-java-for-windows/main/install-online.ps1 | iex
#
# This script:
#   1. Downloads the latest release from GitHub
#   2. Extracts sdk.cmd and src/ to C:\Tools\WindowsSdkJava
#   3. Adds the install directory to your User PATH
#   4. Configures your PowerShell profile to auto-load the SDK module
# =============================================================================

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
$installPath  = 'C:\Tools\WindowsSdkJava'
$repoZipUrl   = 'https://github.com/pankajkpal/sdk-java-for-windows/archive/refs/heads/main.zip'
$extractedDir = 'sdk-java-for-windows-main'  # folder name inside the ZIP

try {
    # ---------------------------------------------------------------------------
    # Banner
    # ---------------------------------------------------------------------------
    Write-Host ""
    Write-Host "  =============================================="  -ForegroundColor Cyan
    Write-Host "   Windows SDK Java Manager - Online Installer"    -ForegroundColor Cyan
    Write-Host "  =============================================="  -ForegroundColor Cyan
    Write-Host ""

    # ---------------------------------------------------------------------------
    # Step 1 - Download the repository ZIP to a temp file
    # ---------------------------------------------------------------------------
    Write-Host "[1/5] Downloading repository archive..." -ForegroundColor Yellow
    $tempZip = Join-Path ([System.IO.Path]::GetTempPath()) "sdk-java-for-windows-$(Get-Date -Format 'yyyyMMddHHmmss').zip"
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "sdk-java-for-windows-extract-$(Get-Date -Format 'yyyyMMddHHmmss')"

    Invoke-WebRequest -Uri $repoZipUrl -OutFile $tempZip -UseBasicParsing
    Write-Host "       Downloaded to: $tempZip" -ForegroundColor DarkGray

    # ---------------------------------------------------------------------------
    # Step 2 - Extract the ZIP to a temp directory
    # ---------------------------------------------------------------------------
    Write-Host "[2/5] Extracting archive..." -ForegroundColor Yellow
    Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force

    $sourcePath = Join-Path $tempDir $extractedDir
    if (-not (Test-Path $sourcePath)) {
        throw "Expected extracted folder '$extractedDir' not found in '$tempDir'."
    }
    Write-Host "       Extracted to:  $tempDir" -ForegroundColor DarkGray

    # ---------------------------------------------------------------------------
    # Step 3 - Copy files to the install directory
    # ---------------------------------------------------------------------------
    Write-Host "[3/5] Installing files to $installPath ..." -ForegroundColor Yellow

    # Create the install directory (and src sub-directory) if they don't exist
    if (-not (Test-Path $installPath)) {
        New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    }
    $srcDest = Join-Path $installPath 'src'
    if (-not (Test-Path $srcDest)) {
        New-Item -ItemType Directory -Path $srcDest -Force | Out-Null
    }

    # Copy sdk.cmd to the install root
    $sdkCmdSource = Join-Path $sourcePath 'sdk.cmd'
    if (Test-Path $sdkCmdSource) {
        Copy-Item -Path $sdkCmdSource -Destination $installPath -Force
        Write-Host "       Copied sdk.cmd" -ForegroundColor DarkGray
    } else {
        Write-Host "       WARNING: sdk.cmd not found in archive" -ForegroundColor Red
    }

    # Copy the entire src\ directory contents
    $srcSource = Join-Path $sourcePath 'src'
    if (Test-Path $srcSource) {
        Copy-Item -Path "$srcSource\*" -Destination $srcDest -Recurse -Force
        Write-Host "       Copied src\ directory" -ForegroundColor DarkGray
    } else {
        Write-Host "       WARNING: src\ directory not found in archive" -ForegroundColor Red
    }

    # ---------------------------------------------------------------------------
    # Step 4 - Add install directory to the User PATH (idempotent)
    # ---------------------------------------------------------------------------
    Write-Host "[4/5] Updating User PATH..." -ForegroundColor Yellow

    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if (-not $currentPath) { $currentPath = '' }

    # Check if the install path is already in the User PATH (case-insensitive)
    $pathEntries = $currentPath -split ';' | Where-Object { $_.Trim() -ne '' }
    $alreadyInPath = $pathEntries | Where-Object { $_.TrimEnd('\') -ieq $installPath.TrimEnd('\') }

    if ($alreadyInPath) {
        Write-Host "       Install path already in User PATH - skipping" -ForegroundColor DarkGray
    } else {
        # Append with semicolon separator (handle trailing semicolons gracefully)
        $newPath = if ($currentPath -and -not $currentPath.EndsWith(';')) {
            "$currentPath;$installPath"
        } elseif ($currentPath) {
            "$currentPath$installPath"
        } else {
            $installPath
        }
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        Write-Host "       Added $installPath to User PATH" -ForegroundColor DarkGray
    }

    # ---------------------------------------------------------------------------
    # Step 5 - Inject Import-Module into PowerShell $PROFILE (idempotent)
    # ---------------------------------------------------------------------------
    Write-Host "[5/5] Configuring PowerShell profile..." -ForegroundColor Yellow

    $importLine = "Import-Module `"$installPath\src\sdk.ps1`" -DisableNameChecking"

    # Create the profile directory and file if they don't exist
    $profileDir = Split-Path -Parent $PROFILE
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        Write-Host "       Created profile directory: $profileDir" -ForegroundColor DarkGray
    }
    if (-not (Test-Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
        Write-Host "       Created profile file: $PROFILE" -ForegroundColor DarkGray
    }

    # Check if the Import-Module line is already present (idempotent)
    $profileContent = Get-Content -Path $PROFILE -Raw -ErrorAction SilentlyContinue
    if (-not $profileContent) { $profileContent = '' }

    if ($profileContent -match [regex]::Escape($importLine)) {
        Write-Host "       Import-Module line already in profile - skipping" -ForegroundColor DarkGray
    } else {
        Add-Content -Path $PROFILE -Value "`n$importLine"
        Write-Host "       Added Import-Module to $PROFILE" -ForegroundColor DarkGray
    }

    # ---------------------------------------------------------------------------
    # Cleanup - Remove temp files
    # ---------------------------------------------------------------------------
    Write-Host ""
    Write-Host "Cleaning up temporary files..." -ForegroundColor DarkGray
    if (Test-Path $tempZip) { Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue }
    if (Test-Path $tempDir) { Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue }

    # ---------------------------------------------------------------------------
    # Success message
    # ---------------------------------------------------------------------------
    Write-Host ""
    Write-Host "  =============================================="  -ForegroundColor Green
    Write-Host "   Installation complete!"                          -ForegroundColor Green
    Write-Host "  =============================================="  -ForegroundColor Green
    Write-Host ""
    Write-Host "  Installed to: $installPath" -ForegroundColor White
    Write-Host ""
    Write-Host "  Next steps:" -ForegroundColor White
    Write-Host "    1. Restart your terminal (or open a new one)" -ForegroundColor White
    Write-Host "    2. Run:  sdk rescan java" -ForegroundColor White
    Write-Host "    3. Run:  sdk list java" -ForegroundColor White
    Write-Host ""

} catch {
    # ---------------------------------------------------------------------------
    # Error handler - clean up and report failure
    # ---------------------------------------------------------------------------
    Write-Host ""
    Write-Host "  ERROR: Installation failed!" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""

    # Attempt cleanup even on failure
    if ($tempZip -and (Test-Path $tempZip)) {
        Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue
    }
    if ($tempDir -and (Test-Path $tempDir)) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    throw
}
