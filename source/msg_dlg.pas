unit msg_dlg;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Menus;

type

  { TForm4 }

  TForm4 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);

  private

  public

  end;

var
  Form4: TForm4;

implementation

{$R *.frm}

{ TForm4 }




procedure TForm4.Button1Click(Sender: TObject);
begin
  modalresult := mrYes;
end;

procedure TForm4.Button2Click(Sender: TObject);
begin
  modalresult := mrNo;
end;

end.
