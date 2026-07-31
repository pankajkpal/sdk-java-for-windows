# src/Environment.ps1

function Invoke-SdkUse {
    param([string]$VersionId, [string]$ExportCmdScript)
    if ($null -eq $VersionId -or $VersionId -eq "") { Write-Error "Version ID required"; return }
    if (-not (Test-Path $global:SdkCatalogPath)) { Write-Error "Run 'sdk rescan java' first."; return }
    
    $jdks = Get-Content $global:SdkCatalogPath | ConvertFrom-Json
    $selected = $jdks | Where-Object { $_.Id -eq $VersionId } | Select-Object -First 1
    
    if ($null -eq $selected) {
        Write-Error "ERROR: Java version '$VersionId' was not found."
        Write-Host "Run:`n  sdk rescan java`n  sdk list java"
        return
    }

    $env:JAVA_HOME = $selected.Path
    $binPath = "$($selected.Path)\bin"

    $pathParts = @($env:PATH -split ';')
    $newPaths = @($binPath)

    foreach ($p in $pathParts) {
        if ($null -eq $p -or $p.Trim() -eq "") { continue }
        $cleanP = $p.TrimEnd('\')
        if ($cleanP -notmatch "\\bin$" -or (-not (Test-Path "$cleanP\java.exe"))) {
            if ($cleanP -ne $binPath.TrimEnd('\')) { $newPaths += $p }
        }
    }

    $env:PATH = $newPaths -join ';'
    Write-Host "Using Java $($selected.Id) in this session."

    if ($ExportCmdScript) {
        $cmdLines = @(
            "@set `"JAVA_HOME=$($env:JAVA_HOME)`"",
            "@set `"PATH=$($env:PATH)`""
        )
        $cmdLines | Out-File -FilePath $ExportCmdScript -Encoding ascii
    }
}

function Invoke-SdkDefault {
    param([string]$VersionId, [switch]$Admin)
    if ($null -eq $VersionId -or $VersionId -eq "") { Write-Error "Version ID required"; return }
    
    $jdks = Get-Content $global:SdkCatalogPath | ConvertFrom-Json
    $selected = $jdks | Where-Object { $_.Id -eq $VersionId } | Select-Object -First 1
    if ($null -eq $selected) { Write-Error "ERROR: Java version '$VersionId' was not found."; return }

    if ($Admin) {
        $principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
        
        # If not elevated, trigger UAC popup to set the variables
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Host "Requesting Administrator privileges to update Machine-level environment variables..."
            
            # Construct a safe command to run in the elevated session
            $script = "[Environment]::SetEnvironmentVariable('JAVA_HOME', '$($selected.Path)', 'Machine'); [Environment]::SetEnvironmentVariable('JAVA_HOME_$($selected.MajorVersion)', '$($selected.Path)', 'Machine')"
            
            try {
                Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command `"$script`"" -Wait -ErrorAction Stop
                Write-Host "Successfully set default Java to $($selected.Id) at Machine scope."
                Write-Host "Note: This does not affect currently running PowerShell sessions."
            } catch {
                Write-Error "Elevation cancelled or failed. Machine-level variables were not updated."
            }
            return
        }

        # If already elevated, set them directly
        [Environment]::SetEnvironmentVariable("JAVA_HOME", $selected.Path, [EnvironmentVariableTarget]::Machine)
        [Environment]::SetEnvironmentVariable("JAVA_HOME_$($selected.MajorVersion)", $selected.Path, [EnvironmentVariableTarget]::Machine)
        Write-Host "Set default Java to $($selected.Id) at Machine scope."
        Write-Host "Note: This does not affect currently running PowerShell sessions."
    } else {
        [Environment]::SetEnvironmentVariable("JAVA_HOME", $selected.Path, [EnvironmentVariableTarget]::User)
        [Environment]::SetEnvironmentVariable("JAVA_HOME_$($selected.MajorVersion)", $selected.Path, [EnvironmentVariableTarget]::User)
        Write-Host "Set default Java to $($selected.Id) at User scope."
        Write-Host "Note: This does not affect currently running PowerShell sessions."
    }
}

function Invoke-SdkCurrent {
    if ($null -eq $env:JAVA_HOME -or -not (Test-Path $env:JAVA_HOME)) {
        Write-Host "No active Java installation detected."
        return
    }
    Write-Host "JAVA_HOME: $env:JAVA_HOME"
    if (Test-Path "$env:JAVA_HOME\bin\java.exe") {
        & "$env:JAVA_HOME\bin\java.exe" -version
    }
}

function Invoke-SdkEnv {
    param([string]$Action, [string]$ExportCmdScript)
    
    if ($Action -eq "init") {
        if ($null -eq $env:JAVA_HOME) { Write-Error "No active Java to init."; return }
        $jdks = Get-Content $global:SdkCatalogPath | ConvertFrom-Json
        $currentId = $jdks | Where-Object { $_.Path -eq $env:JAVA_HOME } | Select-Object -ExpandProperty Id -First 1
        if ($null -ne $currentId) {
            "java=$currentId" | Out-File -FilePath ".\.sdkmanrc" -Encoding ascii
            Write-Host "Created .sdkmanrc with java=$currentId"
        }
    } elseif ($Action -eq "clear") {
        $userJavaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", "User")
        if ($null -ne $userJavaHome) {
            $env:JAVA_HOME = $userJavaHome
            $binPath = "$userJavaHome\bin"
            $pathParts = @($env:PATH -split ';')
            $newPaths = @($binPath)
            foreach ($p in $pathParts) {
                if ($null -eq $p -or $p.Trim() -eq "") { continue }
                $cleanP = $p.TrimEnd('\')
                if ($cleanP -notmatch "\\bin$" -or (-not (Test-Path "$cleanP\java.exe"))) {
                    if ($cleanP -ne $binPath.TrimEnd('\')) { $newPaths += $p }
                }
            }
            $env:PATH = $newPaths -join ';'
            Write-Host "Restored JAVA_HOME to User default."
            if ($ExportCmdScript) {
                $cmdLines = @(
                    "@set `"JAVA_HOME=$($env:JAVA_HOME)`"",
                    "@set `"PATH=$($env:PATH)`""
                )
                $cmdLines | Out-File -FilePath $ExportCmdScript -Encoding ascii
            }
        }
    } else {
        if (Test-Path ".\.sdkmanrc") {
            $rc = Get-Content ".\.sdkmanrc" | Select-Object -First 1
            if ($null -ne $rc -and $rc -match "^java=(.+)$") {
                Invoke-SdkUse -VersionId $matches[1] -ExportCmdScript $ExportCmdScript
            }
        } else {
            Write-Error "No .sdkmanrc found in current directory."
        }
    }
}