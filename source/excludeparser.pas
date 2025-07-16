unit ExcludeParser;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, Forms, StdCtrls,rkutils;

type
  TExcludeCommand = (ecUnknown, ecRF, ecRD, ecRT, ecRFID, ecRAIT, ecRAID);

  TExcludeEntry = record
    Command: TExcludeCommand;
    Path: string;
  end;

  TExcludeList = class
  private
    FList: array of TExcludeEntry;
    FMountPoint: string;
    FLogTarget: TListBox;
    function ParseCommand(const cmd: string): TExcludeCommand;
    function ReplacePlaceholders(const s: string): string;
    function FullPath(const RelPath: string): string;
    procedure ExecuteCommand(const CmdLine: string; clearcmd: string);
  public
    procedure LoadFromFile(const FileName, MountPoint: string);
    procedure Clear;
    function Count: integer;
    function GetEntry(Index: integer): TExcludeEntry;
    procedure ExecuteAll;
    property LogTarget: TListBox read FLogTarget write FLogTarget;
  end;

implementation

uses unit1;


function TExcludeList.ParseCommand(const cmd: string): TExcludeCommand;
begin
  case LowerCase(Trim(cmd)) of
    'rf': Result := ecRF;
    'rd': Result := ecRD;
    'rt': Result := ecRT;
    'rfid': Result := ecRFID;
    'rait': Result := ecRAIT;
    'raid': Result := ecRAID;
    else
      Result := ecUnknown;
  end;
end;

function QuoteString(const S: string): string;
begin
  Result := '"' + StringReplace(S, '"', '\"', [rfReplaceAll]) + '"';
end;


 function TExcludeList.ReplacePlaceholders(const s: string): string;
var
  user: string;
begin
  User := GetEnvironmentVariable('SUDO_USER');
  if User = '' then
    User := GetEnvironmentVariable('USER'); // fallback, wenn nicht über sudo gestartet
   if User = '' then  user := GetEnvironmentVariable('USERNAME');
   Result := StringReplace(s, '§user', user, [rfReplaceAll, rfIgnoreCase]);
end;


function TExcludeList.FullPath(const RelPath: string): string;
begin
  Result := IncludeTrailingPathDelimiter(FMountPoint) + TrimLeft(RelPath.Trim(['/']));
end;

procedure TExcludeList.LoadFromFile(const FileName, MountPoint: string);
var
  sl: TStringList;
  i, p: integer;
  line, key, val: string;
  entry: TExcludeEntry;
begin
  Clear;
  FMountPoint := ExcludeTrailingPathDelimiter(MountPoint);
  sl := TStringList.Create;
  try
    sl.LoadFromFile(FileName);

    for i := 0 to sl.Count - 1 do
    begin
      line := Trim(sl[i]);
      if (line = '') or (line[1] = '#') then
        Continue;

      p := Pos('=', line);
      if p = 0 then Continue;

      key := Trim(Copy(line, 1, p - 1));
      val := Trim(Copy(line, p + 1, Length(line)));
      entry.Command := ParseCommand(key);
      entry.Path := FullPath(ReplacePlaceholders(val));

      if entry.Command <> ecUnknown then
      begin
        SetLength(FList, Length(FList) + 1);
        FList[High(FList)] := entry;
      end;
    end;
  finally
    sl.Free;
  end;
end;

procedure TExcludeList.Clear;
begin
  SetLength(FList, 0);
end;

function TExcludeList.Count: integer;
begin
  Result := Length(FList);
end;

function TExcludeList.GetEntry(Index: integer): TExcludeEntry;
begin
  if (Index >= 0) and (Index < Count) then
    Result := FList[Index]
  else
    raise Exception.CreateFmt('Index %d out of bounds', [Index]);
end;



procedure TExcludeList.ExecuteCommand(const CmdLine: string; clearcmd: string);
var
  s: string;    // nur zum debuggen
begin
  if clearcmd > '' then
  //FLogTarget.Items.Add(clearcmd);
  Listboxaddscroll(FLogTarget, clearcmd);


  s:=runbash(CmdLine);
   if s > #10 then
    Listboxaddscroll(FLogTarget,s);
   //FLogTarget.Items.Add(s);

  // application.ProcessMessages;
end;



procedure TExcludeList.ExecuteAll;
var
  i: integer;
  entry: TExcludeEntry;
  cmd, clearcmd: string;
begin
  for i := 0 to Count - 1 do
  begin
    entry := GetEntry(i);
    case entry.Command of
      ecRF: begin
        clearcmd := 'deletefile ' + copy(entry.Path,length(fmountpoint)+1,1024);
        cmd := 'rm -f ' + QuoteString(entry.Path);
      end;
      ecRD: begin
        clearcmd := 'Remove directory ' + copy(entry.Path,length(fmountpoint)+1,1024);
        cmd := 'rmdir ' + QuoteString(entry.Path);
      end;
       ecRT: begin
        clearcmd := 'Remove tree ' +  copy(entry.Path,length(fmountpoint)+1,1024);
        cmd := 'rm -rf ' + QuoteString(entry.Path);
         end;
      ecRFID: begin
        clearcmd := 'Remove files in directory '+ copy(entry.Path,length(fmountpoint)+1,1024);
        cmd := 'find ' + QuoteString(entry.Path) + ' -maxdepth 1 -type f -exec rm -f {} +';
        end;
      ecRAIT: begin
        clearcmd := 'Remove all in tree ' + copy(entry.Path,length(fmountpoint)+1,1024);
        cmd := 'find ' + QuoteString(entry.Path) + ' -mindepth 1 -exec rm -rf {} +';
         end;
      ecRAID: begin
        clearcmd := 'Remove all in directory ' + copy(entry.Path,length(fmountpoint)+1,1024);
        cmd := 'rm -rf ' + QuoteString(entry.Path) + '/*';
         end;
      else
    Continue;
    end;
    ExecuteCommand(cmd, clearcmd);
  end;
  runbash('sync');
  sleep(3000);
end;

end.
