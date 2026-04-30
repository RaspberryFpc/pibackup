object Form1: TForm1
  AnchorSideRight.Side = asrBottom
  Left = 171
  Height = 561
  Top = 115
  Width = 1146
  ClientHeight = 561
  ClientWidth = 1146
  Position = poDesktopCenter
  LCLVersion = '8.8'
  OnClose = FormClose
  OnCreate = FormCreate
  object Edit1: TEdit
    Left = 113
    Height = 23
    Top = 82
    Width = 583
    ParentFont = False
    TabOrder = 0
    OnChange = GridUpdate
    OnDblClick = Edit1DblClick
  end
  object Button4: TButton
    AnchorSideTop.Control = Edit1
    AnchorSideTop.Side = asrCenter
    Left = 704
    Height = 23
    Top = 82
    Width = 80
    Caption = 'select'
    TabOrder = 1
    OnClick = Edit1DblClick
  end
  object Label2: TLabel
    Left = 24
    Height = 15
    Top = 64
    Width = 86
    Caption = 'Source Device'
  end
  object Label3: TLabel
    Left = 40
    Height = 15
    Top = 88
    Width = 60
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
    Height = 181
    Top = 376
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
    TabOrder = 2
  end
  object StringGrid1: TStringGrid
    AnchorSideTop.Control = Edit1
    Left = 8
    Height = 129
    Top = 116
    Width = 1088
    BorderSpacing.Top = 34
    ColCount = 6
    DefaultRowHeight = 18
    Font.Name = 'Nimbus Mono PS [UKWN]'
    Font.Pitch = fpFixed
    ParentFont = False
    RowCount = 6
    ScrollBars = ssNone
    TabOrder = 3
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
    Left = 111
    Height = 21
    Top = 12
    Width = 235
    Anchors = [akLeft]
    BorderSpacing.Top = 3
    Caption = 'Create System Backup (Image)'
    Checked = True
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 5
    TabStop = True
    OnChange = RadioButton1Change
  end
  object RadioButton2: TRadioButton
    AnchorSideLeft.Control = RadioButton1
    AnchorSideLeft.Side = asrBottom
    AnchorSideTop.Control = RadioButton1
    Left = 376
    Height = 21
    Top = 12
    Width = 237
    BorderSpacing.Left = 30
    Caption = 'Restore Backup or other Image'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 4
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
    Top = 249
    Width = 1088
    Anchors = [akTop, akLeft, akRight]
    BorderSpacing.Top = 4
    BevelInner = bvLowered
    ClientHeight = 100
    ClientWidth = 1088
    TabOrder = 6
    object CheckBox_RemoveSSH: TCheckBox
      Left = 15
      Height = 21
      Top = 54
      Width = 99
      Caption = 'remove SSH'
      Color = clDefault
      ParentColor = False
      TabOrder = 0
    end
    object CheckBox_RemoveDHCP: TCheckBox
      AnchorSideTop.Control = CheckBox_RemoveSSH
      AnchorSideTop.Side = asrCenter
      Left = 136
      Height = 21
      Top = 54
      Width = 112
      Caption = 'Remove DHCP'
      TabOrder = 1
    end
    object Edit2: TEdit
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Side = asrCenter
      AnchorSideRight.Control = ButtonCreateImage
      Left = 120
      Height = 23
      Top = 14
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
      Height = 21
      Top = 54
      Width = 169
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
      Left = 443
      Height = 24
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
      Top = 49
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
      Height = 21
      Top = 15
      Width = 72
      Caption = 'Exclude'
      Checked = True
      State = cbChecked
      TabOrder = 7
    end
    object CheckBox_Delimg: TCheckBox
      AnchorSideTop.Control = CheckBox_RemoveSSH
      Left = 520
      Height = 21
      Top = 54
      Width = 238
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
    Top = 249
    Width = 1088
    Anchors = [akTop, akLeft, akRight]
    BorderSpacing.Top = 4
    BevelInner = bvLowered
    ClientHeight = 100
    ClientWidth = 1088
    TabOrder = 7
    Visible = False
    object ScrollBar1: TScrollBar
      AnchorSideRight.Control = Eddeviceid
      AnchorSideRight.Side = asrBottom
      Left = 99
      Height = 14
      Top = 6
      Width = 560
      Anchors = [akTop, akRight]
      PageSize = 0
      TabOrder = 0
      OnChange = ScrollBar1Change
    end
    object Label_ManSelected: TLabel
      AnchorSideLeft.Side = asrCenter
      AnchorSideTop.Control = ScrollBar1
      AnchorSideTop.Side = asrCenter
      Left = 672
      Height = 18
      Top = 4
      Width = 288
      AutoSize = False
      Caption = '0 MB'
      Font.Height = 16
      ParentFont = False
    end
    object CheckBoxChangeDeviceID: TCheckBox
      AnchorSideTop.Control = Eddeviceid
      AnchorSideTop.Side = asrCenter
      Left = 391
      Height = 21
      Top = 23
      Width = 128
      Anchors = [akTop]
      Caption = 'change device id'
      TabOrder = 1
      OnChange = GridUpdate
    end
    object Eddeviceid: TEdit
      AnchorSideTop.Control = CheckBox_DelPartition3
      AnchorSideTop.Side = asrCenter
      Left = 539
      Height = 23
      Top = 22
      Width = 120
      Alignment = taCenter
      Anchors = []
      TabOrder = 2
      OnChange = EddeviceidChange
      OnKeyPress = EddeviceidKeyPress
    end
    object CheckBox_DelPartition4: TCheckBox
      AnchorSideTop.Control = Eddeviceid
      AnchorSideTop.Side = asrCenter
      Left = 216
      Height = 21
      Top = 23
      Width = 129
      Anchors = [akTop]
      Caption = 'delete partition 4'
      TabOrder = 3
      OnChange = GridUpdate
    end
    object CheckBox_DelPartition3: TCheckBox
      AnchorSideTop.Control = Eddeviceid
      AnchorSideTop.Side = asrCenter
      Left = 59
      Height = 21
      Top = 23
      Width = 137
      Anchors = [akTop]
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
      Top = 34
      Width = 164
      Anchors = [akRight, akBottom]
      BorderSpacing.Right = 45
      BorderSpacing.Bottom = 9
      Caption = 'Write image to device'
      TabOrder = 5
      OnClick = ButtonWriteImagetodeviceClick
    end
    object CBEnableSSH: TCheckBox
      AnchorSideTop.Control = EDhost
      AnchorSideTop.Side = asrCenter
      Left = 57
      Height = 21
      Top = 74
      Width = 94
      Anchors = [akTop]
      Caption = 'Enable SSH'
      TabOrder = 6
    end
    object edit_wlanssid: TEdit
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Control = EDhost
      AnchorSideTop.Side = asrCenter
      Left = 464
      Height = 23
      Top = 73
      Width = 192
      Anchors = [akTop]
      TabOrder = 7
    end
    object edit_wlanpassword: TEdit
      AnchorSideLeft.Control = edit_wlanssid
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Control = EDhost
      AnchorSideTop.Side = asrCenter
      Left = 812
      Height = 23
      Top = 73
      Width = 256
      Anchors = [akTop]
      TabOrder = 8
    end
    object EDusername: TEdit
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Side = asrCenter
      Left = 88
      Height = 23
      Top = 48
      Width = 164
      TabOrder = 9
    end
    object EDuserpassword: TEdit
      AnchorSideLeft.Control = EDusername
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Control = EDusername
      AnchorSideTop.Side = asrCenter
      Left = 372
      Height = 23
      Top = 48
      Width = 280
      Anchors = [akTop]
      TabOrder = 10
    end
    object EDhost: TEdit
      Left = 208
      Height = 23
      Top = 73
      Width = 180
      TabOrder = 11
    end
    object Label1: TLabel
      AnchorSideTop.Control = EDhost
      AnchorSideTop.Side = asrCenter
      Left = 173
      Height = 15
      Top = 77
      Width = 28
      Anchors = [akTop]
      Caption = 'Host'
    end
    object Label4: TLabel
      AnchorSideTop.Control = EDhost
      AnchorSideTop.Side = asrCenter
      Left = 421
      Height = 15
      Top = 77
      Width = 28
      Anchors = [akTop]
      Caption = 'SSID'
    end
    object Label5: TLabel
      AnchorSideTop.Control = EDhost
      AnchorSideTop.Side = asrCenter
      Left = 687
      Height = 15
      Top = 77
      Width = 104
      Anchors = [akTop]
      Caption = 'Passphrase (PSK)'
    end
    object Label6: TLabel
      AnchorSideTop.Control = EDusername
      AnchorSideTop.Side = asrCenter
      Left = 48
      Height = 15
      Top = 52
      Width = 28
      Caption = 'User'
    end
    object Label8: TLabel
      AnchorSideTop.Control = EDusername
      AnchorSideTop.Side = asrCenter
      Left = 264
      Height = 15
      Top = 52
      Width = 57
      Caption = 'Password'
    end
  end
  object BtSaveLog: TButton
    AnchorSideTop.Control = Button4
    AnchorSideTop.Side = asrCenter
    AnchorSideRight.Control = StringGrid1
    AnchorSideRight.Side = asrBottom
    Left = 997
    Height = 25
    Top = 16
    Width = 99
    Anchors = [akRight]
    Caption = 'Save Log'
    TabOrder = 8
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
    Top = 353
    Width = 1087
    Anchors = [akTop, akLeft, akRight]
    BorderSpacing.Left = 1
    BorderSpacing.Top = 108
    ParentColor = False
    ParentFont = False
    Smooth = True
    Step = 1
    TabOrder = 9
    BarShowText = True
  end
  object ComboBox1: TComboBox
    Left = 113
    Height = 23
    Top = 56
    Width = 672
    ItemHeight = 15
    TabOrder = 10
    OnCloseUp = ComboBox1CloseUp
    OnDropDown = ComboBox1DropDown
  end
  object Button1: TButton
    AnchorSideTop.Control = BtSaveLog
    AnchorSideTop.Side = asrCenter
    AnchorSideRight.Control = BtSaveLog
    Left = 910
    Height = 25
    Top = 16
    Width = 75
    Anchors = [akTop, akRight]
    BorderSpacing.Right = 12
    Caption = 'Help'
    TabOrder = 11
    OnClick = Button1Click
  end
  object Button6: TButton
    AnchorSideRight.Control = Button1
    Left = 818
    Height = 25
    Top = 16
    Width = 80
    Anchors = [akTop, akRight]
    BorderSpacing.Right = 12
    Caption = 'close'
    TabOrder = 12
  end
  object BTEditExclude: TButton
    AnchorSideLeft.Control = Button1
    AnchorSideLeft.Side = asrCenter
    Left = 886
    Height = 25
    Top = 48
    Width = 122
    Caption = 'Edit exclude files'
    TabOrder = 13
    OnClick = BTEditExcludeClick
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
end
