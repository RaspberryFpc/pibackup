object Form1: TForm1
  AnchorSideRight.Side = asrBottom
  Left = 171
  Height = 561
  Top = 115
  Width = 1146
  Anchors = []
  BorderStyle = bsSingle
  ClientHeight = 561
  ClientWidth = 1146
  Position = poDesktopCenter
  LCLVersion = '8.9'
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  object Label2: TLabel
    AnchorSideTop.Control = ComboBox1
    AnchorSideTop.Side = asrCenter
    AnchorSideRight.Control = ComboBox1
    Left = 86
    Height = 17
    Top = 52
    Width = 79
    Anchors = [akTop, akRight]
    BorderSpacing.Right = 11
    Caption = 'Source Device'
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
    Height = 184
    Top = 373
    Width = 1088
    Anchors = [akTop, akLeft, akRight, akBottom]
    BorderSpacing.Top = 3
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
    TabOrder = 0
  end
  object StringGrid1: TStringGrid
    Left = 8
    Height = 129
    Top = 113
    Width = 1088
    BorderSpacing.Top = 34
    ColCount = 6
    DefaultRowHeight = 18
    Font.Name = 'Nimbus Mono PS [UKWN]'
    Font.Pitch = fpFixed
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing, goSmoothScroll]
    ParentFont = False
    RowCount = 6
    ScrollBars = ssNone
    TabOrder = 1
    OnEditingDone = StringGrid1EditingDone
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
    Left = 40
    Height = 23
    Top = 15
    Width = 209
    Anchors = [akLeft]
    BorderSpacing.Top = 3
    Caption = 'Create System Backup (Image)'
    Checked = True
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
    TabStop = True
  end
  object RadioButton2: TRadioButton
    AnchorSideLeft.Control = RadioButton1
    AnchorSideLeft.Side = asrBottom
    AnchorSideTop.Control = RadioButton1
    Left = 279
    Height = 23
    Top = 15
    Width = 212
    BorderSpacing.Left = 30
    Caption = 'Restore Backup or other Image'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
    OnChange = RadioButton2Change
  end
  object Panel1: TPanel
    AnchorSideLeft.Control = StringGrid1
    AnchorSideTop.Control = StringGrid1
    AnchorSideTop.Side = asrBottom
    AnchorSideRight.Control = StringGrid1
    AnchorSideRight.Side = asrBottom
    Left = 8
    Height = 100
    Top = 246
    Width = 1088
    Anchors = [akTop, akLeft, akRight]
    BorderSpacing.Top = 4
    BevelInner = bvLowered
    ClientHeight = 100
    ClientWidth = 1088
    TabOrder = 4
    object CheckBox_RemoveSSH: TCheckBox
      Left = 15
      Height = 23
      Top = 54
      Width = 93
      Caption = 'remove SSH'
      Color = clDefault
      ParentColor = False
      TabOrder = 0
    end
    object CheckBox_RemoveDHCP: TCheckBox
      AnchorSideTop.Control = CheckBox_RemoveSSH
      AnchorSideTop.Side = asrCenter
      Left = 136
      Height = 23
      Top = 54
      Width = 106
      Caption = 'Remove DHCP'
      TabOrder = 1
    end
    object Edit2: TEdit
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Side = asrCenter
      AnchorSideRight.Control = ButtonCreateImage
      Left = 120
      Height = 25
      Top = 13
      Width = 817
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
      Left = 945
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
      Height = 23
      Top = 54
      Width = 159
      Caption = 'Compress Image   Level'
      Checked = True
      State = cbChecked
      TabOrder = 4
    end
    object SpinEdit1: TSpinEdit
      AnchorSideLeft.Control = CheckBox1
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Control = CheckBox_RemoveSSH
      AnchorSideTop.Side = asrCenter
      Left = 433
      Height = 26
      Top = 52
      Width = 50
      Alignment = taCenter
      BorderSpacing.Left = 2
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
      Left = 945
      Height = 30
      Top = 50
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
      Height = 23
      Top = 14
      Width = 69
      Caption = 'Exclude'
      Checked = True
      State = cbChecked
      TabOrder = 7
    end
    object CheckBox_Delimg: TCheckBox
      AnchorSideTop.Control = CheckBox_RemoveSSH
      Left = 520
      Height = 23
      Top = 54
      Width = 224
      Caption = 'Remove .img file after compression'
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
    Top = 246
    Width = 1088
    Anchors = [akTop, akLeft, akRight]
    BorderSpacing.Top = 4
    BevelInner = bvLowered
    ClientHeight = 100
    ClientWidth = 1088
    TabOrder = 5
    Visible = False
    object ScrollBar1: TScrollBar
      AnchorSideRight.Control = Eddeviceid
      AnchorSideRight.Side = asrBottom
      Left = 53
      Height = 14
      Top = 6
      Width = 560
      Anchors = [akTop, akRight]
      LargeChange = 100
      PageSize = 0
      TabOrder = 0
      OnChange = ScrollBar1Change
    end
    object Label_ManSelected: TLabel
      AnchorSideLeft.Control = ScrollBar1
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Control = ScrollBar1
      AnchorSideTop.Side = asrCenter
      Left = 625
      Height = 18
      Top = 4
      Width = 288
      AutoSize = False
      BorderSpacing.Left = 12
      Caption = '0 MB'
      Font.Height = 16
      ParentFont = False
    end
    object CheckBoxChangeDeviceID: TCheckBox
      AnchorSideTop.Control = Eddeviceid
      AnchorSideTop.Side = asrCenter
      AnchorSideRight.Control = Eddeviceid
      Left = 374
      Height = 23
      Top = 30
      Width = 119
      Anchors = [akTop, akRight]
      Caption = 'change device id'
      TabOrder = 1
      OnChange = CheckBoxChangeDeviceIDChange
    end
    object Eddeviceid: TEdit
      AnchorSideTop.Control = CheckBox_DelPartition3
      AnchorSideTop.Side = asrCenter
      AnchorSideRight.Control = EDuserpassword
      AnchorSideRight.Side = asrBottom
      Left = 493
      Height = 25
      Top = 29
      Width = 120
      Alignment = taCenter
      Anchors = [akRight]
      TabOrder = 2
      OnChange = EddeviceidChange
      OnKeyPress = EddeviceidKeyPress
    end
    object CheckBox_DelPartition4: TCheckBox
      AnchorSideLeft.Control = CheckBox_DelPartition3
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Control = Eddeviceid
      AnchorSideTop.Side = asrCenter
      Left = 223
      Height = 23
      Top = 30
      Width = 122
      Caption = 'delete partition 4'
      TabOrder = 3
      OnChange = GridUpdate
    end
    object CheckBox_DelPartition3: TCheckBox
      AnchorSideLeft.Control = EDusername
      AnchorSideTop.Control = Eddeviceid
      AnchorSideTop.Side = asrCenter
      Left = 95
      Height = 23
      Top = 30
      Width = 128
      Caption = 'delete  partition 3 '
      DoubleBuffered = False
      ParentDoubleBuffered = False
      TabOrder = 4
      OnChange = GridUpdate
    end
    object ButtonWriteImagetodevice: TButton
      AnchorSideTop.Control = CheckBox_DelPartition3
      AnchorSideTop.Side = asrCenter
      AnchorSideRight.Control = Panel2
      AnchorSideRight.Side = asrBottom
      AnchorSideBottom.Control = edit_wlanpassword
      Left = 877
      Height = 30
      Top = 33
      Width = 164
      Anchors = [akRight, akBottom]
      BorderSpacing.Right = 45
      BorderSpacing.Bottom = 9
      Caption = 'Write image to device'
      TabOrder = 5
      OnClick = ButtonWriteImagetodeviceClick
    end
    object CBEnableSSH: TCheckBox
      AnchorSideLeft.Control = EDuserpassword
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Control = lbl_user
      AnchorSideTop.Side = asrCenter
      Left = 623
      Height = 23
      Top = 53
      Width = 89
      BorderSpacing.Left = 10
      Caption = 'Enable SSH'
      TabOrder = 6
    end
    object edit_wlanssid: TEdit
      AnchorSideLeft.Control = lbl_ssid
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Control = lbl_host
      AnchorSideTop.Side = asrCenter
      Left = 349
      Height = 25
      Top = 72
      Width = 264
      BorderSpacing.Left = 10
      TabOrder = 7
    end
    object edit_wlanpassword: TEdit
      AnchorSideLeft.Control = lbl_passphrase
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Control = lbl_host
      AnchorSideTop.Side = asrCenter
      AnchorSideRight.Control = Panel2
      AnchorSideRight.Side = asrBottom
      Left = 729
      Height = 25
      Top = 72
      Width = 347
      Anchors = [akTop, akLeft, akRight]
      BorderSpacing.Left = 10
      BorderSpacing.Right = 10
      TabOrder = 8
    end
    object EDusername: TEdit
      AnchorSideLeft.Control = lbl_user
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Control = lbl_user
      AnchorSideTop.Side = asrCenter
      Left = 95
      Height = 25
      Top = 52
      Width = 179
      BorderSpacing.Left = 10
      TabOrder = 9
    end
    object EDuserpassword: TEdit
      AnchorSideLeft.Control = lbl_userpassword
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Control = lbl_userpassword
      AnchorSideTop.Side = asrCenter
      Left = 349
      Height = 25
      Top = 52
      Width = 264
      BorderSpacing.Left = 10
      TabOrder = 10
    end
    object EDhost: TEdit
      AnchorSideLeft.Control = lbl_host
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Control = lbl_host
      AnchorSideTop.Side = asrCenter
      Left = 95
      Height = 25
      Top = 72
      Width = 180
      BorderSpacing.Left = 10
      TabOrder = 11
    end
    object lbl_host: TLabel
      AnchorSideLeft.Control = CBEnableSSH
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Control = EDhost
      AnchorSideTop.Side = asrCenter
      Left = 26
      Height = 17
      Top = 76
      Width = 59
      Anchors = []
      BorderSpacing.Left = 10
      Caption = 'Hostname'
    end
    object lbl_ssid: TLabel
      AnchorSideLeft.Control = EDhost
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Control = lbl_host
      AnchorSideTop.Side = asrCenter
      AnchorSideRight.Control = lbl_userpassword
      AnchorSideRight.Side = asrBottom
      Left = 313
      Height = 17
      Top = 76
      Width = 26
      Anchors = [akTop, akRight]
      BorderSpacing.Left = 10
      Caption = 'SSID'
    end
    object lbl_passphrase: TLabel
      AnchorSideLeft.Control = edit_wlanssid
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Control = lbl_host
      AnchorSideTop.Side = asrCenter
      Left = 623
      Height = 17
      Top = 76
      Width = 96
      BorderSpacing.Left = 10
      Caption = 'Passphrase (PSK)'
    end
    object lbl_user: TLabel
      AnchorSideLeft.Control = lbl_host
      AnchorSideTop.Side = asrCenter
      AnchorSideRight.Control = lbl_host
      AnchorSideRight.Side = asrBottom
      Left = 58
      Height = 17
      Top = 56
      Width = 27
      Anchors = [akTop, akRight]
      Caption = 'User'
    end
    object lbl_userpassword: TLabel
      AnchorSideLeft.Control = EDusername
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Control = EDusername
      AnchorSideTop.Side = asrCenter
      Left = 284
      Height = 17
      Top = 56
      Width = 55
      BorderSpacing.Left = 10
      Caption = 'Password'
      OnClick = lbl_userpasswordClick
    end
  end
  object Btn_SaveLog: TButton
    AnchorSideTop.Control = RadioButton2
    AnchorSideTop.Side = asrCenter
    AnchorSideRight.Control = btn_help
    Left = 823
    Height = 25
    Top = 14
    Width = 103
    Anchors = [akTop, akRight]
    Caption = 'Save Log'
    TabOrder = 6
    OnClick = Btn_SaveLogClick
  end
  object ProgressBar1: TProgressBar
    AnchorSideLeft.Control = Panel1
    AnchorSideTop.Control = StringGrid1
    AnchorSideTop.Side = asrBottom
    AnchorSideRight.Control = Panel1
    AnchorSideRight.Side = asrBottom
    Left = 9
    Height = 20
    Top = 350
    Width = 1087
    Anchors = [akTop, akLeft, akRight]
    BorderSpacing.Left = 1
    BorderSpacing.Top = 108
    ParentColor = False
    ParentFont = False
    Smooth = True
    Step = 1
    TabOrder = 7
    BarShowText = True
  end
  object ComboBox1: TComboBox
    Left = 176
    Height = 25
    Top = 48
    Width = 710
    ItemHeight = 17
    TabOrder = 8
    OnChange = ComboBox1Change
    OnCloseUp = ComboBox1CloseUp
    OnDropDown = ComboBox1DropDown
  end
  object btn_help: TButton
    AnchorSideTop.Control = RadioButton2
    AnchorSideTop.Side = asrCenter
    AnchorSideRight.Control = btn_close
    Left = 926
    Height = 25
    Top = 14
    Width = 78
    Anchors = [akTop, akRight]
    Caption = 'Help'
    TabOrder = 9
    OnClick = btn_helpClick
  end
  object btn_close: TButton
    AnchorSideTop.Control = RadioButton2
    AnchorSideTop.Side = asrCenter
    AnchorSideRight.Control = StringGrid1
    AnchorSideRight.Side = asrBottom
    Left = 1004
    Height = 25
    Top = 14
    Width = 80
    Anchors = [akTop, akRight]
    BorderSpacing.Right = 12
    Caption = 'close'
    TabOrder = 10
    OnClick = btn_closeClick
  end
  object btn_EditExclude: TButton
    AnchorSideLeft.Control = btn_help
    AnchorSideLeft.Side = asrCenter
    AnchorSideTop.Control = RadioButton2
    AnchorSideTop.Side = asrCenter
    AnchorSideRight.Control = Btn_SaveLog
    Left = 697
    Height = 25
    Top = 14
    Width = 126
    Anchors = [akTop, akRight]
    Caption = 'Edit exclude files'
    TabOrder = 11
    OnClick = btn_EditExcludeClick
  end
  object Label3: TLabel
    AnchorSideTop.Control = Panel3
    AnchorSideTop.Side = asrCenter
    AnchorSideRight.Control = Label2
    AnchorSideRight.Side = asrBottom
    Left = 109
    Height = 17
    Top = 77
    Width = 56
    Anchors = [akTop, akRight]
    Caption = 'image file'
  end
  object Panel3: TPanel
    AnchorSideLeft.Control = ComboBox1
    AnchorSideTop.Control = ComboBox1
    AnchorSideTop.Side = asrBottom
    AnchorSideRight.Control = ComboBox1
    AnchorSideRight.Side = asrBottom
    Left = 176
    Height = 25
    Top = 73
    Width = 710
    Alignment = taLeftJustify
    Anchors = [akTop, akLeft, akRight]
    BevelOuter = bvNone
    Caption = 'Panel3'
    ClientHeight = 25
    ClientWidth = 710
    TabOrder = 12
    OnClick = Panel3Click
    object Edit1: TEdit
      AnchorSideLeft.Control = Panel3
      AnchorSideTop.Control = Panel3
      AnchorSideRight.Control = Panel3
      AnchorSideRight.Side = asrBottom
      AnchorSideBottom.Control = Panel3
      AnchorSideBottom.Side = asrBottom
      Left = 0
      Height = 25
      Top = 0
      Width = 690
      Anchors = [akLeft, akRight]
      AutoSize = False
      BorderSpacing.Right = 20
      ParentFont = False
      TabOrder = 0
      OnChange = GridUpdate
      OnDblClick = Edit1DblClick
    end
    object SpeedButton1: TSpeedButton
      AnchorSideTop.Control = Panel3
      AnchorSideRight.Control = Panel3
      AnchorSideRight.Side = asrBottom
      AnchorSideBottom.Control = Panel3
      AnchorSideBottom.Side = asrBottom
      Left = 689
      Height = 25
      Top = 0
      Width = 21
      Anchors = [akTop, akRight, akBottom]
      OnClick = SpeedButton1Click
      OnPaint = SpeedButton1Paint
    end
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = '.img'
    Left = 376
    Top = 56
  end
  object OpenDialog1: TOpenDialog
    Left = 464
    Top = 56
  end
  object OpenDialog2: TOpenDialog
    Left = 568
    Top = 48
  end
  object Timer1: TTimer
    Enabled = False
    OnTimer = Timer1Timer
    Left = 32
    Top = 56
  end
end
