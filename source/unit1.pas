unit Unit1;

{$mode objfpc}{$H+}

interface
uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin, Grids,
  Process, inifiles, fileutil, lazutf8, TplScrollbarUnit, Unix,
  baseunix, LCLIntf, rkutils, zstd, ExcludeProcessor, LCLType, MaskEdit,
  ExtCtrls, ComCtrls, Buttons, DateUtils, fpjson, jsonparser, Types, exethread,
  usersetup, pibackup_updater, msg_dlg, unit2, Editor, Themes, Menus,
  CustomDrawn_common;

type
  partitioninfo = record
    Name: string;
    parttype: integer;
    mountpoint: string;
    partlabel: string;
    start: int64;
    size: int64;
  end;

type
  tdriveinfo = record
    partinfo: array[0..4] of partitioninfo;
  end;

type
  partition = record
    Name: string;
    Lbl: string;
    FSType: integer;
    Mountpoint: string;
    Startsector: int64;
    Size: int64;
  end;

type
  tgridcontent = record
    part: array [0..4] of partition;
  end;


type
  { TForm1 }
  TForm1 = class(TForm)
    Btn_SaveLog: TButton;
    btn_help: TButton;
    btn_EditExclude: TButton;
    Button5: TButton;
    btn_close: TButton;
    ButtonCreateImage: TButton;
    ButtonWriteImagetodevice: TButton;
    ButtonWriteClonetodevice: TButton;
    CheckBox1: TCheckBox;
    CleanCClonTarget: TCheckBox;
    CheckBoxChangeDeviceID1: TCheckBox;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    Eddeviceidclone: TEdit;
    EDhost: TEdit;
    Edit1: TEdit;
    EDuserpassword: TEdit;
    edit_wlanssid: TEdit;
    edit_wlanpassword: TEdit;
    EDusername: TEdit;
    CBEnableSSH: TCheckBox;
    CheckBoxChangeDeviceID: TCheckBox;
    CheckBox_Delimg: TCheckBox;
    CheckBox_exclude: TCheckBox;
    CheckBox_RemoveSSH: TCheckBox;
    CheckBox_RemoveDHCP: TCheckBox;
    CheckBox_DelPartition3: TCheckBox;
    CheckBox_DelPartition4: TCheckBox;
    Edit2: TEdit;
    Eddeviceid: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    lbl_host: TLabel;
    Label2: TLabel;
    lbl_ssid: TLabel;
    lbl_passphrase: TLabel;
    lbl_user: TLabel;
    lbl_userpassword: TLabel;
    Label_ManSelected: TLabel;
    ListBox1: TListBox;
    MainMenu1: TMainMenu;
    OpenDialog1: TOpenDialog;
    OpenDialog2: TOpenDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    plScrollbar1: TplScrollbar;
    PopupMenu1: TPopupMenu;
    PopupMenu2: TPopupMenu;
    ProgressBar1: TProgressBar;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    RadioButton3: TRadioButton;
    SaveDialog1: TSaveDialog;
    SpeedButton1: TSpeedButton;
    SpinEdit1: TSpinEdit;
    StringGrid1: TStringGrid;
    Timer1: TTimer;
    procedure btn_closeClick(Sender: TObject);
    procedure btn_EditExcludeClick(Sender: TObject);
    procedure Btn_SaveLogClick(Sender: TObject);
    procedure btn_helpClick(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure ButtonCreateImageClick(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure ButtonWriteClonetodeviceClick(Sender: TObject);
    procedure ButtonWriteImagetodeviceClick(Sender: TObject);
    procedure CheckBoxChangeDeviceID1Change(Sender: TObject);
    procedure CheckBoxChangeDeviceIDChange(Sender: TObject);
    procedure CleanCClonTargetChange(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure ComboBox1CloseUp(Sender: TObject);
    procedure ComboBox1DropDown(Sender: TObject);
    procedure ComboBox2DropDown(Sender: TObject);
    procedure EddeviceidcloneChange(Sender: TObject);
    procedure Edit1DblClick(Sender: TObject);
    procedure EddeviceidChange(Sender: TObject);
    procedure EddeviceidKeyPress(Sender: TObject; var Key: char);
    procedure EddeviceidcloneKeyPress(Sender: TObject; var Key: char);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
        procedure plScrollbar1Scroll(Sender: TObject; ScrollPos: integer);
    procedure RadioButtonChange(Sender: TObject);
    procedure ModifyImage(mountpoint: string);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton1Paint(Sender: TObject);
    procedure StringGrid1BeforeSelection(Sender: TObject; aCol, aRow: integer);
    procedure StringGrid1EditingDone(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure write_ini;
    procedure readDeviceInfo(drive: string; var deviceinfo: Tdriveinfo);
    procedure GridUpdate(Sender: TObject);
    procedure enablesel;
    procedure disablesel;
    procedure FixHover(Data: PtrInt);
    function BuildFinalMBR: TMBR;
    procedure showgrid;
    procedure updatedevicemode;
    procedure UpdateImageMode(sender:tobject);
    procedure UpdateCloneMode;


  private
    procedure SetBaseThreadCount(Data: PtrInt);
  public

  end;

const
  Version = 'v2.1.0';
  p2mpoint = '/tmp/p2_pibackup_img';
  p1mpoint = '/tmp/p1_pibackup_img';
  appname = 'PiBackup ' + version;
  ininame = '/etc/pibackup/pibackup.ini';

  error=1;
  userabort=2;
  del_p3 = 4;
  del_p4 = 8;



  stringGrid1ColWidths: array of integer = (100, 160, 135, 355, 85, 150);


var
  Form1: TForm1;


implementation

{$R *.frm}

{ TForm1 }

var
  lastimagefile: string;
  disableSelection: boolean = False;
  selecteddrive: string;
  DrivePartitionInfo, DrivePartitionInfoTarget: Tdriveinfo;
  user: ansistring;
  Destname: ansistring;
  device: string;
  basicthreads: integer;
  messageuserinfo: boolean = False;
  grid: tgridcontent;
  imagembr: tmbr;
  drivembr: tmbr;
  lastcombotext: string = '';
  Deviceid: Dword;
  clonedeleteP3, clonedeleteP4: boolean;
  scrollposition:dword;
  org_size_p2:dword;


procedure DrawComboButton(C: TCanvas; const R: TRect);
var
  Details: TThemedElementDetails;
begin
  if ThemeServices.ThemesEnabled then
  begin
    Details := ThemeServices.GetElementDetails(tcDropDownButtonNormal);
    ThemeServices.DrawElement(C.Handle, Details, R);
  end
  else
    DrawFrameControl(C.Handle, R, DFC_SCROLL, DFCS_SCROLLCOMBOBOX);
end;


procedure cleangridrow(row: integer);
begin
  grid.part[row].Name := '';
  grid.part[row].Size := 0;
  grid.part[row].Startsector := 0;
  grid.part[row].FSType := 0;
  grid.part[row].Mountpoint := '';
  grid.part[row].Lbl := '';
end;


procedure Gridclean;
var
  x: integer;
begin
  with form1 do
  begin
    StringGrid1.Clean;
    StringGrid1.Cells[0, 0] := 'NAME';
    StringGrid1.Cells[1, 0] := 'LABEL';
    StringGrid1.Cells[2, 0] := 'FSTYPE';
    StringGrid1.Cells[3, 0] := 'MOUNTPOINT';
    StringGrid1.Cells[4, 0] := 'STARTSECTOR';
    StringGrid1.Cells[5, 0] := '   SECTORS / MiB';
    for x := 0 to 4 do cleangridrow(x);
  end;
end;




function SecStringToMiB(const s: string): string;
var
  v: int64;
begin
  v := StrToInt64Def(s, 0);
  Result := IntToStr(v div 2048);
end;


procedure Tform1.disablesel;
begin
  disableSelection := True;
  edit1.ReadOnly := True;
end;

procedure Tform1.enablesel;
begin
  disableSelection := False;
  edit1.ReadOnly := False;
end;


function CountThreads: integer;
var
  SR: TSearchRec;
begin
  Result := 0;
  if FindFirst('/proc/self/task/*', faDirectory, SR) = 0 then
  begin
    repeat
      if (SR.Name <> '.') and (SR.Name <> '..') then
        Inc(Result);
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
end;



procedure TForm1.SetBaseThreadCount(Data: PtrInt);
begin
  Basicthreads := CountThreads;
end;


function WaitForAllThreads(basethreads, TimeoutMS: integer): boolean;
var
  Start: QWord;
  threadcount: integer;
begin
  Start := GetTickCount64;
  repeat
    threadcount := CountThreads;
    if threadcount <= basethreads then
      Exit(True); // ✅ nur Hauptthreads aktiv
    Sleep(50);
  until (GetTickCount64 - Start) > QWord(TimeoutMS);
  Result := False; // ❌ Timeout erreicht
end;




procedure TForm1.EddeviceidKeyPress(Sender: TObject; var Key: char);
begin
  if (not CheckBoxChangeDeviceID.Checked) then key := #0
  else
  begin
    if (key = #127) or (key = #8) then exit; // #127 = Delete   #8 = Backspace
    Key := lowerCase(Key);
    if (not (Key in ['0'..'9', 'a'..'f'])) then
      Key := #0;  // ungültige Taste unterdrücken
  end;
end;


procedure TForm1.EddeviceidcloneKeyPress(Sender: TObject; var Key: char);
begin
  if (not CheckBoxChangeDeviceID1.Checked) then key := #0
  else
  begin
    if (key = #127) or (key = #8) then exit; // #127 = Delete   #8 = Backspace
    Key := lowerCase(Key);
    if (not (Key in ['0'..'9', 'a'..'f'])) then
      Key := #0;  // ungültige Taste unterdrücken
  end;
end;




function SecToMiB(sec: int64): int64;
begin
  Result := sec div 2048;
end;


function FormatSecMiB(sec: int64): string;
begin
  Result :=
    PadLeft(IntToStr(sec), 10) + ' / ' + PadLeft(IntToStr(SecToMiB(sec)), 6);
end;


function IsItExtended(ptype: byte): boolean;
begin
  Result := ptype in [$05, $0F];
end;


function GetDeviceSizeSectors(const device: string): int64;
var
  f: TextFile;
  sectors: string;
  dev: string;
begin
  // /dev/sda → sda
  dev := ExtractFileName(device);
  AssignFile(f, '/sys/block/' + dev + '/size');
  Reset(f);
  ReadLn(f, sectors);
  Result := strtoint64(sectors);
  CloseFile(f);
end;



procedure Tform1.showgrid;
var
  x: integer;
begin
  stringgrid1.Cells[0, 1] := grid.part[0].Name;
  StringGrid1.Cells[5, 1] := FormatSecMiB(grid.part[0].Size);
  for x := 1 to 4 do
  begin
    if grid.part[x].Name > '' then
    begin
      StringGrid1.Cells[0, x + 1] := grid.part[x].Name;
      StringGrid1.Cells[1, x + 1] := grid.part[x].Lbl;
      StringGrid1.Cells[2, x + 1] := GetMBRPartitionTypeName(grid.part[x].FSType);
      StringGrid1.Cells[3, x + 1] := grid.part[x].Mountpoint;
      StringGrid1.Cells[4, x + 1] := PadLeft(IntToStr(grid.part[x].Startsector), 10);
      StringGrid1.Cells[5, x + 1] := FormatSecMiB(grid.part[x].Size);
    end
    else
    begin
      StringGrid1.Cells[1, x + 1] := '';
      StringGrid1.Cells[2, x + 1] := '';
      StringGrid1.Cells[3, x + 1] := '';
      StringGrid1.Cells[4, x + 1] := '';
      StringGrid1.Cells[5, x + 1] := '';
    end;
  end;
end;





procedure TForm1.readDeviceInfo(drive: string; var deviceinfo: Tdriveinfo);
var
  s: string;
  json: TJSONData;
  root, child: TJSONData;
  i: integer;
  mbr: TMBR;
  errormsg: string;

  function SafeGet(json: TJSONData; const path: string): string;
  var
    tmp: TJSONData;
  begin
    tmp := json.FindPath(path);
    if (tmp = nil) or (tmp.JSONType = jtNull) then
      Result := ''
    else
      Result := tmp.AsString;
  end;

begin
  // =========================================================
  // INIT
  // =========================================================
  for i := 0 to 4 do
  begin
    deviceinfo.partinfo[i].Name := '';
    deviceinfo.partinfo[i].parttype := 0;
    deviceinfo.partinfo[i].mountpoint := '';
    deviceinfo.partinfo[i].partlabel := '';
    deviceinfo.partinfo[i].start := 0;
    deviceinfo.partinfo[i].size := 0;
  end;

  if Pos('/dev/', drive) <> 1 then Exit;

  // =========================================================
  // 1. MBR LESEN (WICHTIG!)
  // =========================================================

  // Disk selbst
  deviceinfo.partinfo[0].Name := Copy(drive, 6, 255);

  if not Read_MBR(drive, errormsg, mbr) then
    fillchar(mbr.PartitionEntries, sizeof(mbr.PartitionEntries), 0);


  // =========================================================
  // 2. PARTITIONEN AUS MBR
  // =========================================================
  for i := 1 to 4 do
  begin
    if mbr.PartitionEntries[i].PartitionType <> $00 then
    begin
      deviceinfo.partinfo[i].Name :=
        deviceinfo.partinfo[0].Name + IntToStr(i);

      deviceinfo.partinfo[i].start := mbr.PartitionEntries[i].FirstLBA;

      deviceinfo.partinfo[i].size := mbr.PartitionEntries[i].PartitionSize;

      deviceinfo.partinfo[i].parttype := mbr.PartitionEntries[i].PartitionType;
    end;
  end;

  // =========================================================
  // 3. lsblk nur für Zusatzinfos
  // =========================================================
  if RunCommand('lsblk ' + drive + ' -J -o NAME,LABEL,FSTYPE,MOUNTPOINT', s) then
  begin
    json := GetJSON(s);
    root := json.FindPath('blockdevices[0]');

    if (root <> nil) and (root.FindPath('children') <> nil) then
    begin
      for i := 0 to root.FindPath('children').Count - 1 do
      begin
        if i > 3 then Break;

        child := root.FindPath('children[' + IntToStr(i) + ']');

        deviceinfo.partinfo[i + 1].partlabel :=
          SafeGet(child, 'label');

        deviceinfo.partinfo[i + 1].mountpoint :=
          SafeGet(child, 'mountpoint');
      end;
    end;
    json.Free;
  end;
end;




function Tform1.BuildFinalMBR: TMBR;
var
  x: integer;
begin
  Result := imagembr;
  for x := 1 to 4 do
  begin
    Result.PartitionEntries[x].PartitionType := grid.part[x].FSType;
    Result.PartitionEntries[x].PartitionSize := grid.part[x].Size;
    Result.PartitionEntries[x].FirstLBA := grid.part[x].Startsector;
    Result.PartitionEntries[x].EndCylinder := 0;
    Result.PartitionEntries[x].EndSectorCylinder := 0;
    Result.PartitionEntries[x].StartHead := 0;
    Result.PartitionEntries[x].EndHead := 0;
    Result.PartitionEntries[x].StartCylinder := 0;
    Result.PartitionEntries[x].StartSectorCylinder := 0;
  end;
end;



function TestDeviceWithImageMBR(const Dev: string; StartLBA, Size: QWord): boolean;
var
  loopdev, output: string;
  mountpoint: string;
begin
  Result := False;

  mountpoint := '/tmp/pibackup_test';

  RunCommand(
    'losetup --find --show --read-only ' + '--offset ' + IntToStr(StartLBA * 512) + ' --sizelimit ' + IntToStr(Size * 512) + ' ' + Dev,
    loopdev
    );

  loopdev := Trim(loopdev);
  if loopdev = '' then exit;

  if RunCommand('mount -o ro ' + loopdev + ' ' + mountpoint, output) then
  begin
    RunCommand('umount ' + mountpoint, output);
    Result := True;
  end;

  RunCommand('losetup -d ' + loopdev, output);
end;




function TestImagePartition(const ImageFile: string; StartLBA, SizeSectors: QWord): boolean;
var
  output: string;
  loopdev: string;
  mountpoint: string;
  offset, sizelimit: QWord;
begin
  Result := False;

  mountpoint := '/tmp/pibackup_test_img';

  if not DirectoryExists(mountpoint) then
    CreateDir(mountpoint);

  offset := StartLBA * 512;
  sizelimit := SizeSectors * 512;

  // 1. Loop device mit Offset erzeugen
  if not RunCommand('losetup --find --show --read-only ' + '--offset ' + IntToStr(offset) + ' --sizelimit ' + IntToStr(sizelimit) + ' ' + ImageFile, loopdev) then exit;

  loopdev := Trim(loopdev);

  if loopdev = '' then exit;

  // 2. Mount read-only testen
  if not RunCommand('mount -o ro ' + loopdev + ' ' + mountpoint, output) then
  begin
    RunCommand('losetup -d ' + loopdev, output);
    exit;
  end;

  // 3. sofort wieder unmounten
  RunCommand('umount ' + mountpoint, output);

  // 4. loop entfernen
  RunCommand('losetup -d ' + loopdev, output);

  Result := True;
end;



function IsPartitionRunnable(const Dev: string): boolean;
var
  output: string;
begin
  Result := False;

  // Mountpoint vorbereiten
  if not DirectoryExists('/tmp/pibackup_test') then
    CreateDir('/tmp/pibackup_test');

  // Read-Only mount versuchen
  if not RunCommand('mount ' + Dev + ' /tmp/pibackup_test', output) then
    Exit;

  // sofort wieder unmounten
  RunCommand('umount /tmp/pibackup_test', output);

  Result := True;
end;



function FitsOnDevice(start: int64; size: int64; DeviceSectors: int64): boolean;
var
  endLBA: int64;
begin
  if Size = 0 then  Exit(False);
  endLBA := start + Size - 1;
  Result := endLBA <= DeviceSectors;
end;



procedure TForm1.UpdateDeviceMode;
var
  drive, errormsg: string;
  p, y: integer;
  devSec: int64;
begin
  try
    GridClean;

    p := Pos(':', ComboBox1.Text);
    drive := Copy(ComboBox1.Text, 1, p - 1);

    if drive = '' then
    begin
      ComboBox1.Text := 'None';
      Exit;
    end;

    ReadDeviceInfo(drive, DrivePartitionInfo);
    Read_MBR(drive, errormsg, drivembr);

    devSec := GetDeviceSizeSectors(drive);

    Grid.part[0].Name := drive;
    Grid.part[0].Size := devSec;

    for y := 1 to 4 do
    begin
      Grid.part[y].Name := DrivePartitionInfo.partinfo[y].Name;
      Grid.part[y].Lbl := DrivePartitionInfo.partinfo[y].partlabel;
      Grid.part[y].FSType := DrivePartitionInfo.partinfo[y].parttype;
      Grid.part[y].Mountpoint := DrivePartitionInfo.partinfo[y].mountpoint;
      Grid.part[y].Startsector := DrivePartitionInfo.partinfo[y].start;
      Grid.part[y].Size := DrivePartitionInfo.partinfo[y].size;
    end;

    LastComboText := ComboBox1.Text;

  finally
    ShowGrid;
  end;
end;




procedure Tform1.UpdateImageMode(sender:tobject);
var
  drive, errormsg, na: string;
  p, y,additionalmib: dword;
  devSec,newsize: int64;
  additionalsectors,first_used_sector, free_sectors: int64;
begin
  // =========================================================
  // IMAGE MODE
  // =========================================================

  // freie sectoren berechnen
  try

    if sender <> plscrollbar1 then
    begin
    gridclean;
    p := Pos(':', ComboBox1.Text);
    drive := Copy(ComboBox1.Text, 1, p - 1);

    if drive = '' then
    begin
      ComboBox1.Text := 'None';
      exit;
    end;

    if not FileExists(Edit1.Text) then
    begin
  //    ListboxAddScroll(ListBox1, 'file not existing: ' + Edit1.Text);
      exit;
    end;

    if not Read_MBR(edit1.Text, errormsg, imagembr) then
    begin
      ListboxAddScroll(ListBox1, errormsg);
      Exit;
    end;
      org_size_p2:=imagembr.PartitionEntries[2].PartitionSize;

    if lowercase(extractfileext(edit1.Text)) = '.zst' then
      if not messageuserinfo then
      begin
        Listboxaddscroll(listbox1, 'User settings, Wi-Fi settings, and hostname can only be read from uncompressed .img files.');
        Listboxaddscroll(listbox1, 'However, settings can still be applied without any limitations.');
        Listboxaddscroll(listbox1, 'If values are not changed, the existing settings will be preserved.');
        messageuserinfo := True;
      end;

    Deviceid := imagembr.DiskSignature;
    Eddeviceid.Text := lowercase(hexstr(deviceid, 8));
    ReadUserInfo(edit1.Text);
    // -------------------------
    // P1 / P2 (IMAGE DIREKT)
    // -------------------------
    for y := 1 to 2 do
    begin
      grid.part[y].FSType := imagembr.PartitionEntries[y].PartitionType;
      grid.part[y].Startsector := imagembr.PartitionEntries[y].FirstLBA;
      grid.part[y].Size := imagembr.PartitionEntries[y].PartitionSize;
    end;

    grid.part[1].Name := 'File_P1';
    grid.part[2].Name := 'File_P2';
    grid.part[1].Lbl := 'bootfs';
    grid.part[2].Lbl := 'rootfs';

    if Read_MBR(drive, errormsg, drivembr) then
      ReadDeviceInfo(drive, drivePartitionInfo);
    devSec := GetDeviceSizeSectors(drive);
    grid.part[0].Name := drive;
    grid.part[0].Size := devSec;
    // =========================================================
    // DEVICE PARTITIONEN P3 / P4
    // DEVICE HAT IMMER PRIORITÄT
    // =========================================================
    for y := 3 to 4 do
    begin
      // -------------------------------------------------------
      // zuerst alles löschen
      // -------------------------------------------------------
      cleangridrow(y);
      grid.part[y].Name := '';
      // -------------------------------------------------------
      // DEVICE übernehmen
      // -------------------------------------------------------

      if drivembr.PartitionEntries[y].PartitionType <> 0 then
      begin
        grid.part[y].Name :=        DrivePartitionInfo.partinfo[y].Name + ' (TARGET)';
        grid.part[y].Lbl :=         DrivePartitionInfo.partinfo[y].partlabel;
        grid.part[y].FSType :=      drivembr.PartitionEntries[y].PartitionType;
        grid.part[y].Mountpoint :=  DrivePartitionInfo.partinfo[y].mountpoint;
        grid.part[y].Startsector := drivembr.PartitionEntries[y].FirstLBA;
        grid.part[y].Size :=        drivembr.PartitionEntries[y].PartitionSize;

        // ----------------------------------------------------
        // passt nicht aufs device -> ungültig
        // ----------------------------------------------------
        if not FitsOnDevice(grid.part[y].Startsector, grid.part[y].Size, devSec) then
          cleangridrow(y);

        // ----------------------------------------------------
        // partition nicht mountbar/runnable
        // ----------------------------------------------------
        if grid.part[y].Name <> '' then
        begin
          na := grid.part[y].Name;
          p := pos(' ', na);
          if p > 0 then
            Delete(na, p, MaxInt);

          if not IsPartitionRunnable('/dev/' + na) then
            cleangridrow(y);
        end;
      end;

      // ======================================================
      // FALLBACK AUF IMAGE
      // ======================================================
      if grid.part[y].Name = '' then
      begin

        // imagepartition vorhanden ?
        if imagembr.PartitionEntries[y].PartitionType <> 0 then
        begin

          // passt die imagepartition aufs ziel ?
          if TestDeviceWithImageMBR(grid.part[0].Name, imagembr.PartitionEntries[y].FirstLBA, imagembr.PartitionEntries[y].PartitionSize) then
          begin
            grid.part[y].Name := 'File_P' + IntToStr(y) + ' (IMAGE)';
            grid.part[y].Lbl := '';
            grid.part[y].FSType :=  imagembr.PartitionEntries[y].PartitionType;
            grid.part[y].Mountpoint := '';
            grid.part[y].Startsector := imagembr.PartitionEntries[y].FirstLBA;
            grid.part[y].Size :=   imagembr.PartitionEntries[y].PartitionSize;
          end;
        end;
      end;

      // ======================================================
      // EXTENDED PARTITION markieren
      // ======================================================
      if grid.part[y].FSType in [$05, $0F, $85] then
      begin
        if pos('(EXTENDED)', grid.part[y].Name) = 0 then
          grid.part[y].Name :=
            grid.part[y].Name + ' (EXTENDED)';
      end;
    end;

    // =========================================================
    // DELETE CHECKBOXEN
    // =========================================================
    if CheckBox_DelPartition3.Checked then  cleangridrow(3);
    if CheckBox_DelPartition4.Checked then  cleangridrow(4);

     end;



   // wird ab hier auch von scrollbar ausgeführt


    // =========================================================
    // FREIER PLATZ + P2 SIZE LOGIK
    // =========================================================

    first_used_sector := grid.part[0].Size;


    if (grid.part[4].Startsector > 0 ) and (grid.part[4].Startsector < first_used_sector) then  first_used_sector := grid.part[4].Startsector;
    if (grid.part[3].Startsector > 0 ) and (grid.part[3].Startsector < first_used_sector) then  first_used_sector := grid.part[3].Startsector;

    free_sectors := first_used_sector - grid.part[2].Startsector;       // ab anfang part2

    additionalsectors := first_used_sector - grid.part[2].Startsector - org_size_p2;
    additionalmib:=(additionalsectors + 2047) div 2048;

    if free_sectors < org_size_p2 then
        begin
           plscrollbar1.Position :=0;
           Label_ManSelected.Caption := 'not enough free space';
         Exit;
         end;


    plscrollbar1.min:=0;
    plscrollbar1.max:= additionalmib; // 1mib schritte



    // ---------------------------------------------------------
    // neue p2 größe
    // ---------------------------------------------------------
    newsize :=  (plscrollbar1.Position * 2048 ) + org_size_p2  ;    // in sectoren
    if (newsize + grid.part[2].Startsector ) > first_used_sector then
                                  newsize :=first_used_sector - grid.part[2].Startsector ;

    Label_ManSelected.Caption:=inttostr(newsize div 2048)+' MiB';

    grid.part[2].Size:= newsize;


    // =========================================================
    // DEVICE ID
    // =========================================================
    if not CheckBoxChangeDeviceID.Checked then Eddeviceid.Text := lowercase(IntToHex(imagembr.DiskSignature, 8));
    // =========================================================
    // UI
    // =========================================================
//    Label_ManSelected.Caption := IntToStr(plscrollbar1.Position + smin) + 'MiB';
    checkbox_delpartition3.Visible := (drivembr.PartitionEntries[3].PartitionType > 0) or checkbox_delpartition3.Checked;
    checkbox_delpartition4.Visible := (drivembr.PartitionEntries[4].PartitionType > 0) or checkbox_delpartition4.Checked;

  finally
    showgrid;
  end;
end;



procedure Tform1.UpdateCloneMode;
var
  drive, errormsg, targetdrive: string;
  p, y: integer;
  sourcembr, targetmbr: tmbr;
  devsec: int64;
  firssectorafterp2: int64;
begin
  // =========================================================
  // DEVICE ERMITTELN
  // =========================================================
  try
    gridclean;
    drive := combobox1.Text;
    p := Pos(':', drive);
    drive := Copy(drive, 1, p - 1);

    if drive = '' then
    begin
      ComboBox1.Text := 'None';
      exit;
    end;

    Read_MBR(drive, errormsg, sourcembr);
    deviceid := sourcembr.DiskSignature;
    if not CheckBoxChangeDeviceID1.Checked then Eddeviceidclone.Text := lowercase(inttohex(deviceid, 8));

    ReadDeviceInfo(drive, drivePartitionInfo);
    for y := 1 to 2 do
    begin
      Grid.part[y].Name := DrivePartitionInfo.partinfo[y].Name;
      Grid.part[y].lbl := DrivePartitionInfo.partinfo[y].partlabel;
      Grid.part[y].fstype := DrivePartitionInfo.partinfo[y].parttype;
      Grid.part[y].Mountpoint := DrivePartitionInfo.partinfo[y].mountpoint;
      Grid.part[y].Startsector := DrivePartitionInfo.partinfo[y].start;
      Grid.part[y].Size := DrivePartitionInfo.partinfo[y].size;
    end;

    targetdrive := combobox2.Text;
    p := Pos(':', targetdrive);
    targetdrive := Copy(targetdrive, 1, p - 1);

    if (targetdrive = '') then  // or (combobox2.Text=combobox1.Text
    begin
      ComboBox2.Text := 'None';
      exit;
    end;

    begin
      ReadDeviceInfo(targetdrive, drivePartitionInfotarget);
      Read_MBR(targetdrive, errormsg, targetmbr);
      devSec := GetDeviceSizeSectors(targetdrive);
      grid.part[0].Name := targetdrive;
      grid.part[0].Size := devSec;
      for y := 3 to 4 do
      begin
        Grid.part[y].Name := DrivePartitionInfotarget.partinfo[y].Name;
        Grid.part[y].lbl := DrivePartitionInfotarget.partinfo[y].partlabel;
        Grid.part[y].fstype := DrivePartitionInfotarget.partinfo[y].parttype;
        Grid.part[y].Mountpoint := DrivePartitionInfotarget.partinfo[y].mountpoint;
        Grid.part[y].Startsector := DrivePartitionInfotarget.partinfo[y].start;
        Grid.part[y].Size := DrivePartitionInfotarget.partinfo[y].size;
      end;

      // check für überlappungen p3 + p4
      firssectorafterp2 := Grid.part[2].Startsector + Grid.part[2].Size;
      clonedeleteP3 := (Grid.part[3].Startsector < firssectorafterp2) and (Grid.part[3].size > 0);
      if clonedeleteP3 then
      begin
        cleangridrow(3);
        Grid.part[3].Name := DrivePartitionInfotarget.partinfo[3].Name;
        Grid.part[3].Lbl := DrivePartitionInfotarget.partinfo[3].partlabel;
        Grid.part[3].Mountpoint := 'Partition overlap detected – will be removed';
      end;

      clonedeleteP4 := (Grid.part[4].Startsector < firssectorafterp2) and (Grid.part[4].size > 0);
      if clonedeleteP4 then
      begin
        cleangridrow(4);
        Grid.part[4].Name := DrivePartitionInfotarget.partinfo[4].Name;
        Grid.part[4].Lbl := DrivePartitionInfotarget.partinfo[4].partlabel;
        Grid.part[4].Mountpoint := 'Partition overlap detected – will be removed';
      end;

      if CleanCClonTarget.Checked then
      begin
        clonedeleteP3 := True;
        clonedeleteP4 := True;
        cleangridrow(3);
        cleangridrow(4);
      end;
    end;



    lastcombotext := '';
  finally
    showgrid;
  end;
end;



procedure TForm1.GridUpdate(Sender: TObject);
begin
  if RadioButton1.Checked then
    UpdateDeviceMode
  else
  if RadioButton2.Checked then
    UpdateImageMode(self)
  else
  if RadioButton3.Checked then
    UpdateCloneMode;
end;


procedure ValidateFinalMBR(const MBR: TMBR; DeviceSectors: int64);
var
  i, j: integer;
  aStart, aEnd, bStart, bEnd: int64;
begin
  // =====================================================
  // BOUNDS CHECK
  // =====================================================
  for i := 1 to 4 do
  begin
    if MBR.PartitionEntries[i].PartitionSize = 0 then
      Continue;

    if MBR.PartitionEntries[i].FirstLBA = 0 then
      raise Exception.CreateFmt('Invalid StartLBA in partition %d', [i]);

    aEnd :=
      MBR.PartitionEntries[i].FirstLBA + MBR.PartitionEntries[i].PartitionSize - 1;

    if aEnd > DeviceSectors then
      raise Exception.CreateFmt('Partition %d exceeds device size', [i]);
  end;

  // =====================================================
  // OVERLAP CHECK
  // =====================================================
  for i := 1 to 4 do
  begin
    if MBR.PartitionEntries[i].PartitionSize = 0 then
      Continue;

    aStart := MBR.PartitionEntries[i].FirstLBA;
    aEnd := aStart + MBR.PartitionEntries[i].PartitionSize - 1;

    for j := i + 1 to 4 do
    begin
      if MBR.PartitionEntries[j].PartitionSize = 0 then
        Continue;

      bStart := MBR.PartitionEntries[j].FirstLBA;
      bEnd := bStart + MBR.PartitionEntries[j].PartitionSize - 1;

      if (aStart <= bEnd) and (bStart <= aEnd) then
        raise Exception.CreateFmt('Partition overlap detected between %d and %d', [i, j]);
    end;
  end;
end;


procedure TForm1.RadioButtonChange(Sender: TObject);
begin



  panel1.Visible := False;
  panel2.Visible := False;
  panel4.Visible := False;

  if radiobutton1.Checked then
  begin
    Label2.Caption := 'Source Device';
    Label3.Caption := 'image file';
    panel1.Visible := True;

    panel1.BringToFront;
    combobox2.Visible := False;
    panel3.Visible := True;
    panel3.BringToFront;
    edit1.Text := lastimagefile;

    getdrives(combobox1.Items, False);

    GridUpdate(Sender);
  end;

  if radiobutton2.Checked then
  begin
    CheckBoxChangeDeviceIDChange(Self);

    Label2.Caption := 'Target Device';
    Label3.Caption := 'image file';
    combobox1.Items.Clear;
    application.ProcessMessages;
    panel2.Visible := True;
    panel2.BringToFront;

    combobox2.Visible := False;
    panel3.Visible := True;
    panel3.BringToFront;


    CheckBox_DelPartition3.Checked := False;
    CheckBox_DelPartition4.Checked := False;
    application.ProcessMessages;

    getdrives(combobox1.Items, True);

    combobox1.ItemIndex := 0;
    if combobox1.Items.Count > 0 then combobox1.Text := combobox1.Items[0]
    else
      combobox1.Text := 'None';

    combobox1.ItemIndex := 0;
    if combobox1.Items.Count > 0 then combobox1.Text := combobox1.Items[0]
    else
      combobox1.Text := 'None';
    edit1.Text := lastimagefile;
    if not fileexists(edit1.Text) then Edit1.Text := '';
    GridUpdate(Sender);
  end;


  if radiobutton3.Checked then
  begin
      CheckBoxChangeDeviceID1Change(Self);

    listbox1.Items.Clear;
    getdrives(combobox1.Items, False);
    getdrives(combobox2.Items, True);
    Label2.Caption := 'Source Device';
    Label3.Caption := 'Target Device';
    panel4.Visible := True;
    panel4.BringToFront;
    panel3.Visible := False;
    combobox2.BringToFront;
    combobox2.Visible := True;
    getdrives(combobox1.Items, False);
    GridUpdate(Sender);
   end;
end;



procedure TForm1.write_ini;
var
  ini: tinifile;
begin
  ini := tinifile.Create(ininame);
  ini.WriteString('Drive', 'Last', combobox1.Text);
  ini.WriteString('Destination', 'Last', Edit1.Text);
  ini.WriteString('Exclude', 'Last', Edit2.Text);
  ini.WriteBool('Option', 'compress', checkbox1.Checked);
  ini.WriteBool('Option', 'DeletePastCompress', checkbox_Delimg.Checked);
  ini.Writeinteger('Option', 'compresslevel', spinedit1.Value);

  // for write
  ini.WriteBool('Option', 'ChangeDeviceID', checkboxChangeDeviceID.Checked);
  ini.Free;
end;



procedure TForm1.FormCreate(Sender: TObject);
var
  ini: tinifile;
  s, speichertdrive: ansistring;
  x, w, h: integer;
begin
  Application.QueueAsyncCall(@SetBaseThreadCount, 0);

  runcommand('sudo systemctl stop udisks2', s);
  form1.Caption := appname;

  for x := 0 to 5 do
    stringGrid1.ColWidths[x] := stringGrid1ColWidths[x];

  w := 0;

  for x := 0 to stringgrid1.ColCount - 1 do Inc(w, stringGrid1.ColWidths[x]);
  Inc(w, (2) * stringgrid1.GridLineWidth);

  stringgrid1.Width := w;
  form1.Width := w + stringgrid1.Left + 8;

  h := 0;
  for x := 0 to stringgrid1.rowCount - 1 do Inc(h, stringGrid1.RowHeights[x]);
  Inc(h, (2) * stringgrid1.GridLineWidth);
  stringgrid1.Height := h;
  getdrives(combobox1.Items, False);
  combobox1.ItemIndex := 0;


  ini := tinifile.Create(ininame);

  speichertdrive := ini.readstring('Drive', 'Last', '');
  if combobox1.items.Count > 0 then
    combobox1.ItemIndex := 0;

  for x := 0 to combobox1.Items.Count - 1 do
    if speichertdrive = combobox1.items[x] then
    begin
      combobox1.Text := speichertdrive;
      break;
    end;

  s := ini.ReadString('Destination', 'Last', '');
  if s > '' then
  begin
    edit1.Text := s;
    lastimagefile := s;
  end;
  checkbox1.Checked := ini.ReadBool('Option', 'compress', False);
  spinedit1.Value := ini.readinteger('Option', 'compresslevel', 2);
  edit2.Text := ini.ReadString('Exclude', 'Last', '');
  s := ini.ReadString('Exclude', 'Last', '');
  checkbox_Delimg.Checked := ini.ReadBool('Option', 'DeletePastCompress', False);
  checkboxChangeDeviceID.Checked := ini.ReadBool('Option', 'ChangeDeviceID', False);
  ini.Free;

  runcommand('logname', user);
  Delete(user, Length(user), 1);

  gridupdate(self);

  CloseMountTarget(p1mpoint);
  CloseMountTarget(p2mpoint);
  RadioButtonChange(self);
  timer1.Enabled := True;
end;


procedure TForm1.plScrollbar1Scroll(Sender: TObject; ScrollPos: integer);
begin
  scrollposition:=scrollpos;
  updateimagemode(plScrollbar1);
end;





procedure TForm1.ModifyImage(mountpoint: string);
begin

  if CheckBox_exclude.Checked then
  begin
    if fileexists(edit2.Text) then
      excludeprocessor.ProcessList(edit2.Text, mountpoint);
  end;

  if CheckBox_RemoveSSH.Checked then
  begin
    excludeprocessor.ProcessList('/etc/pibackup/ssh-cleanup.exclude', mountpoint);
  end;

  if CheckBox_RemoveDHCP.Checked then
  begin
    excludeprocessor.ProcessList('/etc/pibackup/dhcp-cleanup.exclude', mountpoint);
  end;

end;

procedure TForm1.SpeedButton1Click(Sender: TObject);
begin
  edit1DblClick(self);
end;

procedure TForm1.SpeedButton1Paint(Sender: TObject);
begin
  DrawComboButton(SpeedButton1.Canvas, SpeedButton1.ClientRect);
end;



procedure TForm1.StringGrid1BeforeSelection(Sender: TObject; aCol, aRow: integer);
begin
  showgrid;
end;

procedure TForm1.StringGrid1EditingDone(Sender: TObject);
begin
  showgrid;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  CheckForUpdates(ListBox1);
  timer1.Enabled := False;
end;




procedure TForm1.ButtonCreateImageClick(Sender: TObject);
var
  filename, sourcedrive, s, mp: ansistring;
  NewBlockCount: int64;
  blocksize: integer;
  deststream: TFileStream = nil;
  mbrwork: TMbr;
  sectorsperblock, p, p1: integer;
  dirpath: string;
  looppartition, errormsg: string;
begin

  if not RunsAsRoot then
    raise Exception.Create('This application must be run as root. Please start with sudo.');

  if ButtonCreateImage.tag > 0 then
  begin
    if MessageDlg('Confirmation', 'Do you really want to cancel?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      ButtonCreateImage.tag := 0;
      terminate_all := True;
      listbox1.items.add('Operation canceled by user.');
      enableSel;
      exit;
    end
    else
    begin
      terminate_all := False;
      exit;
    end;
  end;
  disableSel;
  ButtonCreateImage.tag := 1;

  terminate_all := False;
  ButtonCreateImage.Caption := 'cancel';
  ListBox1.Items.Clear;
  ListBox1.Items.Add('');
  write_ini;
  ListBoxAddScroll(ListBox1, 'Creating image containing: ' + Grid.Part[1].Name + ' and ' + Grid.Part[2].Name);

  try
    sourcedrive := combobox1.Text;
    sourcedrive := copy(sourcedrive, 1, pos(':', sourcedrive) - 1);


    filename := Trim(ChangeFileExt(Edit1.Text, '.img'));

    mp := GetMountPointFromProc(filename);
    if (mp = '/') or (mp = '/boot') or (mp = '/boot/firmware') then
      raise Exception.Create('Destination is on a protected system partition: ' + mp);

    listboxaddscroll(listbox1, '');
    listboxaddscroll(listbox1, starline(Sourcedrive + ' -> ' + ExtractFileName(Filename), 80));
    listboxaddscroll(listbox1, '');

    if terminate_all then raise Exception.Create('Failed to create image from source drive');

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    MakeImageFirst2Partitions(sourcedrive, filename, listbox1);

    //    mbrwork := Read_MBR(sourcedrive);
    if not Read_MBR(sourcedrive, errormsg, mbrwork) then
      fillchar(mbrwork.PartitionEntries, sizeof(mbrwork.PartitionEntries), 0);

    FillChar(mbrwork.PartitionEntries[3], SizeOf(mbrwork.PartitionEntries[3]), 0);
    FillChar(mbrwork.PartitionEntries[4], SizeOf(mbrwork.PartitionEntries[4]), 0);
    Write_MBR(mbrwork, filename);

    // check image
    looppartition := CreateLoopPartition(FileName, 2);
    s := PrexeThreadedBash('/sbin/e2fsck -fy ' + looppartition, listbox1);
    if Pos('errors', LowerCase(s)) > 0 then
      Listboxaddscroll(listbox1, 'Filesystem check reported errors');
    CloseMountTarget(looppartition);


    MountPartition(filename, 2, p2mpoint);

    // image ändern
    ModifyImage(p2mpoint);
    RunCommand('sync', s);
    ListBoxaddscroll(listbox1, 'Removed unnecessary files from the image');
    ListBoxaddscroll(listbox1, '');
    ListBoxaddscroll(listbox1, 'Check the file system consistency of the image and correct it if necessary');
    ListBoxaddscroll(listbox1, '');

    // umount und test filesystem

    CloseMountTarget(p2mpoint);
    looppartition := CreateLoopPartition(FileName, 2);
    s := PrexeThreadedBash('/sbin/e2fsck -fy ' + looppartition, listbox1);
    if Pos('errors', LowerCase(s)) > 0 then
      Listboxaddscroll(listbox1, 'Filesystem check reported errors');

    RunCommand('sync', s);

    s := PrexeThreadedBash('/sbin/resize2fs -M -p ' + looppartition, listbox1, progressbar1, 1);
    progressbar1.Position := progressbar1.Max;
    NewBlockCount := GetValueAfterKeyword(s, 'is now');
    if NewBlockCount = 0 then
      raise Exception.Create('Failed to resize filesystem');

    s := PrexeThreadedBash('/sbin/e2fsck -fy ' + looppartition, listbox1);

    // update filesize
    blocksize := -1;
    s := runbash('blkid ' + looppartition);
    p := pos('BLOCK_SIZE="', s);
    Inc(p, 12);
    p1 := pos('"', s, p + 1);
    s := copy(s, p, p1 - p);
    if not trystrtoint(s, blocksize) then
      raise Exception.Create('Error reading block size');

    //  Listboxaddscroll(listbox1, 'Blocksize: ' + IntToStr(blocksize));
    sectorsperblock := blocksize div 512;

    // grösse korrigieren

    mbrwork.PartitionEntries[2].PartitionSize := NewBlockCount * sectorsperblock;
    Write_MBR(mbrwork, filename);


    try
      deststream := TFileStream.Create(filename, fmOpenReadWrite or fmShareDenyNone);
    except
      on E: Exception do
        raise Exception.Create('Cannot open image file for writing: ' + E.Message);
    end;

    try
      deststream.Size := (mbrwork.PartitionEntries[2].FirstLBA + mbrwork.PartitionEntries[2].PartitionSize) * 512;
    finally
      deststream.Free;
    end;

    // check filesystem
    runbash('/sbin/partprobe ' + looppartition);
    PrexeThreadedBash('/sbin/e2fsck -fy ' + looppartition, Listbox1);


    Listboxaddscroll(listbox1, 'image-size - root only: ' + IntToStr(mbrwork.PartitionEntries[2].PartitionSize * 512) + ' bytes');
    Listboxaddscroll(listbox1, 'image-size - all: ' + IntToStr(FileSize(filename)) + ' bytes');

    CloseMountTarget(looppartition);

    MountPartition(filename, 2, p2mpoint);
    listboxaddscroll(listbox1, 'Clean empty blocks in root-image');
    ClearEmptyBlocks(listbox1, p2mpoint);
    CloseMountTarget(p2mpoint);

    MountPartition(filename, 1, p1mpoint);
    listboxaddscroll(listbox1, 'Clean empty blocks in boot-image');
    ClearEmptyBlocks(listbox1, p1mpoint);
    CloseMountTarget(p1mpoint);

    dirpath := ExtractFilePath(filename);
    fpchown(dirpath, 1000, 1000);
    fpchmod(dirpath, &777);


    fpchown(filename, 1000, 1000);
    fpchmod(filename, &666);


    if (not terminate_all) and (CheckBox1.Checked) then
    begin
      Listboxaddscroll(listbox1, '');
      Listboxaddscroll(listbox1, 'compressing with zstd');

      CompressFileZstdWithProgress(filename, filename + '.zst', SpinEdit1.Value, 4, True, listbox1);
      if checkbox_Delimg.Checked and (not terminate_all) then deletefile(filename);
    end;

  except
    on E: Exception do
      Listboxaddscroll(listbox1, E.Message);
  end;

  fpchown(filename + '.zst', 1000, 1000);
  fpchmod(filename + '.zst', &666);

  Listboxaddscroll(listbox1, starline('all done', 80));
  Listboxaddscroll(listbox1, '');
  ButtonCreateImage.Caption := 'create image';

  enableSel;
  ButtonCreateImage.tag := 0;
end;


procedure TForm1.Btn_SaveLogClick(Sender: TObject);
begin
  if savedialog1.Execute then listbox1.Items.SaveToFile(savedialog1.FileName);
end;

procedure TForm1.btn_EditExcludeClick(Sender: TObject);
begin
  form3.Show;
end;

procedure TForm1.btn_closeClick(Sender: TObject);
begin
  Close;
end;

procedure TForm1.btn_helpClick(Sender: TObject);
begin
  form2.Show;
end;


procedure TForm1.Button7Click(Sender: TObject);
begin
  form3.Show;
end;


procedure TForm1.Button3Click(Sender: TObject);
begin
  terminate_all := True;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  OpenDialog2.Filter := 'Exclude files|*.exclude|All files|*.*';
  OpenDialog2.FilterIndex := 1; // zeigt zuerst nur *.exclude

  if opendialog2.Execute then edit2.Text := opendialog2.FileName;
  write_ini;
end;



function ReadFstabFromDeviceP2(const Device: string; var List: TStringList): boolean;
var
  Cmd, Output, PartDevice: string;
begin
  Result := False;

  if List = nil then
    List := TStringList.Create;

  List.Clear;

  // richtige Partitionsbildung

  PartDevice := partitionname(Device, 2);

  try
    // Mountpoint erstellen
    RunCommand('mkdir -p "/tmp/fstabliste"', Output);

    // sicherheitshalber altes Mount lösen
    RunCommand('umount -l "/tmp/fstabliste"', Output);

    // Partition mounten
    Cmd := 'mount "' + PartDevice + '" "/tmp/fstabliste"';

    if not RunCommand(Cmd, Output) then
      Exit;

    // fstab lesen
    if FileExists('/tmp/fstabliste/etc/fstab') then
    begin
      List.LoadFromFile('/tmp/fstabliste/etc/fstab');
      Result := True;
    end;

  finally
    // immer unmounten
    RunCommand('umount -l "/tmp/fstabliste"', Output);
  end;
end;




procedure TForm1.ButtonWriteimagetodeviceClick(Sender: TObject);
var
  newmbr: TMbr;
  s, par2name, par1name: string;
  sig: dword;
  newsig, driveid: string;
  fstabdrive: TStringList;
  i: integer;
  driveid_ok: boolean;
begin
  if not RunsAsRoot then
    raise Exception.Create('This application must be run as root. Please start with sudo.');

  try
    if ButtonWriteImagetodevice.tag > 0 then
    begin
      if MessageDlg('Confirmation', 'Do you really want to cancel?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        ButtonWriteImagetodevice.tag := 0;
        terminate_all := True;
        ListBoxaddscroll(listbox1, 'Operation canceled by user.');
        ButtonWriteImagetodevice.Caption := 'write image to device';
        enablesel;
        Exit;
      end
      else
      begin
        terminate_all := False;
        exit;
      end;
    end;



    if combobox1.Text = '' then
    begin
      ShowMessage('No target device selected');
      exit;
    end;


    Form4.Label2.Caption := combobox1.Text;
    if form4.ShowModal <> mrYes then exit;

    ButtonWriteImagetodevice.tag := 1;
    Disablesel;

    ButtonWriteImagetodevice.Caption := 'cancel';
    sleep(100);

    terminate_all := False;
    application.ProcessMessages;

    write_ini;

    if not FileExists(edit1.Text) then
      raise Exception.Create('Image file does not exist: ' + edit1.Text);

    selecteddrive := stringgrid1.Cells[0, 1];
    Listboxaddscroll(listbox1, '');

    // delete partition1 and partition2
    Listboxaddscroll(listbox1, '---------- preparing destination: ' + selecteddrive + ' ----------');

    par2name := PartitionName(selecteddrive, 2);
    par1name := PartitionName(selecteddrive, 1);
    CloseMountTarget(par2name);
    sleep(1000);
    CloseMountTarget(par1name);
    sleep(1000);

    runcommand('sync', s);

    s := PrexeThreadedBash('partprobe ' + selecteddrive, listbox1);

    Listboxaddscroll(listbox1, '---------- write image to device: ' + selecteddrive + ' ----------');
    Listboxaddscroll(listbox1, '');


    ImageToDeviceImgAndZstd(edit1.Text, selecteddrive, listbox1);     // keinen mbr schreiben


    // driveid aus fstab holen


    try
      fstabdrive := TStringList.Create;
      driveid_ok := ReadFstabFromDeviceP2(selecteddrive, fstabdrive);
      // driveid isolieren
      if driveid_ok then
      begin
        driveid_ok := False;
        for i := 0 to fstabdrive.Count - 1 do
        begin
          s := trim(fstabdrive[i]);
          if pos(' / ', s) > 0 then
          begin
            if pos('PARTUUID=', s) = 1 then
            begin
              s := copy(s, 10, 8);
              driveid := s;
              driveid_ok := True;
              break;
            end;
          end;
        end;
      end;

    finally
      fstabdrive.Free;
    end;

    newmbr := BuildFinalMBR;

    // in cmdline eintragen
    write_mbr(newmbr, selecteddrive);

    runcommand('sync', s);
    s := PrexeThreadedBash('partprobe ' + selecteddrive, listbox1);
    sleep(1000);
    par2name := partitionname(selecteddrive, 2);
    runcommand('sync', s);

    CloseMountTarget(par2name);

    PrexeThreadedBash('e2fsck -fy ' + par2name, listbox1);
    ListBoxaddscroll(listbox1, 'resize...');
    s := PrexeThreadedBash('resize2fs ' + par2name, listbox1, progressbar1, 1);

    PrexeThreadedBash('e2fsck -fy ' + par2name, listbox1);

    s := PrexeThreadedBash('partprobe ' + selecteddrive, listbox1);
    sleep(500);

    newsig := lowercase(Eddeviceid.Text);
    sig := StrToInt('$' + newsig);
    ListBoxaddscroll(listbox1, 'Set device signature in mbr');
    setPartUUIDinMbr(selecteddrive, sig);

    /////////////////////////////////////////////////////////////////////////////////////////////////7
    ListBoxaddscroll(listbox1, 'Set device signature in cmdline.txt');

    if mountpartition(selecteddrive, 1, tempmountpoint) then
    begin
      setPartUUIDInCmdline(tempmountpoint, sig);
      if CBEnableSSH.Checked then
      begin
        ListBoxaddscroll(listbox1, 'enable SSH');
        EnableSSH(tempmountpoint);
      end;
      Runcommand('umount', [tempmountpoint], s);
    end
    else
      ListBoxaddscroll(listbox1, 'Error mounting: ' + partitionname(selecteddrive, 1));
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // p2 mounten für alle folgenden optionen
    if mountpartition(selecteddrive, 2, tempmountpoint) then
    begin
      ListBoxaddscroll(listbox1, 'Set Partitionuuids in fstab');
      s := ReplacePartUUIDInFstab(tempmountpoint, sig);
      if s > '' then ListBox1.Items.Add(s);

      if edhost.Text > '' then Changehost(tempmountpoint, edhost.Text);

      if (edusername.Text > '') and (eduserpassword.Text > '') then
        CreateUserConfFromDevice(tempmountpoint, EDusername.Text, EDuserpassword.Text, ListBox1);

      Edit_wlanssid.Text := trim(Edit_wlanssid.Text);
      Edit_wlanpassword.Text := trim(Edit_wlanpassword.Text);

      if Edit_wlanssid.Text = '' then
      begin
        ListBoxaddscroll(listbox1, 'SSID missing - no changes to network done');
        exit;
      end;
      if Edit_wlanpassword.Text = '' then
      begin
        ListBoxaddscroll(listbox1, 'Wlan password missing - no changes to network done');
        exit;
      end;

      PrepareWLAN(tempmountpoint, edit_wlanssid.Text, edit_wlanpassword.Text);


      Runcommand('umount', [tempmountpoint], s);
      sleep(500);


      Listboxaddscroll(listbox1, '---------- all done ----------');
      Listboxaddscroll(listbox1, '');
    end;
  except
    on E: Exception do
    begin
      listboxaddscroll(listbox1, '❌ Error: ' + E.Message);
    end;
  end;

  ButtonWriteImagetodevice.Caption := 'write image to device';
  ButtonWriteImagetodevice.tag := 0;
  enablesel;
end;


procedure TForm1.ComboBox1Change(Sender: TObject);
begin
  gridupdate(self);
end;




procedure TForm1.ComboBox1CloseUp(Sender: TObject);
begin
  if disableSelection then
    combobox1.ItemIndex := combobox1.tag
  else
  begin
    combobox1.tag := combobox1.ItemIndex;
    gridupdate(self);
  end;
end;

procedure TForm1.FixHover(Data: PtrInt);
begin
  Mouse.CursorPos := Mouse.CursorPos;
end;

procedure TForm1.ComboBox1DropDown(Sender: TObject);
begin

end;

procedure TForm1.ComboBox2DropDown(Sender: TObject);
begin
    ReleaseCapture;
    getdrives(combobox1.Items, False);
    getdrives(combobox2.Items, True);
end;



procedure TForm1.Edit1DblClick(Sender: TObject);
begin
  if DisableSelection then exit;

  if radiobutton1.Checked then
  begin
    if edit1.Text > '' then  SaveDialog1.InitialDir := extractfilepath(edit1.Text);
    if savedialog1.Execute then destname := savedialog1.FileName;
  end;
  if radiobutton2.Checked then
  begin
    if edit1.Text > '' then openDialog1.InitialDir := extractfilepath(edit1.Text);
    if opendialog1.Execute then destname := opendialog1.FileName;
    ReadUserInfo(destname);
  end;
  edit1.Text := Destname;

end;



procedure TForm1.CheckBoxChangeDeviceIDChange(Sender: TObject);
begin
  if not CheckBoxChangeDeviceID.Checked then
    Eddeviceid.Text := lowercase(inttohex(deviceid, 8))
  else
    Eddeviceid.Text := lowercase(inttohex(CreateDeviceUUID, 8));
end;


procedure TForm1.CheckBoxChangeDeviceID1Change(Sender: TObject);
begin
  if not CheckBoxChangeDeviceID1.Checked then
    Eddeviceidclone.Text := lowercase(inttohex(deviceid, 8))
  else
    Eddeviceidclone.Text := lowercase(inttohex(CreateDeviceUUID, 8));
end;




procedure TForm1.CleanCClonTargetChange(Sender: TObject);
begin
  gridupdate(self);
end;




procedure TForm1.EddeviceidChange(Sender: TObject);
var
  s: string;
begin
  s := Eddeviceid.Text;
  s := copy(s, 1, 8);
  Eddeviceid.Text := s;
end;

procedure TForm1.EddeviceidcloneChange(Sender: TObject);
var
  s: string;
begin
  s := Eddeviceidclone.Text;
  s := copy(s, 1, 8);
  Eddeviceidclone.Text := s;
end;


procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var
  s: string;
begin
  Listboxaddscroll(listbox1, 'The program is shutting down. This may take a moment...');
  terminate_all := True;
  WaitForAllThreads(basicthreads, 15000);
  PrexeThreadedBash('umount ' + device, listbox1);  // optional, wenn es gemountet war
  PrexeThreadedBash('losetup -d ' + device, listbox1);
  PrexeThreadedBash('rm -rf ' + p2mpoint, listbox1);
  runcommand('sudo systemctl start udisks2', s);
end;




function CheckCloneDestination(const Source, Target: string;out Msg: string):integer;
var
  SrcMBR, DstMBR: TMbr;
  TargetSize: int64;
  errormsg: string;
  EndP2Source: int64;
begin
  Result := 0;
  Msg := '';

  if form1.CleanCClonTarget.Checked then
  begin
    if MessageDlg('Clone confirmation', 'The entire target device will be erased.' + LineEnding + LineEnding + 'All existing partitions and all data on the target device will be permanently lost.' +
      LineEnding + 'This operation cannot be undone.' + LineEnding + LineEnding + 'Do you want to continue?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
     result:=2 // user abort
     else
     begin
     result:=12;
     Exit;
     end;
  end;

  Read_MBR(Source, errormsg, srcmbr);
  Read_MBR(target, errormsg, dstmbr);



  EndP2Source := SrcMBR.PartitionEntries[2].FirstLBA + SrcMBR.PartitionEntries[2].PartitionSize;
  TargetSize := GetDeviceSizeSectors(Target);

  if EndP2Source > TargetSize then
  begin
    Msg :=
      'Destination device is too small for this clone.';
    Exit(error); //fehler
  end;



  Msg :=
    'The destination device will be overwritten:' + LineEnding + LineEnding + '• Partition 1 will be overwritten' + LineEnding + '• Partition 2 will be overwritten' + LineEnding + LineEnding;

  if clonedeleteP3 or clonedeleteP4 then
  begin
    Msg := Msg + 'Additional changes required:' + LineEnding;

    if clonedeleteP3 then
    begin
      Msg := Msg + '• Partition 3 will be deleted' + LineEnding;
      result:=result and del_p3;
    end;

    if clonedeleteP4 then
    begin
      Msg := Msg + '• Partition 4 will be deleted' + LineEnding;
       result:=result and del_p4;    ;
    end;

    Msg := Msg + LineEnding;
  end;

  Msg := Msg + 'All data on affected partitions will be lost.' + LineEnding + 'This operation cannot be undone.' + LineEnding + LineEnding + 'Do you want to continue?';

  if MessageDlg('Clone confirmation', Msg, mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    result:=result and userabort;

end;




procedure TForm1.ButtonWriteClonetodeviceClick(Sender: TObject);
var
  newmbr, oldmbr: TMbr;
  s, Source, target: string;
  sig: DWord;
  p: integer;
  re: boolean;
  clonemode:integer;
begin
  if not RunsAsRoot then
    raise Exception.Create('This application must be run as root. Please start with sudo.');
  try
   try
    // Cancel handling
    if ButtonWriteClonetodevice.Tag > 0 then
    begin
      if MessageDlg('Confirmation', 'Do you really want to cancel?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        ButtonWriteClonetodevice.Tag := 0;
        terminate_all := True;
        ListBoxAddScroll(ListBox1, 'Operation canceled by user.');
        ButtonWriteClonetodevice.Caption := 'clone to device';
        EnableSel;
        Exit;
      end
      else
        Exit;
    end;

    // parse source
    Source := Combobox1.Text;
    p := Pos(':', Source);
    Source := Copy(Source, 1, p - 1);

    // parse target
    target := Combobox2.Text;
    p := Pos(':', target);
    target := Copy(target, 1, p - 1);

    if (Source = target) then
      raise Exception.Create('Source and target device are the same.');

    if (Source = '') or (not FileExists(Source)) then
      raise Exception.Create('Invalid source device.');

    if (target = '') or (not FileExists(Target)) then
      raise Exception.Create('Invalid target device.');


    ButtonWriteClonetodevice.Tag := 1;
    DisableSel;
    terminate_all := False;

    ButtonWriteClonetodevice.Caption := 'cancel';
    Application.ProcessMessages;

    ListBoxAddScroll(ListBox1, '');
    ListBoxAddScroll(ListBox1, '---------- cloning to device: ' + target + ' ----------');
    ListBoxAddScroll(ListBox1, '');

    read_mbr(Source, s, newmbr);
    read_mbr(target, s, oldmbr);



    clonemode :=   CheckCloneDestination(Source, target, s);

    if (clonemode and error) > 0 then exit;

    if (clonemode and userabort) > 0 then
    begin
      listboxaddscroll(listbox1, 'operation aborted by user');
      exit;
    end;

    re:=tryunmount(PartitionName(target, 1));
    re:=tryunmount(PartitionName(target, 2));
    re:=tryunmount(PartitionName(target, 3));
    re:=tryunmount(PartitionName(target, 4));

    fillchar(newmbr.PartitionEntries[3], sizeof(newmbr.PartitionEntries[3]), 0);
    fillchar(newmbr.PartitionEntries[4], sizeof(newmbr.PartitionEntries[4]), 0);
    write_mbr(newmbr,target);
    ClonePart(Source, target, ListBox1); // ohne mbr

    re:= tryunmount(PartitionName(target, 2));
    PrexeThreadedBash('e2fsck -fy ' + PartitionName(target, 2), listbox1);

    re := TryUnmount(tempmountpoint);

    sig := StrToInt('$' + LowerCase(Eddeviceidclone.Text));

    if MountPartition(target,1, tempmountpoint) then
    begin
      application.ProcessMessages;
      ListBoxaddscroll(listbox1, 'Set device signature in cmdline');
      setPartUUIDInCmdline(tempmountpoint, sig);
       // hier weitere änderungen an part 1
    end else
    begin
      ListBoxaddscroll(listbox1, 'Error mounting: ' + partitionname(target, 1));
      exit;
    end;
     re:=tryunmount(tempmountpoint);
     application.ProcessMessages;

        // änderungen an part 2
    if MountPartition(target,2, tempmountpoint) then
    begin
      application.ProcessMessages;
      ListBoxaddscroll(listbox1, 'Set Partitionuuids in fstab');
      ReplacePartUUIDInFstab(tempmountpoint, sig);
    end
    else
    begin
      ListBoxaddscroll(listbox1, 'Error mounting: ' + partitionname(target, 2));
      exit;
    end;

    re := TryUnmount(tempmountpoint);
    application.ProcessMessages;

    PrexeThreadedBash('e2fsck -fy ' + PartitionName(target, 2), listbox1);

     // mbr korrigieren
    if clonemode and del_p3 =0 then newmbr.PartitionEntries[3]:=  oldmbr.PartitionEntries[3];
    if clonemode and del_p4 =0 then newmbr.PartitionEntries[4]:=  oldmbr.PartitionEntries[4];
    ListBoxaddscroll(listbox1, 'Set device signature in mbr');


    newmbr.DiskSignature:=sig;
    Write_MBR(newmbr, target);

  except
    on E: Exception do
      ListBoxAddScroll(ListBox1, '❌ Error: ' + E.Message);
  end;

  finally
  ButtonWriteClonetodevice.Caption := 'clone to device';
  ButtonWriteClonetodevice.Tag := 0;
  EnableSel;
  Listboxaddscroll(listbox1, starline('all done', 80));
  Listboxaddscroll(listbox1, '');
  end;
end;


end.
