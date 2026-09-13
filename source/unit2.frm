object Form2: TForm2
  Left = 341
  Height = 622
  Top = 43
  Width = 695
  BorderStyle = bsSingle
  ClientHeight = 622
  ClientWidth = 695
  LCLVersion = '8.8'
  OnShow = FormShow
  object HtmlViewer1: THtmlViewer
    AnchorSideLeft.Control = Owner
    AnchorSideTop.Control = Owner
    AnchorSideRight.Control = Owner
    AnchorSideRight.Side = asrBottom
    AnchorSideBottom.Control = Owner
    AnchorSideBottom.Side = asrBottom
    Left = 0
    Height = 622
    Top = 0
    Width = 695
    BorderStyle = htFocused
    HistoryMaxCount = 0
    NoSelect = False
    PrintMarginBottom = 2
    PrintMarginLeft = 2
    PrintMarginRight = 2
    PrintMarginTop = 2
    PrintScale = 1
    Anchors = [akTop, akLeft, akRight, akBottom]
    TabOrder = 0
  end
end
