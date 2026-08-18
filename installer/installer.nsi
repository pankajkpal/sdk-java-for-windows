!ifndef PRODUCT_VERSION
!define PRODUCT_VERSION "1.0.0"
!endif

!define PRODUCT_NAME "Windows SDK Java Manager"
!define PRODUCT_PUBLISHER "pankajkpal"
!define PRODUCT_WEB_SITE "https://github.com/pankajkpal/sdk-java-for-windows"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"

SetCompressor lzma
Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "WindowsSdkJava-Setup-${PRODUCT_VERSION}.exe"
InstallDir "C:\Tools\WindowsSdkJava"
ShowInstDetails show
ShowUnInstDetails show
BrandingText "${PRODUCT_NAME}"
Unicode True
VIProductVersion "${PRODUCT_VERSION}.0"
VIAddVersionKey "ProductName" "${PRODUCT_NAME}"
VIAddVersionKey "CompanyName" "${PRODUCT_PUBLISHER}"
VIAddVersionKey "LegalCopyright" "Copyright (c) ${PRODUCT_PUBLISHER}"
VIAddVersionKey "FileDescription" "Windows SDK Java Manager Installer"
VIAddVersionKey "FileVersion" "${PRODUCT_VERSION}.0"
VIAddVersionKey "ProductVersion" "${PRODUCT_VERSION}.0"

; --- MultiUser Configuration (must be defined BEFORE including MultiUser.nsh) ---
!define MULTIUSER_EXECUTIONLEVEL Highest
!define MULTIUSER_MUI
!define MULTIUSER_INSTALLMODE_COMMANDLINE
!define MULTIUSER_INSTALLMODE_INSTDIR "WindowsSdkJava"
!define MULTIUSER_INSTALLMODE_DEFAULT_CURRENTUSER

; --- Includes ---
!include "MUI2.nsh"
!include "MultiUser.nsh"
!include "LogicLib.nsh"
!include "WinMessages.nsh"
!include "WordFunc.nsh"

; --- MUI Configuration ---
!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

; --- Installer Pages ---
!insertmacro MUI_PAGE_WELCOME
!insertmacro MULTIUSER_PAGE_INSTALLMODE
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; --- Uninstaller Pages ---
!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; --- Languages ---
!insertmacro MUI_LANGUAGE "English"

; --- Init Functions ---
Function .onInit
  !insertmacro MULTIUSER_INIT
FunctionEnd

Function un.onInit
  !insertmacro MULTIUSER_UNINIT
FunctionEnd

; --- Path Manipulation Helpers ---
Function AddToPath
  Exch $0
  Push $1
  Push $2
  Push $3
  Push $4

  ${If} $MultiUser.InstallMode == "AllUsers"
    StrCpy $2 "HKLM"
    StrCpy $3 "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    ReadRegStr $1 HKLM "$3" "PATH"
  ${Else}
    StrCpy $2 "HKCU"
    StrCpy $3 "Environment"
    ReadRegStr $1 HKCU "$3" "PATH"
  ${EndIf}

  ; Check if already in PATH
  ${WordFind} "$1" ";" "E+$0" $4
  IfErrors 0 Done

  ; Append to PATH
  ${If} $1 == ""
    StrCpy $1 "$0"
  ${Else}
    StrCpy $1 "$1;$0"
  ${EndIf}

  ${If} $2 == "HKLM"
    WriteRegExpandStr HKLM "$3" "PATH" "$1"
  ${Else}
    WriteRegExpandStr HKCU "$3" "PATH" "$1"
  ${EndIf}

  SendMessage ${HWND_BROADCAST} ${WM_SETTINGCHANGE} 0 "STR:Environment" /TIMEOUT=5000

  Done:
  Pop $4
  Pop $3
  Pop $2
  Pop $1
  Pop $0
FunctionEnd

Function un.RemoveFromPath
  Exch $0
  Push $1
  Push $2
  Push $3

  ${If} $MultiUser.InstallMode == "AllUsers"
    StrCpy $2 "HKLM"
    StrCpy $3 "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    ReadRegStr $1 HKLM "$3" "PATH"
  ${Else}
    StrCpy $2 "HKCU"
    StrCpy $3 "Environment"
    ReadRegStr $1 HKCU "$3" "PATH"
  ${EndIf}

  ; Replace $0 with empty string in $1 handling semicolons
  ${WordReplace} "$1" "$0;" "" "+" $1
  ${WordReplace} "$1" ";$0" "" "+" $1
  ${WordReplace} "$1" "$0" "" "+" $1

  ${If} $2 == "HKLM"
    WriteRegExpandStr HKLM "$3" "PATH" "$1"
  ${Else}
    WriteRegExpandStr HKCU "$3" "PATH" "$1"
  ${EndIf}

  SendMessage ${HWND_BROADCAST} ${WM_SETTINGCHANGE} 0 "STR:Environment" /TIMEOUT=5000

  Pop $3
  Pop $2
  Pop $1
  Pop $0
FunctionEnd

; --- PowerShell Profile Helpers ---
Function AddPSProfile
  DetailPrint "Adding Import-Module to PowerShell Profile..."
  StrCpy $0 "if (!(Test-Path `$$PROFILE`)) { New-Item -Type File -Path `$$PROFILE` -Force | Out-Null }; $$p = Get-Content `$$PROFILE`; if ($$p -notcontains 'Import-Module $\"$INSTDIR\src\sdk.ps1$\" -DisableNameChecking') { Add-Content `$$PROFILE` 'Import-Module $\"$INSTDIR\src\sdk.ps1$\" -DisableNameChecking' }"
  nsExec::ExecToLog 'powershell -ExecutionPolicy Bypass -NoProfile -Command "$0"'
FunctionEnd

Function un.RemovePSProfile
  DetailPrint "Removing Import-Module from PowerShell Profile..."
  StrCpy $0 "if (Test-Path `$$PROFILE`) { $$p = Get-Content `$$PROFILE`; $$p = $$p | Where-Object { $$_ -ne 'Import-Module $\"$INSTDIR\src\sdk.ps1$\" -DisableNameChecking' }; Set-Content `$$PROFILE` $$p }"
  nsExec::ExecToLog 'powershell -ExecutionPolicy Bypass -NoProfile -Command "$0"'
FunctionEnd

; --- Installation Section ---
Section "MainSection" SEC01
  SetOutPath "$INSTDIR"
  File "dist\sdk.cmd"
  
  SetOutPath "$INSTDIR\src"
  File "dist\src\*.ps1"

  ; Modify Path
  Push "$INSTDIR"
  Call AddToPath

  ; Modify PowerShell Profile
  Call AddPSProfile

  ; Uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  ; Registry Keys
  WriteRegStr SHCTX "${PRODUCT_UNINST_KEY}" "DisplayName" "${PRODUCT_NAME}"
  WriteRegStr SHCTX "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr SHCTX "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
  WriteRegStr SHCTX "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr SHCTX "${PRODUCT_UNINST_KEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr SHCTX "${PRODUCT_UNINST_KEY}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegStr SHCTX "${PRODUCT_UNINST_KEY}" "QuietUninstallString" '"$INSTDIR\Uninstall.exe" /S'
  WriteRegDWORD SHCTX "${PRODUCT_UNINST_KEY}" "NoModify" 1
  WriteRegDWORD SHCTX "${PRODUCT_UNINST_KEY}" "NoRepair" 1
SectionEnd

; --- Uninstallation Section ---
Section "Uninstall"
  ; Modify PowerShell Profile
  Call un.RemovePSProfile

  ; Modify Path
  Push "$INSTDIR"
  Call un.RemoveFromPath

  ; Clean files and directories
  RMDir /r "$INSTDIR"

  ; Clean registry
  DeleteRegKey SHCTX "${PRODUCT_UNINST_KEY}"
SectionEnd
