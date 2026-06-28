object Form5: TForm5
  Left = 199
  Height = 138
  Top = 101
  Width = 306
  BorderIcons = [biSystemMenu]
  BorderStyle = bsToolWindow
  Caption = 'pibackup updater'
  ClientHeight = 138
  ClientWidth = 306
  Position = poMainFormCenter
  LCLVersion = '8.9'
  object Button1: TButton
    Left = 16
    Height = 25
    Top = 96
    Width = 88
    Caption = 'install'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 114
    Height = 25
    Top = 96
    Width = 83
    Caption = 'not now'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 207
    Height = 25
    Top = 96
    Width = 83
    Caption = 'skip 3 days'
    TabOrder = 2
    OnClick = Button3Click
  end
  object Label1: TLabel
    Left = 40
    Height = 17
    Top = 8
    Width = 38
    Caption = 'Label1'
  end
  object Label2: TLabel
    Left = 40
    Height = 17
    Top = 32
    Width = 10
    Caption = 'l2'
  end
  object Label3: TLabel
    Left = 40
    Height = 17
    Top = 56
    Width = 38
    Caption = 'Label3'
  end
  object Label4: TLabel
    Left = 40
    Height = 17
    Top = 72
    Width = 38
    Caption = 'Label4'
  end
end
