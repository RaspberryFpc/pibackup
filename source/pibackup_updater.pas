unit pibackup_updater;

{$mode objfpc}{$H+}

interface

uses
Classes, SysUtils, Dialogs, StdCtrls, process, exethread, Controls,
Forms, fileutil, updatedlg;

procedure CheckForUpdates(Box: TListBox);

implementation

uses
fpjson, jsonparser, unit1;

const
REPO = 'RaspberryFpc/pibackup';
NEWDEB = '/var/lib/pibackup/pibackup_new.deb';
LASTGOODDEB = '/var/lib/pibackup/pibackup_last_good.deb';

var
RemoteVersion: string;

function GetRemoteVersion: string;
var
S: string;
J: TJSONData;
Tag: string;
begin
Result := '';

// Neueste GitHub-Release abfragen
if not RunCommand(
'curl -L -s --fail https://api.github.com/repos/' + REPO + '/releases/latest',
S
) then
Exit;

try
J := GetJSON(S);
try
Tag := Trim(J.FindPath('tag_name').AsString);

  // Muss wie v2.1.1 aussehen
  if (Length(Tag) < 5) or (Length(Tag) > 15) then
    Exit;

  if (Tag[1] <> 'v') and (Tag[1] <> 'V') then
    Exit;

  Result := Tag;
finally
  J.Free;
end;

except
Result := '';
end;
end;

procedure CommitUpdate;
begin
DeleteFile(LASTGOODDEB);

if RenameFile(NEWDEB, LASTGOODDEB) then
Exit;

if CopyFile(NEWDEB, LASTGOODDEB) then
DeleteFile(NEWDEB);
end;

procedure RestartApplication;
var
P: TProcess;
begin
P := TProcess.Create(nil);
try
P.Executable := '/usr/lib/pibackup/pibackup';
P.Options := [];
P.Execute;
finally
P.Free;
end;

Application.MainForm.Close;
end;

procedure InstallUpdate(Box: TListBox);
var
S: string;
DownloadURL: string;
begin
ForceDirectories('/var/lib/pibackup');

// RemoteVersion wurde vorher automatisch von GitHub ermittelt.
// Beispiel:
// RemoteVersion = v2.1.1
DownloadURL :=
'https://raw.githubusercontent.com/' +
REPO + '/' + RemoteVersion + '/bin/pibackup.deb';

S := PrexeThreadedBash(
'wget -O ' + NEWDEB + ' "' + DownloadURL + '"',
Box
);

if not FileExists(NEWDEB) then
begin
MessageDlg(
'Error',
'Download failed.',
mtError,
[mbOK],
0
);
Exit;
end;

S := PrexeThreadedBash(
'bash -c "sudo env DEBIAN_FRONTEND=noninteractive apt install -y ' +
NEWDEB + '"',
Form1.ListBox1
);

if LastExitCode = 0 then
begin
DeleteFile(NEWDEB);
DeleteFile(LASTGOODDEB);


if MessageDlg(
  'updater',
  'Update installed successfully.' + LineEnding +
  '      Restart pibackup?',
  mtInformation,
  [mbYes, mbNo],
  0
) = mrYes then
begin
  RestartApplication;
end;


end
else
begin
MessageDlg(
'updater',
'Update failed' + LineEnding +
'System remains unchanged.',
mtError,
[mbOK],
0
);
end;
end;

procedure SnoozeInstall;
var
F: TextFile;
SnoozeFile: string;
begin
SnoozeFile := '/var/lib/pibackup/update_snooze.dat';

try
ForceDirectories('/var/lib/pibackup');


AssignFile(F, SnoozeFile);
Rewrite(F);
try
  Writeln(F, DateTimeToStr(Now + 3));
finally
  CloseFile(F);
end;


except
on E: Exception do
Exit;
end;

Form5.Close;
end;

function IsSnoozed: boolean;
var
F: TextFile;
SnoozeFile: string;
S: string;
DT: TDateTime;
begin
Result := False;
SnoozeFile := '/var/lib/pibackup/update_snooze.dat';

if not FileExists(SnoozeFile) then
Exit;

AssignFile(F, SnoozeFile);
Reset(F);
try
ReadLn(F, S);
finally
CloseFile(F);
end;

if not TryStrToDateTime(S, DT) then
begin
DeleteFile(SnoozeFile);
Exit;
end;

if Now < DT then
Result := True
else
begin
DeleteFile(SnoozeFile);
Result := False;
end;
end;

function VersionToInt64(Ver: string): int64;
var
Major, Minor, Patch: int64;
P1, P2: integer;
begin
if (Copy(Ver, 1, 1) = 'v') or
(Copy(Ver, 1, 1) = 'V') then
Delete(Ver, 1, 1);

P1 := Pos('.', Ver);
P2 := Pos('.', Ver, P1 + 1);

if (P1 = 0) or (P2 = 0) then
begin
Result := -1;
Exit;
end;

try
Major := StrToInt64(Copy(Ver, 1, P1 - 1));
Minor := StrToInt64(Copy(Ver, P1 + 1, P2 - P1 - 1));
Patch := StrToInt64(Copy(Ver, P2 + 1, MaxInt));

Result := Major * 100000000 +
          Minor * 10000 +
          Patch;

except
Result := -1;
end;
end;

procedure CheckForUpdates(Box: TListBox);
begin
if IsSnoozed then
Exit;

// Neueste Release-Version automatisch von GitHub holen
RemoteVersion := GetRemoteVersion;

if RemoteVersion = '' then
Exit;

// Nur installieren, wenn Remote-Version neuer ist
if VersionToInt64(RemoteVersion) <= VersionToInt64(Version) then
Exit;

Form5.Label1.Caption := 'There is a update available';
Form5.Label2.Caption := 'Do you want install the update?';
Form5.Label3.Caption := 'Installed: ' + VERSION;
Form5.Label4.Caption := 'Available: ' + RemoteVersion;

Form5.ShowModal;

case Form5.ModalResult of
1: InstallUpdate(Box);
2: Exit;
3: SnoozeInstall;
end;
end;

end.

