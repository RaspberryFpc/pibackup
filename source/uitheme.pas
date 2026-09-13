unit uitheme;

{$mode objfpc}{$H+}

interface

procedure ApplyCodeTyphonStyle;
procedure ApplyFont;

implementation

uses
  Qt5;

procedure ApplyCodeTyphonStyle;
var
  pal: QPaletteH;
  col: QColorH;
  s: widestring;
begin
  pal := QPalette_create;
  col := QColor_create;

  // Fenster
  QColor_fromRgb(@col, 236, 233, 216, 255);
  QPalette_setColor(pal, QPaletteWindow, @col);

  // Text
  QColor_fromRgb(@col, 0, 0, 0, 255);
  QPalette_setColor(pal, QPaletteWindowText, @col);

  // Base
  QColor_fromRgb(@col, 255, 255, 255, 255);
  QPalette_setColor(pal, QPaletteBase, @col);

  // Highlight (Progressbar)
  QColor_fromRgb(@col, 49, 106, 197, 255);
  QPalette_setColor(pal, QPaletteHighlight, @col);

  QColor_fromRgb(@col, 255, 255, 255, 255);
  QPalette_setColor(pal, QPaletteHighlightedText, @col);

  QApplication_setPalette(pal);

  s := 'Fusion';
  QApplication_setStyle(PWideString(s));
end;


procedure ApplyFont;
var
  font: QFontH;
  s: string;
begin
  // CodeTyphon / Lazarus Standard
  s := 'DejaVu Sans';
  font := QFont_Create(PWideString(s), 10, -1, False);
  QApplication_setFont(font);
end;



end.
