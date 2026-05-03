unit ExcludeProcessor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fileutil, rkutils;

type
  TExcludeCommand = (
    exUnknown,
    exfile,
    exfileintree,
    exallintree,
    exdir
  );

  TExcludeEntry = record
    Command: TExcludeCommand;
    Path: string;
  end;

procedure ProcessList(const FileName: string; const MountPoint: string);

implementation

uses unit1;

var
  mountpointlen: integer;
  MP: string;

{ ------------------------------------------------------------ }

function RelPath(const FullPath: string): string;
begin
  if Length(FullPath) <= mountpointlen then
    Exit('');

  Result := Copy(FullPath, mountpointlen + 1, MaxInt);

  if (Result <> '') and (Result[1] = PathDelim) then
    Delete(Result, 1, 1);
end;

{ ------------------------------------------------------------ }

function ReplaceToRealUser(usertoken: string): string;
var
  user: string;
  p: Integer;
begin
  p := Pos('§user', LowerCase(usertoken));

  if p > 0 then
  begin
    user := GetEnvironmentVariable('SUDO_USER');
    if user = '' then
      user := GetEnvironmentVariable('USER');
  end;

  while p > 0 do
  begin
    Delete(usertoken, p, Length('§user'));
    Insert(user, usertoken, p);
    p := Pos('§user', LowerCase(usertoken));
  end;

  Result := usertoken;
end;

{ ------------------------------------------------------------ }

function ParseCommand(const s: string): TExcludeCommand;
begin
  case LowerCase(Trim(s)) of
    'file':        Result := exfile;
    'fileintree':  Result := exfileintree;
    'allintree':   Result := exallintree;
    'dir':         Result := exdir;
  else
    Result := exUnknown;
  end;
end;


// exfile löscht dateien wildcard in filename möglich
// exfileintree löscht dateien recursiv wildcard in filename möglich
// exallintree löscht alles aber der startordner bleibt erhalten
// exdir löscht dir komplett mit inhalt und subdirs

{ ------------------------------------------------------------ }

function ParseLine(const Line: string; LineNo: Integer): TExcludeEntry;
var
  p: Integer;
  key, val, s: string;
begin
  FillChar(Result, SizeOf(Result), 0);

  s := Line;

  s := Trim(s);
  if s = '' then Exit;

  p := Pos('=', s);
  if p = 0 then
    raise Exception.CreateFmt('Line %d: missing "="', [LineNo]);

  key := Trim(Copy(s, 1, p - 1));
  val := Trim(Copy(s, p + 1, MaxInt));

  val := ReplaceToRealUser(val);

  Result.Command := ParseCommand(key);

  if Result.Command = exUnknown then
    raise Exception.CreateFmt('Line %d: unknown command "%s"', [LineNo, key]);

  Result.Path := IncludeTrailingPathDelimiter(MP) + ExcludeLeadingPathDelimiter(val);

  if Pos(#0, Result.Path) > 0 then
    raise Exception.CreateFmt('Line %d: invalid path', [LineNo]);

  listboxaddscroll(form1.ListBox1, key + ' = ' + val);
end;

{ ------------------------------------------------------------ }

procedure DeleteFileMask(const ADir: string; const Mask: string);
var
  SR: TSearchRec;
  Path: string;
begin
  Path := IncludeTrailingPathDelimiter(ADir);

  if not DirectoryExists(ADir) then Exit;

  if FindFirst(Path + Mask, faAnyFile, SR) = 0 then
  try
    repeat
      if (SR.Name <> '.') and (SR.Name <> '..') and ((SR.Attr and faDirectory) = 0) then
      begin
        if not SysUtils.DeleteFile(Path + SR.Name) then
          raise Exception.Create('Failed: ' + RelPath(Path + SR.Name));

        listboxaddscroll(form1.ListBox1,
          'deleted file: ' + RelPath(Path + SR.Name));
      end;
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;
end;

{ ------------------------------------------------------------ }

procedure DeleteFileTreeRecursive(const ADir: string; const Mask: string);
var
  SR: TSearchRec;
  Path: string;
begin
  Path := IncludeTrailingPathDelimiter(ADir);

  if not DirectoryExists(ADir) then Exit;

  DeleteFileMask(ADir, Mask);

  if FindFirst(Path + '*', faDirectory, SR) = 0 then
  try
    repeat
      if (SR.Name <> '.') and (SR.Name <> '..') then
        if (SR.Attr and faDirectory) <> 0 then
          DeleteFileTreeRecursive(Path + SR.Name, Mask);
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;
end;

{ ------------------------------------------------------------ }

procedure DeleteDirContent(const ADir: string);
var
  SR: TSearchRec;
  Path: string;
begin
  Path := IncludeTrailingPathDelimiter(ADir);

  if not DirectoryExists(ADir) then Exit;

  if FindFirst(Path + '*', faAnyFile, SR) = 0 then
  try
    repeat
      if (SR.Name <> '.') and (SR.Name <> '..') then
      begin
        if (SR.Attr and faDirectory) <> 0 then
        begin
          DeleteDirectory(Path + SR.Name, True);
          listboxaddscroll(form1.ListBox1,
            'deleted dir: ' + RelPath(Path + SR.Name));
        end
        else
        begin
          if not SysUtils.DeleteFile(Path + SR.Name) then
            raise Exception.Create('Failed: ' + RelPath(Path + SR.Name));

          listboxaddscroll(form1.ListBox1,
            'deleted file: ' + RelPath(Path + SR.Name));
        end;
      end;
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;
end;

{ ------------------------------------------------------------ }

procedure DeleteTree(const ADir: string);
begin
  if not DirectoryExists(ADir) then Exit;

  if not DeleteDirectory(ADir, True) then
    raise Exception.Create('Failed to delete tree: ' + RelPath(ADir));
end;

{ ------------------------------------------------------------ }

procedure ProcessList(const FileName: string; const MountPoint: string);
var
  i: Integer;
  entry: TExcludeEntry;
  list: TStringList;
  s:string;
  p:integer;

begin
  MP := ExcludeTrailingPathDelimiter(MountPoint);
  mountpointlen := Length(MP);

  list := TStringList.Create;
  try
    if not FileExists(FileName) then
      raise Exception.Create('File not found: ' + FileName);

    list.LoadFromFile(FileName);

    listboxaddscroll(form1.ListBox1, '');
    listboxaddscroll(form1.ListBox1, 'processing exclude: ' + FileName);

    for i := 0 to list.Count - 1 do
    begin
      s:=list[i];
      p := Pos('#', s);
      if p > 0 then
           Delete(s, p, MaxInt);

      entry := ParseLine(s, i + 1);

      if entry.Path = '' then Continue;

      listboxaddscroll(form1.listbox1,'Command: '+s);

      if not entry.Path.StartsWith(MP) then
        raise Exception.Create('SECURITY: escape attempt');

      case entry.Command of

        exfile:
          DeleteFileMask(
            ExtractFilePath(entry.Path),
            ExtractFileName(entry.Path)
          );

        exfileintree:
          DeleteFileTreeRecursive(
            ExtractFilePath(entry.Path),
            ExtractFileName(entry.Path)
          );

        exallintree:
        begin
          if IncludeTrailingPathDelimiter(entry.Path) =
             IncludeTrailingPathDelimiter(MP) then
            raise Exception.Create('SECURITY: refusing to wipe mount root');

          DeleteDirContent(entry.Path);
        end;

        exdir:
          DeleteTree(entry.Path);

      else
        raise Exception.Create('Unknown command');
      end;
    end;

  finally
    list.Free;
  end;
end;

end.
