unit UserSetup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, StdCtrls, Process, Unix, baseunix, StrUtils, rkutils;

type
  EUserSetup = class(Exception);

procedure EnsureUserConfigured(const Device: string; const NewUserName: string; const NewPassword: string; Log: TListBox);

procedure CreateUserConfFromDevice(mountpoint: string; const UserName: string; const Password: string; Log: TListBox);



type
  TUserInfo = record
    HostName: string;
    UserName: string;
    PasswordHash: string;
    SSID: string;
    WLANKey: string;
  end;




procedure ReadUserInfo(filename: string);



implementation

uses unit1;

// ---------------------------------------------------------------
// Logging
// ---------------------------------------------------------------
procedure LogMsg(log: tlistbox; const s: string);
begin
  if Assigned(Log) then listboxaddscroll(Log, s);
end;


// ---------------------------------------------------------------
// Run inside chroot
// ---------------------------------------------------------------

function RunInChroot(const RootMount, Cmd: string): integer;
begin
  Result := fpSystem(PChar('chroot "' + RootMount + '" /bin/bash -c "' + Cmd + '"'));
end;

// ---------------------------------------------------------------
// User detection
// ---------------------------------------------------------------
function FindExistingUser(const RootMount: string): string;
var
  SL: TStringList;
  line, Name, uid: string;
  i, uidInt: integer;
begin
  Result := '';
  SL := TStringList.Create;
  try
    SL.LoadFromFile(RootMount + '/etc/passwd');
    for i := 0 to SL.Count - 1 do
    begin
      line := SL[i].Trim;
      if line = '' then Continue;

      Name := Copy(line, 1, Pos(':', line) - 1);
      uid := ExtractDelimited(3, line, [':']);

      if TryStrToInt(uid, uidInt) and (uidInt >= 1000) then
      begin
        Result := Name;
        Exit;
      end;
    end;
  finally
    SL.Free;
  end;
end;

// ---------------------------------------------------------------
// Create userconf.txt on boot partition
// ---------------------------------------------------------------
procedure CreateUserConfFromDevice(mountpoint: string; const UserName: string; const Password: string; Log: TListBox);
var
  Hash, FileName: string;
begin

  try
    if not RunCommand('openssl passwd -6 "' + Password + '"', Hash) then
      raise Exception.Create('Password hashing failed: ' + Hash);

    Hash := Trim(Hash);

    if (Hash = '') or (Pos('$6$', Hash) = 0) then
      raise Exception.Create('Invalid SHA-512 hash!');

    FileName := mountpoint + '/userconf.txt';

    ForceDirectories(ExtractFileDir(FileName));
    with TStringList.Create do
    try
      Add(UserName + ':' + Hash);
      SaveToFile(FileName);
    finally
      Free;
    end;

    LogMsg(Log, 'Created userconf.txt');
  finally
  end;
end;

// ---------------------------------------------------------------
// User modifications inside root partition
// ---------------------------------------------------------------
procedure RenameUser(const RootMount, OldUser, NewUser: string; Log: TListBox);
begin
  LogMsg(Log, '→ Rename ' + OldUser + ' → ' + NewUser);

  if RunInChroot(RootMount, 'usermod -l ' + NewUser + ' ' + OldUser) <> 0 then
    raise EUserSetup.Create('usermod rename failed');

  if RunInChroot(RootMount, 'usermod -d /home/' + NewUser + ' -m ' + NewUser) <> 0 then
    raise EUserSetup.Create('usermod move home failed');
end;

procedure CreateUser(const RootMount, UserName: string; Log: TListBox);
begin
  LogMsg(Log, '→ Creating user "' + UserName + '"');

  if RunInChroot(RootMount, 'useradd -m -G sudo -s /bin/bash ' + UserName) <> 0 then
    raise EUserSetup.Create('useradd failed');
end;

procedure SetPassword(const RootMount, UserName, NewPassword: string; Log: TListBox);
begin
  if NewPassword = '' then
  begin
    LogMsg(Log, '→ Password unchanged');
    Exit;
  end;

  LogMsg(Log, '→ Setting password');

  if RunInChroot(RootMount, 'bash -c "echo ''' + UserName + ':' + NewPassword + ''' | chpasswd"') <> 0 then
    raise EUserSetup.Create('chpasswd failed');
end;

// ---------------------------------------------------------------
// HAUPTFUNKTION – only Device required
// ---------------------------------------------------------------
procedure EnsureUserConfigured(const Device: string; const NewUserName: string; const NewPassword: string; Log: TListBox);
var
  RootMount, OldUser: string;
begin
  LogMsg(Log, '--- User Setup on ' + Device + ' ---');

  RootMount := '/tmp/tmp_root_user';
  mountpartition(Device, 2, RootMount);

  //  if not MountPartition(Part2, RootMount) then
  //    raise Exception.Create('Failed to mount root partition: ' + Part2);

  try
    OldUser := FindExistingUser(RootMount);

    if OldUser = '' then
      CreateUser(RootMount, NewUserName, Log)
    else if OldUser <> NewUserName then
      RenameUser(RootMount, OldUser, NewUserName, Log)
    else
      LogMsg(Log, 'User already has correct name.');

    SetPassword(RootMount, NewUserName, NewPassword, Log);

    LogMsg(Log, '✔ User setup complete.');
  finally
    CloseMountTarget(RootMount);
  end;
end;


procedure ReadUserInfo(filename: string);
type
  TStringArray = array of string;
var
  SL: TStringList;
  line: string;
  x, uid: integer;
  PasswdPath, HostnamePath, SSIDFile, ShadowPath: string;
  ui: TUserInfo;
  parts: tstringarray;

// -------------------------------
// sichere Split-Funktion
// -------------------------------
  function Split(const S: string; const Delim: char): TStringArray;
  var
    i, p, last: integer;
  begin
    SetLength(Result, 0);
    last := 1;
    for i := 1 to Length(S) do
      if S[i] = Delim then
      begin
        p := Length(Result);
        SetLength(Result, p + 1);
        Result[p] := Copy(S, last, i - last);
        last := i + 1;
      end;
    // letztes Feld
    p := Length(Result);
    SetLength(Result, p + 1);
    Result[p] := Copy(S, last, MaxInt);
  end;



begin
  // -------------------------------
  // Init
  // -------------------------------
  ui.SSID := '';
  ui.UserName := '';
  ui.HostName := '';
  ui.PasswordHash := '';
  ui.WLANKey := '';
   with form1 do
  begin
    edhost.Text := '';
    edusername.Text := '';
    eduserpassword.Text := '';
    edit_wlanssid.Text := '';
    edit_wlanpassword.Text := '';
  end;

  if lowercase(extractfileext(filename)) = '.zst' then exit;

  // Root-Partition mounten
  MountPartition(Filename, 2, p2mpoint);

  try
    // -------------------------------
    // HOSTNAME
    // -------------------------------
    HostnamePath := p2mpoint + '/etc/hostname';
    if fpAccess(PChar(HostnamePath), F_OK) = 0 then
    begin
      SL := TStringList.Create;
      try
        SL.LoadFromFile(HostnamePath);
        if SL.Count > 0 then
          ui.HostName := Trim(SL[0]);
      finally
        SL.Free;
      end;
    end;

    // -------------------------------
    // USERNAME – erste echte UID >= 1000, < 60000
    // -------------------------------
    PasswdPath := p2mpoint + '/etc/passwd';
    if fpAccess(PChar(PasswdPath), F_OK) = 0 then
    begin
      SL := TStringList.Create;
      try
        SL.LoadFromFile(PasswdPath);
        for x := 0 to SL.Count - 1 do
        begin
          line := Trim(SL[x]);
          if line = '' then Continue;

          parts := Split(line, ':');
          if Length(parts) < 3 then Continue;  // UID existiert

          if TryStrToInt(parts[2], uid) then
          begin
            if (uid >= 1000) and (uid < 60000) then
            begin
              ui.UserName := parts[0]; // Hauptuser
              Break;
            end;
          end;
        end;
      finally
        SL.Free;
      end;
    end;

    // -------------------------------
    // PASSWORD HASH aus /etc/shadow
    // -------------------------------
    if ui.UserName <> '' then
    begin
      ShadowPath := p2mpoint + '/etc/shadow';
      if fpAccess(PChar(ShadowPath), F_OK) = 0 then
      begin
        SL := TStringList.Create;
        try
          SL.LoadFromFile(ShadowPath);
          for x := 0 to SL.Count - 1 do
          begin
            line := SL[x];
            if StartsText(ui.UserName + ':', line) then
            begin
              ui.PasswordHash := ExtractDelimited(2, line, [':']);
              Break;
            end;
          end;
        finally
          SL.Free;
        end;
      end;
    end;

    // -------------------------------
    // SSID & WLAN-PASSWORD aus preconfigured.nmconnection
    // -------------------------------
    SSIDFile := p2mpoint + '/etc/NetworkManager/system-connections/preconfigured.nmconnection';
    if fpAccess(PChar(SSIDFile), F_OK) = 0 then
    begin
      SL := TStringList.Create;
      try
        SL.LoadFromFile(SSIDFile);
        for x := 0 to SL.Count - 1 do
        begin
          line := Trim(SL[x]);

          if StartsText('ssid=', line) then
            ui.SSID := Copy(line, 6, MaxInt);

          if StartsText('psk=', line) then
            ui.WLANKey := Copy(line, 5, MaxInt);

          if StartsText('password=', line) then
            ui.WLANKey := Copy(line, 10, MaxInt); // fallback
        end;
      finally
        SL.Free;
      end;
    end;

  finally

  end;

  CloseMountTarget(p2mpoint);
  // -------------------------------
  // GUI füllen
  // -------------------------------
  with form1 do
  begin
    edhost.Text := ui.HostName;
    edusername.Text := ui.UserName;
    eduserpassword.Text := ui.PasswordHash;
    edit_wlanssid.Text := ui.SSID;
    edit_wlanpassword.Text := ui.WLANKey;
  end;
end;




end.
