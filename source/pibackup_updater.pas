unit pibackup_updater;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Dialogs, StdCtrls,   process,  exethread , Controls, forms, fileutil ,updatedlg;

procedure CheckForUpdates(Box: TListBox);

implementation

uses
  fpjson, jsonparser,unit1;

const
  REPO        = 'RaspberryFpc/pibackup';
  NEWDEB      = '/var/lib/pibackup/pibackup_new.deb';
  LASTGOODDEB = '/var/lib/pibackup/pibackup_last_good.deb';

  var
    RemoteVersion:string;



function GetRemoteVersion: string;
var
  S: String;
  J: TJSONData;
begin
  Result := '';

  if not RunCommand(
    'curl -s https://api.github.com/repos/' + REPO + '/releases/latest',
    S
  ) then
    Exit;

  J := GetJSON(S);
  try
    Result := Trim(J.FindPath('tag_name').AsString);
  finally
    J.Free;
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

procedure installupdate(box:tlistbox);
var
  s:string;
begin
ForceDirectories('/var/lib/pibackup');

s:=PrexeThreadedBash('wget -O ' + NEWDEB + ' https://raw.githubusercontent.com/' +  REPO + '/' + RemoteVersion +  '/bin/pibackup.deb',Box);

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

s:= PrexeThreadedBash('bash -c "sudo env DEBIAN_FRONTEND=noninteractive  apt install -y ' + NEWDEB +'"',form1.ListBox1);


if LastExitCode = 0 then
begin
 // =========================
 // UPDATE WAR ERFOLGREICH
 // =========================

 //DeleteDirectory('/var/lib/pibackup', False);
 DeleteFile('/var/lib/pibackup/pibackup_new.deb');
 DeleteFile('/var/lib/pibackup/pibackup_last_good.deb');

 if MessageDlg('updater',
   'Update installed successfully.' + LineEnding +
   '      Restart pibackup?',
   mtInformation,
   [mbYes, mbNo],
   0
 ) = mrYes then
 begin
   ExecuteProcess(ParamStr(0), '');
   Application.MainForm.Close;
 end;

end
else
begin
 // =========================
 // UPDATE FEHLER
 // =========================

 MessageDlg('updater',
   'Update failed'  + LineEnding +
   'System remains unchanged.',
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



function IsSnoozed: Boolean;
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


procedure CheckForUpdates(Box: TListBox);
var
s: String;
  sl:tstringlist;


begin

  if IsSnoozed then exit;

  RemoteVersion := GetRemoteVersion;

  if RemoteVersion = '' then
    Exit;

  if RemoteVersion = VERSION then
    Exit;

form5.Label1.caption:= 'There is a update available';
form5.Label2.caption:= 'Do you want install the update?';
form5.Label3.caption:= 'Installed: ' + VERSION ;
form5.Label4.caption:= 'Available: ' + RemoteVersion ;

form5.ShowModal;

case form5.modalresult of

        1: installupdate(box);
        2: exit;
        3: snoozeinstall;
        end;

end;

end.
