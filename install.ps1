[CmdletBinding()]
param(
    [switch]$Admin,
    [string]$InstallPath = "C:\Tools\WindowsSdkJava"
)

$ErrorActionPreference = 'Stop'

# Auto-Elevation Logic for -Admin
if ($Admin) {
    $principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Requesting Administrator privileges for Machine-level installation..."
        try {
            # Relaunch the script in a new elevated PowerShell instance
            Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Admin -InstallPath `"$InstallPath`"" -Wait -ErrorAction Stop
            Write-Host "Elevated installation completed successfully."
        } catch {
            Write-Error "Elevation cancelled or failed. Installation aborted."
        }
        return # Exit the current non-elevated script so it doesn't continue
    }
}

Write-Host "Installing Windows SDK-Style Java Version Manager to $InstallPath..."

# 1. Create directory structure
if (-not (Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
}

# 2. Copy source files safely based on the current script's location
$sourceDir = Split-Path $PSCommandPath
Copy-Item -Path "$sourceDir\src" -Destination $InstallPath -Recurse -Force
Copy-Item -Path "$sourceDir\sdk.cmd" -Destination $InstallPath -Force

# 3. Add CMD launcher to PATH
$pathTarget = if ($Admin) { [EnvironmentVariableTarget]::Machine } else { [EnvironmentVariableTarget]::User }
$currentPath = [Environment]::GetEnvironmentVariable("PATH", $pathTarget)
$cleanInstallPath = $InstallPath.TrimEnd('\')

if ($currentPath -notmatch [regex]::Escape($cleanInstallPath)) {
    $newPath = "$currentPath;$cleanInstallPath"
    [Environment]::SetEnvironmentVariable("PATH", $newPath, $pathTarget)
    Write-Host "Added $cleanInstallPath to $pathTarget PATH."
} else {
    Write-Host "$cleanInstallPath is already in the $pathTarget PATH."
}

# 4. Profile Integration (Idempotent)
if ($null -eq $PROFILE -or $PROFILE -eq "") {
    Write-Host "[WARN] PowerShell profile variable is null. Skipping profile integration."
} else {
    $profileDir = Split-Path $PROFILE
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    if (-not (Test-Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }

    $importCommand = "Import-Module `"$InstallPath\src\sdk.ps1`" -DisableNameChecking"
    $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue

    if ($null -eq $profileContent -or $profileContent -notmatch [regex]::Escape($importCommand)) {
        Add-Content -Path $PROFILE -Value "`n# Windows SDK Java Manager`n$importCommand"
        Write-Host "Injected sdk module into PowerShell profile."
    } else {
        Write-Host "Profile integration already exists."
    }
}

Write-Host "Installation complete! Please restart your terminal."

# Keep the elevated window open for a few seconds so you can read the output before it closes
if ($Admin -and ($MyInvocation.Line -notmatch 'powershell\.exe')) {
    Start-Sleep -Seconds 4
}