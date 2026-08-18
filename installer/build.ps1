param (
    [string]$Version = "1.0.0"
)

# Force strict error handling
$ErrorActionPreference = "Stop"

# Paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DistDir = Join-Path $ScriptDir "dist"
$SrcDistDir = Join-Path $DistDir "src"
$ProjectRoot = Join-Path $ScriptDir ".."

try {
    # 2. Creates installer\dist\ directory structure
    Write-Host "Creating dist directory structure..."
    if (Test-Path $DistDir) {
        Remove-Item -Path $DistDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $SrcDistDir | Out-Null

    # 3. Copies ..\sdk.cmd to installer\dist\sdk.cmd
    Write-Host "Copying sdk.cmd..."
    Copy-Item -Path (Join-Path $ProjectRoot "sdk.cmd") -Destination $DistDir

    # 4. Copies ..\src\*.ps1 to installer\dist\src\
    Write-Host "Copying src files..."
    Copy-Item -Path (Join-Path $ProjectRoot "src\*.ps1") -Destination $SrcDistDir

    # 5. Checks if makensis.exe is available in PATH
    $MakeNsis = Get-Command "makensis.exe" -ErrorAction SilentlyContinue
    if (-not $MakeNsis) {
        Write-Error "makensis.exe not found in PATH. Please ensure NSIS is installed and in your environment PATH."
        exit 1
    }

    # 6. Runs makensis.exe
    Write-Host "Building installer version $Version with makensis..."
    Set-Location $ScriptDir
    
    # Run makensis and capture exit code
    $nsisArgs = @("/V3", "/DPRODUCT_VERSION=$Version", "installer.nsi")
    & $MakeNsis.Source $nsisArgs
    $ExitCode = $LASTEXITCODE

    # 7. Reports success/failure with the output filename
    if ($ExitCode -eq 0) {
        $OutFile = "WindowsSdkJava-Setup-$Version.exe"
        Write-Host "Build SUCCESS: $OutFile" -ForegroundColor Green
    } else {
        Write-Host "Build FAILED with exit code $ExitCode" -ForegroundColor Red
        exit $ExitCode
    }
}
finally {
    # 8. Cleans up the dist folder after build
    Write-Host "Cleaning up dist folder..."
    if (Test-Path $DistDir) {
        Remove-Item -Path $DistDir -Recurse -Force
    }
    
    # Return to original path just in case
    Set-Location $ScriptDir
}
