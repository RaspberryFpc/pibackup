unit rkutils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, process, baseunix, unix, LazUTF8, fileutil, dateutils, StdCtrls, Forms, Dialogs, UnixType;

type
  TExt4Superblock = packed record
    s_inodes_count: uint32;
    s_blocks_count: uint32;
    s_r_blocks_count: uint32;
    s_free_blocks_count: uint32;
    s_free_inodes_count: uint32;
    s_first_data_block: uint32;
    s_log_block_size: uint32;
    s_log_frag_size: int32;
    s_blocks_per_group: uint32;
    s_frags_per_group: uint32;
    s_inodes_per_group: uint32;
    s_mtime: uint32;
    s_wtime: uint32;
    s_mnt_count: uint16;
    s_max_mnt_count: int16;
    s_magic: uint16;
    s_state: uint16;
    s_errors: uint16;
    s_minor_rev_level: uint16;
    s_lastcheck: uint32;
    s_checkinterval: uint32;
    s_creator_os: uint32;
    s_rev_level: uint32;
    s_def_resuid: uint16;
    s_def_resgid: uint16;
    s_first_ino: uint32;
    s_inode_size: uint16;
    s_block_group_nr: uint16;
    s_feature_compat: uint32;
    s_feature_incompat: uint32;
    s_feature_ro_compat: uint32;
    s_uuid: array[0..15] of byte;
    s_volume_name: array[0..15] of ansichar;
    s_last_mounted: array[0..63] of ansichar;
    s_algorithm_usage_bitmap: uint32;
    // ... weitere Felder ausgelassen
  end;

  TExt4BlockGroupDescriptor = packed record
    bg_block_bitmap: uint32;
    bg_inode_bitmap: uint32;
    bg_inode_table: uint32;
    bg_free_blocks_count: uint16;
    bg_free_inodes_count: uint16;
    bg_used_dirs_count: uint16;
    bg_pad: uint16;
    bg_reserved: array[0..2] of uint32;
  end;



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


type
  TMountedPartition = record
    ImageFile: string;
    PartitionNumber: integer;
    MountPoint: string;
    LoopDevice: string;
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
procedure ReplacePartuuidinmbr(device: string; NewSignature: dword);
function GetMBRPartitionTypeName(PartType: byte): string;
function Read_Mbr(const filename: string): tmbr;
procedure Write_mbr(mbr: tmbr; filename: string);
function PartitionNamefromDevice(device: string; PartitionNumber: integer): string;
procedure MakeImagefirst2partitions(Sourcedrive, Filename: ansistring; listbox: tlistbox);
function getValueAfterKeyword(s, keyword: ansistring): int64;
function ms2T(ms: int64): ansistring;
function getStringAfterKeyword(s, keyword: ansistring): string;
function starLine(s: ansistring; len: integer): ansistring;
procedure Listboxupdate(listbox: tlistbox; item: string);
procedure ImageToDeviceImgAndZstd(Source, Destination: string; delpar3, delpar4: boolean; box: TListBox);
procedure PreCheckImageWrite(const Source, Destination: string);
function RunsAsRoot: boolean;
procedure SaveUmount(mount: string; listbox: TListBox);
function is_mounted(mount: string; var mountpoint: string; var device: string): boolean;
procedure ClearEmptyBlocks(listbox: tlistbox; Mounted: TMountedPartition);
procedure MountPartitionFromImage(const ImageFile: string; PartitionNumber: integer; const MountPoint: string; out Mounted: TMountedPartition; ListBox: TListBox);
procedure UnmountOnly(const Mounted: TMountedPartition; ListBox: TListBox);
procedure RemountPartition(const Mounted: TMountedPartition; ListBox: TListBox);
procedure ClosePartition(var Mounted: TMountedPartition; ListBox: TListBox);
function LoopDeviceExists(const Device: string): boolean;


var
  terminate_all: boolean;

implementation

uses zstd, unit1;

const

  puffersize = 48;


var
  //  Buffer: array[0..buffersize - 1] of byte;
  ValHistory: array[0..PufferSize - 1] of int64;
  TimeHistory: array[0..PufferSize - 1] of uint64;
  pufferindex: integer;


function RunsAsRoot: boolean;
begin
  if fpGetEUID = 0 then
    Result := True
  else
    Result := False;
end;

procedure MountPartitionFromImage(const ImageFile: string; PartitionNumber: integer; const MountPoint: string; out Mounted: TMountedPartition; ListBox: TListBox);
var
  s, offsetStr, loopDev: string;
  startSector: int64;
  mbr: TMbr;
begin
  Mounted.ImageFile := ImageFile;
  Mounted.PartitionNumber := PartitionNumber;
  Mounted.MountPoint := MountPoint;
  Mounted.LoopDevice := '';

  if not FileExists(ImageFile) then
    raise Exception.Create('Image not found: ' + ImageFile);

  if not DirectoryExists(MountPoint) then
    ForceDirectories(MountPoint);

  // MBR auslesen
  mbr := read_mbr(ImageFile);

  if (PartitionNumber < Low(mbr.PartitionEntries)) or (PartitionNumber > High(mbr.PartitionEntries)) then
    raise Exception.Create('Invalid PartitionNumber: ' + IntToStr(PartitionNumber));

  startSector := mbr.PartitionEntries[PartitionNumber].FirstLBA;
  offsetStr := IntToStr(startSector * 512); // Sektorgröße 512 Byte

  // Loopdevice anlegen
  RunCommand('losetup --find --show -o ' + offsetStr + ' "' + ImageFile + '"', loopDev);
  loopDev := Trim(loopDev);
  if loopDev = '' then
    raise Exception.Create('Failed to create loop device');
  Mounted.LoopDevice := loopDev;

  // Partition mounten
  RunCommand('mount -t auto ' + loopDev + ' "' + MountPoint + '"', s);
  listboxaddscroll(ListBox, '✓ Mounted partition ' + IntToStr(PartitionNumber) + ' at ' + MountPoint + ' (' + loopDev + ')');
end;




procedure UnmountOnly(const Mounted: TMountedPartition; ListBox: TListBox);
begin
  if Mounted.MountPoint <> '' then
    SaveUmount(Mounted.MountPoint, ListBox);
end;

procedure RemountPartition(const Mounted: TMountedPartition; ListBox: TListBox);
var
  s: string;
begin
  if (Mounted.MountPoint <> '') and (Mounted.LoopDevice <> '') then
  begin
    if not DirectoryExists(Mounted.MountPoint) then
      ForceDirectories(Mounted.MountPoint);

    RunCommand('mount -t auto ' + Mounted.LoopDevice + ' ' + Mounted.MountPoint, s);
    listboxaddscroll(ListBox, '✓ Remounted partition at ' + Mounted.MountPoint + ' (' + Mounted.LoopDevice + ')');
  end;
end;

function LoopDeviceExists(const Device: string): boolean;
var
  s: string;
begin
  Result := False;
  if Device = '' then Exit;

  if RunCommand('losetup -a', s) then
    Result := Pos(Device, s) > 0;
end;


procedure RemoveEmptyPathUpwards(const Path: string; ListBox: TListBox);
var
  Current: string;
  sr: TSearchRec;
  IsEmpty: boolean;
begin
  Current := ExcludeTrailingPathDelimiter(Path);

  while (Current <> '') and DirectoryExists(Current) do
  begin
    IsEmpty := True;

    if FindFirst(Current + PathDelim + '*', faAnyFile, sr) = 0 then
    begin
      repeat
        if (sr.Name <> '.') and (sr.Name <> '..') then
        begin
          IsEmpty := False;
          Break;
        end;
      until FindNext(sr) <> 0;
    end;
    SysUtils.FindClose(sr);

    if IsEmpty then
    begin
      if RemoveDir(Current) then
        listboxaddscroll(ListBox, '✓ Removed empty mount directory: ' + Current)
      else
        listboxaddscroll(ListBox, '⚠ Failed to remove: ' + Current);
      // nächstes Level hoch
      Current := ExtractFilePath(Current);
      Current := ExcludeTrailingPathDelimiter(Current);
    end
    else
      Break; // nicht leer → stop
  end;
end;


 procedure ClosePartition(var Mounted: TMountedPartition; ListBox: TListBox);
var
  s: string;
begin
  if Mounted.MountPoint = '' then Exit;

  Listboxaddscroll(ListBox, 'Closing device: ' + Mounted.LoopDevice);

  // Sicher unmounten
  SaveUmount(Mounted.MountPoint, ListBox);

  // Flush write buffers
  if Mounted.LoopDevice <> '' then
  begin
    if not RunCommand('blockdev --flushbufs ' + Mounted.LoopDevice, s) then
      listboxaddscroll(ListBox, '⚠ Flush failed: ' + s);
  end;

  // Loopdevice detach
  if Mounted.LoopDevice <> '' then
  begin
    if not RunCommand('losetup -d ' + Mounted.LoopDevice, s) then
    begin
      listboxaddscroll(ListBox, 'Detach by device failed, trying by file...');
      if (Mounted.ImageFile <> '') and (not RunCommand('losetup -d ' + Mounted.ImageFile, s)) then
        listboxaddscroll(ListBox, '✗ Failed to detach loop device: ' + s);
    end;
  end;

  // Rekursiv leere Mountpoint-Ordner entfernen
  RemoveEmptyPathUpwards(Mounted.MountPoint, ListBox);

  // Final sync
  if not RunCommand('sync', s) then
    listboxaddscroll(ListBox, '⚠ Sync failed: ' + s);

  // Prüfen ob Loopdevice wirklich verschwunden ist
  if (Mounted.LoopDevice <> '') then
  begin
    if not LoopDeviceExists(Mounted.LoopDevice) then
    begin
      listboxaddscroll(ListBox, '✓ Loop device released: ' + Mounted.LoopDevice);
      Mounted.LoopDevice := '';
      Mounted.MountPoint := '';
    end
    else
      listboxaddscroll(ListBox, '⚠ Loop device still present: ' + Mounted.LoopDevice);
  end
  else
    Mounted.MountPoint := '';
end;







procedure Listboxaddscroll(listbox: tlistbox; item: string);
var
  topindex: integer;
  Visible, ih: integer;
begin  // qt5 itemheight immer 0  - selbst messen oder ownerdrawfixed
  listbox.Items.add(item);
  //  ih := listbox.Canvas.TextHeight('Wy') + 4;
  ih := listbox.ItemHeight;
  Visible := ListBox.ClientHeight div ih;
  topindex := ListBox.Items.Count - Visible + 2;
  if topindex < 0 then topindex := 0;
  ListBox.TopIndex := topindex;
  listbox.Repaint;
end;


procedure Listboxupdate(listbox: tlistbox; item: string);
begin
  listbox.Items[ListBox.Items.Count - 1] := item;
  listbox.Repaint;
end;


function is_mounted(mount: string; var mountpoint: string; var device: string): boolean;
var
  sl: TStringList;
  line: string;
  parts: TStringArray;
  i: integer;
begin
  mountpoint := '';
  device := '';
  Result := False;

  sl := TStringList.Create;
  try
    sl.LoadFromFile('/proc/mounts');
    for i := 0 to sl.Count - 1 do
    begin
      line := sl[i];
      parts := line.Split([' ']);
      if Length(parts) >= 2 then
      begin
        if (parts[0] = mount) or (parts[1] = mount) then
        begin
          device := parts[0];
          mountpoint := parts[1];
          Result := True;
          Exit;
        end;
      end;
    end;
  finally
    sl.Free;
  end;
end;



procedure SaveUmount(mount: string; listbox: TListBox);
var
  s: string;
  dev, mountpt: string;
  i: integer;
begin
  listboxaddscroll(listbox, 'Umount: '+  mount);

  if not is_mounted(mount, dev, mountpt) then
  begin
    listboxaddscroll(listbox, 'Not mounted: ' + mount);
    Exit;
  end;

  //listboxaddscroll(listbox, 'Trying to unmount: ' + mountpt + ' (' + dev + ')');

  for i := 0 to 4 do
  begin
    if not is_mounted(mount, dev, mountpt) then
    begin
//      listboxaddscroll(listbox, 'Unmounted successfully.');
      Exit;
    end;

    case i of
      0: begin
//        listboxaddscroll(listbox, '→ umount');
        runcommand('umount ' + mountpt, s);
      end;
      1: begin
//        listboxaddscroll(listbox, '→ lazy umount (-l)');
        runcommand('umount -l ' + mountpt, s);
      end;
      2: begin
//        listboxaddscroll(listbox, '→ force umount (-f)');
        runcommand('umount -f ' + mountpt, s);
      end;
      3: begin
//        listboxaddscroll(listbox, '→ killing blocking processes (fuser -km)');
        runcommand('fuser -km ' + mountpt, s);
      end;
      else
      begin
//        listboxaddscroll(listbox, '→ final force umount');
        runcommand('umount -f ' + mountpt, s);
      end;
    end;

    Sleep(1000);
  end;

  if is_mounted(mount, dev, mountpt) then
    raise Exception.Create('ERROR: Still mounted: ' + mountpt)
  else
    listboxaddscroll(listbox, 'Successfully unmounted');
end;




function prexe(cmdl: ansistring; parameter: array of string; box: tlistbox): ansistring;
const
  prexeBytesToRead = 2048;
var
  cBuffer: array[0..prexeBytesToRead - 1] of char;
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


function Read_Mbr(const filename: string): tmbr;
var
  Header: array[0..3] of byte;
  IsZstd, IsDevice: boolean;
  F: TFileStream;
  FD: cint;
  BytesRead: ssize_t;
  Proc: TProcess;
  mbr: tmbr;
begin
  FillChar(Mbr, 512, 0);

  if not FileExists(filename) then           //  and ) not FileExists('/dev/' + ExtractFileName(filename)
    raise Exception.Create('reading mbr - file not existing: ' + filename);

  IsDevice := Pos('/dev/', filename) = 1;

  // Bei Geräten: direkt low-level öffnen (kein TFileStream)
  if IsDevice then
  begin
    FD := fpOpen(PChar(filename), O_RDONLY);
    if FD < 0 then  raise Exception.Create('reading mbr - can''''t file open: ' + filename);

    BytesRead := fpRead(FD, @Mbr, 512);
    fpClose(FD);
    if BytesRead <> 512 then raise Exception.Create('reading mbr - error reading file: ' + filename);

    if (Mbr.Signature <> $aa55) then raise Exception.Create('reading mbr - error mbr signature: ' + filename);

    Result := mbr;
    Exit;
  end;

  // Zstandard-Magic prüfen
  F := TFileStream.Create(filename, fmOpenRead or fmShareDenyNone);
  try
    if F.Read(Header, 4) <> 4 then Exit;   // 4byte lesen
    IsZstd := (Header[0] = $28) and (Header[1] = $B5) and (Header[2] = $2F) and (Header[3] = $FD);
  finally
    F.Free;
  end;

  ////////////////////////////  ist Datei  ////////////////////////////////////////////////
  if not IsZstd then
  begin
    F := TFileStream.Create(filename, fmOpenRead or fmShareDenyNone);
    try
      if F.Size < 512 then
        raise Exception.Create('reading mbr - file to small: ' + filename);

      F.Position := 0;
      Bytesread := F.Read(mbr, 512);
      if bytesread <> 512 then raise Exception.Create('reading mbr - error reading file: ' + filename);
      if (Mbr.Signature <> $aa55) then raise Exception.Create('reading mbr - error mbr signature: ' + filename);
      Result := mbr;
    finally
      F.Free;
    end;
  end
  else
  begin
    try
      Proc := TProcess.Create(nil);

      Proc.Executable := '/bin/sh';
      Proc.Parameters.Add('-c');
      Proc.Parameters.Add(Format('zstd -dc "%s" | head -c 512', [filename]));
      Proc.Options := [poUsePipes];
      Proc.Execute;
      BytesRead := Proc.Output.Read(Mbr, SizeOf(Mbr));
      if bytesread <> 512 then raise Exception.Create('reading mbr - error reading file: ' + filename);
      if (Mbr.Signature <> $aa55) then raise Exception.Create('reading mbr - error mbr signature: ' + filename);
      Result := mbr;
    finally
      Proc.Free;
    end;
  end;
end;




procedure Write_mbr(mbr: tmbr; filename: string);
var
  mbr_writestream: tfilestream;
begin
  try
    try
      mbr_writestream := tfilestream.Create(Filename, fmOpenReadWrite or fmShareDenyNone);
    except
      on E: Exception do
      begin
        raise Exception.Create('error opening file/device for writing mbr to: ' + filename);
      end;
    end;
    mbr_writestream.position := 0;
    if mbr_writestream.Write(mbr, 512) <> 512 then raise Exception.Create('error writing mbr to file/device: ' + filename);
  finally
    FreeAndNil(mbr_writestream);
  end;
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


procedure replacePartuuidinmbr(device: string; NewSignature: dword);
var
  uMBR: TMbr;
begin
  uMBR := Read_MBR(device);
  uMBR.DiskSignature := NewSignature;
  Write_MBR(uMBR, device);
end;



procedure MakeImageFirst2Partitions(Sourcedrive, Filename: ansistring; ListBox: TListBox);
var
  done: int64;
  line: string;
  sl: TStringList;
  info: string;
  s: string;
  bps: double;
  makeImageStart: int64;
  makeImageEnd: int64;
  readnr: int64;
  remain: int64;
  bytestocopy: int64;
  tocopy: int64;
  toread: int64;
  all: int64;
  all_alt: int64;
  ak_time: int64;
  bps_time: int64;
  dis_time: int64;
  gelesen: ssize_t;
  geschrieben: ssize_t;
  MBR: TMbr;
  SourceStream, DestStream: TFileStream;
  promille: int64;
  buffer: array of byte;
  BufferSize: int64 = 32 * 1024 * 1024;
begin
  form1.progressbar1.Max := 1000;
  form1.progressbar1.Position := 0;
  try
    setlength(Buffer, BufferSize);
    bps := 0;
    bps_time := 0;
    dis_time := 0;
    all := 0;
    all_alt := 0;
    makeImageStart := GetTickCount64;


    // Read MBR and calculate size
    MBR := Read_MBR(SourceDrive);
    bytestocopy := (MBR.PartitionEntries[2].FirstLBA + MBR.PartitionEntries[2].PartitionSize) * 512;
    tocopy := bytestocopy;
    toread := tocopy;

    DestStream := TFileStream.Create(Filename, fmCreate or fmOpenWrite or fmShareDenyNone);
    SourceStream := TFileStream.Create(Sourcedrive, fmOpenRead or fmShareDenyNone);

    // Read MBR for safety (again)
    gelesen := SourceStream.Read(MBR, 512);
    SourceStream.Position := 0;

    ak_time := GetTickCount64;
    bps_time := ak_time;
    dis_time := ak_time;

    repeat
      if toread > BufferSize then
        readnr := BufferSize
      else
        readnr := toread;

      gelesen := SourceStream.Read(Buffer, readnr);
      if gelesen <= 0 then
        raise Exception.Create('Read error from source drive.');

      geschrieben := DestStream.Write(Buffer, gelesen);
      if geschrieben <> gelesen then
        raise Exception.Create('Write error: byte count mismatch.');

      Dec(toread, geschrieben);
      // Inc(all, geschrieben);

      all := deststream.Position;
      promille := (all * 1000) div bytestocopy;

      form1.ProgressBar1.Position := promille;

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

        info := Format('%d MB  speed: %.1f MB/sec  ETA: %s', [all div 1000000, bps / 1000, s]);
        Listboxupdate(ListBox, info);
      end;

      application.ProcessMessages;

      if terminate_all then
      begin
        FreeAndNil(SourceStream);
        FreeAndNil(DestStream);
        deletefile(filename);
        raise Exception.Create('writing image is terminated');
      end;

    until (toread = 0);

    makeImageEnd := GetTickCount64;
    ListBox.Items.Add(IntToStr(all) + ' of ' + IntToStr(tocopy) + ' bytes copied in ' + ms2t(makeImageEnd - makeImageStart));

    RunCommand('sync', s);

  finally
    FreeAndNil(SourceStream);
    FreeAndNil(DestStream);
  end;

end;

////////////////////////////////////////////////////////////////////////////////////////////////////


procedure PreCheckImageWrite(const Source, Destination: string);
var
  bline, line: string;
  sl: TStringList;
  bi: integer;
begin
  if not FileExists(Source) then
    raise Exception.Create('Source file not found: ' + Source);

  if not FileExists(Destination) then
    raise Exception.Create('Destination device not found: ' + Destination);

  // Check for mounted partitions

  if not RunCommand('lsblk ' + Destination + ' -b -J -o MOUNTPOINT', line) then
    raise Exception.Create('Error executing lsblk command.');

  sl := TStringList.Create;
  try
    sl.Text := line;
    for bi := 0 to sl.Count - 1 do
    begin
      bline := LowerCase(Trim(sl[bi]));
      if Pos('"mountpoint":', bline) > 0 then
      begin
        if bline = '"mountpoint": "/"' then
          raise Exception.Create('Partition mounted as root. Writing canceled.');
        if (bline = '"mountpoint": "/boot"') or (line = '"mountpoint": "/boot/firmware"') then
          raise Exception.Create('Partition mounted as boot. Writing canceled.');
      end;
    end;
  finally
    sl.Free;
  end;
end;

procedure FinalizeMBRUpdate(Source, Destination: string; delpar3, delpar4: boolean);
var
  mbr_image, mbr_old: TMBR;
begin
  mbr_image := Read_MBR(Source);
  mbr_old := Read_MBR(Destination);
  if not delpar3 then
    mbr_image.PartitionEntries[3] := mbr_old.PartitionEntries[3]
  else
    FillChar(mbr_image.PartitionEntries[3], SizeOf(mbr_image.PartitionEntries[3]), 0);
  if not delpar4 then
    mbr_image.PartitionEntries[4] := mbr_old.PartitionEntries[4]
  else
    FillChar(mbr_image.PartitionEntries[4], SizeOf(mbr_image.PartitionEntries[4]), 0);

  Write_MBR(mbr_image, Destination);
end;




function CalculateSpeed: double;
var
  iFirst: integer;
  bytesWritten: int64;
  totalTimeMs: uint64;
begin
  // index steht auf letztem eintrag
  iFirst := (pufferIndex + 1) mod PufferSize;
  bytesWritten := ValHistory[pufferindex] - ValHistory[iFirst];
  totalTimeMs := TimeHistory[pufferindex] - TimeHistory[iFirst];
  if totalTimeMs < 1 then totalTimeMs := 1;
  Result := (bytesWritten / 1048576) / (totalTimeMs / 1000.0);  // MB/s
end;



procedure AddHistory(Val: int64; timestamp: uint64);
begin
  pufferindex := (pufferindex + 1) mod puffersize;
  ValHistory[pufferIndex] := Val;
  TimeHistory[pufferIndex] := timestamp;
end;

procedure inizRingBuffer(Val: int64; timestamp: uint64);
var
  i: integer;
begin
  pufferIndex := 0;
  for i := 0 to puffersize - 1 do
  begin
    ValHistory[i] := Val;
    TimeHistory[i] := timestamp;
  end;
end;


procedure ImageToDeviceStandard(Source, Destination: string; delpar3, delpar4: boolean; box: TListBox);
const
  BufferSize = 16 * 1024 * 1024;
  PufferSize = 48;   // Anzahl Messungen +1 im Ringpuffer 48 * 5 sec
var
  fsource, fdest: TFileStream;
  ibuffer: array of byte;
  done, tocopy: int64;
  lastUpdate: uint64;
  speedMBs, etaSecs: double;
  lastline: integer;
  ReadCount, WrittenCount: int64;
  etaStr, status, st: string;
  totalSecs, h, m, s: integer;
  i: integer;
  nowTick, starttick: uint64;
begin
  form1.ProgressBar1.Max := 1000;
  form1.ProgressBar1.Position := 0;
  ;
  fsource := nil;
  fdest := nil;

  fsource := TFileStream.Create(Source, fmOpenRead or fmShareDenyNone);
  fdest := TFileStream.Create(Destination, fmOpenWrite or fmShareDenyNone);
  try
    if fsource.Size <= 512 then
      raise Exception.Create('Image-Datei zu klein oder beschädigt.');

    setlength(ibuffer, BufferSize);

    fsource.Position := 512;
    fdest.Position := 512;
    done := 512;

    tocopy := fsource.Size;



    // Ringpuffer initialisieren
    nowTick := GetTickCount64;

    for i := 0 to PufferSize - 1 do
    begin
      ValHistory[i] := 0;
      TimeHistory[i] := nowTick;
    end;

    lastUpdate := nowTick;

    lastline := box.Items.Add('');
    starttick := gettickcount64;

    repeat
      ReadCount := fsource.Read(ibuffer, BufferSize);
      if ReadCount > 0 then
      begin
        WrittenCount := fdest.Write(ibuffer, ReadCount);
        if WrittenCount <> ReadCount then
          raise Exception.Create('Write error: Bytes written do not match bytes read.');

        Inc(done, WrittenCount);
        nowTick := GetTickCount64;

        // Anzeige alle 5 Sekunden
        if (nowTick - lastUpdate) >= 5000 then
        begin
          lastUpdate := nowTick;
          if nowtick - starttick > 10000 then
          begin
            AddHistory(done, nowTick);
          end
          else
            inizringbuffer(done, nowtick);

          speedMBs := CalculateSpeed;



          if speedMBs > 0 then
            etaSecs := ((tocopy - done) / 1048576) / speedMBs
          else
            etaSecs := 0;

          totalSecs := Trunc(etaSecs);
          h := totalSecs div 3600;
          m := (totalSecs mod 3600) div 60;
          s := totalSecs mod 60;
          etaStr := Format('%.2d:%.2d:%.2d', [h, m, s]);

          status := Format('%.1f MiB  %.2f MB/s  ETA: %s', [done / 1048576, speedMBs, etaStr]);
          listboxupdate(box, status);
        end;
        form1.ProgressBar1.Position := done * 1000 div tocopy;
      end;

    until (ReadCount = 0) or (done >= tocopy) or terminate_all;


    if terminate_all then
      raise Exception.Create('Writing to device: process terminated.');

    FinalizeMBRUpdate(Source, Destination, delpar3, delpar4);

  finally
    FreeAndNil(fsource);
    FreeAndNil(fdest);
  end;

  RunCommand('sync', st);
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
  done: int64 = 0;
  startTime, lastUpdate, etaSecs: double;
  lastline, res: integer;
  speedMBs: double;
  etaStr, status: string;
  totalSecs, h, m, s, percent: integer;
  tocopy, nowtick, starttick: int64;
  skipBytes: integer = 512;
  sumread: int64;
begin
  form1.ProgressBar1.max := 1000;
  form1.ProgressBar1.Position := 0;

  Result := '';

  try
    fin := TFileStream.Create(Source, fmOpenRead or fmShareDenyNone);
    fout := TFileStream.Create(Destination, fmOpenWrite or fmShareDenyNone);
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

    //    done := 0;
    startTime := Now;
    lastUpdate := startTime;
    listboxaddscroll(box, '');
    lastline := box.Count - 1;
    lastUpdate := gettickcount64;
    starttick := gettickcount64;
    repeat
      // Eingabe lesen
      InBuffer.size := fin.Read(InData[0], BufferSize);
      InBuffer.src := @InData[0];
      InBuffer.pos := 0;
      Inc(sumread, InBuffer.size);

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
              fout.Write(pbyte(@OutData[0] + skipBytes)^, OutBuffer.pos - skipBytes);
              //  Inc(done, OutBuffer.pos - skipBytes);
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

        // Fortschrittsanzeige alle 3 Sekunden

        // Anzeige alle 5 Sekunden
        nowtick := gettickcount64;

        if (nowTick - lastUpdate) >= 5000 then
        begin
          lastUpdate := nowTick;
          if nowtick - starttick > 10000 then
          begin
            AddHistory(fin.Position, nowTick);
          end
          else
            inizringbuffer(fin.Position, nowtick);

          speedMBs := CalculateSpeed;

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
            form1.ProgressBar1.Position := fin.Position * 1000 div fin.Size;
          status := Format(' %.1f MB  %1f MB/s  ETA %s', [fin.Position / 1048576, speedMBs, etaStr]);
          box.Items[lastline] := status;
          Application.ProcessMessages;
        end;
      end;


      if terminate_all then raise Exception.Create('Writing image to device is terminated');
    until (res = 0);


    // Abschluss-Update nach erfolgreicher Dekompression
    speedMBs := 0;
    percent := 100;
    etaStr := '00:00:00';

    if fin.Size > 0 then
      form1.ProgressBar1.Position := fin.Position * 1000 div fin.Size;

    status := Format(' %.1f MB  %1f MB/s  ETA %s', [fin.Position / 1048576, speedMBs, etaStr]);

    box.Items[lastline] := status;
    Application.ProcessMessages;


    // Nachbearbeitung (z. B. MBR anpassen)
    FinalizeMBRUpdate(Source, Destination, delpar3, delpar4);

  finally
    ZSTD_freeDCtx(dctx);
    fin.Free;
    fout.Free;
  end;
end;




procedure ImageToDeviceImgAndZstd(Source, Destination: string; delpar3, delpar4: boolean; box: TListBox);
begin
  PreCheckImageWrite(Source, Destination);

  if LowerCase(ExtractFileExt(Source)) = '.zst' then
    ImageToDeviceZstd(Source, Destination, delpar3, delpar4, box)

  else
  begin
    if FileSize(Source) mod 512 <> 0 then
      raise Exception.Create('Image size is not a multiple of 512 bytes (sector size).');
    ImageToDeviceStandard(Source, Destination, delpar3, delpar4, box);
  end;
end;




procedure ClearEmptyBlocks(listbox: tlistbox; Mounted: TMountedPartition);
const
  BlockSize = 16 * 1024 * 1024; // 16 MiB          var
var
  Stream: TFileStream;
  BytesWritten, TotalWritten: int64;
  s, filepath: string;
  buffer: array of byte;
begin
  try
    ListBoxaddscroll(listbox, 'overwriting free blocks on partition ' + IntToStr(mounted.PartitionNumber));
    listboxaddscroll(listbox, '');
    filepath := mounted.MountPoint + '/fillfile';
    setlength(buffer, blocksize);
    FillChar(Buffer[0], blockSize, 255);
    try
      Stream := TFileStream.Create(FilePath, fmCreate);
    except
      on E: Exception do
      begin
        listboxaddscroll(listbox, 'ERROR: Failed to create file: ' + E.Message);
        Exit;
      end;
    end;

    // Schreiben bis kein Platz mehr
    TotalWritten := 0;
    repeat
    try
      BytesWritten := Stream.Write(Buffer, BlockSize);
      Inc(TotalWritten, BytesWritten);
      listboxupdate(listbox, Format('Written: %.2f MiB', [TotalWritten / (1024 * 1024)]));
    except
      on E: Exception do
      begin
        listboxaddscroll(listbox, 'Write error: ' + E.Message);
        Break;
      end;
    end;
    until BytesWritten <> BlockSize;



  finally
    if Assigned(Stream) then
    begin
      try
        Stream.Free;
      except
        on E: Exception do
          listboxaddscroll(listbox, 'Error closing file: ' + E.Message);
      end;
    end;

    RunCommand('sync', s);
    DeleteFile(FilePath);
    RunCommand('sync', s);
    listboxaddscroll(listbox, 'Fillfile deleted and system sync complete.');
  end;
end;



end.
