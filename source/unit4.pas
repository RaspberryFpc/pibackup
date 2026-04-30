unit Unit4;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Menus;

type

  { TForm3 }

  TForm3 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Memo1: TMemo;
    OpenDialog1: TOpenDialog;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Memo1Change(Sender: TObject);

  private

  public

  end;

var
  Form3: TForm3;

implementation

{$R *.frm}

{ TForm3 }

uses unit1;

var
filename:string;
changes:boolean;

procedure openfile(openfile:string);
begin
  if changes then
       begin
          if  MessageDlg('Confirmation','Do you want to save the changes in ?',mtConfirmation, [mbYes, mbNo], 0) = mryes then
                              form3.memo1.Lines.SaveToFile(Filename);
       end;
  form3.Caption:= '';
  form3.memo1.lines.clear;
  Filename := openfile;
  form3.memo1.Lines.LoadFromFile(Filename);
  form3.Caption:= filename;
  changes:=false;

end;


procedure TForm3.Button1Click(Sender: TObject);
begin
   openfile('/etc/pibackup/raspberry.exclude');
end;

procedure TForm3.Button2Click(Sender: TObject);
begin
  openfile('/etc/pibackup/ssh-cleanup.exclude');
end;

procedure TForm3.Button3Click(Sender: TObject);
begin
  openfile('/etc/pibackup/dhcp-cleanup.exclude');
end;

procedure TForm3.Button5Click(Sender: TObject);
begin
  close;
end;

procedure TForm3.Button6Click(Sender: TObject);
begin
  opendialog1.InitialDir:='/etc/pibackup';
  if opendialog1.Execute then openfile(opendialog1.filename);
end;

procedure TForm3.Memo1Change(Sender: TObject);
begin
   changes:=true;
end;


end.

