# src/Diagnostics.ps1

function Invoke-SdkDoctor {
    Write-Host "Running SDK Diagnostics..."
    Write-Host "--------------------------"

    # Profile integration check
    if ($null -ne $PROFILE -and (Test-Path $PROFILE)) {
        $profileContent = Get-Content $PROFILE -Raw
        if ($profileContent -match "Import-Module.*sdk\.ps1") {
            Write-Host "[OK] PowerShell Profile integration found."
        } else {
            Write-Host "[WARN] SDK not found in PowerShell Profile."
        }
    } else {
        Write-Host "[WARN] PowerShell Profile does not exist."
    }

    # JAVA_HOME check
    if ($null -ne $env:JAVA_HOME -and (Test-Path $env:JAVA_HOME)) {
        Write-Host "[OK] JAVA_HOME is valid: $env:JAVA_HOME"
    } else {
        Write-Host "[ERROR] JAVA_HOME is missing or invalid."
    }

    # Catalog check
    if (Test-Path $global:SdkCatalogPath) {
        Write-Host "[OK] Java Catalog exists."
    } else {
        Write-Host "[WARN] Java Catalog missing. Run 'sdk rescan java'."
    }

    # PATH checks
    $pathParts = @($env:PATH -split ';')
    $javaPathCount = 0
    foreach ($p in $pathParts) {
        if ($null -ne $p -and $p -match "\\bin$" -and (Test-Path "$p\java.exe" -ErrorAction SilentlyContinue)) {
            $javaPathCount++
        }
    }
    
    if ($javaPathCount -eq 1) {
        Write-Host "[OK] Clean PATH configuration (1 Java binary path detected)."
    } elseif ($javaPathCount -gt 1) {
        Write-Host "[WARN] Multiple Java binaries found in PATH. This may cause conflicts."
    } else {
        Write-Host "[ERROR] No Java binary found in PATH."
    }
}