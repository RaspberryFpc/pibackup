unit Editor;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Menus, LCLType, Interfaces;

type

  TForm3 = class(TForm)
    bt_saveto: TButton;
    bt_savechanges: TButton;
    bt_close: TButton;
    bt_openfile: TButton;
    ComboBox1: TComboBox;
    Memo1: TMemo;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    procedure bt_savetoClick(Sender: TObject);
    procedure bt_savechangesClick(Sender: TObject);
    procedure bt_closeClick(Sender: TObject);
    procedure bt_openfileClick(Sender: TObject);
    procedure ComboBox1CloseUp(Sender: TObject);
    procedure ComboBox1DropDown(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Memo1Change(Sender: TObject);
  private
  public
  end;

var
  Form3: TForm3;

implementation

{$R *.frm}

uses unit1;

const
  fpath = '/etc/pibackup/';

var
  filename: string;
  changes: boolean;

type
  TExcludeCommand = (
    exUnknown,
    exfile,
    exfileintree,
    exallintree,
    exdir
  );

{ ------------------------------------------------------------ }
function ParseCommand(const s: string; out Cmd: TExcludeCommand): Boolean;
var
  key: string;
begin
  key := LowerCase(Trim(s));

  if key = 'file' then Cmd := exfile else
  if key = 'fileintree' then Cmd := exfileintree else
  if key = 'allintree' then Cmd := exallintree else
  if key = 'dir' then Cmd := exdir else
  begin
    Cmd := exUnknown;
    Exit(False);
  end;

  Result := True;
end;

{ ------------------------------------------------------------ }
procedure MarkLine(Memo: TMemo; LineNo: Integer);
var
  i, PosStart: Integer;
begin
  if (LineNo < 1) or (LineNo > Memo.Lines.Count) then Exit;

  PosStart := 0;

  for i := 0 to LineNo - 2 do
    PosStart := PosStart + Length(Memo.Lines[i]) + 1; // + CRLF

  Memo.SelStart := PosStart;
  Memo.SelLength := Length(Memo.Lines[LineNo - 1]);

  Memo.SetFocus;
end;

{ ------------------------------------------------------------ }
function ValidateLineSyntax(const Line: string; LineNo: Integer): string;
var
  p: Integer;
  key, val, s: string;
  cmd: TExcludeCommand;
begin
  Result := '';

  s := Trim(Line);

  if (s = '') or (s[1] = '#') then Exit;

  p := Pos('#', s);
  if p > 0 then
    Delete(s, p, MaxInt);

  // 🔴 1. Struktur prüfen
  p := Pos('=', s);
  if p = 0 then
    Exit(Format('Line %d: missing "="', [LineNo]));

  // trennen
  key := Trim(Copy(s, 1, p - 1));
  val := Trim(Copy(s, p + 1, MaxInt));

  // 🔴 2. Command prüfen (nach "=" korrekt!)
  if not ParseCommand(key, cmd) then
    Exit(Format('Line %d: unknown command "%s"', [LineNo, key]));

  // 🔴 3. Key muss sinnvoll sein
  if key = '' then
    Exit(Format('Line %d: empty command', [LineNo]));

  // 🔴 4. Value prüfen
  if val = '' then
    Exit(Format('Line %d: empty path', [LineNo]));

  if Pos(#0, val) > 0 then
    Exit(Format('Line %d: invalid char', [LineNo]));

  if Pos('..', val) > 0 then
    Exit(Format('Line %d: ".." not allowed', [LineNo]));

  // 🔥 5. Command-spezifische Regeln
  case cmd of

    exfile:
      if (Pos('*', ExtractFilePath(val)) > 0) or
         (Pos('?', ExtractFilePath(val)) > 0) then
        Exit(Format('Line %d: wildcard only in filename', [LineNo]));

    exfileintree:
      if (Pos('*', ExtractFilePath(val)) > 0) or
         (Pos('?', ExtractFilePath(val)) > 0) then
        Exit(Format('Line %d: wildcard not allowed in path', [LineNo]));

    exallintree, exdir:
      if (Pos('*', val) > 0) or (Pos('?', val) > 0) then
        Exit(Format('Line %d: wildcards not allowed', [LineNo]));
  end;
end;
{ ------------------------------------------------------------ }
procedure ValidateMemo(Memo: TMemo);
var
  i: Integer;
  err: string;
begin
  for i := 0 to Memo.Lines.Count - 1 do
  begin
    err := ValidateLineSyntax(Memo.Lines[i], i + 1);

    if err <> '' then
    begin
      MarkLine(Memo, i + 1);
      raise Exception.Create(err);
    end;
  end;
end;

{ ------------------------------------------------------------ }

procedure openfile(openfile: string);
begin
  if changes then
    if MessageDlg('Confirmation','Save changes?',mtConfirmation,[mbYes,mbNo],0)=mryes then
      Form3.Memo1.Lines.SaveToFile(Filename);

  Form3.Memo1.Clear;
  Filename := openfile;
  Form3.Memo1.Lines.LoadFromFile(Filename);
  Form3.Caption := Filename;
  changes := false;
end;

procedure updatecombobox;
var
  SR: TSearchRec;
begin
  Form3.ComboBox1.Items.Clear;

  if FindFirst('/etc/pibackup/*.exclude', faAnyFile and not faDirectory, SR) = 0 then
  begin
    repeat
      Form3.ComboBox1.Items.Add(SR.Name);
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
end;

{ ------------------------------------------------------------ }

procedure TForm3.bt_savetoClick(Sender: TObject);
begin
  try
    ValidateMemo(Memo1);

    if SaveDialog1.Execute then
    begin
      Filename := ChangeFileExt(SaveDialog1.FileName, '.exclude');
      Memo1.Lines.SaveToFile(Filename);
    end;

  except
    on E: Exception do
    begin
      ShowMessage(E.Message);
      Abort;
    end;
  end;
  changes:=false;
end;



procedure TForm3.bt_savechangesClick(Sender: TObject);
begin
  try
    ValidateMemo(Memo1);
    Memo1.Lines.SaveToFile(Filename);
  except
    on E: Exception do
    begin
      ShowMessage(E.Message);
      Abort;
    end;
  end;
   changes:=false;
end;

procedure TForm3.bt_openfileClick(Sender: TObject);
begin
  OpenDialog1.InitialDir := '/etc/pibackup';
  if OpenDialog1.Execute then
    openfile(OpenDialog1.FileName);
end;

procedure TForm3.ComboBox1CloseUp(Sender: TObject);
begin
  openfile(fpath + ComboBox1.Text);
end;

procedure TForm3.ComboBox1DropDown(Sender: TObject);
begin
  updatecombobox;
end;

procedure TForm3.FormCreate(Sender: TObject);
begin
  updatecombobox;

  if ComboBox1.Items.Count > 0 then
  begin
    ComboBox1.ItemIndex := 0;
    openfile(fpath + ComboBox1.Text);
  end
  else
    ComboBox1.Text := 'raspberry.exclude';
end;

procedure TForm3.Memo1Change(Sender: TObject);
begin
  changes := true;
end;

procedure TForm3.bt_closeClick(Sender: TObject);
begin
  Close;
end;

end.
