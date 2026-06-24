unit pibackup_updater;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Dialogs, StdCtrls,   process,  exethread , Controls ;

procedure CheckForUpdates(Box: TListBox);

implementation

uses
  fpjson, jsonparser,unit1;

const
  REPO        = 'RaspberryFpc/pibackup';
  NEWDEB      = '/var/lib/pibackup/pibackup_new.deb';
  LASTGOODDEB = '/var/lib/pibackup/pibackup_last_good.deb';

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
var
  Dummy: String;
begin
  RunCommand(
    'cp ' + NEWDEB + ' ' + LASTGOODDEB,
    Dummy
  );
end;

procedure RestartApplication;
begin
  ExecuteProcess(ParamStr(0), '');
  Halt;
end;

procedure CheckForUpdates(Box: TListBox);
var
  RemoteVersion,s: String;
begin
  RemoteVersion := GetRemoteVersion;

  if RemoteVersion = '' then
    Exit;

  if RemoteVersion = VERSION then
    Exit;


  if MessageDlg('Pibackup updater',
       'There is a update available'+ LineEnding +
       'Installed: ' + VERSION + LineEnding +
       'Available: ' + RemoteVersion + LineEnding + LineEnding +
       'Do you want install the update now?',
       mtConfirmation,
       [mbYes, mbNo],
       0
     ) <> mrYes then  exit;





  ForceDirectories('/var/lib/pibackup');

  s:=PrexeThreadedBash(
    'wget -O ' + NEWDEB +
    ' https://raw.githubusercontent.com/' +
    REPO + '/' + RemoteVersion +
    '/bin/pibackup.deb',
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

  s:= PrexeThreadedBash('apt install -y ' + NEWDEB,             // sudo
    Box
  );

  CommitUpdate;

  MessageDlg(
    'Update erfolgreich',
    'pibackup wird jetzt neu gestartet.',
    mtInformation,
    [mbOK],
    0
  );

  RestartApplication;
end;

end.
