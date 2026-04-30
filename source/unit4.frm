object Form3: TForm3
  Left = 469
  Height = 441
  Top = 43
  Width = 792
  Caption = 'Form3'
  ClientHeight = 441
  ClientWidth = 792
  Position = poMainFormCenter
  LCLVersion = '8.8'
  object Memo1: TMemo
    Left = 8
    Height = 392
    Top = 40
    Width = 776
    TabOrder = 0
    OnChange = Memo1Change
  end
  object Button1: TButton
    Left = 8
    Height = 25
    Top = 11
    Width = 112
    Caption = 'main exclude'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 128
    Height = 25
    Top = 12
    Width = 112
    Caption = 'ssh exclude'
    TabOrder = 2
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 248
    Height = 25
    Top = 12
    Width = 112
    Caption = 'dhcp exclude'
    TabOrder = 3
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 528
    Height = 25
    Top = 12
    Width = 112
    Caption = 'save changes'
    TabOrder = 4
  end
  object Button5: TButton
    Left = 648
    Height = 25
    Top = 12
    Width = 112
    Caption = 'close'
    TabOrder = 5
    OnClick = Button5Click
  end
  object Button6: TButton
    Left = 368
    Height = 25
    Top = 11
    Width = 112
    Caption = 'open file'
    TabOrder = 6
    OnClick = Button6Click
  end
  object OpenDialog1: TOpenDialog
    Left = 66
    Top = 57
  end
end
