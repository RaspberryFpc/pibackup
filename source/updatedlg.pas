unit UpdateDlg;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TForm5 }

  TForm5 = class(TForm)
    label1:tlabel;
    label2:tlabel;
    label3:tlabel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Label4: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);


  private

  public

  end;

var
  Form5: TForm5;

implementation

{$R *.frm}

{ TForm5 }


procedure TForm5.Button1Click(Sender: TObject);
begin
  modalresult:=1;
end;

procedure TForm5.Button2Click(Sender: TObject);
begin
   modalresult:=2;
end;

procedure TForm5.Button3Click(Sender: TObject);
begin
   modalresult:=3;
end;



end.

