[Setup]
AppName=Smart University System
AppVersion=1.0.0
DefaultDirName={autopf}\Smart University System
DefaultGroupName=Smart University System
OutputDir=.
OutputBaseFilename=SmartUniversity_Setup
Compression=lzma
SolidCompression=yes
SetupIconFile=windows\runner\resources\app_icon.ico

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "windows\runner\resources\app_icon.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Smart University System"; Filename: "{app}\SmartUniversity.exe"; IconFilename: "{app}\app_icon.ico"
Name: "{autodesktop}\Smart University System"; Filename: "{app}\SmartUniversity.exe"; IconFilename: "{app}\app_icon.ico"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
