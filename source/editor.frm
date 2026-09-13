object Form3: TForm3
  Left = 469
  Height = 441
  Top = 43
  Width = 792
  BorderStyle = bsSingle
  Caption = 'Form3'
  ClientHeight = 441
  ClientWidth = 792
  Position = poMainFormCenter
  LCLVersion = '8.9'
  OnCreate = FormCreate
  object Memo1: TMemo
    Left = 8
    Height = 392
    Top = 40
    Width = 776
    TabOrder = 0
    OnChange = Memo1Change
  end
  object bt_savechanges: TButton
    Left = 624
    Height = 25
    Top = 6
    Width = 96
    Anchors = [akTop, akRight]
    Caption = 'save changes'
    TabOrder = 1
    OnClick = bt_savechangesClick
  end
  object bt_close: TButton
    Left = 720
    Height = 25
    Top = 6
    Width = 56
    Caption = 'close'
    TabOrder = 2
    OnClick = bt_closeClick
  end
  object bt_openfile: TButton
    AnchorSideRight.Control = bt_saveto
    Left = 477
    Height = 25
    Top = 6
    Width = 72
    Anchors = [akTop, akRight]
    Caption = 'open file'
    TabOrder = 3
    OnClick = bt_openfileClick
  end
  object ComboBox1: TComboBox
    Left = 8
    Height = 23
    Top = 8
    Width = 456
    ItemHeight = 15
    TabOrder = 4
    OnCloseUp = ComboBox1CloseUp
    OnDropDown = ComboBox1DropDown
  end
  object bt_saveto: TButton
    AnchorSideRight.Control = bt_savechanges
    Left = 549
    Height = 25
    Top = 6
    Width = 75
    Anchors = [akTop, akRight]
    Caption = 'save to'
    TabOrder = 5
    OnClick = bt_savetoClick
  end
  object OpenDialog1: TOpenDialog
    Left = 66
    Top = 57
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = '.exclude'
    Filter = 'exclude files|*.exclude|all files|*'
    InitialDir = '/etc/pibackup'
    Left = 144
    Top = 57
  end
end
