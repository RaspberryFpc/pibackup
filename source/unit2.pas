unit Unit2;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, HtmlView, HtmlGlobals;

type

  { TForm2 }

  TForm2 = class(TForm)
    HtmlViewer1: THtmlViewer;
  procedure FormShow(Sender: TObject);

  private

  public

  end;

var
  Form2: TForm2;

implementation

{$R *.frm}

{ TForm2 }

procedure TForm2.FormShow(Sender: TObject);
begin
 try
   HtmlViewer1.LoadFromFile('/usr/share/doc/pibackup/help/intro.html');
    finally
   end;
end;



end.

