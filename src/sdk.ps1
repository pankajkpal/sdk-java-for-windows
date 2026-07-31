# src/sdk.ps1
$global:SdkCatalogPath = "$env:USERPROFILE\.sdk-java\java-installations.json"

# Safely dot-source dependencies when the module is imported
. "$PSScriptRoot\Discovery.ps1"
. "$PSScriptRoot\Environment.ps1"
. "$PSScriptRoot\Diagnostics.ps1"

function sdk {
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$Command,
        
        [Parameter(Position=1)]
        [string]$Component,
        
        [Parameter(Position=2)]
        [string]$VersionId,
        
        [string]$ExportCmdScript,
        
        # Capture raw flags like --admin to bypass strict PowerShell parameter binding
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$RemainingArgs
    )

    # Support both --admin (spec) and -admin
    $isAdmin = ($RemainingArgs -contains "--admin") -or ($RemainingArgs -contains "-admin")

    if ($Component -ne "java" -and $Command -notmatch "^(help|doctor|env)$") {
        Write-Host "Currently only 'java' is supported."
        return
    }

    switch ($Command) {
        "rescan" { Invoke-SdkRescan }
        "list" { Invoke-SdkList }
        "use" { Invoke-SdkUse -VersionId $VersionId -ExportCmdScript $ExportCmdScript }
        "default" { Invoke-SdkDefault -VersionId $VersionId -Admin:$isAdmin }
        "current" { Invoke-SdkCurrent }
        "env" { Invoke-SdkEnv -Action $Component -ExportCmdScript $ExportCmdScript }
        "doctor" { Invoke-SdkDoctor }
        "help" { Invoke-SdkHelp }
        default { Write-Host "Command '$Command' not recognized. Run 'sdk help'." }
    }
}

function Invoke-SdkHelp {
    Write-Host ""
    Write-Host "Windows SDK-Style Java Version Manager" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "Usage: sdk <command> [component] [version] [options]"
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Yellow
    Write-Host "  sdk rescan java                 Scans your system and updates the local JDK catalog."
    Write-Host "  sdk list java                   Lists all discovered and valid JDK installations."
    Write-Host "  sdk use java <id>               Temporarily switches to the specified JDK for this PowerShell session."
    Write-Host "  sdk default java <id>           Sets the specified JDK as the User-level default (JAVA_HOME & PATH)."
    Write-Host "  sdk default java <id> --admin   Sets the JDK as the Machine-level default (Prompts for UAC elevation)."
    Write-Host "  sdk current java                Displays the currently active Java version and JAVA_HOME path."
    Write-Host "  sdk env init                    Creates an .sdkmanrc file in the current directory with the active JDK."
    Write-Host "  sdk env                         Reads the .sdkmanrc file and switches to that JDK in this session."
    Write-Host "  sdk env clear                   Restores the current session's environment to the User default."
    Write-Host "  sdk doctor                      Runs diagnostics to check for environment, profile, or PATH issues."
    Write-Host "  sdk help                        Displays this help documentation."
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  sdk rescan java"
    Write-Host "  sdk list java"
    Write-Host "  sdk use java 17.0.5-tem"
    Write-Host "  sdk default java 21.0.8-zulu --admin"
    Write-Host ""
}