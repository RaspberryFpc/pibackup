unit UdiskieControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process;

function StopUdiskie: Boolean;
procedure StartUdiskie;

implementation

var
  UdiskieWasRunning: Boolean = False;
  UdiskieUser: string = '';
  UdiskieCommand: string = '';

function GetUserUID(const UserName: string): string;
var
  S: string;
begin
  Result := '';
  if RunCommand('id -u ' + QuotedStr(UserName), S) then
    Result := Trim(S);
end;

function IsProcessRunning(const PID: string): Boolean;
var
  S: string;
begin
  Result := RunCommand('kill -0 ' + PID, S);
end;

function StopUdiskie: Boolean;
var
  S: string;
  Lines: TStringList;
  I: Integer;
  PID: string;
  P: Integer;
  UserName: string;
  CommandLine: string;
  N: Integer;
begin
  Result := False;
  UdiskieWasRunning := False;
  UdiskieUser := '';
  UdiskieCommand := '';

  if not RunCommand('ps -eo user=,pid=,args=', S) then
    Exit;

  Lines := TStringList.Create;
  try
    Lines.Text := S;

    for I := 0 to Lines.Count - 1 do
    begin
      S := Trim(Lines[I]);

      if S = '' then
        Continue;

      P := Pos(' ', S);
      if P = 0 then
        Continue;

      UserName := Trim(Copy(S, 1, P - 1));
      Delete(S, 1, P);
      S := TrimLeft(S);

      P := Pos(' ', S);
      if P = 0 then
        Continue;

      PID := Trim(Copy(S, 1, P - 1));
      Delete(S, 1, P);
      CommandLine := TrimLeft(S);

      if Pos('/usr/bin/udiskie', CommandLine) = 0 then
        Continue;

      if (UserName = '') or (PID = '') or (CommandLine = '') then
        Continue;

      UdiskieUser := UserName;
      UdiskieCommand := CommandLine;
      UdiskieWasRunning := True;

      RunCommand('kill -TERM ' + PID, S);

      for N := 1 to 20 do
      begin
        Sleep(100);
        if not IsProcessRunning(PID) then
          Break;
      end;

      if IsProcessRunning(PID) then
      begin
        RunCommand('kill -KILL ' + PID, S);
        Sleep(200);
      end;

      Result := not IsProcessRunning(PID);
      Break;
    end;
  finally
    Lines.Free;
  end;
end;

procedure StartUdiskie;
var
  UID: string;
  RuntimeDir: string;
  DBusAddress: string;
  HomeDir: string;
  Cmd: string;
  S: string;
begin
  if not UdiskieWasRunning then
    Exit;

  if (UdiskieUser = '') or (UdiskieCommand = '') then
    Exit;

  UID := GetUserUID(UdiskieUser);

  if UID = '' then
    Exit;

  HomeDir := '/home/' + UdiskieUser;
  RuntimeDir := '/run/user/' + UID;
  DBusAddress := 'unix:path=' + RuntimeDir + '/bus';

  Cmd := 'runuser -u ' + QuotedStr(UdiskieUser) +
         ' -- env' +
         ' HOME=' + QuotedStr(HomeDir) +
         ' USER=' + QuotedStr(UdiskieUser) +
         ' LOGNAME=' + QuotedStr(UdiskieUser) +
         ' DISPLAY=:0.0' +
         ' XDG_RUNTIME_DIR=' + QuotedStr(RuntimeDir) +
         ' DBUS_SESSION_BUS_ADDRESS=' + QuotedStr(DBusAddress) +
         ' sh -c ' + QuotedStr(UdiskieCommand + ' >/dev/null 2>&1 &');

  RunCommand(Cmd, S);

  UdiskieWasRunning := False;
end;

end.
