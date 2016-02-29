; deploy.nsi

;--------------------------------
;Include Modern UI

  !include "MUI2.nsh"

;--------------------------------
;General

  ;Name and file
  Name "PrivateCloud"

  ; The file to write
  OutFile "PrivateCloudSetup.exe"

  ; The default installation directory
  InstallDir $PROGRAMFILES\PrivateCloud

  ;Get installation folder from registry if available
  InstallDirRegKey HKCU "Software\PrivateCloud" ""

  ; Request application privileges for Windows Vista
  RequestExecutionLevel admin

;--------------------------------
;Variables

  Var StartMenuFolder

;--------------------------------
;Interface Settings

  !define MUI_ABORTWARNING

;--------------------------------
;Pages

  !insertmacro MUI_PAGE_LICENSE "${NSISDIR}\Docs\Modern UI\License.txt"
  !insertmacro MUI_PAGE_DIRECTORY

  ;Start Menu Folder Page Configuration
  !define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKCU" 
  !define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\PrivateCloud" 
  !define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu Folder"

  !insertmacro MUI_PAGE_STARTMENU Application $StartMenuFolder

  !insertmacro MUI_PAGE_INSTFILES

  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES

;--------------------------------
;Languages
 
  !insertmacro MUI_LANGUAGE "English"

;--------------------------------
;Installer Sections

Section "PrivateCloud"

  ; Set output path to the installation directory.
  SetOutPath $INSTDIR
  ; Put file there
  File "node.exe"
  File "nssm.exe"

  SetOutPath "$LOCALAPPDATA\PrivateCloud"
  File /r "..\privateCloud\*.*"
  
  ; Write the installation path into the registry
  WriteRegStr HKCU SOFTWARE\PrivateCloud "" $INSTDIR
  
  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\PrivateCloud" "DisplayName" "Private Cloud"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\PrivateCloud" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\PrivateCloud" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\PrivateCloud" "NoRepair" 1

  WriteUninstaller "$INSTDIR\uninstall.exe"

  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application

    ;Create shortcuts
    CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Uninstall Private Cloud.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
    ;CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Private Cloud App.url" "http://localhost:30000"

  !insertmacro MUI_STARTMENU_WRITE_END

  nsExec::Exec '"$INSTDIR\nssm.exe" install PrivateCloud "$INSTDIR\node.exe" "$LOCALAPPDATA\PrivateCloud\server.js"'
  nsExec::Exec '"$INSTDIR\nssm.exe" start PrivateCloud'
  ExecShell open "http://localhost:30000"

SectionEnd

;--------------------------------
; Uninstaller

Section "Uninstall"

  nsExec::Exec '"$INSTDIR\nssm.exe" stop PrivateCloud'
  nsExec::Exec '"$INSTDIR\nssm.exe" remove PrivateCloud confirm'

  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\PrivateCloud"

  RMDir /r "$LOCALAPPDATA\PrivateCloud"

  Delete $INSTDIR\node.exe
  Delete $INSTDIR\nssm.exe
  Delete $INSTDIR\uninstall.exe

  RMDir "$INSTDIR"

  !insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder
  DeleteRegKey HKCU SOFTWARE\PrivateCloud
  Delete "$SMPROGRAMS\$StartMenuFolder\*.*"
  RMDir "$SMPROGRAMS\$StartMenuFolder"

SectionEnd

