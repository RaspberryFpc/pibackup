object Form1: TForm1
  AnchorSideRight.Side = asrBottom
  Left = 171
  Height = 561
  Top = 115
  Width = 1016
  ClientHeight = 561
  ClientWidth = 1016
  Position = poDesktopCenter
  LCLVersion = '8.7'
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  object Edit1: TEdit
    Left = 111
    Height = 30
    Top = 40
    Width = 608
    ParentFont = False
    TabOrder = 0
    OnChange = GridUpdate
    OnDblClick = Edit1DblClick
  end
  object ComboBox1: TComboBox
    Left = 112
    Height = 30
    Top = 6
    Width = 608
    Anchors = [akLeft]
    ItemHeight = 22
    TabOrder = 1
    Text = 'Laufwerk'
    OnChange = GridUpdate
  end
  object Button2: TButton
    AnchorSideTop.Control = ComboBox1
    AnchorSideTop.Side = asrCenter
    Left = 728
    Height = 30
    Top = 6
    Width = 126
    Caption = 'reload'
    TabOrder = 2
    OnClick = Button2Click
  end
  object Button4: TButton
    AnchorSideTop.Control = Edit1
    AnchorSideTop.Side = asrCenter
    Left = 728
    Height = 30
    Top = 40
    Width = 126
    Caption = 'select'
    TabOrder = 3
    OnClick = Edit1DblClick
  end
  object Label2: TLabel
    Left = 31
    Height = 22
    Top = 8
    Width = 47
    Caption = 'Device'
  end
  object Label3: TLabel
    Left = 30
    Height = 22
    Top = 42
    Width = 68
    Caption = 'image file'
  end
  object ListBox1: TListBox
    AnchorSideLeft.Control = StringGrid1
    AnchorSideTop.Control = ProgressBar1
    AnchorSideTop.Side = asrBottom
    AnchorSideRight.Control = StringGrid1
    AnchorSideRight.Side = asrBottom
    AnchorSideBottom.Control = Owner
    AnchorSideBottom.Side = asrBottom
    Left = 8
    Height = 197
    Top = 360
    Width = 995
    Anchors = [akTop, akLeft, akRight, akBottom]
    BorderSpacing.Bottom = 4
    ClickOnSelChange = False
    ExtendedSelect = False
    Font.CharSet = ANSI_CHARSET
    Font.Color = clBlack
    Font.Height = -16
    Font.Name = 'DejaVu Sans Mono'
    Font.Pitch = fpFixed
    Items.Strings = (
      ''
    )
    ItemHeight = 20
    ParentFont = False
    Style = lbOwnerDrawFixed
    TabOrder = 4
  end
  object StringGrid1: TStringGrid
    AnchorSideTop.Control = Edit1
    Left = 8
    Height = 129
    Top = 74
    Width = 995
    BorderSpacing.Top = 34
    ColCount = 6
    DefaultRowHeight = 18
    Font.Name = 'Nimbus Mono PS [UKWN]'
    Font.Pitch = fpFixed
    ParentFont = False
    RowCount = 6
    ScrollBars = ssNone
    TabOrder = 5
    ColWidths = (
      75
      124
      90
      214
      184
      162
    )
  end
  object RadioButton1: TRadioButton
    AnchorSideTop.Control = StringGrid1
    AnchorSideTop.Side = asrBottom
    Left = 182
    Height = 28
    Top = 206
    Width = 248
    BorderSpacing.Top = 3
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
    Left = 460
    Height = 28
    Top = 206
    Width = 249
    BorderSpacing.Left = 30
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
    Height = 100
    Top = 238
    Width = 995
    Anchors = [akTop, akLeft, akRight]
    BorderSpacing.Top = 4
    BevelInner = bvLowered
    ClientHeight = 100
    ClientWidth = 995
    TabOrder = 8
    object CheckBox_RemoveSSH: TCheckBox
      Left = 15
      Height = 28
      Top = 54
      Width = 112
      Caption = 'remove SSH'
      Color = clDefault
      ParentColor = False
      TabOrder = 0
    end
    object CheckBox_RemoveDHCP: TCheckBox
      AnchorSideTop.Control = CheckBox_RemoveSSH
      AnchorSideTop.Side = asrCenter
      Left = 136
      Height = 28
      Top = 54
      Width = 129
      Caption = 'Remove DHCP'
      TabOrder = 1
    end
    object Edit2: TEdit
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Side = asrCenter
      AnchorSideRight.Control = ButtonCreateImage
      Left = 120
      Height = 30
      Top = 10
      Width = 724
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
      AnchorSideTop.Control = Edit2
      AnchorSideTop.Side = asrCenter
      Left = 852
      Height = 30
      Top = 10
      Width = 126
      Caption = 'select'
      TabOrder = 3
      OnClick = Button5Click
    end
    object CheckBox1: TCheckBox
      AnchorSideTop.Control = CheckBox_RemoveSSH
      AnchorSideTop.Side = asrCenter
      Left = 272
      Height = 28
      Top = 54
      Width = 193
      Caption = 'Compress Image   Level'
      Checked = True
      State = cbChecked
      TabOrder = 4
    end
    object SpinEdit1: TSpinEdit
      AnchorSideTop.Control = CheckBox_RemoveSSH
      AnchorSideTop.Side = asrCenter
      Left = 464
      Height = 31
      Top = 53
      Width = 50
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
      Left = 852
      Height = 30
      Top = 53
      Width = 126
      Anchors = [akTop, akRight]
      BorderSpacing.Right = 15
      Caption = 'Create image'
      ParentFont = False
      TabOrder = 6
      OnClick = ButtonCreateImageClick
    end
    object CheckBox_exclude: TCheckBox
      AnchorSideTop.Control = Edit2
      AnchorSideTop.Side = asrCenter
      Left = 40
      Height = 28
      Top = 11
      Width = 80
      Caption = 'Exclude'
      Checked = True
      State = cbChecked
      TabOrder = 7
    end
    object CheckBox_Delimg: TCheckBox
      AnchorSideTop.Control = CheckBox_RemoveSSH
      Left = 520
      Height = 28
      Top = 54
      Width = 207
      Caption = 'If compressed delete .img'
      Checked = True
      State = cbChecked
      TabOrder = 8
    end
  end
  object Panel2: TPanel
    AnchorSideLeft.Control = StringGrid1
    AnchorSideTop.Control = StringGrid1
    AnchorSideTop.Side = asrBottom
    AnchorSideRight.Control = StringGrid1
    AnchorSideRight.Side = asrBottom
    AnchorSideBottom.Control = Panel1
    AnchorSideBottom.Side = asrBottom
    Left = 8
    Height = 100
    Top = 238
    Width = 995
    Anchors = [akTop, akLeft, akRight]
    BorderSpacing.Top = 35
    BevelInner = bvLowered
    ClientHeight = 100
    ClientWidth = 995
    TabOrder = 9
    Visible = False
    object ScrollBar1: TScrollBar
      Left = 128
      Height = 22
      Top = 14
      Width = 592
      PageSize = 0
      TabOrder = 0
      OnChange = ScrollBar1Change
    end
    object Label_ManSelected: TLabel
      AnchorSideLeft.Side = asrCenter
      AnchorSideTop.Control = ScrollBar1
      AnchorSideTop.Side = asrCenter
      Left = 728
      Height = 18
      Top = 16
      Width = 112
      AutoSize = False
      Caption = '0 MB'
      Font.Height = 16
      ParentFont = False
    end
    object CheckBoxChangeDeviceID: TCheckBox
      AnchorSideTop.Control = CheckBox_DelPartition3
      AnchorSideTop.Side = asrCenter
      Left = 470
      Height = 28
      Top = 54
      Width = 143
      Anchors = [akTop]
      Caption = 'change device id'
      TabOrder = 1
      OnChange = GridUpdate
    end
    object Edit3: TEdit
      AnchorSideTop.Control = CheckBox_DelPartition3
      AnchorSideTop.Side = asrCenter
      Left = 622
      Height = 30
      Top = 53
      Width = 104
      Alignment = taCenter
      Anchors = [akTop]
      TabOrder = 2
      OnChange = Edit3Change
      OnKeyPress = Edit3KeyPress
    end
    object CheckBox_DelPartition4: TCheckBox
      AnchorSideTop.Control = CheckBox_DelPartition3
      AnchorSideTop.Side = asrCenter
      Left = 248
      Height = 28
      Top = 54
      Width = 144
      Caption = 'delete partition 4'
      TabOrder = 3
      OnChange = GridUpdate
    end
    object CheckBox_DelPartition3: TCheckBox
      AnchorSideTop.Side = asrCenter
      Left = 62
      Height = 28
      Top = 54
      Width = 151
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
      Left = 814
      Height = 30
      Top = 53
      Width = 164
      Anchors = [akTop]
      Caption = 'Write image to device'
      TabOrder = 5
      OnClick = ButtonWriteImageClick
    end
  end
  object BtSaveLog: TButton
    AnchorSideTop.Control = RadioButton1
    AnchorSideTop.Side = asrCenter
    AnchorSideRight.Control = StringGrid1
    AnchorSideRight.Side = asrBottom
    Left = 904
    Height = 30
    Top = 205
    Width = 99
    Anchors = [akTop, akRight]
    Caption = 'Save Log'
    TabOrder = 10
    OnClick = BtSaveLogClick
  end
  object ProgressBar1: TProgressBar
    AnchorSideLeft.Control = Panel1
    AnchorSideTop.Control = StringGrid1
    AnchorSideTop.Side = asrBottom
    AnchorSideRight.Control = Panel1
    AnchorSideRight.Side = asrBottom
    Left = 9
    Height = 20
    Top = 340
    Width = 994
    Anchors = [akTop, akLeft, akRight]
    BorderSpacing.Left = 1
    BorderSpacing.Top = 137
    ParentColor = False
    ParentFont = False
    Smooth = True
    Step = 1
    TabOrder = 11
    BarShowText = True
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = '.img'
    Left = 535
    Top = 14
  end
  object OpenDialog1: TOpenDialog
    Left = 584
    Top = 14
  end
end
