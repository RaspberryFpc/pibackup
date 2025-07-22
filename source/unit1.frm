object Form1: TForm1
  AnchorSideRight.Side = asrBottom
  Left = 171
  Height = 502
  Top = 115
  Width = 1080
  ClientHeight = 502
  ClientWidth = 1080
  DesignTimePPI = 102
  Position = poDesktopCenter
  LCLVersion = '8.6'
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  object Edit1: TEdit
    Left = 118
    Height = 31
    Top = 41
    Width = 646
    ParentFont = False
    TabOrder = 0
    OnChange = GridUpdate
    OnDblClick = Edit1DblClick
  end
  object ComboBox1: TComboBox
    Left = 119
    Height = 31
    Top = 4
    Width = 646
    Anchors = [akLeft]
    ItemHeight = 23
    TabOrder = 1
    Text = 'Laufwerk'
    OnChange = GridUpdate
  end
  object Button2: TButton
    Left = 774
    Height = 24
    Top = 8
    Width = 134
    Caption = 'reload'
    TabOrder = 2
    OnClick = Button2Click
  end
  object Button4: TButton
    Left = 774
    Height = 24
    Top = 46
    Width = 134
    Caption = 'select'
    TabOrder = 3
    OnClick = Edit1DblClick
  end
  object Label2: TLabel
    Left = 33
    Height = 23
    Top = 8
    Width = 50
    Caption = 'Device'
  end
  object Label3: TLabel
    Left = 32
    Height = 23
    Top = 45
    Width = 73
    Caption = 'image file'
  end
  object ListBox1: TListBox
    AnchorSideLeft.Control = StringGrid1
    AnchorSideTop.Control = RadioButton1
    AnchorSideTop.Side = asrBottom
    AnchorSideRight.Control = StringGrid1
    AnchorSideRight.Side = asrBottom
    AnchorSideBottom.Control = Owner
    AnchorSideBottom.Side = asrBottom
    Left = 8
    Height = 161
    Top = 337
    Width = 1057
    Anchors = [akTop, akLeft, akRight, akBottom]
    BorderSpacing.Top = 94
    BorderSpacing.Bottom = 4
    Font.CharSet = ANSI_CHARSET
    Font.Color = clBlack
    Font.Height = -17
    Font.Name = 'DejaVu Sans Mono'
    Font.Pitch = fpFixed
    Items.Strings = (
      ''
    )
    ItemHeight = 21
    MultiSelect = True
    ParentFont = False
    TabOrder = 4
  end
  object StringGrid1: TStringGrid
    AnchorSideTop.Control = Edit1
    Left = 8
    Height = 137
    Top = 77
    Width = 1057
    BorderSpacing.Top = 36
    ColCount = 6
    DefaultRowHeight = 19
    Font.Name = 'Nimbus Mono PS [UKWN]'
    Font.Pitch = fpFixed
    ParentFont = False
    RowCount = 6
    ScrollBars = ssNone
    TabOrder = 5
    ColWidths = (
      80
      132
      96
      227
      196
      172
    )
  end
  object RadioButton1: TRadioButton
    AnchorSideTop.Control = StringGrid1
    AnchorSideTop.Side = asrBottom
    Left = 193
    Height = 29
    Top = 214
    Width = 262
    Caption = 'Create System Backup (Image)'
    Checked = True
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 7
    TabStop = True
    OnChange = RadioButton1Change
  end
  object RadioButton2: TRadioButton
    AnchorSideLeft.Control = RadioButton1
    AnchorSideLeft.Side = asrBottom
    AnchorSideTop.Control = RadioButton1
    Left = 487
    Height = 29
    Top = 214
    Width = 262
    BorderSpacing.Left = 32
    Caption = 'Restore Backup or other Image'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 6
    OnChange = RadioButton2Change
  end
  object Panel1: TPanel
    AnchorSideLeft.Control = StringGrid1
    AnchorSideTop.Control = RadioButton1
    AnchorSideTop.Side = asrBottom
    AnchorSideRight.Control = StringGrid1
    AnchorSideRight.Side = asrBottom
    Left = 8
    Height = 86
    Top = 247
    Width = 1057
    Anchors = [akTop, akLeft, akRight]
    BorderSpacing.Top = 4
    BevelInner = bvLowered
    ClientHeight = 86
    ClientWidth = 1057
    TabOrder = 8
    object CheckBox_RemoveSSH: TCheckBox
      Left = 17
      Height = 29
      Top = 44
      Width = 118
      Caption = 'remove SSH'
      TabOrder = 0
    end
    object CheckBox_RemoveDHCP: TCheckBox
      AnchorSideTop.Control = CheckBox_RemoveSSH
      AnchorSideTop.Side = asrCenter
      Left = 145
      Height = 29
      Top = 44
      Width = 135
      Caption = 'Remove DHCP'
      TabOrder = 1
    end
    object Edit2: TEdit
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Side = asrCenter
      AnchorSideRight.Control = ButtonCreateImage
      Left = 128
      Height = 31
      Top = 7
      Width = 713
      Anchors = [akLeft, akRight]
      BorderSpacing.Left = 5
      BorderSpacing.Right = 8
      ParentFont = False
      TabOrder = 2
      Text = 'name of exclude file'
      OnDblClick = Button5Click
    end
    object Button5: TButton
      AnchorSideLeft.Control = ButtonCreateImage
      AnchorSideTop.Side = asrCenter
      Left = 849
      Height = 23
      Top = 12
      Width = 134
      Anchors = [akLeft]
      Caption = 'select'
      TabOrder = 3
      OnClick = Button5Click
    end
    object CheckBox1: TCheckBox
      AnchorSideTop.Control = CheckBox_RemoveSSH
      AnchorSideTop.Side = asrCenter
      Left = 289
      Height = 29
      Top = 44
      Width = 204
      Caption = 'Compress Image   Level'
      TabOrder = 4
    end
    object SpinEdit1: TSpinEdit
      AnchorSideTop.Control = CheckBox_RemoveSSH
      AnchorSideTop.Side = asrCenter
      Left = 493
      Height = 32
      Top = 42
      Width = 53
      Alignment = taCenter
      MaxValue = 19
      MinValue = 1
      TabOrder = 5
      Value = 2
    end
    object ButtonCreateImage: TButton
      AnchorSideTop.Control = CheckBox_RemoveSSH
      AnchorSideTop.Side = asrCenter
      AnchorSideRight.Control = Panel1
      AnchorSideRight.Side = asrBottom
      Left = 849
      Height = 29
      Top = 44
      Width = 190
      Anchors = [akTop, akRight]
      BorderSpacing.Right = 16
      Caption = 'Create image'
      ParentFont = False
      TabOrder = 6
      OnClick = ButtonCreateImageClick
    end
    object CheckBox_exclude: TCheckBox
      Left = 41
      Height = 29
      Top = 8
      Width = 84
      Caption = 'Exclude'
      Checked = True
      State = cbChecked
      TabOrder = 7
    end
    object CheckBox_Delimg: TCheckBox
      AnchorSideTop.Control = CheckBox_RemoveSSH
      Left = 553
      Height = 29
      Top = 44
      Width = 218
      Caption = 'If compressed delete .img'
      Checked = True
      State = cbChecked
      TabOrder = 8
    end
  end
  object Panel2: TPanel
    AnchorSideLeft.Control = StringGrid1
    AnchorSideTop.Control = RadioButton1
    AnchorSideTop.Side = asrBottom
    AnchorSideRight.Control = StringGrid1
    AnchorSideRight.Side = asrBottom
    AnchorSideBottom.Control = Panel1
    AnchorSideBottom.Side = asrBottom
    Left = 8
    Height = 86
    Top = 247
    Width = 1057
    Anchors = [akTop, akLeft, akRight]
    BorderSpacing.Top = 4
    BevelInner = bvLowered
    ClientHeight = 86
    ClientWidth = 1057
    TabOrder = 9
    Visible = False
    object ScrollBar1: TScrollBar
      Left = 152
      Height = 10
      Top = 16
      Width = 458
      PageSize = 0
      TabOrder = 0
      OnChange = ScrollBar1Change
    end
    object Label_ManSelected: TLabel
      AnchorSideLeft.Side = asrCenter
      AnchorSideTop.Control = ScrollBar1
      AnchorSideTop.Side = asrCenter
      Left = 632
      Height = 19
      Top = 12
      Width = 146
      AutoSize = False
      Caption = '0 MB'
      Font.Height = 17
      ParentFont = False
    end
    object CheckBox12: TCheckBox
      AnchorSideTop.Control = CheckBox_DelPartition3
      AnchorSideTop.Side = asrCenter
      Left = 502
      Height = 29
      Top = 44
      Width = 150
      Anchors = [akTop]
      Caption = 'change device id'
      TabOrder = 1
      OnChange = GridUpdate
    end
    object Edit3: TEdit
      AnchorSideTop.Control = CheckBox_DelPartition3
      AnchorSideTop.Side = asrCenter
      Left = 664
      Height = 31
      Top = 43
      Width = 110
      Alignment = taCenter
      Anchors = [akTop]
      TabOrder = 2
      OnChange = Edit3Change
      OnKeyPress = Edit3KeyPress
    end
    object CheckBox_DelPartition4: TCheckBox
      AnchorSideTop.Control = CheckBox_DelPartition3
      AnchorSideTop.Side = asrCenter
      Left = 264
      Height = 29
      Top = 44
      Width = 152
      Caption = 'delete partition 4'
      TabOrder = 3
      OnChange = GridUpdate
    end
    object CheckBox_DelPartition3: TCheckBox
      AnchorSideTop.Side = asrCenter
      Left = 66
      Height = 29
      Top = 44
      Width = 159
      Anchors = [akLeft]
      Caption = 'delete  partition 3 '
      DoubleBuffered = False
      ParentDoubleBuffered = False
      TabOrder = 4
      OnChange = GridUpdate
    end
    object ButtonWriteImage: TButton
      AnchorSideTop.Control = CheckBox_DelPartition3
      AnchorSideTop.Side = asrCenter
      AnchorSideRight.Control = Edit3
      AnchorSideRight.Side = asrBottom
      Left = 809
      Height = 26
      Top = 45
      Width = 174
      Anchors = [akTop]
      Caption = 'Write image to device'
      TabOrder = 5
      OnClick = ButtonWriteImageClick
    end
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = '.img'
    Left = 568
    Top = 15
  end
  object OpenDialog1: TOpenDialog
    Left = 621
    Top = 15
  end
end
