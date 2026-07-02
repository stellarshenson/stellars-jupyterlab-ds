; --------------------------------------------------------------------------------------------------
;
;   Stellars JupyterLab DS Platform - Windows installer
;   Project Home: https://github.com/stellarshenson/stellars-jupyterlab-ds
;
;   Installs the docker compose deployment (compose files + start/stop scripts) into a
;   per-user directory, asks for the initial JupyterLab password (stored in .env as
;   JUPYTERLAB_SERVER_TOKEN), creates Start Menu shortcuts and registers an uninstaller
;   that removes containers, images and (on confirmation) the data volumes.
;
;   Requires Docker Desktop or Rancher Desktop (docker compose) on the target machine -
;   checked at startup, the installer points to both download pages when missing.
;   The platform image is pulled from Docker Hub on first start, nothing is built locally.
;
;   Build with: ./build.sh   (or: makensis -DVERSION=<x.y.z> installer.nsi)
;
; --------------------------------------------------------------------------------------------------

Unicode true
SetCompressor /SOLID lzma

!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "LogicLib.nsh"

!ifndef VERSION
  !define VERSION "0.0.0"
!endif

!define PROJECT_NAME "stellars-jupyterlab-ds"
!define DISPLAY_NAME "Stellars JupyterLab DS"
!define PUBLISHER "Stellars"
!define ACCESS_URL "https://localhost/${PROJECT_NAME}/jupyterlab"
!define UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PROJECT_NAME}"

Name "${DISPLAY_NAME}"
OutFile "dist/${PROJECT_NAME}-setup-${VERSION}.exe"
InstallDir "$LOCALAPPDATA\${PROJECT_NAME}"
RequestExecutionLevel user
ShowInstDetails show
ShowUninstDetails show

Var Dialog
Var PasswordBox
Var Password

; ---------------------------------------- pages

!define MUI_WELCOMEPAGE_TITLE "${DISPLAY_NAME} ${VERSION}"
!define MUI_WELCOMEPAGE_TEXT "This wizard installs the ${DISPLAY_NAME} platform (JupyterLab, Traefik proxy and watchtower - a docker compose deployment).$\r$\n$\r$\nDocker Desktop or Rancher Desktop with the docker compose plugin must be installed and able to run Linux containers.$\r$\n$\r$\nThe first start downloads the platform image from Docker Hub (several GB)."
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
Page custom PasswordPageCreate PasswordPageLeave
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Start the platform now"
!define MUI_FINISHPAGE_RUN_FUNCTION StartPlatform
!define MUI_FINISHPAGE_TEXT "${DISPLAY_NAME} has been installed.$\r$\n$\r$\nAccess URL: ${ACCESS_URL}$\r$\n$\r$\nLog in with the password you set - it is never placed in the URL, and you can change it after you log in. The password is stored in $INSTDIR\.env (key JUPYTERLAB_SERVER_TOKEN).$\r$\n$\r$\nUse the Start Menu shortcuts to start, stop or open JupyterLab later."
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

; ---------------------------------------- version info shown in the .exe file properties

VIProductVersion "${VERSION}.0"
VIAddVersionKey "ProductName" "${DISPLAY_NAME}"
VIAddVersionKey "ProductVersion" "${VERSION}"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "FileDescription" "${DISPLAY_NAME} installer"
VIAddVersionKey "LegalCopyright" "${PUBLISHER}"

; ---------------------------------------- install

; refuse to install when docker compose is not available on the machine
Function .onInit
  nsExec::ExecToStack 'cmd.exe /C docker compose version'
  Pop $0
  Pop $1
  ${If} $0 != "0"
    MessageBox MB_ICONSTOP "Docker Compose was not found on this system.$\r$\n$\r$\nInstall Docker Desktop (https://www.docker.com/products/docker-desktop/) or Rancher Desktop (https://rancherdesktop.io/) and run this installer again."
    Abort
  ${EndIf}
FunctionEnd

; first-start password page - same role as the prompt in start.bat: the value becomes
; JUPYTERLAB_SERVER_TOKEN in .env and is asked for on the JupyterLab login page
Function PasswordPageCreate
  !insertmacro MUI_HEADER_TEXT "JupyterLab password" "Set the initial password for JupyterLab access"
  nsDialogs::Create 1018
  Pop $Dialog
  ${If} $Dialog == error
    Abort
  ${EndIf}
  ${NSD_CreateLabel} 0 0 100% 36u "This is the initial password; you can change it after you log in.$\r$\nIt is stored in the .env file (key JUPYTERLAB_SERVER_TOKEN) inside the install directory and is asked for on the JupyterLab login page - it is never placed in the URL."
  Pop $0
  ${NSD_CreateLabel} 0 44u 20% 12u "Password:"
  Pop $0
  ${NSD_CreatePassword} 21% 42u 65% 13u ""
  Pop $PasswordBox
  ${NSD_SetFocus} $PasswordBox
  nsDialogs::Show
FunctionEnd

Function PasswordPageLeave
  ${NSD_GetText} $PasswordBox $Password
  ${If} $Password == ""
    MessageBox MB_ICONEXCLAMATION "Please enter a password."
    Abort
  ${EndIf}
FunctionEnd

Section "Install"
  SetOutPath "$INSTDIR"

  ; platform deployment files - the image itself is pulled from Docker Hub on first start
  File "../../compose.yml"
  File "../../compose-gpu.yml"
  File "../../start.bat"
  File "../../stop.bat"
  File "../../LICENSE"

  ; .env with the project name and the password typed on the password page
  FileOpen $0 "$INSTDIR\.env" w
  FileWrite $0 "# name of the project for docker-compose$\r$\n"
  FileWrite $0 "COMPOSE_PROJECT_NAME=${PROJECT_NAME}$\r$\n"
  FileWrite $0 "# initial JupyterLab password (login page asks for it); change it after you log in$\r$\n"
  FileWrite $0 "JUPYTERLAB_SERVER_TOKEN=$Password$\r$\n"
  FileClose $0

  ; start menu shortcuts - start/stop console scripts, access URL and uninstaller
  CreateDirectory "$SMPROGRAMS\${DISPLAY_NAME}"
  CreateShortCut "$SMPROGRAMS\${DISPLAY_NAME}\Start JupyterLab.lnk" "$INSTDIR\start.bat"
  CreateShortCut "$SMPROGRAMS\${DISPLAY_NAME}\Stop JupyterLab.lnk" "$INSTDIR\stop.bat"
  WriteINIStr "$SMPROGRAMS\${DISPLAY_NAME}\Open JupyterLab.url" "InternetShortcut" "URL" "${ACCESS_URL}"

  ; desktop shortcut to the server access URL
  WriteINIStr "$DESKTOP\JupyterLab.url" "InternetShortcut" "URL" "${ACCESS_URL}"
  WriteUninstaller "$INSTDIR\uninstall.exe"
  CreateShortCut "$SMPROGRAMS\${DISPLAY_NAME}\Uninstall.lnk" "$INSTDIR\uninstall.exe"

  ; add/remove programs entry (per-user)
  WriteRegStr HKCU "${UNINST_KEY}" "DisplayName" "${DISPLAY_NAME}"
  WriteRegStr HKCU "${UNINST_KEY}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "${UNINST_KEY}" "Publisher" "${PUBLISHER}"
  WriteRegStr HKCU "${UNINST_KEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "${UNINST_KEY}" "DisplayIcon" "$INSTDIR\uninstall.exe"
  WriteRegStr HKCU "${UNINST_KEY}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKCU "${UNINST_KEY}" "NoModify" 1
  WriteRegDWORD HKCU "${UNINST_KEY}" "NoRepair" 1
SectionEnd

; "Start the platform now" on the finish page - start.bat pulls the image when missing,
; starts compose (GPU-aware) and prints the access URL in its console window
Function StartPlatform
  ExecShell "open" "$INSTDIR\start.bat"
FunctionEnd

; ---------------------------------------- uninstall

Section "Uninstall"
  ; ask about the data volumes first - deleting them erases all notebooks and data
  StrCpy $R0 ""
  MessageBox MB_YESNO|MB_ICONQUESTION|MB_DEFBUTTON2 "Also remove the data volumes (JupyterLab home, workspace, cache, certificates)?$\r$\n$\r$\nThis permanently deletes all notebooks and data stored in the platform." IDNO keep_volumes
  StrCpy $R0 "--volumes"
keep_volumes:

  ; stop and remove containers, the network and the images used by the services
  DetailPrint "Stopping the platform and removing containers and images..."
  nsExec::ExecToLog 'cmd.exe /C cd /d "$INSTDIR" && docker compose --env-file .env -f compose.yml down --remove-orphans --rmi all $R0'
  Pop $0
  ${If} $0 != "0"
    DetailPrint "Warning: docker compose down failed (is Docker Desktop running?) - remove containers manually."
  ${EndIf}

  ; installed files
  Delete "$INSTDIR\compose.yml"
  Delete "$INSTDIR\compose-gpu.yml"
  Delete "$INSTDIR\start.bat"
  Delete "$INSTDIR\stop.bat"
  Delete "$INSTDIR\LICENSE"
  Delete "$INSTDIR\.env"
  Delete "$INSTDIR\uninstall.exe"
  RMDir "$INSTDIR"

  ; shortcuts and registry
  Delete "$DESKTOP\JupyterLab.url"
  Delete "$SMPROGRAMS\${DISPLAY_NAME}\Start JupyterLab.lnk"
  Delete "$SMPROGRAMS\${DISPLAY_NAME}\Stop JupyterLab.lnk"
  Delete "$SMPROGRAMS\${DISPLAY_NAME}\Open JupyterLab.url"
  Delete "$SMPROGRAMS\${DISPLAY_NAME}\Uninstall.lnk"
  RMDir "$SMPROGRAMS\${DISPLAY_NAME}"
  DeleteRegKey HKCU "${UNINST_KEY}"
SectionEnd

; EOF
