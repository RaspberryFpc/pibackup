  unit UdiskieControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, process;

function StopUdiskie: Boolean;
procedure StartUdiskie;

implementation

var
  UdiskieWasRunning: Boolean = False;
  UdiskieUser: string = '';
  UdiskieCommand: string = '';

function StopUdiskie: Boolean;
var
  S: string;
  Lines: TStringList;
  I: Integer;
  PID: string;
  P: Integer;
  UserName: string;
  CommandLine: string;
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

      { USER }
      P := Pos(' ', S);
      if P = 0 then
        Continue;

      UserName := Trim(Copy(S, 1, P - 1));
      Delete(S, 1, P);
      S := TrimLeft(S);

      { PID }
      P := Pos(' ', S);
      if P = 0 then
        Continue;

      PID := Trim(Copy(S, 1, P - 1));
      Delete(S, 1, P);
      CommandLine := TrimLeft(S);

      { nur den udiskie-Prozess suchen }
      if Pos('/usr/bin/udiskie', CommandLine) = 0 then
        Continue;

      if (UserName = '') or (PID = '') or (CommandLine = '') then
        Continue;

      UdiskieUser := UserName;
      UdiskieCommand := CommandLine;
      UdiskieWasRunning := True;

      { nur diese udiskie-Instanz beenden }
      RunCommand('kill ' + PID, S);

      Sleep(200);

      Result := True;
      Break;
    end;
  finally
    Lines.Free;
  end;
end;

procedure StartUdiskie;
var
  Cmd: string;
  S: string;
begin
  if not UdiskieWasRunning then
    Exit;

  if (UdiskieUser = '') or (UdiskieCommand = '') then
    Exit;

  Cmd := 'runuser -u ' + QuotedStr(UdiskieUser) +
         ' -- sh -c ' +
         QuotedStr(UdiskieCommand + ' >/dev/null 2>&1 &');

  RunCommand(Cmd, S);

  UdiskieWasRunning := False;
end;

end.
