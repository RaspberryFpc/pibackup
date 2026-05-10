unit rkutils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, process, baseunix, unix, LazUTF8, fileutil, dateutils, StdCtrls, Forms, Dialogs, UnixType, ExtCtrls;

//type
//  TExt4Superblock = packed record
//    s_inodes_count: uint32;
//    s_blocks_count: uint32;
//    s_r_blocks_count: uint32;
//    s_free_blocks_count: uint32;
//    s_free_inodes_count: uint32;
//    s_first_data_block: uint32;
//    s_log_block_size: uint32;
//    s_log_frag_size: int32;
//    s_blocks_per_group: uint32;
//    s_frags_per_group: uint32;
//    s_inodes_per_group: uint32;
//    s_mtime: uint32;
//    s_wtime: uint32;
//    s_mnt_count: uint16;
//    s_max_mnt_count: int16;
//    s_magic: uint16;
//    s_state: uint16;
//    s_errors: uint16;
//    s_minor_rev_level: uint16;
//    s_lastcheck: uint32;
//    s_checkinterval: uint32;
//    s_creator_os: uint32;
//    s_rev_level: uint32;
//    s_def_resuid: uint16;
//    s_def_resgid: uint16;
//    s_first_ino: uint32;
//    s_inode_size: uint16;
//    s_block_group_nr: uint16;
//    s_feature_compat: uint32;
//    s_feature_incompat: uint32;
//    s_feature_ro_compat: uint32;
//    s_uuid: array[0..15] of byte;
//    s_volume_name: array[0..15] of ansichar;
//    s_last_mounted: array[0..63] of ansichar;
//    s_algorithm_usage_bitmap: uint32;
//    // ... weitere Felder ausgelassen
//  end;
//
//  TExt4BlockGroupDescriptor = packed record
//    bg_block_bitmap: uint32;
//    bg_inode_bitmap: uint32;
//    bg_inode_table: uint32;
//    bg_free_blocks_count: uint16;
//    bg_free_inodes_count: uint16;
//    bg_used_dirs_count: uint16;
//    bg_pad: uint16;
//    bg_reserved: array[0..2] of uint32;
//  end;
//


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
  TStatVFS = record
    f_bsize: cULong;   // Filesystem block size
    f_frsize: cULong;   // Fragment size
    f_blocks: cUInt64;  // fsblkcnt_t
    f_bfree: cUInt64;  // fsblkcnt_t
    f_bavail: cUInt64;  // fsblkcnt_t
    f_files: cUInt64;  // fsfilcnt_t
    f_ffree: cUInt64;  // fsfilcnt_t
    f_favail: cUInt64;  // fsfilcnt_t
    f_fsid: cULong;   // Filesystem ID
    f_flag: cULong;   // Mount flags
    f_namemax: cULong;   // Maximum filename length
    f_spare: array[0..5] of cULong;
  end;

type
  rngbuffer = record
    position: integer;   // Schreibposition
    size: integer;       // maximale Größe
    time: array of int64;
    val: array of qword;
  end;



procedure EnsureEnoughSpace(const FilePath: string; NewSize: int64);
function statvfs(path: pchar; var buf: TStatVFS): cint; cdecl; external 'c';
function runbash(command: ansistring): string;
function padleft(s: string; Count: integer): string;
function RunsAsRoot: boolean;
function IsProgInstalled(progname: string): boolean;
function GetMBRPartitionTypeName(PartType: byte): string;
function Read_Mbr(const filename: string): tmbr;
function GetMountPointFromProc(const path: string): string;
function starLine(s: ansistring; len: integer): ansistring;
function getValueAfterKeyword(s, keyword: ansistring): int64;
procedure Listboxaddscroll(listbox: tlistbox; item: string);
procedure Listboxupdate(listbox: tlistbox; item: string);
procedure getDrives(sl: TStrings;excludesys:boolean);
procedure setPartuuidinmbr(device: string; NewSignature: dword);
function setPartUUIDInCmdline(Device: string; partition:integer; NewID: string):boolean;
function ReplacePartUUIDInFstab(device: string;partition:integer; oldID, newID: string): string;
procedure ChangeHost(device: string; newHostName: string);
procedure enableSsh(device: string);
procedure PrepareWLAN(const Device, SSID, PSK: string);
procedure Write_mbr(const mbr: TMbr; const Filename: string);
procedure MakeImagefirst2partitions(Sourcedrive, Filename: ansistring; listbox: tlistbox);
procedure ImageToDeviceImgAndZstd(Source, Destination: string; box: TListBox);
procedure ClearEmptyBlocks(listbox: tlistbox; Mountpoint: string);
procedure DeletePartition(const Device: string; Partition: integer);
function PartitionName(device: string; partitionNumber: integer): string;
function CreateLoopPartition(const FileName: string; Partition: integer): string;
function MountPartition(const Source: string; PartitionNumber: integer; const MountPoint: string): boolean;
procedure CloseMountTarget(const Target: string);
function readlosetup: string;
function TryUnmount(const Mp: string): boolean;
function IsMountedExact(const Mp: string): boolean;
procedure ParseMountLine(const L: string; out Device, Mp: string);

var
  terminate_all: boolean;

implementation

uses zstd, unit1;

function mstostr(secs: double): string;
var
  h, m, s: integer;
  sec: integer;
begin
  sec := trunc(secs);
  h := Sec div 3600;
  m := (Sec mod 3600) div 60;
  s := Sec mod 60;
  Result := Format('%.2d:%.2d:%.2d', [h, m, s]);
end;

procedure InitRingBuffer(var b: rngbuffer; size: integer; time, val: int64);
var
  x: integer;
begin
  b.size := size;
  b.position := 0;
  SetLength(b.val, size);
  SetLength(b.time, size);
  for x := 0 to b.size - 1 do
  begin
    b.val[x] := val;
    b.time[x] := time;
  end;
end;

function AddRingBuffer(var b: rngbuffer; time: qword; val: int64): int64;
var
  lastval: int64;
  lasttime: int64;
  dval, dtime: int64;
begin
  lastval := b.val[b.position];
  lasttime := b.time[b.position];
  dval := val - lastval;
  dtime := time - lasttime;

  Result := dval * 1000 div dtime;
  b.val[b.position] := val;
  b.time[b.position] := time;
  b.position := (b.position + 1) mod b.size;
end;


function PartitionName(device: string; partitionNumber: integer): string;
var
  LastChar: char;
begin
  LastChar := Device[Length(Device)];
  if LastChar in ['0'..'9'] then
    Result := Device + 'p' + IntToStr(PartitionNumber)
  else
    Result := Device + IntToStr(PartitionNumber);

end;


function InterlockedExchangeDouble(var Target: double; Source: double): double;
var
  OldInt: int64;
begin
  OldInt := InterlockedExchange64(PInt64(@Target)^, PInt64(@Source)^);
  Result := PDouble(@OldInt)^;
end;



function RunsAsRoot: boolean;
begin
  if fpGetEUID = 0 then
    Result := True
  else
    Result := False;
end;




function MountPartition(const Source: string; PartitionNumber: integer; const MountPoint: string): boolean;
var
  IsImage: boolean;
  LoopDev, PartDev: string;
  OutStr: string;
  rc: longint;
begin
  Result := False;
  LoopDev := '';

  // Erkennen, ob Image oder Device
  IsImage := FileExists(Source);

  // MountPoint anlegen
  if not DirectoryExists(MountPoint) then
  begin
    rc := fpSystem(PChar('mkdir -p "' + MountPoint + '"'));
    if rc <> 0 then Exit;
  end;

  // ----------------------------------------------------
  // A) IMAGE → Loopdevice erstellen
  // ----------------------------------------------------
  if IsImage then
  begin
    if not RunCommand('losetup -Pf --show "' + Source + '"', OutStr) then
      Exit;

    LoopDev := Trim(OutStr);
    if LoopDev = '' then Exit;

    PartDev := LoopDev + 'p' + IntToStr(PartitionNumber);
  end
  else
  begin
    // ----------------------------------------------------
    // B) echtes Device
    // ----------------------------------------------------
    PartDev := Source + IntToStr(PartitionNumber);
  end;

  // Mount ausführen
  rc := fpSystem(PChar('mount "' + PartDev + '" "' + MountPoint + '"'));
  if rc <> 0 then
  begin
    // Bei Image → Loopdevice aufräumen
    if IsImage and (LoopDev <> '') then
      fpSystem(PChar('losetup -d "' + LoopDev + '"'));
    Exit;
  end;

  Result := True;
end;




function CreateLoopPartition(const FileName: string; Partition: integer): string;
var
  OutStr: string;
  Offset: int64;
  SectorSize: int64;
  StartSector: dword;
  MBR: array[0..511] of byte;
  f: file;
begin
  Result := '';

  if not FileExists(FileName) then
    raise Exception.Create('Datei nicht gefunden: ' + FileName);

  // MBR lesen
  AssignFile(f, FileName);
  Reset(f, 1);
  BlockRead(f, MBR, 512);
  CloseFile(f);

  SectorSize := 512;

  // Prüfen Partition 1..4
  if (Partition < 1) or (Partition > 4) then
    raise Exception.Create('Partition muss 1..4 sein');

  // Startsektor aus MBR auslesen (Partition 1 = Offset 0x1BE, Partition 2 = 0x1BE + 16)
  StartSector := PDword(@MBR[$1BE + (Partition - 1) * 16 + 8])^;

  Offset := StartSector * SectorSize;

  // Loopdevice erstellen mit Offset
  if not RunCommand('/sbin/losetup --find --show --offset ' + IntToStr(Offset) + ' ' + FileName, OutStr) then
    raise Exception.Create('losetup fehlgeschlagen: ' + OutStr);

  Result := Trim(OutStr);
end;




procedure Write_mbr(const mbr: TMbr; const Filename: string);
var
  mbr_writestream: TFileStream = nil;
  res: ssize_t;
  fd: cint = -1;
begin
  try
    try
      // Gerät oder Datei zum Lesen + Schreiben öffnen
      // WICHTIG: fmShareDenyNone ist ok für Devices, blockiert nichts
      mbr_writestream := TFileStream.Create(Filename, fmOpenReadWrite or fmShareDenyNone);
    except
      on E: Exception do
        raise Exception.Create('Error opening file/device for writing MBR: ' + Filename + ' --> ' + E.Message);
    end;

    // Immer an Anfang
    mbr_writestream.Position := 0;

    // Versuchen die 512 Bytes zu schreiben
    res := mbr_writestream.Write(mbr, 512);

    if res <> 512 then
      raise Exception.CreateFmt('Error writing MBR (only %d bytes written) to %s', [res, Filename]);

    // Bei Blockdevices unbedingt flushen
    // (TFileStream.Flush funktioniert nicht sicher bei echten Geräten)
    fd := fpOpen(PChar(Filename), O_RDWR);   // zweiten Handle öffnen
    if fd <> -1 then
    begin
      fpFSync(fd);                          // Force write to disk
      fpClose(fd);
    end;

  finally
    FreeAndNil(mbr_writestream);
  end;
end;


function MountpointFromPartition(device: string; partitionNumber: integer): string;
var
  PartitionDevice: string;
  lastchar: char;
begin
  LastChar := Device[Length(Device)];
  if LastChar in ['0'..'9'] then
    PartitionDevice := Device + 'p' + IntToStr(PartitionNumber)
  else
    PartitionDevice := Device + IntToStr(PartitionNumber);

  runcommand('lsblk -no MOUNTPOINT ' + PartitionDevice, Result);
  if Result > '' then Delete(Result, length(Result), 1);

end;


{------------------------------
   Prüft, ob ein Target ein Loopdevice ist
-------------------------------}
function CheckLoop(Target: string): string;
var
  s, nr: string;
  x: integer;
begin
  Result := '';
  s := Target;
  if Copy(Target, 1, 9) = '/dev/loop' then
    s := Copy(Target, 10, 999);
  nr := '';
  for x := 1 to Length(s) do
  begin
    if s[x] in ['0'..'9'] then
      nr := nr + s[x]
    else
      break;
  end;
  if nr > '' then
    Result := '/dev/loop' + nr;
end;



{------------------------------
   Liest losetup aus, liefert Name + Backfile
   Ergebnis: "loopDevice backfile"
-------------------------------}
function readlosetup: string;
var
  sl: TStringList;
  x, p: integer;
  lo, fi, s: string;
begin
  sl := TStringList.Create;
  try
    runcommand('losetup -O NAME,BACK-FILE', s);
    sl.Text := s;
    if sl.Count > 0 then
      sl.Delete(0); // Überschrift entfernen

    for x := 0 to sl.Count - 1 do
    begin
      s := sl[x];
      p := Pos(' ', s);
      if p = 0 then Continue;
      lo := Copy(s, 1, p - 1);
      if (Pos('p', lo) > 9) then Delete(lo, p, 999); // /dev/loop0p1 → /dev/loop0

      fi := Trim(Copy(s, p + 1, 999));
      p := Pos(' ', fi);
      if p > 0 then fi := Trim(Copy(fi, p + 1, 999)); // nur Backfile
      sl[x] := lo + ' ' + fi;
    end;

    Result := sl.Text;
  finally
    sl.Free;
  end;
end;



function GetMountPoint(const LoopDev: string): string;
var
  SL: TStringList;
  i: integer;
  Parts: TStringList;
begin
  Result := '';
  SL := TStringList.Create;
  Parts := TStringList.Create;
  try
    SL.LoadFromFile('/proc/mounts');
    for i := 0 to SL.Count - 1 do
    begin
      Parts.DelimitedText := SL[i];
      if Parts.Count >= 2 then
      begin
        if Parts[0] = LoopDev then
        begin
          Result := Parts[1]; // Mountpoint
          Exit;
        end;
      end;
    end;
  finally
    SL.Free;
    Parts.Free;
  end;
end;

function GetLoopDeviceFromMountPoint(const MountPoint: string): string;
var
  SL: TStringList;
  i: integer;
  Parts: TStringList;
begin
  Result := '';
  SL := TStringList.Create;
  Parts := TStringList.Create;
  try
    SL.LoadFromFile('/proc/mounts');
    for i := 0 to SL.Count - 1 do
    begin
      Parts.DelimitedText := SL[i];
      if Parts.Count >= 2 then
      begin
        if Parts[1] = MountPoint then
        begin
          // Prüfen ob Gerät ein Loopdevice ist
          if Copy(Parts[0], 1, 9) = '/dev/loop' then
          begin
            Result := Parts[0];
            Exit;
          end;
        end;
      end;
    end;
  finally
    SL.Free;
    Parts.Free;
  end;
end;



procedure CloseMountTarget(const Target: string);
var
  sl: TStringList;
  i, p: integer;
  loopDev, backfile, s: string;
  loop, mountpoint: string;

  procedure DetachAllLoopsForBackfile(const ABackfile: string);
  var
    i, p: integer;
    ldev, bf: string;
  begin
    for i := 0 to sl.Count - 1 do
    begin
      p := Pos(' ', sl[i]);
      if p = 0 then Continue;
      ldev := Trim(Copy(sl[i], 1, p - 1));
      bf := Trim(Copy(sl[i], p + 1, 999));
      if bf = ABackfile then
        runcommand('losetup -d ' + ldev, s);
    end;
  end;

begin
  sl := TStringList.Create;
  try
    sl.Text := readlosetup;

    // ---------- Fall 1: Target ist Loopdevice ----------
    loop := CheckLoop(Target);
    if loop > '' then
    begin
      mountpoint := getmountpoint(loop);
      if mountpoint > '' then
        tryunmount(mountpoint);

      // Backfile ermitteln
      backfile := '';
      for i := 0 to sl.Count - 1 do
      begin
        p := Pos(' ', sl[i]);
        if p = 0 then Continue;
        loopDev := Trim(Copy(sl[i], 1, p - 1));
        if loopDev = loop then
        begin
          backfile := Trim(Copy(sl[i], p + 1, 999));
          Break;
        end;
      end;

      if backfile > '' then
        DetachAllLoopsForBackfile(backfile);

      Exit;
    end;

    // ---------- Fall 2: Target ist Mountpoint ----------
    loop := CheckLoop(GetLoopDeviceFromMountPoint(Target));
    if loop > '' then
    begin
      tryunmount(Target);

      // Backfile suchen
      backfile := '';
      for i := 0 to sl.Count - 1 do
      begin
        p := Pos(' ', sl[i]);
        if p = 0 then Continue;
        loopDev := Trim(Copy(sl[i], 1, p - 1));
        if loopDev = loop then
        begin
          backfile := Trim(Copy(sl[i], p + 1, 999));
          Break;
        end;
      end;

      if backfile > '' then
        DetachAllLoopsForBackfile(backfile);

      Exit;
    end;

    // ---------- Fall 3: normales Mount ohne Loop ----------
    tryunmount(Target);

  finally
    sl.Free;
  end;
end;




procedure DeletePartition(const Device: string; Partition: integer);
var
  mbr: TMbr;
  s: string;
  StatRec: stat;
begin
  // Device prüfen (fpStat für /dev)
  if fpStat(PChar(Device), StatRec) <> 0 then
    raise Exception.Create('DeletePartition - Device not found: ' + Device);

  // Partition Index prüfen (0..3)
  if (Partition < 1) or (Partition > 4) then
    raise Exception.Create('DeletePartition - Partition index out of range (1..4)');

  // MBR lesen
  mbr := Read_Mbr(Device);

  // Partitionseintrag löschen
  FillChar(mbr.PartitionEntries[Partition], 16, 0);

  // MBR zurückschreiben
  Write_mbr(mbr, Device);

  // Kernel Tabelle aktualisieren
  RunCommand('partprobe ' + Device, s);

  Sleep(500); // kurz warten, bis Kernel die Partitionstabelle übernommen hat
end;



procedure EnsureEnoughSpace(const FilePath: string; NewSize: int64);
const
  mib=1024*1024;

var
  vfs: TStatVFS;
  DirPath, ExistingPath: string;
  OldSize, FreeBytes: int64;
begin
  // Alte Dateigröße bestimmen
  if FileExists(FilePath) then
    OldSize := FileSize(FilePath)
  else
    OldSize := 0;

  // Zielverzeichnis
  DirPath := ExtractFileDir(FilePath);

  // Nächstexistierendes Verzeichnis suchen
  ExistingPath := DirPath;
  while (ExistingPath <> '') and (not DirectoryExists(ExistingPath)) do
    ExistingPath := ExtractFileDir(ExistingPath);

  if (ExistingPath = '') then
    raise Exception.Create('No existing parent directory found for "' + FilePath + '"');


  // Freien Speicher prüfen
  if statvfs(PChar(ExistingPath), vfs) <> 0 then
    raise Exception.Create('Failed to get free space for "' + ExistingPath + '"');


  FreeBytes := vfs.f_bsize * vfs.f_bavail;

  // Prüfen ob genug Platz da ist
  if NewSize > OldSize then
    if (NewSize - OldSize) > FreeBytes then
      raise Exception.Create(Format('Not enough disk space: required %d MiB, available %d MiB_', [(NewSize + mib -1) div 1024 div 1024,
                                                  (FreeBytes + OldSize + mib -1) div 1024 div 1024]));

  // Erst jetzt die Verzeichnisse erstellen
  if not DirectoryExists(DirPath) then
    if not ForceDirectories(DirPath) then
      raise Exception.Create('Failed to create directory "' + DirPath + '"');
end;




procedure Listboxaddscroll(listbox: tlistbox; item: string);
var
  topindex: integer;
  Visible, ih, Count: integer;
begin  // qt5 itemheight immer 0  - selbst messen oder ownerdrawfixed
  Count := listbox.Items.add(item);
  //  ih := listbox.Canvas.TextHeight('Wy') + 4;
  ih := listbox.ItemHeight;
  Visible := ListBox.ClientHeight div ih;
  //topindex := ListBox.Items.Count - Visible + 2;
  topindex := Count - Visible + 2;

  if topindex < 0 then topindex := 0;
  ListBox.TopIndex := topindex;
  listbox.Repaint;
end;


procedure Listboxupdate(listbox: tlistbox; item: string);
begin
  listbox.Items[ListBox.Items.Count - 1] := item;
  listbox.Repaint;
end;


function TryUnmount(const Mp: string): boolean;
var
  k: integer;
  tmp: string;
begin
  Result := False;
  for k := 0 to 3 do
  begin
    case k of
      0: RunCommand('umount ' + Mp, tmp);
      1: RunCommand('umount -l ' + Mp, tmp);
      2: RunCommand('umount -f ' + Mp, tmp);
      3: RunCommand('fuser -km ' + Mp, tmp);
    end;
    Sleep(700);
    if not IsMountedExact(Mp) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;




function IsMountedExact(const Mp: string): boolean;
var
  t: TStringList;
  l, d, m: string;
begin
  Result := False;
  t := TStringList.Create;
  try
    t.LoadFromFile('/proc/mounts');
    for l in t do
    begin
      ParseMountLine(l, d, m);
      if m = Mp then
      begin
        Result := True;
        Exit;
      end;
    end;
  finally
    t.Free;
  end;
end;

procedure ParseMountLine(const L: string; out Device, Mp: string);
var
  tmp: TStringList;
begin
  Device := '';
  Mp := '';
  tmp := TStringList.Create;
  try
    tmp.StrictDelimiter := True;
    tmp.Delimiter := ' ';
    tmp.DelimitedText := L;
    if tmp.Count >= 2 then
    begin
      Device := tmp[0];
      Mp := tmp[1];
    end;
  finally
    tmp.Free;
  end;
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


////////////////////////// disk utils ///////////////////////////////7


procedure getDrives(sl: TStrings; ExcludeSys: boolean);
var
  s, dr, exclude: ansistring;
  p, n, x: integer;
  stl: TStringList;
  v: string;
  systemdrive,par:string;

 begin
  RunCommand( 'df --output=source /',par);
  p:=pos(#10,par);
  delete(par,1,p);
  delete(par,length(par),1);
  RunCommand('lsblk -no PKNAME ' + par, systemdrive);
  delete(systemdrive,length(systemdrive),1);
   systemdrive:='/dev/'+systemdrive;

  stl := TStringList.Create;

  RunCommand('fdisk -l', s);
  stl.Text := s;

  // =========================================================
  // nur "Disk /dev/..." Zeilen behalten
  // =========================================================
  for x := stl.Count - 1 downto 0 do
  begin
    if Pos('Disk /dev/', stl[x]) <> 1 then
      stl.Delete(x);
  end;

  // =========================================================
  // einkürzen
  // =========================================================
  for x := stl.Count - 1 downto 0 do
  begin
    p := Pos(':', stl[x]);
    p := Pos(', ', stl[x], p);
    stl[x] := Copy(stl[x], 1, p - 1);
  end;

  // =========================================================
  // RAM entfernen
  // =========================================================
  exclude := 'Disk /dev/ram';
  for x := stl.Count - 1 downto 0 do
  begin
    s := stl[x];
    n := Pos(':', s);
    s := Copy(s, 1, n - 1);
    p := Pos(exclude, s);
    if p = 1 then
    begin
      Delete(s, 1, Length(exclude));
      while (Length(s) > 0) and (s[1] in ['0'..'9']) do
        Delete(s, 1, 1);
    end;
    if s = '' then
      stl.Delete(x);
  end;

  // =========================================================
  // ZRAM entfernen
  // =========================================================
  exclude := 'Disk /dev/zram';
  for x := stl.Count - 1 downto 0 do
  begin
    s := stl[x];
    n := Pos(':', s);
    s := Copy(s, 1, n - 1);
    p := Pos(exclude, s);
    if p = 1 then
    begin
      Delete(s, 1, Length(exclude));
      while (Length(s) > 0) and (s[1] in ['0'..'9']) do
        Delete(s, 1, 1);
    end;
    if s = '' then
      stl.Delete(x);
  end;

  // =========================================================
  // LOOP entfernen
  // =========================================================
  exclude := 'Disk /dev/loop';
  for x := stl.Count - 1 downto 0 do
  begin
    s := stl[x];
    n := Pos(':', s);
    s := Copy(s, 1, n - 1);
    p := Pos(exclude, s);
    if p = 1 then
    begin
      Delete(s, 1, Length(exclude));
      while (Length(s) > 0) and (s[1] in ['0'..'9']) do
        Delete(s, 1, 1);
    end;
    if s = '' then
      stl.Delete(x);
  end;

  // =========================================================
  // Ergebnisliste
  // =========================================================
  sl.Clear;

  for x := 0 to stl.Count - 1 do
  begin

    dr := Copy(stl[x], 6, MaxInt); // → sda, sdb, ...
    p:=pos(':',dr);
    v:= copy(dr,1,p-1);
    if ExcludeSys and (v=systemdrive) then Continue;  //exclude system;
    sl.Add(dr);
  end;

  stl.Free;
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
  F: TFileStream = nil;
  BytesRead: ssize_t;
  Proc: TProcess;
  Rmbr: tmbr;
begin
  FillChar(RMbr, 512, 0);
  result:=Rmbr;

  if not FileExists(filename) then
    raise Exception.Create('reading mbr from: ' + filename + ' not found');

  IsDevice := Pos('/dev/', filename) = 1;

  if IsDevice then
  begin
    try
    F := TFileStream.Create(filename, fmOpenRead or fmShareDenyNone);

      F.Position := 0;
      Bytesread := F.Read(Rmbr, 512);
      if bytesread <> 512 then raise Exception.Create('error reading MBR: ' + filename);
      if (RMbr.Signature <> $aa55)  then
        raise Exception.Create( 'reading mbr - wrong mbr signature: ' + filename + ' = 0x' + hexstr(RMbr.Signature, 4) + ' instead of 0xaa55.');
    finally
       if assigned(F) then F.Free;
    end;
    Result := Rmbr;
    Exit;
  end;

  // Zstandard-Magic prüfen
  F := TFileStream.Create(filename, fmOpenRead or fmShareDenyNone);
  try
    if F.Read(Header, 4) <> 4 then Exit;   // 4byte lesen
    IsZstd := (Header[0] = $28) and (Header[1] = $B5) and (Header[2] = $2F) and (Header[3] = $FD);
  finally
    if assigned(F) then F.Free;
  end;

  ////////////////////////////  ist Datei  ////////////////////////////////////////////////
  if not IsZstd then
  begin
    F := TFileStream.Create(filename, fmOpenRead or fmShareDenyNone);
    try
      if F.Size < 512 then
        raise Exception.Create('reading mbr - file to small: ' + filename);

      F.Position := 0;
      Bytesread := F.Read(Rmbr, 512);
      if bytesread <> 512 then raise Exception.Create('reading mbr - error reading file: ' + filename);
      if (RMbr.Signature <> $aa55)  then
        raise Exception.Create( 'reading mbr - wrong mbr signature: ' + filename + ' = 0x' + hexstr(RMbr.Signature, 4) + ' instead of 0xaa55.');
      Result := Rmbr;
    finally
      if assigned(F) then F.Free;
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
      BytesRead := Proc.Output.Read(RMbr, 512);
      if bytesread <> 512 then raise Exception.Create('reading mbr - error reading file: ' + filename);
      if (RMbr.Signature <> $aa55)  then
        raise Exception.Create( 'reading mbr - wrong mbr signature: ' + filename + ' = 0x' + hexstr(RMbr.Signature, 4) + ' instead of 0xaa55.');
      Result := Rmbr;
    finally
      Proc.Free;
    end;
  end;
end;



function GenerateUUID: string;
var
  i: integer;
  Hex: array[0..15] of byte;
begin
  for i := 0 to 15 do
    Hex[i] := Random(256);

  // RFC4122 Version 4 UUID
  Hex[6] := (Hex[6] and $0F) or $40; // Version 4
  Hex[8] := (Hex[8] and $3F) or $80; // Variant

  Result := Format('%2.2x%2.2x%2.2x%2.2x-%2.2x%2.2x-%2.2x%2.2x-%2.2x%2.2x-%2.2x%2.2x%2.2x%2.2x%2.2x%2.2x', [Hex[0], Hex[1], Hex[2], Hex[3], Hex[4], Hex[5], Hex[6], Hex[7], Hex[8], Hex[9], Hex[10], Hex[11], Hex[12], Hex[13], Hex[14], Hex[15]]);
end;



procedure PrepareWLAN(const Device, SSID, PSK: string);
var
  P1, P2: string;
  M1, M2: string;
  s: ansistring;
  NMDir, NMFile: string;
  UUID: string;

  procedure WriteTextFile(const FileName: string; const Lines: array of string);
  var
    F: TextFile;
    i: integer;
  begin
    ForceDirectories(ExtractFileDir(FileName));
    AssignFile(F, FileName);
    Rewrite(F);
    for i := 0 to High(Lines) do
      WriteLn(F, Lines[i]);
    CloseFile(F);
  end;

begin
  // Partitionen ermitteln
  P1 := partitionname(Device, 1);
  P2 := partitionname(Device, 2);

  M1 := '/images/tmp_boot';
  M2 := '/images/tmp_root';

  ForceDirectories(M1);
  ForceDirectories(M2);

  try
    // Vorherige Mounts entfernen
    RunCommand('umount', [M1], s);
    RunCommand('umount', [M2], s);

    // Partitionen mounten
    if not RunCommand('mount', [P1, M1], s) then
      raise Exception.Create('Failed to mount boot: ' + s);
    if not RunCommand('mount', [P2, M2], s) then
      raise Exception.Create('Failed to mount root: ' + s);

    // --- NetworkManager File ---
    NMDir := M2 + '/etc/NetworkManager/system-connections';
    NMFile := NMDir + '/' + SSID + '.nmconnection';
    UUID := GenerateUUID;

    WriteTextFile(NMFile, ['[connection]', 'id=' + SSID, 'uuid=' + UUID, 'type=wifi', '[wifi]', 'mode=infrastructure', 'ssid=' + SSID, 'hidden=true', '[wifi-security]', 'key-mgmt=wpa-psk',
      'psk=' + PSK, '[ipv4]', 'method=auto', '[ipv6]', 'addr-gen-mode=default', 'method=auto', '[proxy]']);

    // Rechte korrekt setzen
    RunCommand('chmod', ['600', NMFile], s);
    RunCommand('chown', ['root:root', NMFile], s);

    // --- NetworkManager State setzen ---
    WriteTextFile(M2 + '/var/lib/NetworkManager/NetworkManager.state', ['[main]', 'NetworkingEnabled=true', 'WirelessEnabled=true', 'WWANEnabled=true']);

  finally
    RunCommand('sync', s);
    RunCommand('umount', [M1], s);
    RunCommand('umount', [M2], s);
    RemoveDir(M1);
    RemoveDir(M2);
  end;
end;

function setPartUUIDInCmdline(Device: string; partition: integer;
  newid: string): boolean;
var
  PartitionDevice, MountPoint, CommandFile: string;
  s, uline: string;
  i,p1,p2: integer;
  sl: TStringList;
begin
  Result := False;

  MountPoint := '/tmp/tmp_mount';
  PartitionDevice := PartitionName(Device, partition);
  CommandFile := MountPoint + '/cmdline.txt';

  try
    // altes Mount aufräumen
    if DirectoryExists(MountPoint) then
    begin
      RunCommand('sync', s);
      RunCommand('umount', [MountPoint], s);
      Sleep(500);
      DeleteDirectory(MountPoint, False);
    end;

    ForceDirectories(MountPoint);

    // mounten
    if not RunCommand('mount',
      ['-t', 'vfat', '-o', 'rw', PartitionDevice, MountPoint], s) then
      raise Exception.Create('Failed to mount partition ' + PartitionDevice);

    if not FileExists(CommandFile) then
      raise Exception.Create('cmdline.txt not found');

    // cmdline lesen
    sl := TStringList.Create;
    try
      sl.LoadFromFile(CommandFile);

      if sl.Count = 0 then
        raise Exception.Create('cmdline.txt is empty');

      s:=sl.Text;
      p1:=pos('root=PARTUUID=',s);
      p2:=pos('-',s,p1);
      delete(s,p1,p2-p1);
      insert('root=PARTUUID='+ newid,s,p1);
      sl.Text:=s;
      sl.SaveToFile(CommandFile);

    finally
      sl.Free;
    end;

    RunCommand('sync', s);
    RunCommand('umount', [MountPoint], s);
    DeleteDirectory(MountPoint, False);

    Result := True;

  except
    on E: Exception do
    begin
      RunCommand('sync', s);
      RunCommand('umount', [MountPoint], s);

      if DirectoryExists(MountPoint) then
        RemoveDir(MountPoint);

      Result := False;
    end;
  end;
end;


function ReplacePartUUIDInFstab(device: string;partition:integer; oldID, newID: string): string;
var
  sl: TStringList;
  i: integer;
  s: string;
  PartitionDevice, uMountPoint: string;
begin
  Result := '';
  uMountPoint := '/images/tmp_mount';

  try
    PartitionDevice := partitionname(device, partition);

    RunCommand('sync', s);
    RunCommand('umount', [uMountPoint], s);
    Sleep(500);

    if not DirectoryExists(uMountPoint) then
      ForceDirectories(uMountPoint);

    fpchmod(uMountPoint, &777);

    if not RunCommand('mount', [PartitionDevice, uMountPoint], s) then
      raise Exception.Create('Mount failed');

    if not FileExists(uMountPoint + '/etc/fstab') then
      raise Exception.Create('fstab not found');

    sl := TStringList.Create;
    try
      sl.LoadFromFile(uMountPoint + '/etc/fstab');

      for i := 0 to sl.Count - 1 do
      begin
        s := sl[i];

        // -----------------------------------------
        // 🔥 nur Disk-ID im PARTUUID ersetzen
        // -----------------------------------------
        s := StringReplace(
          s,
          oldID,
          newID,
          [rfReplaceAll]
        );

        sl[i] := s;
      end;

      sl.SaveToFile(uMountPoint + '/etc/fstab');

    finally
      sl.Free;
    end;

    RunCommand('sync', s);
    RunCommand('umount', [uMountPoint], s);

  except
    on E: Exception do
    begin
      RunCommand('umount', [uMountPoint], s);
      Result := E.Message;
    end;
  end;
end;




procedure ChangeHost(device: string; newHostName: string);
var
  sl: TStringList;
  i: integer;
  line: string;
  PartitionDevice: ansistring;
  uMountPoint: ansistring;
  s: ansistring;
begin
  uMountPoint := '/images/tmp_mount';
  sl := TStringList.Create;

  try
    // Partition Device 2 ermitteln
    PartitionDevice := PartitionName(device, 2);

    // Mountpoint vorbereiten
    if not DirectoryExists(uMountPoint) then
      if not ForceDirectories(uMountPoint) then
        raise Exception.Create('Failed to create mount directory: ' + uMountPoint);

    fpchmod(uMountPoint, &777);

    // Partition mounten
    if not RunCommand('mount', [PartitionDevice, uMountPoint], s) then
      raise Exception.Create('Failed to mount partition ' + PartitionDevice + ': ' + s);

    // Prüfen ob /etc/hosts existiert
    if not FileExists(uMountPoint + '/etc/hosts') then
      raise Exception.Create('/etc/hosts not found on partition');

    // /etc/hosts laden
    sl.LoadFromFile(uMountPoint + '/etc/hosts');

    // Zeile ersetzen
    for i := 0 to sl.Count - 1 do
    begin
      line := TrimLeft(sl[i]);

      // exakte Erkennung: beginnt mit "127.0.1.1" + whitespace
      if (Copy(line, 1, 9) = '127.0.1.1') and ((Length(line) = 9) or (line[10] in [' ', #9])) then
      begin
        sl[i] := '127.0.1.1' + #9 + newHostName;
        Break;
      end;
    end;

    sl.SaveToFile(uMountPoint + '/etc/hosts');

    // /etc/hostname neu schreiben
    sl.Clear;
    sl.Add(newHostName);
    sl.SaveToFile(uMountPoint + '/etc/hostname');

  finally
    sl.Free;
    RunCommand('sync', s);
    RunCommand('umount', [uMountPoint], s);
    RunCommand('sync', s);
    RemoveDir(uMountPoint);
  end;
end;

procedure EnableSSH(device: string);
var
  s: ansistring;
  MountPoint: ansistring;
  F: TextFile;
begin
  MountPoint := '/images/tmp_mount1';
  Tryunmount(Mountpoint);

  mountpartition(device, 1, mountpoint);
  // ssh Datei anlegen
  AssignFile(F, MountPoint + '/ssh');
  Rewrite(F);
  CloseFile(F);
  RunCommand('sync', s);
  Tryunmount(mountpoint);
end;




procedure setPartuuidinmbr(device: string; NewSignature: dword);
var
  uMBR: TMbr;
begin
  uMBR := Read_MBR(device);
  uMBR.DiskSignature := NewSignature;
  Write_MBR(uMBR, device);
end;



procedure MakeImageFirst2Partitions(Sourcedrive, Filename: ansistring; ListBox: TListBox);
var
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
  SourceStream: TFileStream = nil;
  DestStream: TFileStream = nil;
  promille: int64;
  buffer: array of byte;
  BufferSize: int64 = 32 * 1024 * 1024;
begin
  form1.progressbar1.Max := 1000;
  form1.progressbar1.Position := 0;
  try
    //    try
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

    EnsureEnoughSpace(Filename, bytestocopy);

    tocopy := bytestocopy;
    toread := tocopy;


    try
      DestStream := TFileStream.Create(Filename, fmCreate or fmOpenWrite or fmShareDenyNone);
    except
      on E: Exception do
        raise Exception.CreateFmt('Failed to create output file "%s": %s', [Filename, E.Message]);
    end;

    try
      SourceStream := TFileStream.Create(SourceDrive, fmOpenRead or fmShareDenyNone);
    except
      on E: Exception do
        raise Exception.CreateFmt('Failed to open source drive "%s": %s', [SourceDrive, E.Message]);
    end;

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

    info := Format('%d MB  speed: %.1f MB/sec  ETA: %s', [all div 1000000, bps / 1000, '0 seconds']);
    Listboxupdate(ListBox, info);

    makeImageEnd := GetTickCount64;
    ListBox.Items.Add(IntToStr(all) + ' of ' + IntToStr(tocopy) + ' bytes copied in ' + ms2t(makeImageEnd - makeImageStart));

    RunCommand('sync', s);

  finally
    if Assigned(SourceStream) then FreeAndNil(SourceStream);
    if Assigned(DestStream) then FreeAndNil(DestStream);
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

procedure ImageToDeviceStandard(Source, Destination:string; box: TListBox);
const
  BufferSize = 16 * 1024 * 1024;
var
  fsource: tfilestream = nil;
  fdest: TFileStream = nil;
  ibuffer: array of byte;
  done, tocopy: int64;
  lastUpdate: uint64;
  speed: int64;
  etaSecs: double;
  //  lastline: integer;
  ReadCount, WrittenCount: int64;
  etaStr, status, st: string;
  nowTick: uint64;   //, starttick
  ringbuffer: rngbuffer;
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

    // schreiben das ganze image und korrigieren später  - ziel könnte leer sein
    //fsource.Position := 0;
    //fdest.Position := 0;
    //done := 0;

    tocopy := fsource.Size;

    // Ringpuffer initialisieren
    nowTick := GetTickCount64;

    InitRingBuffer(ringbuffer, 48, nowTick, 0);
    lastUpdate := nowTick;

    listboxaddscroll(box,'');

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
          speed := addringbuffer(ringbuffer, nowtick, done);


          if speed > 0 then
            etaSecs := (tocopy - done) / speed
          else
            etaSecs := 0;

          etaStr := mstostr(etaSecs);

          status := Format('%.1f MiB  %.2f MB/s  ETA: %s', [done / 1048576, speed / 1048576, etaStr]);
          listboxupdate(box, status);
        end;
        form1.ProgressBar1.Position := done * 1000 div tocopy;
      end;
      application.ProcessMessages;
    until (ReadCount = 0) or (done >= tocopy) or terminate_all;

    if not terminate_all then status := Format('%.1f MiB  %.2f MB/s', [done / 1048576, speed / 1048576]);
    listboxupdate(box, status);

    if terminate_all then
      raise Exception.Create('Writing to device: process terminated.');

  finally
    FreeAndNil(fsource);
    FreeAndNil(fdest);
  end;

  RunCommand('sync', st);
end;



function ImageToDeviceZstd(Source, Destination: string; box: TListBox): string;
const
  BufferSize = 32 * 1024 * 1024;
var
  fin: TFileStream = nil;
  fout: TFileStream = nil;
  dctx: TZSTD_DCtx;
  InBuffer: TZSTD_inBuffer;
  OutBuffer: TZSTD_outBuffer;
  InData: array of byte;
  OutData: array of byte;
  done: int64 = 0;
  starttime: int64;
  lastUpdate, etaSecsZ: double;
  lastline, res: integer;
  speedZMBs, speeddonembs: double;
  etaStr, status: string;
 // percent: integer;
  tocopy, nowtick: int64;     // , starttick
  skipBytes: integer = 512;
  sumread: int64;
  ringdonebuffer, ringZbuffer: rngbuffer;
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
    startTime := gettickcount64;
    listboxaddscroll(box, '');
    lastline := box.Count - 1;
    lastUpdate := gettickcount64;
 //   starttick := gettickcount64;

    initringbuffer(Ringdonebuffer, 48, starttime, 0);
    initringbuffer(ringZbuffer, 48, starttime, 0);

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

        // Anzeige alle 5 Sekunden

        nowtick := gettickcount64;

        if (nowTick - lastUpdate) >= 5000 then
        begin
          lastUpdate := nowTick;

          speedZMBs := AddRingbuffer(ringZbuffer, nowTick, fin.Position);
          speedDoneMBs := AddRingbuffer(ringDonebuffer, nowTick, done);


          if (speedZMBs > 0) and (fin.Size > 0) then
            etaSecsZ := (fin.Size - fin.Position) / speedZMBs
          else
            etaSecsZ := 0;

          etaStr := mstostr(etaSecsZ);

          if fin.Size > 0 then
            form1.ProgressBar1.Position := fin.Position * 1000 div fin.Size;
          status := Format(' %.1f MB  %1f MB/s  ETA %s', [done / 1048576, speedDoneMBs / 1048576, etaStr]);   //fin.Position / 1048576,
          box.Items[lastline] := status;
        end;
        Application.ProcessMessages;
      end;


      if terminate_all then raise Exception.Create('Writing image to device is terminated');
    until (res = 0);


    // Abschluss-Update nach erfolgreicher Dekompression
    speedZMBs := 0;
//    percent := 100;
    etaStr := '00:00:00';

    if fin.Size > 0 then
      form1.ProgressBar1.Position := fin.Position * 1000 div fin.Size;

    status := Format(' %.1f MB  %1f MB/s  ETA %s', [done / 1048576, speedDoneMBs / 1048576, etaStr]);

    box.Items[lastline] := status;
    Application.ProcessMessages;


  finally
    ZSTD_freeDCtx(dctx);
    fin.Free;
    fout.Free;
  end;
end;




procedure ImageToDeviceImgAndZstd(Source, Destination: string; box: TListBox);
begin
  PreCheckImageWrite(Source, Destination);

  if LowerCase(ExtractFileExt(Source)) = '.zst' then
    ImageToDeviceZstd(Source, Destination, box)

  else
  begin
    if FileSize(Source) mod 512 <> 0 then
      raise Exception.Create('Image size is not a multiple of 512 bytes (sector size).');
    ImageToDeviceStandard(Source, Destination, box);
  end;
end;


procedure ClearEmptyBlocks(listbox: tlistbox; mountpoint: string);
const
  BlockSize = 16 * 1024 * 1024; // 16 MiB
var
  Stream: TFileStream = nil;
  BytesWritten, TotalWritten: int64;
  s, filepath: string;
  buffer: array of byte;
begin
  try
    listboxaddscroll(listbox, '');
    filepath := MountPoint + '/fillfile';
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
