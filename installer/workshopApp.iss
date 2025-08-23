; installer/WorkshopApp.iss
#define MyAppName "Workshop App"
#define MyAppExeName "flutter_workshop_front.exe"   ; <-- executável correto
#define MyAppPublisher "Unspoken Tech Org"
#define MyAppVersion GetEnv("APP_VER")              ; setado pelo CI
#define MyAppDir "C:\Program Files\WorkshopApp"

[Setup]
AppId={{A8B5D3C4-1A2B-4C5D-9E0F-112233445566}}      ; GUID fixo
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={#MyAppDir}
DefaultGroupName={#MyAppName}
DisableDirPage=yes
DisableProgramGroupPage=yes
OutputDir=..\dist
OutputBaseFilename=WorkshopApp-setup
Compression=lzma
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=lowest
CloseApplications=yes
RestartIfNeededByRun=no
UsePreviousAppDir=no

[Languages]
Name: "ptbr"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Files]
; Copia tudo da pasta Release do build do Flutter
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"

[Run]
; Abre o app após instalação (opcional)
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
