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
        Write-Host "Requesting Administrator privileges for Machine-level uninstallation..."
        try {
            Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Admin -InstallPath `"$InstallPath`"" -Wait -ErrorAction Stop
            Write-Host "Elevated uninstallation completed successfully."
        } catch {
            Write-Error "Elevation cancelled or failed. Uninstallation aborted."
        }
        return
    }
}

Write-Host "Uninstalling Windows SDK-Style Java Version Manager from $InstallPath..."

# 1. Remove InstallPath from PATH
$pathTarget = if ($Admin) { [EnvironmentVariableTarget]::Machine } else { [EnvironmentVariableTarget]::User }
$currentPath = [Environment]::GetEnvironmentVariable("PATH", $pathTarget)
$cleanInstallPath = $InstallPath.TrimEnd('\')

if ($null -ne $currentPath -and $currentPath -match [regex]::Escape($cleanInstallPath)) {
    $newPaths = ($currentPath -split ';') | Where-Object { $_.TrimEnd('\') -ne $cleanInstallPath }
    $newPath = $newPaths -join ';'
    [Environment]::SetEnvironmentVariable("PATH", $newPath, $pathTarget)
    Write-Host "Removed $cleanInstallPath from $pathTarget PATH."
}

# 2. Remove Profile Integration
if ($null -ne $PROFILE -and (Test-Path $PROFILE)) {
    $importPattern = "Import-Module `"$InstallPath\\src\\sdk\.ps1`".*"
    $lines = Get-Content $PROFILE | Where-Object { $_ -notmatch $importPattern -and $_ -notmatch "# Windows SDK Java Manager" }
    $lines | Set-Content $PROFILE
    Write-Host "Removed sdk module from PowerShell profile."
}

# 3. Delete directory structure
if (Test-Path $InstallPath) {
    Remove-Item -Path $InstallPath -Recurse -Force
    Write-Host "Deleted $InstallPath."
}

Write-Host "Uninstallation complete!"