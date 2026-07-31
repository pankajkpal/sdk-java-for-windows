# src/Discovery.ps1

function Invoke-SdkRescan {
    Write-Host "Scanning system for Java installations..."
    
    $searchPaths = @(
        $env:JAVA_HOME, $env:JAVA_HOME_8, $env:JAVA_HOME_11, $env:JAVA_HOME_17,
        $env:JAVA_HOME_21, $env:JAVA_HOME_25, "$env:ProgramFiles\Java", 
        "${env:ProgramFiles(x86)}\Java", "$env:ProgramFiles\Eclipse Adoptium",
        "$env:ProgramFiles\Microsoft", "$env:ProgramFiles\Amazon Corretto", 
        "$env:ProgramFiles\Zulu", "$env:ProgramFiles\BellSoft"
    )

    $validJdks = @()

    foreach ($basePath in $searchPaths) {
        if ($null -eq $basePath -or -not (Test-Path -Path $basePath -PathType Any)) { continue }

        $directories = @(Get-ChildItem -Path $basePath -Directory -ErrorAction SilentlyContinue)
        if (Test-Path -Path "$basePath\bin\java.exe") {
            $directories += (Get-Item -Path $basePath)
        }

        foreach ($dir in $directories) {
            $javaExe = "$($dir.FullName)\bin\java.exe"
            $javacExe = "$($dir.FullName)\bin\javac.exe"

            if ((Test-Path -Path $javaExe) -and (Test-Path -Path $javacExe)) {
                $versionOutput = & $javaExe -version 2>&1 | Out-String
                
                $majorVersion = "Unknown"
                $fullVersion = "Unknown"
                $vendor = "openjdk"

                # FIXED: Using single quotes for the regex string avoids parsing errors
                if ($versionOutput -match 'version "([^"]+)"') {
                    $fullVersion = $matches[1]
                    if ($fullVersion -match "^1\.8") { $majorVersion = "8" }
                    elseif ($fullVersion -match "^(\d+)") { $majorVersion = $matches[1] }
                }

                if ($versionOutput -match "Temurin") { $vendor = "tem" }
                elseif ($versionOutput -match "Microsoft") { $vendor = "microsoft" }
                elseif ($versionOutput -match "Corretto") { $vendor = "corretto" }
                elseif ($versionOutput -match "Zulu") { $vendor = "zulu" }
                elseif ($versionOutput -match "Liberica") { $vendor = "liberica" }
                elseif ($versionOutput -match "Oracle") { $vendor = "oracle" }

                $validJdks += [PSCustomObject]@{
                    Id = "$fullVersion-$vendor"
                    MajorVersion = $majorVersion
                    FullVersion = $fullVersion
                    Vendor = $vendor
                    Path = $dir.FullName
                    IsValid = $true
                }
            }
        }
    }

    $uniqueJdks = @($validJdks | Group-Object -Property Path | ForEach-Object { $_.Group[0] })
    
    if ($uniqueJdks.Count -gt 0) {
        $dir = Split-Path $global:SdkCatalogPath
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
        $uniqueJdks | ConvertTo-Json -Depth 2 | Out-File -FilePath $global:SdkCatalogPath -Encoding utf8
        Write-Host "Found $($uniqueJdks.Count) valid JDK(s). Catalog updated."
    } else {
        Write-Host "No valid JDK installations found."
    }
}

function Invoke-SdkList {
    if (-not (Test-Path $global:SdkCatalogPath)) {
        Write-Host "Catalog empty. Run: sdk rescan java"
        return
    }
    $jdks = Get-Content $global:SdkCatalogPath | ConvertFrom-Json
    Write-Host "Installed Java versions"
    Write-Host "======================="
    foreach ($jdk in $jdks) {
        $marker = if ($jdk.Path -eq $env:JAVA_HOME) { ">" } else { " " }
        Write-Host "$marker $($jdk.Id)`tJava $($jdk.FullVersion)`t$($jdk.Vendor)`t$($jdk.Path)"
    }
}