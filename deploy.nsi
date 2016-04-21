; deploy.nsi

;--------------------------------
;Include Modern UI

  !include "MUI2.nsh"

;--------------------------------
;General

  ;Name and file
  Name "Xcloud"

  ; The file to write
  OutFile "XcloudSetup.exe"

  ; The default installation directory
  InstallDir $PROGRAMFILES\Xcloud

  ;Get installation folder from registry if available
  InstallDirRegKey HKCU "Software\Xcloud" ""

  ; Request application privileges for Windows Vista
  RequestExecutionLevel admin

  BrandingText "AllMobilize Inc."
;--------------------------------
;Macros

!macro "CreateURLShortCut" "URLFile" "URLSite"
  WriteINIStr "${URLFile}.URL" "InternetShortcut" "URL" "${URLSite}"
!macroend

;--------------------------------
;Variables

  Var StartMenuFolder
  Var ProgramName

;--------------------------------
;Interface Settings

  !define MUI_ABORTWARNING
  !define MUI_ICON "install.ico"
  !define MUI_UNICON "uninstall.ico"

;--------------------------------
;Language Selection Dialog Settings

  ;Remember the installer language
  !define MUI_LANGDLL_REGISTRY_ROOT "HKCU"
  !define MUI_LANGDLL_REGISTRY_KEY "Software\$ProgramName"
  !define MUI_LANGDLL_REGISTRY_VALUENAME "Installer Language"

;--------------------------------
;Pages

  !insertmacro MUI_PAGE_LICENSE "License.txt"
  !insertmacro MUI_PAGE_DIRECTORY

  ;Start Menu Folder Page Configuration
  !define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKCU" 
  !define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\$ProgramName"
  !define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu Folder"

  !insertmacro MUI_PAGE_STARTMENU Application $StartMenuFolder

  !insertmacro MUI_PAGE_INSTFILES

  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES

;--------------------------------
;Languages
 
  !insertmacro MUI_LANGUAGE "English"
  !insertmacro MUI_LANGUAGE "SimpChinese"

;--------------------------------
;Reserve Files

  ;If you are using solid compression, files that are required before
  ;the actual installation should be stored first in the data block,
  ;because this will make your installer start faster.

  !insertmacro MUI_RESERVEFILE_LANGDLL

;--------------------------------
;Installer Sections

Section "Xcloud"

  ; Set output path to the installation directory.
  SetOutPath $INSTDIR
  ; Put file there
  File "node.exe"
  File "nssm.exe"
  File "logo.ico"

  SetOutPath "$LOCALAPPDATA\$ProgramName"
  File /r /x ".git" "..\xcloud-private-deployment\*.*"

  ; Write the installation path into the registry
  WriteRegStr HKCU SOFTWARE\$ProgramName "" $INSTDIR

  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$ProgramName" "DisplayName" "$ProgramName"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$ProgramName" "DisplayIcon" "$INSTDIR\logo.ico"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$ProgramName" "Publisher" "美通云动（北京）科技有限公司"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$ProgramName" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$ProgramName" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$ProgramName" "NoRepair" 1

  WriteUninstaller "$INSTDIR\uninstall.exe"

  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application

    ;Create shortcuts
    CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Uninstall $ProgramName.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
    !insertmacro "CreateURLShortCut" "$SMPROGRAMS\$StartMenuFolder\$ProgramName App" "http://localhost:30000"

  !insertmacro MUI_STARTMENU_WRITE_END

  nsExec::Exec '"$INSTDIR\nssm.exe" install $ProgramName "$INSTDIR\node.exe" "$LOCALAPPDATA\$ProgramName\server.js"'
  nsExec::Exec '"$INSTDIR\nssm.exe" set $ProgramName AppEnvironmentExtra "NODE_ENV=production"'
  nsExec::Exec '"$INSTDIR\nssm.exe" set $ProgramName Start SERVICE_AUTO_START'
  nsExec::Exec '"$INSTDIR\nssm.exe" set $ProgramName AppExit Default Restart'
  nsExec::Exec '"$INSTDIR\nssm.exe" set $ProgramName AppRestartDelay 0'
  nsExec::Exec '"$INSTDIR\nssm.exe" set $ProgramName AppThrottle 1500'
  nsExec::Exec '"$INSTDIR\nssm.exe" start $ProgramName'
  ExecShell open "http://localhost:30000"

SectionEnd

;--------------------------------
;Installer Functions

Function .onInit

  StrCpy $ProgramName "Xcloud"
  !insertmacro MUI_LANGDLL_DISPLAY

FunctionEnd

;--------------------------------
; Uninstaller

Section "Uninstall"

  nsExec::Exec '"$INSTDIR\nssm.exe" stop $ProgramName'
  nsExec::Exec '"$INSTDIR\nssm.exe" remove $ProgramName confirm'

  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$ProgramName"

  RMDir /r "$LOCALAPPDATA\$ProgramName"

  Delete $INSTDIR\node.exe
  Delete $INSTDIR\nssm.exe
  Delete $INSTDIR\uninstall.exe

  RMDir "$INSTDIR"

  !insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder
  DeleteRegKey HKCU SOFTWARE\$ProgramName
  Delete "$SMPROGRAMS\$StartMenuFolder\*.*"
  RMDir "$SMPROGRAMS\$StartMenuFolder"

SectionEnd

;--------------------------------
;Uninstaller Functions

Function un.onInit

  StrCpy $ProgramName "Xcloud"
  !insertmacro MUI_UNGETLANGUAGE

FunctionEnd
