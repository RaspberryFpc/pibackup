unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin, Grids,
  Process, inifiles, fileutil, lazutf8, Unix, baseunix, LCLIntf, rkutils,zstd,
  LCLType, MaskEdit, ExtCtrls, excludeParser, DateUtils, fpjson;

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
    Button5: TButton;
    Button2: TButton;
    Button4: TButton;
    ButtonCreateImage: TButton;
    ButtonWriteImage: TButton;
    CheckBox1: TCheckBox;
    CheckBox12: TCheckBox;
    CheckBox_Delimg: TCheckBox;
    CheckBox_exclude: TCheckBox;
    CheckBox_RemoveSSH: TCheckBox;
    CheckBox_RemoveDHCP: TCheckBox;
    CheckBox_DelPartition3: TCheckBox;
    CheckBox_DelPartition4: TCheckBox;
    ComboBox1: TComboBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    Label_ManSelected: TLabel;
    ListBox1: TListBox;
    OpenDialog1: TOpenDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    SaveDialog1: TSaveDialog;
    ScrollBar1: TScrollBar;
    SpinEdit1: TSpinEdit;
    StringGrid1: TStringGrid;
    procedure ButtonCreateImageClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure ButtonWriteImageClick(Sender: TObject);
    procedure Edit1DblClick(Sender: TObject);
    procedure Edit3Change(Sender: TObject);
    procedure Edit3KeyPress(Sender: TObject; var Key: char);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure RadioButton1Change(Sender: TObject);
    procedure RadioButton2Change(Sender: TObject);
    procedure ScrollBar1Change(Sender: TObject);
    function ModifyImage(mountpoint: string): boolean;
    function InstallMissingRoutines: boolean;
    procedure write_ini;
    procedure checkboxClick(Sender: TObject);
    procedure CompressWithProgress(const infile: string; level: integer; LBox: TListBox);
    procedure readDeviceInfo(drive: string; var deviceinfo: Tdriveinfo);
    procedure GridUpdate(Sender: TObject);

  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.frm}

{ TForm1 }

const
  appname = 'PiBackupTool';
  ininame = 'pbt.ini';
  mpoint = '/images/pbt_img';

  par1 = 2;
  par2 = 3;
  par3 = 4;
  par4 = 5;
  parstart = 4;
  parsize = 5;
  parname = 0;
  parLABEL = 1;
  partype = 2;
  parMOUNTPOINT = 3;

var
  selecteddrive: string;
  devicePartitionInfo: Tdriveinfo;
  user: ansistring;
  Destname: ansistring;
  FirstAktiv: boolean = True;
  device: string;



procedure TForm1.readDeviceInfo(drive: string; var deviceinfo: Tdriveinfo);
var
  s: string;
  json: TJSONData;
  root, child: TJSONData;
  i: integer;

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
  // Initialisieren
  for i := 0 to 4 do
  begin
    deviceinfo.partinfo[i].Name := '';
    deviceinfo.partinfo[i].parttype := '';
    deviceinfo.partinfo[i].mountpoint := '';
    deviceinfo.partinfo[i].partlabel := '';
    deviceinfo.partinfo[i].start := '';
    deviceinfo.partinfo[i].size := '';
  end;

  if Pos('/dev/', drive) = 1 then
  begin
    if not RunCommand('lsblk ' + drive + ' -b -J -o NAME,LABEL,FSTYPE,MOUNTPOINT,START,SIZE', s) then
      Exit;

    json := GetJSON(s);

    deviceinfo.partinfo[0].Name := SafeGet(json, 'blockdevices[0].name');
    deviceinfo.partinfo[0].size := PadLeft(SafeGet(json, 'blockdevices[0].size'), 16);

    root := json.FindPath('blockdevices[0]');
    if root = nil then
    begin
      json.Free;
      Exit;
    end;

    if root.FindPath('children') <> nil then
    begin
      for i := 0 to root.FindPath('children').Count - 1 do
      begin
        if i > 3 then Break; // Maximal 4 Einträge
        child := root.FindPath('children[' + IntToStr(i) + ']');

        deviceinfo.partinfo[i + 1].Name := SafeGet(child, 'name');
        deviceinfo.partinfo[i + 1].partlabel := SafeGet(child, 'label');
        deviceinfo.partinfo[i + 1].parttype := SafeGet(child, 'fstype');
        deviceinfo.partinfo[i + 1].mountpoint := SafeGet(child, 'mountpoint');
        deviceinfo.partinfo[i + 1].start := SafeGet(child, 'start');
        deviceinfo.partinfo[i + 1].size := SafeGet(child, 'size');
      end;
    end;

    json.Free;
    deviceinfo.partinfo[0].Name := Copy(drive, 6, 255); // Überschreibt ggf. Namen mit sda etc.
  end;
end;


procedure TForm1.Edit3KeyPress(Sender: TObject; var Key: char);
begin
  if (key=#127) or (key=#8) then exit;  // #127 = Delete   #8 = Backspace
  Key := UpCase(Key);
  if (not CheckBox12.Checked) or (not (Key in ['0'..'9', 'A'..'F'])) then
   Key := #0;  // ungültige Taste unterdrücken
end;



procedure TForm1.ScrollBar1Change(Sender: TObject);
begin
  GridUpdate(scrollbar1);
end;



var
  drive: string;
  p, y, col: integer;
  s: string;
  imagembr: tmbr;
  availableSectors, minimumSectors: int64;
  minsec1MB,manuellsize,par2Size,scrollrange,av: int64;

    procedure Tform1.GridUpdate(Sender: TObject);

begin
  // Bei ScrollBar-Änderung nur die Größe aktualisieren
  if Sender = ScrollBar1 then
  begin
    manuellsize:=minsec1mb + ScrollBar1.Position;
    Label_ManSelected.Caption := IntToStr(manuellsize)  + ' MB';
    par2Size := manuellsize * 1024 * 1024 - imagembr.PartitionEntries[2].FirstLBA * 512;  // in bytes
    StringGrid1.Cells[parsize, par2] := PadLeft(IntToStr(par2Size), 16);
    Exit;
  end;

  // Gerät ermitteln
  p := Pos(':', ComboBox1.Text);
  drive := Copy(ComboBox1.Text, 1, p - 1);
  ReadDeviceInfo(drive, devicePartitionInfo);

  // Grid neu aufbauen
  StringGrid1.Clean;
  StringGrid1.Cells[0, 0] := 'NAME';
  StringGrid1.Cells[1, 0] := 'LABEL';
  StringGrid1.Cells[2, 0] := 'FSTYPE';
  StringGrid1.Cells[3, 0] := 'MOUNTPOINT';
  StringGrid1.Cells[4, 0] := 'STARTSECTOR';
  StringGrid1.Cells[5, 0] := 'SIZE Bytes';

  for y := 0 to 4 do
  begin
    StringGrid1.Cells[0, y + 1] := devicePartitionInfo.partinfo[y].Name;
    StringGrid1.Cells[1, y + 1] := devicePartitionInfo.partinfo[y].partlabel;
    StringGrid1.Cells[2, y + 1] := devicePartitionInfo.partinfo[y].parttype;
    StringGrid1.Cells[3, y + 1] := devicePartitionInfo.partinfo[y].mountpoint;
    s := devicePartitionInfo.partinfo[y].start;
    while Length(s) < 12 do s := ' ' + s;
    StringGrid1.Cells[4, y + 1] := s;
    s := devicePartitionInfo.partinfo[y].size;
    while Length(s) < 16 do s := ' ' + s;
    StringGrid1.Cells[5, y + 1] := s;
  end;

  // Schreibe Image-Infos in Grid
  if RadioButton2.Checked then
  begin
    if Read_MBR(Edit1.Text, imagembr) then
    begin
      // Partition 1 (Boot)
      StringGrid1.Cells[parname, par1] := 'File_P1';
      StringGrid1.Cells[parlabel, par1] := 'boot';
      StringGrid1.Cells[partype, par1] := GetMBRPartitionTypeName(imagembr.PartitionEntries[1].PartitionType);
      StringGrid1.Cells[parmountpoint, par1] := '';
      StringGrid1.Cells[parstart, par1] := PadLeft(IntToStr(imagembr.PartitionEntries[1].FirstLBA), 12);
      StringGrid1.Cells[parsize, par1] := PadLeft(IntToStr(imagembr.PartitionEntries[1].PartitionSize * 512), 16);

      // Partition 2 (Root)
      StringGrid1.Cells[parname, par2] := 'File_P2';
      StringGrid1.Cells[parlabel, par2] := 'root';
      StringGrid1.Cells[partype, par2] := GetMBRPartitionTypeName(imagembr.PartitionEntries[2].PartitionType);
      StringGrid1.Cells[parmountpoint, par2] := '';
      StringGrid1.Cells[parstart, par2] := PadLeft(IntToStr(imagembr.PartitionEntries[2].FirstLBA), 12);
      StringGrid1.Cells[parsize, par2] := PadLeft(IntToStr(imagembr.PartitionEntries[2].PartitionSize * 512), 16);

      // Partition 3 ggf. löschen
      if CheckBox_DelPartition3.Checked then
        for col := 0 to StringGrid1.ColCount - 1 do
          StringGrid1.Cells[col, par3] := '';

      // Partition 4 ggf. löschen
      if CheckBox_DelPartition4.Checked then
        for col := 0 to StringGrid1.ColCount - 1 do
          StringGrid1.Cells[col, par4] := '';

      // === Verfügbaren Platz berechnen ===
      availableSectors  := StrToInt64(StringGrid1.Cells[parsize,1]) div 512; // Gerätegröße in Sektoren
       if Trim(StringGrid1.Cells[parstart, par3]) <> '' then
             begin
             av:=StrToInt64(Trim(StringGrid1.Cells[parstart, par3]));
             if availableSectors > AV then availableSectors := av;
             end;
       if Trim(StringGrid1.Cells[parstart, par4]) <> '' then
             begin
             av:=StrToInt64(Trim(StringGrid1.Cells[parstart, par4]));
             if availableSectors > AV then  availableSectors := av;
             end;
     // Minimalplatz (für das gesamte Image bis Partition 2 Ende)
      minimumSectors := imagembr.PartitionEntries[2].FirstLBA + imagembr.PartitionEntries[2].PartitionSize;

      minsec1MB:= (minimumSectors+2047) div 2048;    // min sector auf 1mb aufgerundet

      if availableSectors < minsec1mb then
      begin
        ScrollBar1.Min := 0;
        ScrollBar1.Max := 0;
        ScrollBar1.Position := 0;
        Label_ManSelected.Caption := 'not enough free space';
        Exit;
      end;

      scrollrange:= availableSectors div 2048 - minsec1mb; // 1mb steps
      ScrollBar1.Min :=0;
      ScrollBar1.Max := scrollrange;
      ScrollBar1.Position := scrollrange;  // auf maximum

      // Anzeige & Größe aktualisieren

      manuellsize:=minsec1mb + ScrollBar1.Position;
      Label_ManSelected.Caption := IntToStr(manuellsize)  + ' MB';

      par2Size := manuellsize * 1024 * 1024 - imagembr.PartitionEntries[2].FirstLBA * 512;  // in bytes
      StringGrid1.Cells[parsize, par2] := PadLeft(IntToStr(par2Size), 16);
    end;
  end;


  // Disk Signature setzen
  if not CheckBox12.Checked then
  begin
    s := IntToHex(imagembr.DiskSignature, 8);
    Edit3.Text := s;
  end;
end;



procedure TForm1.RadioButton1Change(Sender: TObject);
begin
  if radiobutton1.Checked then
     begin
     panel1.Visible := true;
     panel1.BringToFront;
     end else
     panel1.Visible := false;
  GridUpdate(Sender);
end;

procedure TForm1.RadioButton2Change(Sender: TObject);
begin
  if radiobutton2.Checked then
     begin
     panel2.Visible := true;
     panel2.BringToFront;
     end else
     panel2.Visible := false;
  GridUpdate(Sender);
end;



procedure TForm1.CheckBoxClick(Sender: TObject);
var
  i: integer;
  Clicked: TCheckBox;
begin
  Clicked := TCheckBox(Sender);
  if not Clicked.Checked then
  begin
    // Temporär OnClick-Handler entfernen, um Endlosschleife zu vermeiden
    Clicked.OnClick := nil;
    Clicked.Checked := True;
    Clicked.OnClick := @CheckBoxClick;
    Exit;
  end;

  // Alle anderen Checkboxen deaktivieren
  for i := 0 to ComponentCount - 1 do
  begin
    if (Components[i] is TCheckBox) and (Components[i] <> Clicked) then
    begin
      TCheckBox(Components[i]).OnClick := nil;
      TCheckBox(Components[i]).Checked := False;
      TCheckBox(Components[i]).OnClick := @CheckBoxClick;
    end;
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
  ini.Writeinteger('Option', 'compresslevel',spinedit1.value);
  ini.Free;
end;


function TForm1.InstallMissingRoutines: boolean;
var
  zstdinstalled, installdone: boolean;
begin
  installdone := False;
  Result := False;
  zstdinstalled := isproginstalled('zstd');


  if not zstdinstalled then
  begin
    if MessageDlg('Question', 'Zstd is used for compression.'#13#10'Zstd was not found on your system.'#13#10'Would you like to install it?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin

      Listboxaddscroll(listbox1,starline('Installing zstd', 80));

      PrexeBash('apt-get update && sudo apt upgrade -y',listbox1);
      PrexeBash('apt-get -y -q install zstd',listbox1);
      installdone := True;
    end;
  end;
  zstdinstalled := isproginstalled('zstd');
  if not zstdinstalled then Listboxaddscroll(listbox1,starline('zstd is not installed - compression won' + #39 + 't work without it.', 80));
  Result := zstdinstalled;
  if Result then
  begin
    FirstAktiv := False;
  end;
  if installdone then Listboxaddscroll(listbox1,starline('OK', 80));
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  if firstaktiv then
    installmissingroutines;
  firstaktiv := False;
end;


procedure TForm1.CompressWithProgress(const infile: string; level: integer; LBox: TListBox);
begin
  Listboxaddscroll(listbox1,Starline('compressing with zstd', 80));
  CompressFileZstdWithProgress(edit1.text,edit1.text+'.zst',spinedit1.Value,4,true,Listbox1);
  Listboxaddscroll(listbox1,'filesize is now: ' + FileSizeAsString(filesize(infile + '.zst'), False) + '  /  ' + FileSizeAsString(filesize(infile + '.zst'), True));
end;


procedure TForm1.FormCreate(Sender: TObject);
var
  ini: tinifile;
  s, speichertdrive: ansistring;
  x, w, h: integer;
begin
  runcommand('sudo systemctl stop udisks2', s);
  form1.Caption := appname;
  stringGrid1.ColWidths[0] := 80;
  stringGrid1.ColWidths[1] := 220;
  stringGrid1.ColWidths[2] := 100;
  stringGrid1.ColWidths[3] := 270;
  stringGrid1.ColWidths[4] := 135;
  stringGrid1.ColWidths[5] := 175;
  w := 0;
  // w := GetSystemMetrics(SM_CXVSCROLL);   // ScrollBarWidth
  for x := 0 to stringgrid1.ColCount - 1 do Inc(w, stringGrid1.ColWidths[x]);
  Inc(w, (2) * stringgrid1.GridLineWidth);

  stringgrid1.Width := w;
  form1.Width := w + stringgrid1.Left + 8;

  h := 0;
  for x := 0 to stringgrid1.rowCount - 1 do Inc(h, stringGrid1.RowHeights[x]);
  Inc(h, (2) * stringgrid1.GridLineWidth);
  stringgrid1.Height := h;

  getdrives(combobox1.Items);
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
  checkbox1.Checked := ini.ReadBool('Option','compress', False);
  spinedit1.value:=ini.readinteger('Option','compresslevel',2);
  edit2.Text := ini.ReadString('Exclude', 'Last', '');
  ini.Free;
  runcommand('logname', user);
  Delete(user, Length(user), 1);
 end;



function TForm1.ModifyImage(mountpoint: string): boolean;
var
  excludelist: Texcludelist;

begin
  ExcludeList := TExcludeList.Create;

  try
    ExcludeList.LogTarget := ListBox1;
    if CheckBox_exclude.Checked then
    begin
    ExcludeList.LoadFromFile(Edit2.Text, mountpoint);
    ExcludeList.ExecuteAll;
    end;

    if CheckBox_RemoveSSH.Checked then
    begin
    ExcludeList.LoadFromFile(extractfilepath(application.ExeName)+'ssh-cleanup.exclude', mountpoint);
    ExcludeList.ExecuteAll;
    end;

    if CheckBox_RemoveDHCP.Checked then
    begin
     ExcludeList.LoadFromFile(Edit2.Text, mountpoint);
     ExcludeList.ExecuteAll;
    end;

  finally
    ExcludeList.Free;
  end;
end;



procedure TForm1.ButtonCreateImageClick(Sender: TObject);
var
  filename, sourcedrive, part2, s, device, mp: ansistring;
  minsize, NewBlockCount: int64;
  blocksize: integer;
  deststream: TFileStream;
  mbrwork: TMbr;
  sectorsperblock: integer;
begin
  if ButtonCreateImage.Caption = 'cancel' then
  begin
    terminate_all := True;
    listbox1.items.add('Operation canceled by user.');
    ButtonCreateImage.Enabled:=false;
    exit;
  end;

  terminate_all := False;
  ButtonCreateImage.Caption := 'cancel';
  ListBox1.Items.Clear;
  ListBox1.Items.Add('');
  ListBoxaddscroll(listbox1,'Create image');
  application.ProcessMessages;


  try
    sourcedrive := combobox1.Text;
    sourcedrive := copy(sourcedrive, 1, pos(':', sourcedrive) - 1);
    filename := Trim(ChangeFileExt(Edit1.Text, '.img'));

    s := runbash('LC_ALL=C stat -f /');
    blocksize := GetValueAfterKeyword(s, 'Block size:');
    if blocksize <= 0 then
      raise Exception.Create('Error reading block size');

    sectorsperblock := blocksize div 512;

    if not DirectoryExists(ExtractFilePath(filename)) then
      raise Exception.Create('Destination path does not exist');

    mp := GetMountPointFromProc(filename);
    if (mp = '/') or (mp = '/boot') or (mp = '/boot/firmware') then
      raise Exception.Create('Destination is on a protected system partition: ' + mp);

    ListBox1.Items.Add(starline(Sourcedrive + ' -> ' + ExtractFileName(Filename), 80));
    ListBox1.Items.Add('');

    if terminate_all or (not MakeImageFirst2Partitions(sourcedrive, filename,listbox1)) then
      begin
         raise Exception.Create('Failed to create image from source drive');
      end;

    if not Read_MBR(sourcedrive, mbrwork) then
      raise Exception.Create('Failed to read mbr from source drive');
    FillChar(mbrwork.PartitionEntries[3], SizeOf(mbrwork.PartitionEntries[3]), 0);
    FillChar(mbrwork.PartitionEntries[4], SizeOf(mbrwork.PartitionEntries[4]), 0);
    if not Write_MBR(mbrwork, filename) then
      raise Exception.Create('Failed to write mbr to ' + filename);


    device := PrexeBash('losetup --partscan --nooverlap --find --show ' + filename,listbox1);
    device := Trim(device);
    if device = '' then
      raise Exception.Create('Failed to setup loop device for image');

    part2 := device + 'p2';
    runbash('rm -rf ' + mpoint);
    runbash('mkdir -p ' + mpoint);

    s := PrexeBash('mount ' + part2 + ' ' + mpoint,listbox1);
    if Pos('failed', LowerCase(s)) > 0 then
      raise Exception.Create('Mount failed: ' + s);

    ModifyImage(mpoint);
    runbash('umount ' + mpoint);
    Sleep(5000);

    ListBox1.Items.Add('Removed unnecessary files from the image');
    ListBox1.Items.Add('Check the file system consistency of the image and correct it if necessary');

    s := PrexeBash('/sbin/e2fsck -fy ' + part2,listbox1);
    if Pos('errors', LowerCase(s)) > 0 then
      Listboxaddscroll(listbox1,'Filesystem check reported errors');

    s := PrexeBash('/sbin/resize2fs -P ' + part2,listbox1);
    minsize := GetValueAfterKeyword(s, 'filesystem:');
    if minsize = 0 then
      raise Exception.Create('Could not determine minimum filesystem size');

    Inc(minsize, 500);

    s := PrexeBash('/sbin/resize2fs -p ' + part2 + ' ' + IntToStr(minsize),listbox1);
    NewBlockCount := GetValueAfterKeyword(s, 'is now');
    if NewBlockCount = 0 then
      raise Exception.Create('Failed to resize filesystem');

    mbrwork.PartitionEntries[2].PartitionSize := NewBlockCount * sectorsperblock;
     if not Write_MBR(mbrwork, filename) then
      raise Exception.Create('Failed to write mbr to ' + filename);
    runbash('/sbin/partprobe ' + device);
    PrexeBash('/sbin/e2fsck -fy ' + part2,Listbox1);
    runbash('losetup -d ' + device);

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

    fpchown(filename, 1000, 1000);
    fpchmod(filename, &755);

    Listboxaddscroll(listbox1,'image-size - root only: ' + IntToStr(mbrwork.PartitionEntries[2].PartitionSize * 512) + ' bytes');
    Listboxaddscroll(listbox1,'image-size - all: ' + IntToStr(FileSize(filename)) + ' bytes');

    if (not terminate_all) and (CheckBox1.Checked) then
    begin
    CompressFileZstdWithProgress(filename,filename+'.zst', SpinEdit1.Value,4,true,listbox1);
    if checkbox_Delimg.Checked  and (not terminate_all) then deletefile(filename);
    end;

    Listboxaddscroll(listbox1,starline('all done', 80));


  except
    on E: Exception do
    begin
      Listboxaddscroll(listbox1,'Error: ' + E.Message);
      if device <> '' then
        runbash('losetup -d ' + device);
    end;
  end;

  ButtonCreateImage.Caption := 'create image';
  ButtonCreateImage.Enabled := true;
end;



procedure TForm1.Button2Click(Sender: TObject);
begin
  getdrives(combobox1.Items);
  combobox1.ItemIndex := 0;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  terminate_all := True;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  if opendialog1.Execute then edit2.Text := opendialog1.FileName;
  write_ini;
end;



procedure TForm1.ButtonWriteImageClick(Sender: TObject);
var
  workmbr: TMbr;
  s, par2name: string;
  sig: dword;
  sigtext: string;
begin
  try
    if ButtonWriteImage.Caption = 'cancel' then
    begin
      terminate_all := True;
      listbox1.items.add('Operation canceled by user.');
      ButtonWriteImage.Caption := 'write image to device';
      ButtonWriteImage.Enabled:=false;
      Exit;
    end;

    ButtonWriteImage.Caption := 'cancel';
    terminate_all := False;
    application.ProcessMessages;

    if not FileExists(edit1.Text) then
      raise Exception.Create('Image file does not exist: ' + edit1.Text);

    selecteddrive := '/dev/' + stringgrid1.Cells[0, 1];



    Listboxaddscroll(listbox1,'write image');

   // s:=ImageToDevice(edit1.Text, selecteddrive,CheckBox_DelPartition3.Checked,CheckBox_DelPartition4.Checked,listbox1);
    s:=ImageToDeviceImgAndZstd(edit1.Text, selecteddrive,CheckBox_DelPartition3.Checked,CheckBox_DelPartition4.Checked,listbox1);

    if s>'' then
      begin
      Listboxaddscroll(listbox1,s);
      raise Exception.Create('Failed to write image to device.');
      end;


    // Get partition 2 name
    par2name := PartitionNamefromDevice(selecteddrive, 2);

    // Unmount partition
    runcommand('umount -l ' + par2name, s);
    Sleep(1000);
    runcommand('umount -f ' + par2name, s);
    Sleep(2000);

    s := Prexebash('e2fsck -fy ' + par2name,listbox1);
    ListBox1.Items.Add(s);
    if Pos('error', LowerCase(s)) > 0 then
      raise Exception.Create('Filesystem errors detected – please check manually.');

    // Update MBR to resize partition 2
    Read_MBR(selecteddrive, workmbr);
    workmbr.PartitionEntries[2].PartitionSize := strtoint64(stringgrid1.Cells[parsize,par2]) div 512;  // neue grösse in sectors
    Write_MBR(workmbr, selecteddrive);

    ListBox1.Items.Add('partprobe - reloading partition table');
    s := Prexebash('partprobe ' + selecteddrive,listbox1);

    Prexebash('e2fsck -fy ' + par2name,listbox1);
    ListBox1.Items.Add('resize...');
    s := Prexebash('resize2fs ' + par2name,listbox1);
    ListBox1.Items.Add('partprobe - reloading partition table');
    s := Prexebash('partprobe ' + selecteddrive,listbox1);

    Application.ProcessMessages;

    if CheckBox12.Checked then
    begin
     // ListBox1.Items.Add('Changing device signature');
      s := Trim(edit3.Text);
      sig := StrToInt('$' + s);
      sigtext := LowerCase(HexStr(sig, 8));

       ListBox1.Items.Add('Change device signature in cmdline.txt');
      s:= ReplacePartUUIDInCmdline(selecteddrive, sigtext+'-02');
      if s>'' then ListBox1.Items.Add(s);

       ListBox1.Items.Add('Change device signature in fstab');
       s:= ReplacePartUUIDInFstab(selecteddrive, sigtext);
       if s>'' then ListBox1.Items.Add(s);

       ListBox1.Items.Add('Change device signature in mbr');
       s:= ReplacePartUUIDinMbr(selecteddrive, sig);
       if s>'' then ListBox1.Items.Add(s);
    end;

    Listboxaddscroll(listbox1,'---------- all done ----------');

  except
    on E: Exception do
    begin
      ListBox1.Items.Add('❌ Error: ' + E.Message);
    end;
  end;

  ButtonWriteImage.Caption := 'write image to device';
  ButtonWriteImage.Enabled:=true;
end;



procedure TForm1.Edit1DblClick(Sender: TObject);
begin
  if radiobutton1.Checked then if savedialog1.Execute then destname := savedialog1.FileName;
  if radiobutton2.Checked then if opendialog1.Execute then destname := opendialog1.FileName;
  edit1.Text := Destname;
  write_ini;
end;



procedure TForm1.Edit3Change(Sender: TObject);
var
  s: string;
begin
  s := edit3.Text;
  s := copy(s, 1, 8);
  edit3.Text := s;
end;


procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var
  s: string;
begin

  Listboxaddscroll(listbox1,'The program is shutting down. This may take a moment...');

  terminate_all := True;
  sleep(3000);
  PrexeBash('umount ' + device,listbox1);  // optional, wenn es gemountet war
  PrexeBash('losetup -d ' + device,listbox1);
  PrexeBash('rm -rf ' + mpoint,listbox1);
  runcommand('sudo systemctl start udisks2', s);
  write_ini;
end;

end.
