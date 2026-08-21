unit pibackup_updater;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Dialogs, StdCtrls, process, exethread, Controls, Forms, fileutil, updatedlg;

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
  res: boolean;
  dotcount, x: integer;

begin
  Result := '';
  res := True;
  dotcount := 0;
  if RunCommand('curl -L -s https://raw.githubusercontent.com/' + REPO + '/master/bin/version.txt', S) then
  begin
    S := Trim(S);

    // Ist wirklich eine Versionsnummer?


    if (length(s) > 15) or (length(s) < 5)    then res := False;

    if res and (copy(s,1,1) <> 'v') then res := False;

    if res  then
    for x := 2 to length(s) do
    begin
      if s[x] = '.' then Inc(dotcount);
      if (not (S[x] in ['0'..'9'])) and (S[x] <> '.') then
          begin
            res := False;
            break;
          end;
     end;

    if res and (dotcount <> 2) then res := False;
    if res and (pos('..',s)>0) then res := False;

    if res then
    begin
      Result := S;
      Exit;
    end;
  end;



  // Fallback: alte GitHub-API
  if not RunCommand('curl -s https://api.github.com/repos/' + REPO + '/releases/latest', S) then
    Exit;

  try
    J := GetJSON(S);
    try
      Result := Trim(J.FindPath('tag_name').AsString);
    finally
      J.Free;
    end;
  except
    Result := '';
  end;
end;




procedure CommitUpdate;
begin
  DeleteFile(LASTGOODDEB);         // falls vorhanden
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
    P.Options := [];          // Nicht auf das neue Programm warten
    P.Execute;
  finally
    P.Free;
  end;
  Application.MainForm.Close;
  //  Application.Terminate;
end;




procedure installupdate(box: tlistbox);
var
  s: string;
begin
  ForceDirectories('/var/lib/pibackup');

  s := PrexeThreadedBash('wget -O ' + NEWDEB + ' https://raw.githubusercontent.com/' + REPO + '/' + RemoteVersion + '/bin/pibackup.deb', Box);

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

  s := PrexeThreadedBash('bash -c "sudo env DEBIAN_FRONTEND=noninteractive  apt install -y ' + NEWDEB + '"', form1.ListBox1);


  if LastExitCode = 0 then
  begin
    // =========================
    // UPDATE WAR ERFOLGREICH
    // =========================

    //DeleteDirectory('/var/lib/pibackup', False);
    DeleteFile('/var/lib/pibackup/pibackup_new.deb');
    DeleteFile('/var/lib/pibackup/pibackup_last_good.deb');

    if MessageDlg('updater', 'Update installed successfully.' + LineEnding + '      Restart pibackup?', mtInformation, [mbYes, mbNo], 0) = mrYes then
    begin
      //ExecuteProcess(ParamStr(0), '');
      restartapplication;

    end;

  end
  else
  begin
    // =========================
    // UPDATE FEHLER
    // =========================

    MessageDlg('updater',
      'Update failed' + LineEnding + 'System remains unchanged.',
      mtError,
      [mbOK],
      0
      );

    // OPTIONAL: rollback aktiv lassen
    // CommitUpdate NICHT aufrufen
  end;
end;


procedure SnoozeInstall;
var
  f: TextFile;
  SnoozeFile: string;
begin
  SnoozeFile := '/var/lib/pibackup/update_snooze.dat';

  try
    ForceDirectories('/var/lib/pibackup');

    AssignFile(f, SnoozeFile);
    Rewrite(f);
    try
      // z.B. 3 Tage Snooze
      Writeln(f, DateTimeToStr(Now + 3));
    finally
      CloseFile(f);
    end;

  except
    on E: Exception do
    begin
      // optional Logging statt GUI
      Exit;
    end;
  end;

  Form5.Close;
end;



function IsSnoozed: boolean;
var
  f: TextFile;
  SnoozeFile: string;
  s: string;
  dt: TDateTime;
begin
  Result := False;
  SnoozeFile := '/var/lib/pibackup/update_snooze.dat';

  if not FileExists(SnoozeFile) then
    Exit;

  AssignFile(f, SnoozeFile);
  Reset(f);
  try
    ReadLn(f, s);
  finally
    CloseFile(f);
  end;

  // Datum/Uhrzeit aus Datei lesen
  if not TryStrToDateTime(s, dt) then
  begin
    // ungültige Datei -> löschen
    DeleteFile(SnoozeFile);
    Exit;
  end;

  // Snooze ist noch aktiv
  if Now < dt then
    Result := True
  else
  begin
    // abgelaufen -> Datei entfernen
    DeleteFile(SnoozeFile);
    Result := False;
  end;
end;


function VersionToInt64(Ver: string): int64;
var
  Major, Minor, Patch: int64;
  p1, p2: integer;
begin

  if (copy(ver,1,1)='v') or (copy(ver,1,1)='V') then delete(ver,1,1);

  p1 := Pos('.', Ver);
  p2 := Pos('.', Ver, p1 + 1);

  Major := StrToInt64(Copy(Ver, 1, p1 - 1));
  Minor := StrToInt64(Copy(Ver, p1 + 1, p2 - p1 - 1));
  Patch := StrToInt64(Copy(Ver, p2 + 1, MaxInt));

  Result := Major * 100000000 + Minor * 10000 + Patch;
end;




procedure CheckForUpdates(Box: TListBox);
var
  remoteversion: string;
begin

  if IsSnoozed then exit;

  remoteversion := GetRemoteVersion;
  if remoteversion = '' then exit;

  if VersionToInt64(RemoteVersion) <= VersionToInt64(Version) then
    Exit;


  form5.Label1.Caption := 'There is a update available';
  form5.Label2.Caption := 'Do you want install the update?';
  form5.Label3.Caption := 'Installed: ' + VERSION;
  form5.Label4.Caption := 'Available: ' + RemoteVersion;

  form5.ShowModal;

  case form5.modalresult of
    1: installupdate(box);
    2: exit;
    3: snoozeinstall;
  end;

end;

end.
