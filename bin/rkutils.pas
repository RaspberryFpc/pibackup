unit rkutils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, process, baseunix, LazUTF8, fileutil, dateutils, StdCtrls, Forms, ctypes, Dialogs;

type
  TMBRPartition = packed record
    BootFlag: byte;         // 0x0 Bootflag
    StartHead: byte;        // 0x1 Kopf, an dem die Partition anfängt
    StartSectorCylinder: byte; // 0x2 Anfangssektor und Bits des Anfangszylinders
    StartCylinder: byte;    // 0x3 Zylinderbeginn
    PartitionType: byte;    // 0x4 Partitions-Typ
    EndHead: byte;          // 0x5 Kopf, an dem die Partition endet
    EndSectorCylinder: byte; // 0x6 Letzter Sektor und Bits des Endzylinders
    EndCylinder: byte;      // 0x7 Zylinderende
    FirstLBA: DWORD;        // 0x8 LBA Nummer des ersten Sektors (32-Bit)
    PartitionSize: DWORD;   // 0xC Länge der Partition in Sektoren (32-Bit)
  end;


  TMBR = packed record
    BootCode: array[0..439] of byte;          // 0x000–0x1B7
    DiskSignature: DWORD;                     // 0x1B8–0x1BB
    Reserved: word;                           // 0x1BC–0x1BD (muss 0)
    PartitionEntries: array[1..4] of TMBRPartition; // 0x1BE–0x1FD
    Signature: word;                          // 0x1FE–0x1FF (muss $AA55)
  end;


function runbash(command: ansistring): string;
function prexe(cmdl: ansistring; parameter: array of string; box: tlistbox): ansistring;
function Prexebash(command: ansistring; box: tlistbox): ansistring;
function padleft(s: string; Count: integer): string;
function GetSecondField(const s: string): string;
function IsProgInstalled(progname: string): boolean;
function GetMountPointFromProc(const path: string): string;
procedure Listboxaddscroll(listbox: tlistbox; item: string);
function FileSizeAsString(size: int64; Use1024: boolean = True): ansistring;
procedure getDrives(sl: TStrings);
function ReplacePartUUIDInCmdline(Device: string; NewID: string): string;
function ReplacePartUUIDInFstab(device: string; newsignatur: string): string;
function GetMBRPartitionTypeName(PartType: byte): string;
function replacePartuuidinmbr(device: string; NewSignature: dword): string;
function Read_Mbr(const filename: string; var mbr: TMbr): boolean;
function Write_mbr(mbr: tmbr; filename: string): boolean;
function PartitionNamefromDevice(device: string; PartitionNumber: integer): string;
function ImageToDevice(Source, Destination: string; keep3, keep4: boolean; box: tlistbox): string;
//function WriteImageEx(const Source, Destination: string; keep3, keep4: boolean): string;
function MakeImagefirst2partitions(Sourcedrive, Filename: ansistring; listbox: tlistbox): boolean;
function getValueAfterKeyword(s, keyword: ansistring): int64;
function ms2T(ms: int64): ansistring;
function getStringAfterKeyword(s, keyword: ansistring): string;
function starLine(s: ansistring; len: integer): ansistring;
procedure Listboxupdate(listbox: tlistbox; item: string);
function ImageToDeviceImgAndZstd(Source, Destination: string; delpar3, delpar4: boolean; box: TListBox): string;
function PreCheckImageWrite(const Source, Destination: string): string;
function RunsAsRoot:boolean;

var
  terminate_all: boolean;

implementation

uses zstd;

const
  buffersize = 1024 * 1024 * 32; // 32 MB Buffer
  prexeBytesToRead = 2048;


var
  Buffer: array[0..buffersize - 1] of byte;
  cBuffer: array[0..prexeBytesToRead - 1] of char;

function RunsAsRoot:boolean;
begin
  if fpGetEUID = 0 then
   result:=true else result:=false;
end;


procedure Listboxaddscroll(listbox: tlistbox; item: string);
var
  pos: integer;
  n: integer;
begin
  listbox.Items.add(item);
  n := ListBox.ClientHeight div ListBox.ItemHeight;
  pos := ListBox.Items.Count - n + 2;
  if pos < 0 then pos := 0;
  ListBox.TopIndex := pos;
  listbox.Repaint;
end;

procedure Listboxupdate(listbox: tlistbox; item: string);
begin
  listbox.Items[ListBox.Items.Count - 1] := item;
  listbox.Repaint;
end;



function prexe(cmdl: ansistring; parameter: array of string; box: tlistbox): ansistring;
var
  cbufferpos: integer;
  xpos, bytesread: integer;
  su, sm: ansistring;
  n, x: integer;
  done: boolean;
  Count: integer;
  pr: tprocess;
begin
  Result := '';
  Count := box.items.Count;
  Listboxaddscroll(box, '');

  Pr := TProcess.Create(nil);
  pr.PipeBufferSize := prexeBytesToRead;
  pr.Executable := cmdl;

  for n := 0 to length(parameter) - 1 do pr.Parameters.Add(parameter[n]);

  Pr.Options := [poUsepipes, poStderrToOutPut, poDefaultErrorMode];
  Pr.Execute;
  Listboxaddscroll(box, '');
  xpos := 0;

  while pr.Running do
  begin
    sleep(50);
    //   application.ProcessMessages;
    bytesread := Pr.Output.Read(cbuffer, prexebytestoread);
    cbufferpos := 0;
    repeat
      su := '';
      done := False;

      while (cbufferpos < bytesread) and (cbuffer[cbufferpos] > #31) do

      begin
        su := su + cbuffer[cbufferpos];
        Inc(cbufferpos);
      end;
      if su > '' then
      begin
        sm := box.items[box.items.Count - 1];
        insert(su, sm, xpos + 1);
        Inc(xpos, length(su));
        Delete(sm, xpos + 1, length(su));
        Listboxupdate(box, sm);
        done := True;
      end;

      if (cbufferpos < bytesread) then
        if cbuffer[cbufferpos] = #10 then
        begin
          Inc(cBufferpos);
          Listboxaddscroll(box, '');
          xpos := 0;
          done := True;
        end;
      if (cbufferpos < bytesread) then
        if cbuffer[cbufferpos] = #8 then
        begin
          Inc(cBufferpos);
          Dec(xpos);
          if xpos < 0 then xpos := 0;
          done := True;
        end;
      if (cbufferpos < bytesread) then
        if cbuffer[cbufferpos] = #13 then
        begin
          Inc(cBufferpos);
          xpos := 0;
          done := True;
        end;

      if done = False then Inc(cbufferpos);
    until cbufferpos >= bytesread;            // testen was richtig ist  until cbufferpos > bytesread;


    if terminate_all then
    begin
      pr.Terminate(0);
      sleep(1000);
      if Pr.Running then
        fpKill(Pr.ProcessID, SIGKILL);
    end;
  end;

  if box.items.Count > Count then
    for x := Count to box.items.Count - 1 do
      Result := Result + box.items[x] + #10;

end;


function Prexebash(command: ansistring; box: tlistbox): ansistring;
begin
  if not terminate_all then
  begin
    Result := prexe('bash', ['-c', command], box);
  end
  else
    Result := '';
end;




function starLine(s: ansistring; len: integer): ansistring;
var
  l: integer;
  ch: char = '-';
begin
  s := ' ' + s + ' ';
  l := (len - UTF8Length(s)) div 2;
  for l := 1 to l do s := ch + s;
  while utf8length(s) < len do s := s + ch;
  Result := s;
end;

function getStringAfterKeyword(s, keyword: ansistring): string;
var
  p, x: integer;
  st, sx: ansistring;
begin
  p := pos(keyword, s);
  Delete(s, 1, p + length(keyword) - 1);
  s := trim(s);
  st := '';
  for x := 1 to length(s) do
  begin
    sx := copy(s, x, 1);
    if sx < #33 then break;
    st := st + sx;
  end;
  Result := st;
end;


function ms2T(ms: int64): ansistring;
var
  s, m, h, r: integer;
begin
  r := ms div 1000;
  s := r mod 60;
  r := r div 60;
  m := r mod 60;
  h := r div 60;
  Result := '';
  Result := IntToStr(h) + ':';
  if m < 10 then Result := Result + '0';
  Result := Result + IntToStr(m) + ':';
  if s < 10 then Result := Result + '0';
  Result := Result + IntToStr(s);
end;


function FileSizeAsString(size: int64; Use1024: boolean = True): ansistring;
const
  Sizes1024: array[0..8] of string = ('Byte', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB', 'ZiB', 'YiB');
  Sizes1000: array[0..8] of string = ('Byte', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB');
var
  Units: integer;
  S: string;
  Divisor: integer;
  sizef: double;
begin
  sizef := size;
  if Use1024 then
    Divisor := 1024
  else
    Divisor := 1000;

  Units := 0;

  while (Sizef >= Divisor) do
  begin
    Sizef := Sizef / Divisor;
    Inc(Units);
  end;
  if Use1024 then
    S := Sizes1024[Units]
  else
    S := Sizes1000[Units];
  Result := Format('%.3f %s', [Sizef, S]);
end;

function getValueAfterKeyword(s, keyword: ansistring): int64;
var
  p: integer;
  st: ansistring;
begin
  p := pos(keyword, s);
  Delete(s, 1, p + length(keyword) - 1);
  s := trim(s);
  st := '';
  while (S > '') and (Copy(s, 1, 1) >= '0') and (Copy(s, 1, 1) <= '9') do
  begin
    st := st + Copy(s, 1, 1);
    Delete(s, 1, 1);
  end;
  Result := 0;
  tryStrToInt64(st, Result);
end;


function IsProgInstalled(progname: string): boolean;
var
  debian: boolean;
  s, output: string;
begin
  Result := False;
  if RunCommand('cat', ['/etc/os-release'], Output) then
    debian := Pos('debian', LowerCase(Output)) > 0;
  if debian then
  begin
    runcommand('sudo dpkg -s ' + progname, s);
    if (s > '') and (pos('Package: ' + progname + #10, s) = 1) and (pos('Status: install ok installed', s) > 0) then Result := True;
  end
  else
  begin
    runcommand('sudo which ' + progname, s);
    if s = '/usr/bin/' + progname then Result := True;
  end;
end;


function padleft(s: string; Count: integer): string;
var
  p: integer;
begin
  p := Count - Length(s);
  if p > 0 then
    Result := StringOfChar(' ', p) + s
  else
    Result := s;
end;

function GetSecondField(const s: string): string;
var
  p1, p2: integer;
begin
  Result := '';
  p1 := Pos(' ', s);
  if p1 = 0 then Exit;

  // Suche nach Ende des 2. Feldes
  p2 := Pos(' ', s, p1 + 1);
  if p2 = 0 then
    Result := Trim(Copy(s, p1 + 1, Length(s))) // Rest der Zeile
  else
    Result := Trim(Copy(s, p1 + 1, p2 - p1 - 1));
end;


function GetExistingParent(const path: string): string;
var
  current: string;
begin
  current := ExpandFileName(path);
  while (not DirectoryExists(current)) and (not FileExists(current)) do
    current := ExtractFileDir(current);
  Result := current;
end;

function GetOriginalUser: string;
begin
  Result := GetEnvironmentVariable('SUDO_USER');
  if Result = '' then
    Result := GetEnvironmentVariable('USER');  // Falls nicht via sudo, normalen User holen
end;


function runbash(command: ansistring): string;
const
  BytesToRead = 2048;
var
  Buffer: array[0..BytesToRead - 1] of byte;
  BytesRead: longint;
  OutputStream: TMemoryStream;
  Pr: TProcess;
begin
  Result := '';
  Pr := TProcess.Create(nil);
  try
    Pr.Executable := 'bash';
    Pr.Parameters.Add('-c');
    Pr.Parameters.Add(command);
    Pr.Options := [poUsePipes, poStderrToOutPut];
    Pr.Execute;

    OutputStream := TMemoryStream.Create;
    try
      repeat
        // Wenn Daten verfügbar sind, lesen
        if Pr.Output.NumBytesAvailable > 0 then
        begin
          BytesRead := Pr.Output.Read(Buffer, SizeOf(Buffer));
          if BytesRead > 0 then
            OutputStream.Write(Buffer, BytesRead);
        end
        else
          Sleep(50);

        // Falls Abbruchsignal gesetzt: Prozess beenden
        if terminate_all then
        begin
          Pr.Terminate(0);
          Sleep(1000);
          if Pr.Running then
            fpKill(Pr.ProcessID, SIGKILL);
        end;

      until not Pr.Running and (Pr.Output.NumBytesAvailable = 0);

      // Ergebnis als String zurückgeben
      SetLength(Result, OutputStream.Size);
      OutputStream.Position := 0;
      if OutputStream.Size > 0 then
        OutputStream.Read(Result[1], OutputStream.Size);

    finally
      OutputStream.Free;
    end;
  finally
    Pr.Free;
  end;
end;


/////////////////////////// disk utils ///////////////////////////////7


procedure getDrives(sl: TStrings);
var
  s, dr: ansistring;
  p: integer;
begin
  sl.Clear;
  runcommand('fdisk -l', s);
  while pos('Disk /dev/ram', s) > 0 do
    Delete(s, pos('Disk /dev/ram', s), 13);
  repeat
    p := 0;
    p := pos('Disk /dev/', s);
    if p > 0 then
    begin
      Delete(s, 1, p + 4);
      p := pos(',', s);
      dr := copy(s, 1, p);
      Delete(s, 1, p);
      p := pos(',', s);
      dr := dr + copy(s, 1, p - 1);
      if p > 0 then
        sl.Add(dr);
    end;
  until p = 0;
end;



function GetMountPointFromProc(const path: string): string;
var
  mounts: TStringList;
  line, mountPoint: string;
  longestMatchLen: integer;
  i: integer;
  searchPath: string;
begin
  Result := '';
  mounts := TStringList.Create;
  try
    mounts.LoadFromFile('/proc/mounts');
    searchPath := GetExistingParent(path);
    longestMatchLen := 0;

    for i := 0 to mounts.Count - 1 do
    begin
      line := mounts[i];
      mountPoint := GetSecondField(line);  // holt 2. Wort
      if (mountPoint <> '') and (Pos(mountPoint, searchPath) = 1) and (Length(mountPoint) > longestMatchLen) and ((Length(searchPath) = Length(mountPoint)) or (searchPath[Length(mountPoint) + 1] = '/')) then
      begin
        Result := mountPoint;
        longestMatchLen := Length(mountPoint);
      end;
    end;
  finally
    mounts.Free;
  end;
end;



function GetMBRPartitionTypeName(PartType: byte): string;
begin
  case PartType of
    $00: Result := 'Empty';
    $01: Result := 'FAT12';
    $04: Result := 'FAT16(CHS)';
    $05: Result := 'Extended(CHS)';
    $06: Result := 'FAT16(LBA)';
    $07: Result := 'HPFS/NTFS/exFAT';
    $0B: Result := 'FAT32(CHS)';
    $0C: Result := 'FAT32(LBA)';
    $0E: Result := 'FAT16(LBA)';
    $0F: Result := 'Extended(LBA)';
    $11: Result := 'Hidden FAT12';
    $12: Result := 'Compaq diagnostics';
    $14: Result := 'Hidden FAT16 <32M';
    $17: Result := 'Hidden NTFS';
    $1B: Result := 'Hidden FAT32';
    $1C: Result := 'Hidden FAT32(LBA)';
    $1E: Result := 'Hidden FAT16(LBA)';
    $82: Result := 'Linux Swap';
    $83: Result := 'Linux';
    $84: Result := 'Hibernation';
    $85: Result := 'Linux Extended';
    $8E: Result := 'Linux LVM';
    $A5: Result := 'FreeBSD';
    $A6: Result := 'OpenBSD';
    $A8: Result := 'Mac OS X';
    $A9: Result := 'NetBSD';
    $AF: Result := 'macOS HFS/HFS+';
    $EE: Result := 'GPT Protective';
    $EF: Result := 'EFI System Partition';
    else
      Result := 'Unbekannt (' + IntToHex(PartType, 2) + ')';
  end;
end;

function Read_Mbr(const filename: string; var mbr: TMbr): boolean;
var
  Header: array[0..3] of byte;
  IsZstd, IsDevice: boolean;
  F: TFileStream;
  FD: cint;
  BytesRead: ssize_t;
  Proc: TProcess;
begin
  Result := False;
  FillChar(Mbr, 512, 0);

  if not FileExists(filename) and not FileExists('/dev/' + ExtractFileName(filename)) then
    Exit;

  IsDevice := Pos('/dev/', filename) = 1;

  // Bei Geräten: direkt low-level öffnen (kein TFileStream)
  if IsDevice then
  begin
    FD := fpOpen(PChar(filename), O_RDONLY);
    if FD < 0 then Exit;

    BytesRead := fpRead(FD, @Mbr, 512);
    fpClose(FD);

    if BytesRead = 512 then
      Result := True; //(Mbr.Signature = $55AA);
    Exit;
  end;

  // Zstandard-Magic prüfen
  try
    F := TFileStream.Create(filename, fmOpenRead or fmShareDenyNone);
    try
      if F.Read(Header, 4) <> 4 then Exit;
      IsZstd := (Header[0] = $28) and (Header[1] = $B5) and (Header[2] = $2F) and (Header[3] = $FD);
    finally
      F.Free;
    end;
  except
    Exit;
  end;

  if not IsZstd then
  begin
    try
      F := TFileStream.Create(filename, fmOpenRead or fmShareDenyNone);
      try
        if F.Size < 512 then Exit;
        F.Position := 0;
        Bytesread := F.Read(mbr, 512);
        Result := Bytesread = 512; //(Mbr.Signature = $55AA);
      finally
        F.Free;
      end;
    except
      Exit;
    end;
  end
  else
  begin
    // Komprimiert: Shell mit zstd | head -c 512
    Proc := TProcess.Create(nil);
    try
      Proc.Executable := '/bin/sh';
      Proc.Parameters.Add('-c');
      Proc.Parameters.Add(Format('zstd -dc "%s" | head -c 512', [filename]));
      Proc.Options := [poUsePipes];
      Proc.Execute;

      BytesRead := Proc.Output.Read(Mbr, SizeOf(Mbr));
      Result := (BytesRead = 512); // and (Mbr.Signature = $55AA);
    finally
      Proc.Free;
    end;
  end;
end;


function Write_mbr(mbr: tmbr; filename: string): boolean;
var
  mbr_writestream: tfilestream;
begin
  try
    mbr_writestream := tfilestream.Create(Filename, fmOpenReadWrite or fmShareDenyNone);
  except
    on E: Exception do
    begin
      Result := False;
      Exit;
    end;
  end;
  mbr_writestream.position := 0;
  mbr_writestream.Write(mbr, 512);
  mbr_writestream.Free;
  Result := True;
end;

function PartitionNamefromDevice(device: string; PartitionNumber: integer): string;
var
  sl: TStringList;
  s: string;
begin
  Result := '';
  if not RunCommand('lsblk ' + device + ' -rn -o NAME', s) then  exit;
  sl := TStringList.Create;
  sl.Text := s;
  if sl.Count < partitionnumber + 1 then exit;
  Result := '/dev/' + sl[partitionnumber];
  sl.Free;
end;

function ReplacePartUUIDInCmdline(Device: string; NewID: string): string;
var
  PartitionDevice, MountPoint, CommandFile, uline, s: ansistring;
  ft: TextFile;
  i: integer;
  sl: TStringList;
begin
  Result := ''; // leer = kein Fehler
  try
    PartitionDevice := PartitionNameFromDevice(Device, 1); // z.B. /dev/sdX1
    MountPoint := '/images/tmp_mount';
    CommandFile := MountPoint + '/cmdline.txt';

    RunCommand('umount', [MountPoint], s);
    RunCommand('umount', ['-l', PartitionDevice], s);
    RunCommand('umount', ['-f', PartitionDevice], s);
    Sleep(1000);

    if not DirectoryExists(MountPoint) then
      if not ForceDirectories(MountPoint) then
        raise Exception.Create('Failed to create mount directory: ' + MountPoint);
    Sleep(500);

    if not RunCommand('mount', ['-t', 'vfat', '-o', 'rw,uid=0,gid=0,umask=000', PartitionDevice, MountPoint], s) then
      raise Exception.Create('Failed to mount partition ' + PartitionDevice);

    if not FileExists(CommandFile) then
    begin
      RunCommand('umount', [MountPoint], s);
      RemoveDir(MountPoint);
      raise Exception.Create('cmdline.txt not found on partition');
    end;

    AssignFile(ft, CommandFile);
    Reset(ft);
    try
      ReadLn(ft, uline);
    finally
      CloseFile(ft);
    end;

    sl := TStringList.Create;
    try
      sl.StrictDelimiter := True;
      sl.Delimiter := ' ';
      sl.DelimitedText := uline;

      for i := 0 to sl.Count - 1 do
        if Copy(sl[i], 1, 5) = 'root=' then
        begin
          sl[i] := 'root=PARTUUID=' + NewID;
          Break;
        end;

      uline := sl.DelimitedText;

      AssignFile(ft, CommandFile);
      Rewrite(ft);
      try
        Write(ft, uline);
      finally
        CloseFile(ft);
      end;
    finally
      sl.Free;
    end;

    RunCommand('umount', [MountPoint], s);
    RemoveDir(MountPoint);

  except
    on E: Exception do
    begin
      // versuche Aufräumen auch bei Fehlern
      RunCommand('umount', [MountPoint], s);
      RemoveDir(MountPoint);

      Result := E.Message; // Fehlertext als Result
    end;
  end;
end;


function ReplacePartUUIDInFstab(device: string; newsignatur: string): string;
var
  sl: TStringList;
  p, x: integer;
  s: ansistring;
  PartitionDevice: ansistring;
  uMountPoint: ansistring;
begin
  Result := '';
  uMountPoint := '/images/tmp_mount';

  try
    // Partition Device 2 ermitteln
    PartitionDevice := partitionnamefromdevice(device, 2);

    // Sicher unmounten (unbedingt prüfen ob benötigt)
    RunCommand('umount', [uMountPoint], s);
    RunCommand('umount', ['-l', PartitionDevice], s);
    RunCommand('umount', ['-f', PartitionDevice], s);
    Sleep(3000);

    // Mountpoint vorbereiten
    if not DirectoryExists(uMountPoint) then
      if not ForceDirectories(uMountPoint) then
        raise Exception.Create('Failed to create mount directory: ' + uMountPoint);
    fpchmod(uMountPoint, &777);
    Sleep(1000);

    // Partition mounten, prüfen ob erfolgreich
    if not RunCommand('mount', [PartitionDevice, uMountPoint], s) then
      raise Exception.Create('Failed to mount partition ' + PartitionDevice);

    // Prüfen ob fstab existiert
    if not FileExists(uMountPoint + '/etc/fstab') then
    begin
      RunCommand('umount', [uMountPoint], s);
      RemoveDir(uMountPoint);
      raise Exception.Create('/etc/fstab not found on partition');
    end;

    sl := TStringList.Create;
    try
      sl.LoadFromFile(uMountPoint + '/etc/fstab');

      for x := 0 to sl.Count - 1 do
      begin
        s := sl[x];

        if (Pos(' /boot/firmware ', s) > 0) or (Pos(' /boot ', s) > 0) then
        begin
          // erstes "Wort" (UUID) entfernen
          p := Pos(' ', s);
          if p > 0 then
          begin
            Delete(s, 1, p - 1);
            sl[x] := 'PARTUUID=' + newsignatur + '-01' + s;
          end;
        end
        else if (Pos(' / ', s) > 0) then
        begin
          p := Pos(' ', s);
          if p > 0 then
          begin
            Delete(s, 1, p - 1);
            sl[x] := 'PARTUUID=' + newsignatur + '-02' + s;
          end;
        end;
      end;

      sl.SaveToFile(uMountPoint + '/etc/fstab');
    finally
      sl.Free;
    end;

    RunCommand('umount', [uMountPoint], s);
    RemoveDir(uMountPoint);

  except
    on E: Exception do
    begin
      // Aufräumen bei Fehler
      RunCommand('umount', [uMountPoint], s);
      RemoveDir(uMountPoint);
      Result := E.Message;
    end;
  end;
end;

function replacePartuuidinmbr(device: string; NewSignature: dword): string;
var
  uMBR: TMbr;
begin
  Result := '';
  try
    if not Read_MBR(device, uMBR) then
      raise Exception.Create('Could not read MBR from device: ' + device);

    uMBR.DiskSignature := NewSignature;

    if not Write_MBR(uMBR, device) then
      raise Exception.Create('Could not write MBR to device: ' + device);

  except
    on E: Exception do
      Result := E.Message;
  end;
end;


const
  BarWidth = 30;
  UpdateIntervalSec = 2;

var
  mbr_alt, mbr_image: TMbr;
  fsource, fdest: TFileStream;
  tocopy, done: int64;
  ReadCount, WrittenCount: integer;
  startTime, lastUpdate: TDateTime;
  elapsedSecs, speedMBs, etaSecs: double;
  percent: double;
  bar, StatusText, line: string;
  i, filled: integer;
  bootfound, rootfound: boolean;
  sl: TStringList;
  etaHours, etaMinutes, etaSeconds: integer;
  etaStr: string;
  lastline: integer;


function ImageToDevice(Source, Destination: string; keep3, keep4: boolean; box: tlistbox): string;
const
  BufferSize = 4 * 1024 * 1024;
begin
  Result := '';
  try
    bootfound := False;
    rootfound := False;

    if not RunCommand('lsblk ' + Destination + ' -b -J -o MOUNTPOINT', line) then
      raise Exception.Create('Error executing lsblk command.');

    sl := TStringList.Create;
    try
      sl.Text := line;
      for i := 0 to sl.Count - 1 do
      begin
        line := LowerCase(Trim(sl[i]));
        if Pos('"mountpoint":', line) > 0 then
        begin
          if line = '"mountpoint": "/"' then
            rootfound := True;
          if (line = '"mountpoint": "/boot"') or (line = '"mountpoint": "/boot/firmware"') then
            bootfound := True;
        end;
      end;
    finally
      sl.Free;
    end;

    if rootfound or bootfound then
      raise Exception.Create('Partition mounted as root or boot detected. Writing canceled.');

    if not FileExists(Source) then
      raise Exception.Create('Source file not found: ' + Source);

    if not Read_MBR(Source, mbr_image) then
      raise Exception.Create('Failed to read MBR from source file.');

    if not Read_MBR(Destination, mbr_alt) then
      raise Exception.Create('Failed to read MBR from destination device.');

    mbr_image.PartitionEntries[3] := mbr_alt.PartitionEntries[3];
    mbr_image.PartitionEntries[4] := mbr_alt.PartitionEntries[4];

    if keep3 then  FillChar(mbr_image.PartitionEntries[3], SizeOf(mbr_image.PartitionEntries[3]), 0);
    if keep4 then  FillChar(mbr_image.PartitionEntries[3], SizeOf(mbr_image.PartitionEntries[4]), 0);


    if not Write_MBR(mbr_image, Destination) then
      raise Exception.Create('Failed to write updated MBR to destination device.');


    fsource := TFileStream.Create(Source, fmOpenRead or fmShareDenyNone);
    fdest := TFileStream.Create(Destination, fmOpenWrite or fmShareDenyNone);
    try
      fsource.Position := 512;
      fdest.Position := 512;

      tocopy := FileSize(Source) - 512;
      done := 0;
      startTime := Now;
      lastUpdate := startTime;
      box.Items.Add('');
      box.Items.Add('');
      lastline := box.Count - 1;
      repeat
        ReadCount := fsource.Read(buffer, BufferSize);
        if ReadCount > 0 then
        begin
          WrittenCount := fdest.Write(buffer, ReadCount);
          if WrittenCount <> ReadCount then
            raise Exception.Create('Write error: Bytes written do not match bytes read.');
          Inc(done, WrittenCount);

          if SecondSpan(lastUpdate, Now) >= UpdateIntervalSec then
          begin
            lastUpdate := Now;
            elapsedSecs := SecondSpan(startTime, Now);
            if elapsedSecs < 0.001 then elapsedSecs := 0.001;

            percent := (done / tocopy) * 100.0;
            speedMBs := (done / 1048576) / elapsedSecs;
            if speedMBs > 0 then
              etaSecs := ((tocopy - done) / 1048576) / speedMBs
            else
              etaSecs := 0;

            filled := Round((percent / 100.0) * BarWidth);
            bar := StringOfChar('X', filled) + StringOfChar('-', BarWidth - filled);

            etaHours := Trunc(etaSecs) div 3600;
            etaMinutes := (Trunc(etaSecs) mod 3600) div 60;
            etaSeconds := Trunc(etaSecs) mod 60;
            etaStr := Format('%d:%.2d:%.2d', [etaHours, etaMinutes, etaSeconds]);

            StatusText := Format('%.1f MB (%.1f%%) [%s]  %.2f MB/s  ETA: %s', [done / 1048576, percent, bar, speedMBs, etaStr]);
            box.Items[lastline] := statustext;// optional: callback oder logging
            application.ProcessMessages;
          end;
        end;
      until (ReadCount = 0) or (done >= tocopy) or terminate_all;

      if done <> tocopy then
        raise Exception.Create('Incomplete image write operation.');
    finally
      fsource.Free;
      fdest.Free;
    end;

  except
    on E: Exception do
      Result := E.Message;
  end;
end;




function MakeImageFirst2Partitions(Sourcedrive, Filename: ansistring; ListBox: TListBox): boolean;
const
  buf_size = 1024 * 1024 * 32;
var
  info, s, loop: string;
  bps: double;
  makeImageStart, makeImageEnd: int64;
  readnr, remain, bytestocopy, tocopy, toread, all, all_alt: int64;
  ak_time, bps_time, dis_time: int64;
  gelesen, geschrieben: ssize_t;
  SourceStream, DestStream: TFileStream;
  MBR: TMbr;
begin
  try
    Result := False;
    bps := 0;
    bps_time := 0;
    dis_time := 0;
    all := 0;
    all_alt := 0;
    makeImageStart := GetTickCount64;


    // Read MBR and calculate size
    Read_MBR(SourceDrive, MBR);
    bytestocopy := (MBR.PartitionEntries[2].FirstLBA + MBR.PartitionEntries[2].PartitionSize) * 512;
    tocopy := bytestocopy;
    toread := tocopy;

    try
      DestStream := TFileStream.Create(Filename, fmCreate or fmOpenWrite or fmShareDenyNone);
    except
      on E: Exception do
      begin
        ListBox.Items.Add('Cannot open destination file for writing: ' + E.Message);
        Exit;
      end;
    end;

    try
      SourceStream := TFileStream.Create(Sourcedrive, fmOpenRead or fmShareDenyNone);
    except
      on E: Exception do
      begin
        ListBox.Items.Add('Cannot open source drive for reading: ' + E.Message);
        DestStream.Free;
        Exit;
      end;
    end;

    // Read MBR for safety (again)
    gelesen := SourceStream.Read(MBR, 512);
    SourceStream.Position := 0;

    ak_time := GetTickCount64;
    bps_time := ak_time;
    dis_time := ak_time;

    repeat
      if toread > Buf_Size then
        readnr := Buf_Size
      else
        readnr := toread;

      gelesen := SourceStream.Read(Buffer, readnr);
      if gelesen <= 0 then
        raise Exception.Create('Read error from source drive.');

      geschrieben := DestStream.Write(Buffer, gelesen);
      if geschrieben <> gelesen then
        raise Exception.Create('Write error: byte count mismatch.');

      Dec(toread, geschrieben);
      Inc(all, geschrieben);

      ak_time := GetTickCount64;



      // Update speed and ETA every 1–10 seconds

      if ak_time - bps_time > 10000 then
      begin
        bps := (all - all_alt) / (ak_time - bps_time); // KB/ms
        all_alt := all;
        bps_time := ak_time;
      end;

      if ak_time - dis_time > 5000 then
      begin
        dis_time := ak_time;

        if bps > 10 then
          remain := Round((tocopy - all) / bps / 1000)
        else
          remain := 0;

        if remain > 119 then
          s := IntToStr((remain div 60) + 1) + ' minutes'
        else
          s := IntToStr(remain) + ' seconds';

        info := Format('%d MB  %d%%  speed: %.1f MB/sec  ETA: %s', [all div 1000000, all * 100 div tocopy, bps / 1000, s]);

        // ListBox.Items.Delete(ListBox.Items.Count - 1);
        //Listboxaddscroll(ListBox,info);
        Listboxupdate(ListBox, info);

      end;

      application.ProcessMessages;

      if terminate_all then
      begin
        SourceStream.Free;
        DestStream.Free;
        RunBash('rm -f ' + Filename);
        Exit;
      end;

    until (toread = 0);

    makeImageEnd := GetTickCount64;
    ListBox.Items.Add(IntToStr(all) + ' of ' + IntToStr(tocopy) + ' bytes copied in ' + ms2t(makeImageEnd - makeImageStart));
    SourceStream.Free;
    DestStream.Free;

    // Attach loopback device and fix filesystem
    if RunCommand('losetup', ['-f', '--show', '-o', IntToStr(MBR.PartitionEntries[2].FirstLBA * 512), Filename], loop) then
    begin
      loop := Trim(loop);
      PrexeBash('e2fsck -fy ' + loop, listbox);
      PrexeBash('losetup -d ' + loop, listbox);
    end
    else
      ListBox.Items.Add('Warning: failed to create loopback device.');

    Result := True;

  except
    on E: Exception do
    begin
      ListBox.Items.Add('Exception: ' + E.Message);
      if Assigned(SourceStream) then SourceStream.Free;
      if Assigned(DestStream) then DestStream.Free;
      RunBash('rm -f ' + Filename);
    end;
  end;
end;


function WriteImagePlus(Source, Destination: string; DelPar3, DelPar4: boolean; box: TListBox): string;
const
  BufferSize = 65536; // optimal für ZSTD
  BarWidth = 30;
var
  fsource, fdest: TFileStream;
  dctx: TZSTD_DCtx;
  InBuf, OutBuf: array[0..BufferSize - 1] of byte;
  input: TZSTD_inBuffer;
  output: TZSTD_outBuffer;
  readBytes, WrittenCount: integer;
  compressed, bootfound, rootfound: boolean;
  totalRead, tocopy, done: int64;
  startTime, lastUpdate: TDateTime;
  percent, speedMBs, etaSecs, elapsedSecs: double;
  filled: integer;
  bar, etaStr, statustext, line: string;
  etaHours, etaMinutes, etaSeconds, lastline: integer;
  sl: TStringList;
  i: integer;
  mbr_image, mbr_alt: TMBR; // Annahme: MBR-Struktur ist verfügbar
begin
  Result := '';
  try
    compressed := LowerCase(ExtractFileExt(Source)) = '.zst';

    // 🔍 Prüfen, ob root/boot Partition auf Destination gemountet ist
    if not RunCommand('lsblk ' + Destination + ' -b -J -o MOUNTPOINT', line) then
      raise Exception.Create('Error executing lsblk command.');

    bootfound := False;
    rootfound := False;

    sl := TStringList.Create;
    try
      sl.Text := line;
      for i := 0 to sl.Count - 1 do
      begin
        line := LowerCase(Trim(sl[i]));
        if Pos('"mountpoint":', line) > 0 then
        begin
          if line = '"mountpoint": "/"' then rootfound := True;
          if (line = '"mountpoint": "/boot"') or (line = '"mountpoint": "/boot/firmware"') then bootfound := True;
        end;
      end;
    finally
      sl.Free;
    end;

    if rootfound or bootfound then
      raise Exception.Create('Partition mounted as root or boot detected. Writing canceled.');

    if not FileExists(Source) then
      raise Exception.Create('Source file not found: ' + Source);



    // Zielgerät öffnen
    fdest := TFileStream.Create(Destination, fmOpenWrite or fmShareDenyNone);
    try
      fdest.Position := 512;

      box.Items.Add('');
      box.Items.Add('');
      lastline := box.Count - 1;
      startTime := Now;
      lastUpdate := startTime;

      if compressed then
      begin
        fsource := TFileStream.Create(Source, fmOpenRead or fmShareDenyNone);
        try
          tocopy := fsource.Size;
          totalRead := 0;

          dctx := ZSTD_createDCtx;
          if dctx = nil then raise Exception.Create('ZSTD_createDCtx failed');
          ZSTD_initDStream(dctx);

          input.src := @InBuf;
          input.size := 0;
          input.pos := 0;

          repeat
            if input.pos >= input.size then
            begin
              readBytes := fsource.Read(InBuf, BufferSize);
              input.src := @InBuf;
              input.size := readBytes;
              input.pos := 0;
              Inc(totalRead, readBytes);
            end;

            output.dst := @OutBuf;
            output.size := BufferSize;
            output.pos := 0;

            if ZSTD_isError(ZSTD_decompressStream(dctx, output, input)) <> 0 then
              raise Exception.Create('ZSTD_decompressStream failed');

            WrittenCount := fdest.Write(OutBuf, output.pos);
            if WrittenCount <> output.pos then
              raise Exception.Create('Write error during decompression');

            // Fortschritt (komprimiert)
            percent := (totalRead / tocopy) * 100.0;
            elapsedSecs := SecondSpan(startTime, Now);
            if elapsedSecs < 0.001 then elapsedSecs := 0.001;
            speedMBs := (totalRead / 1048576) / elapsedSecs;
            if speedMBs > 0 then
              etaSecs := ((tocopy - totalRead) / 1048576) / speedMBs
            else
              etaSecs := 0;

            filled := Round((percent / 100.0) * BarWidth);
            bar := StringOfChar('X', filled) + StringOfChar('-', BarWidth - filled);
            etaHours := Trunc(etaSecs) div 3600;
            etaMinutes := (Trunc(etaSecs) mod 3600) div 60;
            etaSeconds := Trunc(etaSecs) mod 60;
            etaStr := Format('%d:%.2d:%.2d', [etaHours, etaMinutes, etaSeconds]);
            statustext := Format('%.1f MB (%.1f%%) [%s]  %.2f MB/s  ETA: %s', [totalRead / 1048576, percent, bar, speedMBs, etaStr]);

            box.Items[lastline] := statustext;
            Application.ProcessMessages;

          until (readBytes = 0) and (input.pos >= input.size);

          ZSTD_freeDCtx(dctx);
        finally
          fsource.Free;
        end;
      end
      else

      begin
        // Unkomprimiertes Schreiben ab Offset 512
        fsource := TFileStream.Create(Source, fmOpenRead or fmShareDenyNone);
        try
          fsource.Position := 512;
          tocopy := fsource.Size - 512;
          done := 0;

          repeat
            readBytes := fsource.Read(InBuf, BufferSize);
            if readBytes > 0 then
            begin
              WrittenCount := fdest.Write(InBuf, readBytes);
              if WrittenCount <> readBytes then
                raise Exception.Create('Write error: Bytes written do not match bytes read.');

              Inc(done, WrittenCount);

              if SecondSpan(lastUpdate, Now) >= 0.3 then
              begin
                lastUpdate := Now;
                elapsedSecs := SecondSpan(startTime, Now);
                if elapsedSecs < 0.001 then elapsedSecs := 0.001;
                percent := (done / tocopy) * 100.0;
                speedMBs := (done / 1048576) / elapsedSecs;
                if speedMBs > 0 then
                  etaSecs := ((tocopy - done) / 1048576) / speedMBs
                else
                  etaSecs := 0;

                filled := Round((percent / 100.0) * BarWidth);
                bar := StringOfChar('X', filled) + StringOfChar('-', BarWidth - filled);
                etaHours := Trunc(etaSecs) div 3600;
                etaMinutes := (Trunc(etaSecs) mod 3600) div 60;
                etaSeconds := Trunc(etaSecs) mod 60;
                etaStr := Format('%d:%.2d:%.2d', [etaHours, etaMinutes, etaSeconds]);
                statustext := Format('%.1f MB (%.1f%%) [%s]  %.2f MB/s  ETA: %s', [done / 1048576, percent, bar, speedMBs, etaStr]);

                box.Items[lastline] := statustext;
                Application.ProcessMessages;
              end;
            end;
          until (readBytes = 0) or (done >= tocopy);
        finally
          fsource.Free;
        end;
      end;


      if not Read_MBR(Source, mbr_image) then
        raise Exception.Create('Failed to read MBR from source file.');

      if not Read_MBR(Destination, mbr_alt) then
        raise Exception.Create('Failed to read MBR from destination device.');


      // MBR manipulieren  sollte man am ende machen
      mbr_image.PartitionEntries[3] := mbr_alt.PartitionEntries[3];
      mbr_image.PartitionEntries[4] := mbr_alt.PartitionEntries[4];

      if DelPar3 then FillChar(mbr_image.PartitionEntries[3], SizeOf(mbr_image.PartitionEntries[3]), 0);
      if DelPar4 then FillChar(mbr_image.PartitionEntries[4], SizeOf(mbr_image.PartitionEntries[4]), 0);

      if not Write_MBR(mbr_image, Destination) then
        raise Exception.Create('Failed to write updated MBR to destination device.');

    finally
      fdest.Free;
    end;

  except
    on E: Exception do
      Result := E.Message;
  end;
end;

////////////////////////////////////////////////////////////////////////////////////////////////////
var
  bline: string;
  bsl: TStringList;
  bi: integer;

function PreCheckImageWrite(const Source, Destination: string): string;
begin
  if not FileExists(Source) then
    Exit('Source file not found: ' + Source);

  if not FileExists(Destination) then
    Exit('Destination device not found: ' + Destination);

  // Check for mounted partitions

  if not RunCommand('lsblk ' + Destination + ' -b -J -o MOUNTPOINT', line) then
    Exit('Error executing lsblk command.');

  sl := TStringList.Create;
  try
    sl.Text := line;
    for bi := 0 to sl.Count - 1 do
    begin
      bline := LowerCase(Trim(sl[bi]));
      if Pos('"mountpoint":', bline) > 0 then
      begin
        if bline = '"mountpoint": "/"' then
          Exit('Partition mounted as root. Writing canceled.');
        if (bline = '"mountpoint": "/boot"') or (line = '"mountpoint": "/boot/firmware"') then
          Exit('Partition mounted as boot. Writing canceled.');
      end;
    end;
  finally
    bsl.Free;
  end;

  Result := '';
end;

function FinalizeMBRUpdate(Source, Destination: string; delpar3, delpar4: boolean): string;
var
  mbr_image, mbr_old: TMBR;
begin
  Result := '';

  if not Read_MBR(Source, mbr_image) then
    Exit('Failed to read MBR from source image.');
  if not Read_MBR(Destination, mbr_old) then
    Exit('Failed to read current MBR from destination.');

  if not delpar3 then
    mbr_image.PartitionEntries[3] := mbr_old.PartitionEntries[3]
  else
    FillChar(mbr_image.PartitionEntries[3], SizeOf(mbr_image.PartitionEntries[3]), 0);

  if not delpar4 then
    mbr_image.PartitionEntries[4] := mbr_old.PartitionEntries[4]
  else
    FillChar(mbr_image.PartitionEntries[4], SizeOf(mbr_image.PartitionEntries[4]), 0);

  if not Write_MBR(mbr_image, Destination) then
    Result := 'Failed to write updated MBR.';
end;



var
ibuffer: array of byte;

function ImageToDeviceStandard(Source, Destination: string; delpar3, delpar4: boolean; box: TListBox): string;
const
  BufferSize = 8 * 1024 * 1024;
var
  fsource: TFileStream;
  fdest: TFileStream;
  done, tocopy: int64;
  startTime, lastUpdate, elapsedSecs, percent, speedMBs, etaSecs: double;
  lastline: integer;
//  buffer: array of byte;
  ReadCount: int64;
  WrittenCount: int64;
  etaStr, bar, status: string;
  totalSecs, h, m, s: integer;
begin
  Result := '';
  try
    fsource := TFileStream.Create(Source, fmOpenRead or fmShareDenyNone);
    fdest := TFileStream.Create(Destination, fmOpenWrite or fmShareDenyNone);
    try
      fsource.Position := 512;
      fdest.Position := 512;

      tocopy := fsource.Size - 512;
      done := 0;
      startTime := Now;
      lastUpdate := startTime;
      lastline := box.Count-1;
      box.Items.Add('');
      repeat
        SetLength(ibuffer, BufferSize);
        ReadCount := fsource.Read(ibuffer[0], BufferSize);
        if ReadCount > 0 then
        begin
          WrittenCount := fdest.Write(ibuffer[0], ReadCount);
          if WrittenCount <> ReadCount then
            raise Exception.Create('Write error: Bytes written do not match bytes read.');

          Inc(done, WrittenCount);

          if SecondSpan(lastUpdate, Now) >= 0.5 then
          begin
            lastUpdate := Now;
            elapsedSecs := SecondSpan(startTime, Now);
            if elapsedSecs < 0.001 then elapsedSecs := 0.001;

            percent := (done / tocopy) * 100.0;
            speedMBs := (done / 1048576) / elapsedSecs;
            etaSecs := 0.0;
            if speedMBs > 0 then
              etaSecs := ((tocopy - done) / 1048576) / speedMBs;



            totalSecs := Trunc(etaSecs);
            h := totalSecs div 3600;
            m := (totalSecs mod 3600) div 60;
            s := totalSecs mod 60;
            etaStr := Format('%.2d:%.2d:%.2d', [h, m, s]);

            bar := StringOfChar('X', Round(percent *40 /100 )) + StringOfChar('-', 40 - Round(percent *40 / 100));
            status := Format('%.1f MB (%.1f%%) [%s]  %.2f MB/s  ETA: %s', [done / 1048576, percent, bar, speedMBs, etaStr]);
            box.Items[lastline] := status;
            Application.ProcessMessages;
          end;
        end;
      until (ReadCount = 0) or (done >= tocopy) or terminate_all;
    finally
      fsource.Free;
      fdest.Free;
    end;

    Result := FinalizeMBRUpdate(Source, Destination, delpar3, delpar4);
  except
    on E: Exception do
      Result := E.Message;
  end;
end;


function ImageToDeviceZstd(Source, Destination: string; delpar3, delpar4: boolean; box: TListBox): string;
const
  BufferSize = 32 * 1024 * 1024;
var
  fin, fout: TFileStream;
  dctx: TZSTD_DCtx;
  InBuffer: TZSTD_inBuffer;
  OutBuffer: TZSTD_outBuffer;
  InData: array of byte;
  OutData: array of byte;
  done: Int64 = 0;
  startTime, lastUpdate, elapsedSecs, etaSecs: double;
  lastline, res: integer;
  speedMBs: double;
  etaStr, status: string;
  totalSecs, h, m, s, percent: integer;
  tocopy: Int64;
  skipBytes: integer = 512;
begin
  Result := '';
  try
    fin := TFileStream.Create(Source, fmOpenRead or fmShareDenyNone);
    fout := TFileStream.Create(Destination, fmOpenWrite or fmShareDenyNone);
    try
      // Quelle vollständig lesen (inkl. MBR), Zielposition auf 512 setzen
      fin.Position := 0;
      fout.Position := 512;

      // Fortschrittsberechnung auf Basis des Zieldatenbereichs (ab Byte 512)
      tocopy := fin.Size;  // Komplette Datei
      if tocopy > 512 then
        tocopy := tocopy - 512
      else
        tocopy := 0;

      dctx := ZSTD_createDCtx();

      SetLength(InData, BufferSize);
      SetLength(OutData, BufferSize);

      done := 0;
      startTime := Now;
      lastUpdate := startTime;
      lastline := box.Count-1;
      box.Items.Add('');

      repeat
        // Eingabe lesen
        InBuffer.size := fin.Read(InData[0], BufferSize);
        InBuffer.src := @InData[0];
        InBuffer.pos := 0;

        while InBuffer.pos < InBuffer.size do
        begin
          OutBuffer.dst := @OutData[0];
          OutBuffer.size := BufferSize;
          OutBuffer.pos := 0;

          res := ZSTD_decompressStream(dctx, OutBuffer, InBuffer);
          if ZSTD_isError(res) <> 0 then
            raise Exception.Create('ZSTD decompress error: ' + ZSTD_getErrorName(res));

          if OutBuffer.pos > 0 then
          begin
            if skipBytes > 0 then
            begin
              if OutBuffer.pos > skipBytes then
              begin
                fout.Write(PByte(@OutData[0] + skipBytes)^, OutBuffer.pos - skipBytes);
                Inc(done, OutBuffer.pos - skipBytes);
                skipBytes := 0;
              end
              else
              begin
                // Noch im Überspringbereich
                Dec(skipBytes, OutBuffer.pos);
              end;
            end
            else
            begin
              fout.Write(OutData[0], OutBuffer.pos);
              Inc(done, OutBuffer.pos);
            end;
          end;

          // Fortschrittsanzeige alle 1 Sekunden
          if SecondSpan(lastUpdate, Now) >= 1.0 then
          begin
            lastUpdate := Now;
            elapsedSecs := SecondSpan(startTime, Now);
            if elapsedSecs < 0.001 then elapsedSecs := 0.001;

            speedMBs := (fin.Position / 1048576) / elapsedSecs;

           if (speedMBs > 0) and (fin.Size > 0) then
                         etaSecs := ((fin.Size - fin.Position) / 1048576) / speedMBs
           else
            etaSecs := 0;

            totalSecs := Trunc(etaSecs);
            h := totalSecs div 3600;
            m := (totalSecs mod 3600) div 60;
            s := totalSecs mod 60;
            etaStr := Format('%.2d:%.2d:%.2d', [h, m, s]);


            if fin.Size > 0 then
            percent := Round((fin.Position / fin.Size) * 100)
            else
            percent := 0;

            status := Format('%.1f MB written [%d%%] %.2f MB/s ETA %s', [done / 1048576, percent, speedMBs, etaStr]);
            box.Items[lastline] := status;
            Application.ProcessMessages;
          end;
        end;
      until (res = 0) or (terminate_all=true);

      ZSTD_freeDCtx(dctx);
    finally
      fin.Free;
      fout.Free;
    end;

    // Nachbearbeitung (z. B. MBR anpassen)
    Result := FinalizeMBRUpdate(Source, Destination, delpar3, delpar4);
  except
    on E: Exception do
      Result := E.Message;
  end;
end;




function ImageToDeviceImgAndZstd(Source, Destination: string; delpar3, delpar4: boolean; box: TListBox): string;
begin
  Result := PreCheckImageWrite(Source, Destination);
  if Result <> '' then Exit;

  if LowerCase(ExtractFileExt(Source)) = '.zst' then
    Result := ImageToDeviceZstd(Source, Destination, delpar3, delpar4, box)
    // filesize feststellen in comp-file   -------------------------------------------------------------------

  else
    begin
       if FileSize(source) mod 512 <> 0 then
                    raise Exception.Create('Image size is not a multiple of 512 bytes (sector size).');
    Result := ImageToDeviceStandard(Source, Destination, delpar3, delpar4, box);
    end;

end;


end.
