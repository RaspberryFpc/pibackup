unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin, Grids,
  Process, inifiles, fileutil, lazutf8, Unix, baseunix, LCLIntf, rkutils, zstd, ExcludeProcessor,
  LCLType, MaskEdit, ExtCtrls, ComCtrls, DateUtils, fpjson, jsonparser, Types, exethread, usersetup, unit2, Editor;

type
  partitioninfo = record
    Name: string;
    parttype: string;
    mountpoint: string;
    partlabel: string;
    start: string;
    size: string;
  end;

type
  tdriveinfo = record
    partinfo: array[0..4] of partitioninfo;
  end;

type
  { TForm1 }
  TForm1 = class(TForm)
    Btn_SaveLog: TButton;
    btn_help: TButton;
    btn_EditExclude: TButton;
    Button5: TButton;
    btn_select: TButton;
    btn_close: TButton;
    ButtonCreateImage: TButton;
    ButtonWriteImagetodevice: TButton;
    CheckBox1: TCheckBox;
    ComboBox1: TComboBox;
    EDhost: TEdit;
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
    Edit1: TEdit;
    Edit2: TEdit;
    Eddeviceid: TEdit;
    Label3: TLabel;
    lbl_host: TLabel;
    Label2: TLabel;
    lbl_ssid: TLabel;
    lbl_passphrase: TLabel;
    lbl_user: TLabel;
    lbl_userpassword: TLabel;
    Label_ManSelected: TLabel;
    ListBox1: TListBox;
    OpenDialog1: TOpenDialog;
    OpenDialog2: TOpenDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    ProgressBar1: TProgressBar;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    SaveDialog1: TSaveDialog;
    ScrollBar1: TScrollBar;
    SpinEdit1: TSpinEdit;
    StringGrid1: TStringGrid;
    procedure btn_EditExcludeClick(Sender: TObject);
    procedure Btn_SaveLogClick(Sender: TObject);
    procedure btn_helpClick(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure ButtonCreateImageClick(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure ButtonWriteImagetodeviceClick(Sender: TObject);
    procedure ComboBox1CloseUp(Sender: TObject);
    procedure ComboBox1DropDown(Sender: TObject);
    procedure Edit1DblClick(Sender: TObject);
    procedure EddeviceidChange(Sender: TObject);
    procedure EddeviceidKeyPress(Sender: TObject; var Key: char);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure lbl_userpasswordClick(Sender: TObject);
    procedure RadioButton2Change(Sender: TObject);
    procedure ScrollBar1Change(Sender: TObject);
    procedure ModifyImage(mountpoint: string);
    procedure write_ini;
    procedure readDeviceInfo(drive: string; var deviceinfo: Tdriveinfo);
    procedure GridUpdate(Sender: TObject);
    procedure enablesel;
    procedure disablesel;
    procedure FixHover(Data: PtrInt);
    function BuildFinalMBR: TMBR;

  private
    procedure SetBaseThreadCount(Data: PtrInt);
  public

  end;

const
  p2mpoint = '/pi_images/p2_pibackup_img';
  p1mpoint = '/pi_images/p1_pibackup_img';
  appname = 'PiBackup  v2.0.0';
  ininame = '/etc/pibackup/pibackup.ini';

  stringGrid1ColWidths: array of integer = (100, 160, 135, 355, 85, 150);


var
  Form1: TForm1;


implementation

{$R *.frm}

{ TForm1 }

const
  par2 = 3;
  par3 = 4;
  par4 = 5;
  parsize = 5;


var
  disableSelection: boolean = False;
  selecteddrive: string;
  devicePartitionInfo: Tdriveinfo;
  user: ansistring;
  Destname: ansistring;
  device: string;
  basicthreads: integer;
  messageuserinfo: boolean = False;


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
  if (key = #127) or (key = #8) then exit;  // #127 = Delete   #8 = Backspace
  Key := UpCase(Key);
  if (not CheckBoxChangeDeviceID.Checked) or (not (Key in ['0'..'9', 'A'..'F'])) then
    Key := #0;  // ungültige Taste unterdrücken
end;


procedure TForm1.ScrollBar1Change(Sender: TObject);
begin
  GridUpdate(scrollbar1);
end;


procedure TForm1.readDeviceInfo(drive: string; var deviceinfo: Tdriveinfo);
var
  s: string;
  json: TJSONData;
  root, child: TJSONData;
  i: integer;
  mbr: TMBR;

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
    deviceinfo.partinfo[i].parttype := '';
    deviceinfo.partinfo[i].mountpoint := '';
    deviceinfo.partinfo[i].partlabel := '';
    deviceinfo.partinfo[i].start := '';
    deviceinfo.partinfo[i].size := '';
  end;

  if Pos('/dev/', drive) <> 1 then Exit;

  // =========================================================
  // 1. MBR LESEN (WICHTIG!)
  // =========================================================
  mbr := Read_MBR(drive);  // eigene Funktion wie bei dir für Images

  // Disk selbst
  deviceinfo.partinfo[0].Name := Copy(drive, 6, 255);

  // =========================================================
  // 2. PARTITIONEN AUS MBR
  // =========================================================
  for i := 1 to 4 do
  begin
    if mbr.PartitionEntries[i].PartitionType <> $00 then
    begin
      deviceinfo.partinfo[i].Name :=
        deviceinfo.partinfo[0].Name + IntToStr(i);

      deviceinfo.partinfo[i].start :=
        IntToStr(mbr.PartitionEntries[i].FirstLBA);

      deviceinfo.partinfo[i].size :=
        IntToStr(mbr.PartitionEntries[i].PartitionSize);

      deviceinfo.partinfo[i].parttype :=
        GetMBRPartitionTypeName(mbr.PartitionEntries[i].PartitionType);
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

        // FS nur ergänzend anzeigen
        if deviceinfo.partinfo[i + 1].parttype <> '' then
        begin
          if SafeGet(child, 'fstype') <> '' then
            deviceinfo.partinfo[i + 1].parttype :=
              deviceinfo.partinfo[i + 1].parttype + ' (' + SafeGet(child, 'fstype') + ')';
        end;
      end;
    end;
    json.Free;
  end;
end;


function GetDeviceSizeSectors(const device: string): int64;
var
  f: TextFile;
  sectors: string;
  dev: string;
begin
  //Result := '0';
  // /dev/sda → sda
  dev := ExtractFileName(device);
  AssignFile(f, '/sys/block/' + dev + '/size');
  Reset(f);
  ReadLn(f, sectors);
  Result := strtoint64(sectors);
  CloseFile(f);
end;




function ValueFromGrid(StringGrid: TStringGrid; x, y: integer): int64;
var
  s, val: string;
  p, p2: integer;
  res: int64;
begin
  Result := -1;
  s := Trim(StringGrid.Cells[x, y]);

  // erste Ziffer suchen
  p := 1;
  while (p <= Length(s)) and not (s[p] in ['0'..'9', '-']) do
    Inc(p);

  // keine Zahl gefunden
  if p > Length(s) then
    Exit;

  // Ende der Zahl suchen
  p2 := p;
  if s[p2] = '-' then Inc(p2); // Minus berücksichtigen

  while (p2 <= Length(s)) and (s[p2] in ['0'..'9']) do
    Inc(p2);

  // Zahl extrahieren
  val := Copy(s, p, p2 - p);

  // konvertieren
  if not TryStrToInt64(val, Res) then
    exit;
  Result := res;
end;




function TestMountImagePartitionDirect(const image: string; entry: TMBRPartition): boolean;
var
  offset: int64;
  output: string;
begin
  Result := False;

  offset := entry.FirstLBA * 512;

  if RunCommand(Format('mount -o loop,ro,noload,offset=%d "%s" /tmp/testmount', [offset, image]), output) then
  begin
    Result := True;
    RunCommand('umount /tmp/testmount', output);
  end;
end;


function Tform1.BuildFinalMBR: TMBR;
var
  size: int64;
  p: integer;
  drivembr, imagembr: tmbr;
  drive: string;

  function IsTarget(row: integer): boolean;
  begin
    Result := Pos('(TARGET)', UpperCase(StringGrid1.Cells[0, row])) > 0;
  end;

begin
  drive := '';
  p := Pos(':', ComboBox1.Text);
  drive := Copy(ComboBox1.Text, 1, p - 1);
  drivembr := read_mbr(drive);

  if FileExists(Edit1.Text) then  imagembr := Read_MBR(Edit1.Text);


  // -----------------------------------------
  // P1 + P2 kommen IMMER aus Image
  // -----------------------------------------
  Result := ImageMBR;

  // -----------------------------------------
  // EINZIGE erlaubte Änderung: P2 Size
  // -----------------------------------------
  size := ValueFromGrid(StringGrid1, 5, 3);
  if size > 0 then
    Result.PartitionEntries[2].PartitionSize := size;

  // -----------------------------------------
  // P3 + P4 abhängig vom Grid
  // -----------------------------------------
  if IsTarget(4) then
    Result.PartitionEntries[3] := DriveMBR.PartitionEntries[3]
  else
    Result.PartitionEntries[3] := ImageMBR.PartitionEntries[3];

  if IsTarget(5) then
    Result.PartitionEntries[4] := DriveMBR.PartitionEntries[4]
  else
    Result.PartitionEntries[4] := ImageMBR.PartitionEntries[4];
end;

function FitsOnDevice(const Part: TMBRPartition; DeviceSectors: int64): boolean;
var
  endLBA: int64;
begin
  if Part.PartitionSize = 0 then
    Exit(False);

  endLBA := Part.FirstLBA + Part.PartitionSize - 1;
  Result := endLBA <= DeviceSectors;
end;



procedure TForm1.GridUpdate(Sender: TObject);
var
  y, p, n: integer;
  drive, s: string;

  devSec, first_used_sector, free_sectors, scrollbar_max: int64;
  imagembr, drivembr: TMbr;
  startpar2, startpar3, startpar4, par2gridsize: integer;

  isExtended: boolean;
  sizepar2, scrollbar_min: System.DWord;
  //  : System.DWord;

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

begin

  if RadioButton1.Checked then
  begin
    StringGrid1.Clean;
    // =========================================================
    // DEVICE ERMITTELN
    // =========================================================
    drive := '';
    p := Pos(':', ComboBox1.Text);
    drive := Copy(ComboBox1.Text, 1, p - 1);

    ReadDeviceInfo(drive, devicePartitionInfo);
    drivembr := read_mbr(drive);

    // =========================================================
    // GRID HEADER
    // =========================================================
    StringGrid1.Clean;

    StringGrid1.Cells[0, 0] := 'NAME';
    StringGrid1.Cells[1, 0] := 'LABEL';
    StringGrid1.Cells[2, 0] := 'FSTYPE';
    StringGrid1.Cells[3, 0] := 'MOUNTPOINT';
    StringGrid1.Cells[4, 0] := 'STARTSECTOR';
    StringGrid1.Cells[5, 0] := '   SECTORS / MiB';

    devSec := GetDeviceSizeSectors(drive);

    StringGrid1.Cells[0, 1] := drive;
    StringGrid1.Cells[5, 1] := FormatSecMiB(devSec);

    // =========================================================
    // DEVICE PARTITIONEN (IST)
    // =========================================================
    for y := 1 to 4 do
    begin
      StringGrid1.Cells[0, y + 1] := devicePartitionInfo.partinfo[y].Name;
      StringGrid1.Cells[1, y + 1] := devicePartitionInfo.partinfo[y].partlabel;
      StringGrid1.Cells[2, y + 1] := devicePartitionInfo.partinfo[y].parttype;
      StringGrid1.Cells[3, y + 1] := devicePartitionInfo.partinfo[y].mountpoint;

      StringGrid1.Cells[4, y + 1] :=
        PadLeft(devicePartitionInfo.partinfo[y].start, 10);

      s := devicePartitionInfo.partinfo[y].size;
      StringGrid1.Cells[5, y + 1] :=
        FormatSecMiB(StrToInt64Def(s, 0));
    end;

  end
  else

  begin
    // =========================================================
    // IMAGE MODE
    // =========================================================
    if lowercase(extractfileext(edit1.Text)) = '.zst' then
      if not messageuserinfo then
      begin
        Listboxaddscroll(listbox1, 'User settings, Wi-Fi settings, and hostname can only be read from uncompressed .img files.');
        Listboxaddscroll(listbox1, 'However, settings can still be applied without any limitations.');
        Listboxaddscroll(listbox1, 'If values are not changed, the existing settings will be preserved.');
        messageuserinfo := True;
      end;
    ReadUserInfo(edit1.Text);
    StringGrid1.Clean;

    StringGrid1.Cells[0, 0] := 'NAME';
    StringGrid1.Cells[1, 0] := 'LABEL';
    StringGrid1.Cells[2, 0] := 'FSTYPE';
    StringGrid1.Cells[3, 0] := 'MOUNTPOINT';
    StringGrid1.Cells[4, 0] := 'STARTSECTOR';
    StringGrid1.Cells[5, 0] := '   SECTORS / MiB';


    fillchar(imagembr, sizeof(imagembr), 0);

    if FileExists(Edit1.Text) then
    begin
      imagembr := Read_MBR(Edit1.Text);
      Eddeviceid.Text := hexstr(imagembr.DiskSignature, 8);



      // -------------------------
      // P1 / P2 (IMAGE DIREKT)
      // -------------------------
      for y := 1 to 2 do
      begin
        StringGrid1.Cells[2, y + 1] :=
          GetMBRPartitionTypeName(imagembr.PartitionEntries[y].PartitionType);

        StringGrid1.Cells[4, y + 1] :=
          PadLeft(IntToStr(imagembr.PartitionEntries[y].FirstLBA), 12);

        StringGrid1.Cells[5, y + 1] :=
          FormatSecMiB(imagembr.PartitionEntries[y].PartitionSize);
      end;
      StringGrid1.Cells[0, 2] := 'File_P1';
      StringGrid1.Cells[0, 3] := 'File_P2';
      StringGrid1.Cells[1, 2] := 'bootfs';
      StringGrid1.Cells[1, 3] := 'rootfs';
    end;



    drive := '';
    p := Pos(':', ComboBox1.Text);
    drive := Copy(ComboBox1.Text, 1, p - 1);
    if drive = '' then exit;

    fillchar(drivembr,sizeof(drivembr),0);
    drivembr := read_mbr(drive);

    ReadDeviceInfo(drive, devicePartitionInfo);
    devSec := GetDeviceSizeSectors(drive);

    StringGrid1.Cells[0, 1] := drive;
    StringGrid1.Cells[5, 1] := FormatSecMiB(devSec);


    // =========================================================
    // DEVICE PARTITIONEN (IST)
    // =========================================================
    for y := 3 to 4 do
    begin
      StringGrid1.Cells[0, y + 1] := devicePartitionInfo.partinfo[y].Name;
      StringGrid1.Cells[1, y + 1] := devicePartitionInfo.partinfo[y].partlabel;
      StringGrid1.Cells[2, y + 1] := devicePartitionInfo.partinfo[y].parttype;
      StringGrid1.Cells[3, y + 1] := devicePartitionInfo.partinfo[y].mountpoint;


      StringGrid1.Cells[4, y + 1] :=
        PadLeft(devicePartitionInfo.partinfo[y].start, 12);

      s := devicePartitionInfo.partinfo[y].size;
      StringGrid1.Cells[5, y + 1] :=
        FormatSecMiB(StrToInt64Def(s, 0));
    end;

     // -------------------------
    // P3 / P4 LOGIK
    // -------------------------
    for y := 3 to 4 do
    begin
      // DEVICE HAT PRIORITÄT
      if drivembr.PartitionEntries[y].PartitionType <> 0 then
      begin
        StringGrid1.Cells[0, y + 1] :=
          devicePartitionInfo.partinfo[y].Name + ' (TARGET)';

        StringGrid1.Cells[2, y + 1] :=
          devicePartitionInfo.partinfo[y].parttype;

        StringGrid1.Cells[4, y + 1] :=
          PadLeft(devicePartitionInfo.partinfo[y].start, 12);

        StringGrid1.Cells[5, y + 1] :=
          FormatSecMiB(StrToInt64Def(devicePartitionInfo.partinfo[y].size, 0));
      end
      else
      begin
        // IMAGE FALLBACK

        if not FitsOnDevice(imagembr.PartitionEntries[y], devSec) then
        begin
          // ❌ passt nicht aufs Device → komplett verwerfen
          for n := 0 to 5 do
            StringGrid1.Cells[n, y + 1] := '';
          Continue;
        end;


        isExtended := IsItExtended(imagembr.PartitionEntries[y].PartitionType);

        if isExtended then
        begin
          StringGrid1.Cells[0, y + 1] :=
            'File_P' + IntToStr(y) + ' (EXTENDED)';

          StringGrid1.Cells[2, y + 1] :=
            GetMBRPartitionTypeName(imagembr.PartitionEntries[y].PartitionType);

          StringGrid1.Cells[4, y + 1] :=
            PadLeft(IntToStr(imagembr.PartitionEntries[y].FirstLBA), 12);

          StringGrid1.Cells[5, y + 1] :=
            FormatSecMiB(imagembr.PartitionEntries[y].PartitionSize);
        end
        else
        begin
          if TestMountImagePartitionDirect(Edit1.Text, imagembr.PartitionEntries[y]) then
            StringGrid1.Cells[0, y + 1] :=
              'File_P' + IntToStr(y) + ' (IMAGE OK)'
          else
            StringGrid1.Cells[0, y + 1] :=
              'File_P' + IntToStr(y) + ' (IMAGE)';

          StringGrid1.Cells[2, y + 1] :=
            GetMBRPartitionTypeName(imagembr.PartitionEntries[y].PartitionType);

          StringGrid1.Cells[4, y + 1] :=
            PadLeft(IntToStr(imagembr.PartitionEntries[y].FirstLBA), 12);

          StringGrid1.Cells[5, y + 1] :=
            FormatSecMiB(imagembr.PartitionEntries[y].PartitionSize);
        end;
      end;
    end;

    if CheckBox_DelPartition3.Checked then
      for n := 0 to 5 do StringGrid1.Cells[n, 4] := '';

    if CheckBox_DelPartition4.Checked then
      for n := 0 to 5 do StringGrid1.Cells[n, 5] := '';


    // =========================================================
    // FREIER PLATZ + P2 SIZE LOGIK (UNVERÄNDERT)
    // =========================================================


    if not FileExists(Edit1.Text) then  exit;


    startpar2 := imagembr.PartitionEntries[2].FirstLBA;
    startpar3 := ValueFromGrid(StringGrid1, 4, par3);
    startpar4 := ValueFromGrid(StringGrid1, 4, par4);
    sizepar2 := imagembr.PartitionEntries[2].PartitionSize;

    first_used_sector := devSec;
    if (startpar4 > 0) and (startpar4 < first_used_sector) then  first_used_sector := startpar4;
    if (startpar3 > 0) and (startpar3 < first_used_sector) then  first_used_sector := startpar3;

    free_sectors := first_used_sector - startpar2;

    Label_ManSelected.Caption := '';
    if free_sectors < sizepar2 then
    begin
      ScrollBar1.Min := 0;
      ScrollBar1.Max := 0;
      ScrollBar1.Position := 0;
      Label_ManSelected.Caption := 'not enough free space';
      Exit;
    end;

    scrollbar_min := (sizepar2 + 2047) div 2048;   //gerundet auf volle mb
    scrollbar_max := (free_sectors + 2047) div 2048;

    ScrollBar1.Min := 0;
    if Sender <> scrollbar1 then  ScrollBar1.Position := 0;
    ScrollBar1.Max := scrollbar_max;
    ScrollBar1.Min := scrollbar_min;
    if Sender <> scrollbar1 then  ScrollBar1.Position := scrollbar_max;

    // size ins grid eintragen
    par2gridsize := scrollbar1.Position * 2048;
    if par2gridsize > free_sectors then par2gridsize := free_sectors;
    StringGrid1.Cells[parsize, par2] := FormatSecMiB(par2gridsize);

    if not CheckBoxChangeDeviceID.Checked then
      Eddeviceid.Text := IntToHex(imagembr.DiskSignature, 8);
  end;

  Label_ManSelected.Caption := IntToStr(scrollbar1.Position) + 'MiB';;

  checkbox_delpartition3.Visible := stringgrid1.Cells[0, 4] > '';
  checkbox_delpartition4.Visible := stringgrid1.Cells[0, 5] > '';

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


procedure TForm1.RadioButton2Change(Sender: TObject);
begin
  if radiobutton2.Checked then
  begin
    Label2.Caption := 'Target Device';
    combobox1.Items.Clear;
    application.ProcessMessages;
    panel1.Visible := False;;
    panel2.Visible := True;
    panel2.BringToFront;
    application.ProcessMessages;
    getdrives(combobox1.Items, True);
    combobox1.ItemIndex := 0;;
    if not fileexists(edit1.Text) then Edit1.Text := '';
    GridUpdate(Sender);
  end
  else
  begin
    panel1.Visible := True;
    panel2.Visible := False;;
    getdrives(combobox1.Items, False);
    Label2.Caption := 'Source Device';
    panel1.Visible := True;
    panel1.BringToFront;
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
  if s > '' then edit1.Text := s;
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

  // cleanup

  CloseMountTarget(p1mpoint);
  CloseMountTarget(p2mpoint);
end;

procedure TForm1.lbl_userpasswordClick(Sender: TObject);
begin

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



procedure TForm1.ButtonCreateImageClick(Sender: TObject);
var
  filename, sourcedrive, s, mp: ansistring;
  NewBlockCount: int64;
  blocksize: integer;
  deststream: TFileStream = nil;
  mbrwork: TMbr;
  sectorsperblock, p, p1: integer;
  dirpath: string;
  looppartition: string;
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
  ListBoxaddscroll(listbox1, 'Create image');
  Application.ProcessMessages;
  write_ini;

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

    mbrwork := Read_MBR(sourcedrive);
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




function MakeFstab(fstabImage, fstabDrive: TStringList; oldSig, newSig: string): TStringList;
var
  i: integer;
  line: string;
  hasP3: boolean;
  driveEntries: TStringList;
begin
  Result := TStringList.Create;
  driveEntries := TStringList.Create;
  try

    // -----------------------------------
    // 1. p3+ aus DRIVE sammeln
    // -----------------------------------
    hasP3 := False;

    for i := 0 to fstabDrive.Count - 1 do
    begin
      line := fstabDrive[i];

      if (Pos('PARTUUID=', line) > 0) and (Pos('/boot', line) = 0) and (Pos(' / ', line) = 0) then
      begin
        line := StringReplace(line, oldSig, newSig, [rfReplaceAll]);
        driveEntries.Add(line);
        hasP3 := True;
      end;
    end;

    // -----------------------------------
    // 2. IMAGE übernehmen (p1/p2 + fallback p3)
    // -----------------------------------
    for i := 0 to fstabImage.Count - 1 do
    begin
      line := fstabImage[i];

      // System bleibt unverändert
      if (Pos(' / ', line) > 0) or (Pos('/boot', line) > 0) then
      begin
        Result.Add(line);
        continue;
      end;

      // p3+ aus DRIVE hat Vorrang
      if hasP3 then
      begin
        Result.AddStrings(driveEntries);
        hasP3 := False; // nur einmal einfügen
      end
      else
      begin
        // fallback: Image behalten
        Result.Add(line);
      end;
    end;

  finally
    driveEntries.Free;
  end;
end;


function ReadFstabFromImageP2(const ImageFile: string): TStringList;
var
  offset: int64;
  cmd, output: string;
  loopDev: string;
  mbr: tmbr;
begin
  mbr := Read_mbr(ImageFile);
  Result := TStringList.Create;
  loopDev := '';

  try
    // -----------------------------------------
    // 1. p2 Offset berechnen (rootfs)
    // -----------------------------------------
    offset := MBR.PartitionEntries[2].FirstLBA * 512;

    // -----------------------------------------
    // 2. Image als loop device mit offset binden
    // -----------------------------------------
    cmd := 'losetup -f --show -o ' + IntToStr(offset) + ' ' + ImageFile;
    if not RunCommand(cmd, output) then
      Exit;

    loopDev := Trim(output);  // z.B. /dev/loop0

    // -----------------------------------------
    // 3. read-only mount
    // -----------------------------------------
    cmd := 'mount -o ro ' + loopDev + ' /mnt/img';
    if not RunCommand(cmd, output) then
      Exit;

    try
      // -----------------------------------------
      // 4. fstab lesen
      // -----------------------------------------
      Result.LoadFromFile('/mnt/img/etc/fstab');

    finally
      // -----------------------------------------
      // 5. unmount
      // -----------------------------------------
      RunCommand('umount /mnt/img', output);
    end;

  finally
    // -----------------------------------------
    // 6. loop device freigeben
    // -----------------------------------------
    if loopDev <> '' then
      RunCommand('losetup -d ' + loopDev, output);
  end;
end;

function ReadFstabFromDeviceP2(const Device: string): TStringList;
var
  cmd, output: string;
begin
  Result := TStringList.Create;

  try
    // -----------------------------------------
    // 1. Mountpoint sicherstellen
    // -----------------------------------------
    RunCommand('mkdir -p /mnt/dev', output);

    // -----------------------------------------
    // 2. p2 mounten (rootfs)
    // -----------------------------------------
    cmd := 'mount ' + Device + '2 /mnt/dev';
    if not RunCommand(cmd, output) then
      Exit;

    try
      // -----------------------------------------
      // 3. fstab lesen
      // -----------------------------------------
      Result.LoadFromFile('/mnt/dev/etc/fstab');

    finally
      // -----------------------------------------
      // 4. unmount (immer!)
      // -----------------------------------------
      RunCommand('umount /mnt/dev', output);
    end;

  except
    on e: Exception do
    begin
      Result.Free;
      Result := nil;
    end;
  end;
end;

function WriteFstabToDeviceP2(const Device: string; newfstab: TStringList): boolean;
var
  output: string;
  filename: string;
begin
  Result := False;

  try
    // -----------------------------------------
    // 1. Mountpoint sicherstellen
    // -----------------------------------------
    RunCommand('mkdir -p /mnt/dev', output);

    // -----------------------------------------
    // 2. p2 mounten (rootfs)
    // -----------------------------------------
    if not RunCommand('mount ' + Device + '2 /mnt/dev', output) then
      Exit;

    try
      filename := '/mnt/dev/etc/fstab';

      // -----------------------------------------
      // 3. Backup optional (sehr empfohlen)
      // -----------------------------------------
      if FileExists(filename) then
        RunCommand('cp ' + filename + ' ' + filename + '.bak', output);

      // -----------------------------------------
      // 4. neue fstab schreiben
      // -----------------------------------------
      newfstab.SaveToFile(filename);

      Result := True;

    finally
      // -----------------------------------------
      // 5. unmount immer
      // -----------------------------------------
      RunCommand('umount /mnt/dev', output);
    end;

  except
    on e: Exception do
      Result := False;
  end;
end;



procedure TForm1.ButtonWriteImagetodeviceClick(Sender: TObject);
var
  newmbr, oldmbr: TMbr;
  s, par2name, par1name: string;
  sig: dword;

  oldsig, newsig: string;
  fstabimage, fstabdrive, newfstab: TStringList;
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
    CloseMountTarget(par1name);

    runcommand('sync', s);

    s := PrexeThreadedBash('partprobe ' + selecteddrive, listbox1);

    Listboxaddscroll(listbox1, '---------- write image to device: ' + selecteddrive + ' ----------');
    Listboxaddscroll(listbox1, '');


    oldmbr := read_mbr(selecteddrive);
    oldsig := lowercase(hexstr(oldmbr.DiskSignature, 8));

    // fstab aus image

    fstabimage := ReadFstabFromImageP2(edit1.Text);

    fstabdrive := ReadFstabFromDeviceP2(selecteddrive);

    newfstab := MakeFstab(fstabImage, fstabDrive, oldSig, newSig);

    ImageToDeviceImgAndZstd(edit1.Text, selecteddrive, listbox1);     // keinen mbr schreiben

    newmbr := BuildFinalMBR;
    newsig := lowercase(hexstr(newmbr.DiskSignature, 8));
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

    //  newfstab schreiben
    WriteFstabToDeviceP2(selecteddrive, newfstab);


    Application.ProcessMessages;

    if CheckBoxChangeDeviceID.Checked then
    begin
      newsig := lowercase(Eddeviceid.Text);


      //  if oldsig <> newsig then
      //       begin
      sig := StrToInt('$' + newsig);
      ListBoxaddscroll(listbox1, 'Change device signature in mbr');
      ReplacePartUUIDinMbr(selecteddrive, sig);

      ListBoxaddscroll(listbox1, 'Change device signature in cmdline.txt');
      s := ReplacePartUUIDInCmdline(selecteddrive, newsig + '-02');
      if s > '' then ListBox1.Items.Add(s);

      ListBoxaddscroll(listbox1, 'Change Partitionuuids in fstab');
      s := ReplacePartUUIDInFstab(selecteddrive, oldsig, newsig);
      if s > '' then ListBox1.Items.Add(s);

    end;


    if edhost.Text > '' then Changehost(selecteddrive, edhost.Text);
    if CBEnableSSH.Checked then EnableSSH(selecteddrive);
    if (edusername.Text > '') and (eduserpassword.Text > '') then
      CreateUserConfFromDevice(selecteddrive, EDusername.Text, EDuserpassword.Text, ListBox1);

    if (Edit_wlanssid.Text > '') and (Edit_wlanpassword.Text > '') then
      PrepareWLAN(selecteddrive, edit_wlanssid.Text, edit_wlanpassword.Text);

    Listboxaddscroll(listbox1, '---------- all done ----------');
    Listboxaddscroll(listbox1, '');

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
  ReleaseCapture;
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



procedure TForm1.EddeviceidChange(Sender: TObject);
var
  s: string;
begin
  s := Eddeviceid.Text;
  s := copy(s, 1, 8);
  Eddeviceid.Text := s;
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


end.
