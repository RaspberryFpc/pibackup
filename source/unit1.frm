object Form1: TForm1
  AnchorSideRight.Side = asrBottom
  Left = 171
  Height = 561
  Top = 115
  Width = 1016
  ClientHeight = 561
  ClientWidth = 1016
  Position = poDesktopCenter
  LCLVersion = '8.8'
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  object Edit1: TEdit
    Left = 113
    Height = 33
    Top = 82
    Width = 608
    ParentFont = False
    TabOrder = 0
    OnChange = GridUpdate
    OnDblClick = Edit1DblClick
  end
  object ComboBox1: TComboBox
    Left = 114
    Height = 33
    Top = 47
    Width = 608
    Anchors = [akLeft]
    ItemHeight = 29
    TabOrder = 1
    Text = 'Laufwerk'
    OnChange = GridUpdate
    OnDropDown = ComboBox1DropDown
  end
  object Button4: TButton
    AnchorSideTop.Control = Edit1
    AnchorSideTop.Side = asrCenter
    Left = 736
    Height = 30
    Top = 83
    Width = 126
    Caption = 'select'
    TabOrder = 2
    OnClick = Edit1DblClick
  end
  object Label2: TLabel
    Left = 32
    Height = 23
    Top = 56
    Width = 99
    Caption = 'Source Device'
  end
  object Label3: TLabel
    Left = 32
    Height = 23
    Top = 84
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
    Height = 181
    Top = 376
    Width = 995
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
    TabOrder = 3
  end
  object StringGrid1: TStringGrid
    AnchorSideTop.Control = Edit1
    Left = 8
    Height = 129
    Top = 116
    Width = 995
    BorderSpacing.Top = 34
    ColCount = 6
    DefaultRowHeight = 18
    Font.Name = 'Nimbus Mono PS [UKWN]'
    Font.Pitch = fpFixed
    ParentFont = False
    RowCount = 6
    ScrollBars = ssNone
    TabOrder = 4
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
    Height = 28
    Top = 8
    Width = 260
    Anchors = [akLeft]
    BorderSpacing.Top = 3
    Caption = 'Create System Backup (Image)'
    Checked = True
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 6
    TabStop = True
    OnChange = RadioButton1Change
  end
  object RadioButton2: TRadioButton
    AnchorSideLeft.Control = RadioButton1
    AnchorSideLeft.Side = asrBottom
    AnchorSideTop.Control = RadioButton1
    Left = 401
    Height = 28
    Top = 8
    Width = 261
    BorderSpacing.Left = 30
    Caption = 'Restore Backup or other Image'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 5
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
    Width = 995
    Anchors = [akTop, akLeft, akRight]
    BorderSpacing.Top = 4
    BevelInner = bvLowered
    ClientHeight = 100
    ClientWidth = 995
    TabOrder = 7
    object CheckBox_RemoveSSH: TCheckBox
      Left = 15
      Height = 28
      Top = 54
      Width = 118
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
      Width = 136
      Caption = 'Remove DHCP'
      TabOrder = 1
    end
    object Edit2: TEdit
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Side = asrCenter
      AnchorSideRight.Control = ButtonCreateImage
      Left = 120
      Height = 33
      Top = 9
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
      Width = 198
      Caption = 'Compress Image   Level'
      Checked = True
      State = cbChecked
      TabOrder = 4
    end
    object SpinEdit1: TSpinEdit
      AnchorSideTop.Control = CheckBox_RemoveSSH
      AnchorSideTop.Side = asrCenter
      Left = 464
      Height = 33
      Top = 52
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
      Width = 86
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
      Width = 273
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
    Width = 995
    Anchors = [akTop, akLeft, akRight]
    BorderSpacing.Top = 4
    BevelInner = bvLowered
    ClientHeight = 100
    ClientWidth = 995
    TabOrder = 8
    Visible = False
    object ScrollBar1: TScrollBar
      AnchorSideRight.Control = Eddeviceid
      AnchorSideRight.Side = asrBottom
      Left = 48
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
      Left = 616
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
      Left = 343
      Height = 28
      Top = 19
      Width = 147
      Anchors = [akTop]
      Caption = 'change device id'
      TabOrder = 1
      OnChange = GridUpdate
    end
    object Eddeviceid: TEdit
      AnchorSideTop.Control = CheckBox_DelPartition3
      AnchorSideTop.Side = asrCenter
      Left = 488
      Height = 33
      Top = 17
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
      Left = 181
      Height = 28
      Top = 19
      Width = 150
      Anchors = [akTop]
      Caption = 'delete partition 4'
      TabOrder = 3
      OnChange = GridUpdate
    end
    object CheckBox_DelPartition3: TCheckBox
      AnchorSideTop.Control = Eddeviceid
      AnchorSideTop.Side = asrCenter
      Left = 37
      Height = 28
      Top = 19
      Width = 158
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
      Left = 784
      Height = 30
      Top = 35
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
      Left = 38
      Height = 28
      Top = 76
      Width = 115
      Anchors = [akTop]
      Caption = 'Enable SSH'
      TabOrder = 6
    end
    object edit_wlanssid: TEdit
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Control = EDhost
      AnchorSideTop.Side = asrCenter
      Left = 416
      Height = 33
      Top = 74
      Width = 192
      Anchors = [akTop]
      TabOrder = 7
      OnChange = edit_wlanssidChange
    end
    object edit_wlanpassword: TEdit
      AnchorSideLeft.Control = edit_wlanssid
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Control = EDhost
      AnchorSideTop.Side = asrCenter
      Left = 732
      Height = 33
      Top = 74
      Width = 256
      Anchors = [akTop]
      TabOrder = 8
    end
    object EDusername: TEdit
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Side = asrCenter
      Left = 88
      Height = 33
      Top = 48
      Width = 164
      TabOrder = 9
    end
    object EDuserpassword: TEdit
      AnchorSideLeft.Control = EDusername
      AnchorSideLeft.Side = asrBottom
      AnchorSideTop.Control = EDusername
      AnchorSideTop.Side = asrCenter
      Left = 328
      Height = 33
      Top = 48
      Width = 280
      Anchors = [akTop]
      TabOrder = 10
    end
    object EDhost: TEdit
      Left = 192
      Height = 33
      Top = 74
      Width = 180
      TabOrder = 11
    end
    object Label1: TLabel
      AnchorSideTop.Control = EDhost
      AnchorSideTop.Side = asrCenter
      Left = 154
      Height = 23
      Top = 79
      Width = 35
      Anchors = [akTop]
      Caption = 'Host'
    end
    object Label4: TLabel
      AnchorSideTop.Control = EDhost
      AnchorSideTop.Side = asrCenter
      Left = 381
      Height = 23
      Top = 79
      Width = 35
      Anchors = [akTop]
      Caption = 'SSID'
    end
    object Label5: TLabel
      AnchorSideTop.Control = EDhost
      AnchorSideTop.Side = asrCenter
      Left = 615
      Height = 23
      Top = 79
      Width = 122
      Anchors = [akTop]
      Caption = 'Passphrase (PSK)'
    end
    object Label6: TLabel
      AnchorSideTop.Control = EDusername
      AnchorSideTop.Side = asrCenter
      Left = 48
      Height = 23
      Top = 53
      Width = 34
      Caption = 'User'
    end
    object Label8: TLabel
      AnchorSideTop.Control = EDusername
      AnchorSideTop.Side = asrCenter
      Left = 264
      Height = 23
      Top = 53
      Width = 69
      Caption = 'Password'
    end
  end
  object BtSaveLog: TButton
    AnchorSideTop.Control = Button4
    AnchorSideTop.Side = asrCenter
    AnchorSideRight.Control = StringGrid1
    AnchorSideRight.Side = asrBottom
    Left = 904
    Height = 30
    Top = 83
    Width = 99
    Anchors = [akTop, akRight]
    Caption = 'Save Log'
    TabOrder = 9
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
    Width = 994
    Anchors = [akTop, akLeft, akRight]
    BorderSpacing.Left = 1
    BorderSpacing.Top = 108
    ParentColor = False
    ParentFont = False
    Smooth = True
    Step = 1
    TabOrder = 10
    BarShowText = True
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = '.img'
    Left = 537
    Top = 56
  end
  object OpenDialog1: TOpenDialog
    Left = 586
    Top = 56
  end
  object OpenDialog2: TOpenDialog
    Left = 634
    Top = 50
  end
end
