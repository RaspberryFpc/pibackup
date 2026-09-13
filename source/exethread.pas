unit exethread;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, process, baseunix, unix, LazUTF8, fileutil, dateutils, StdCtrls, Forms, Dialogs,
  ExtCtrls, ComCtrls, rkutils;

type
  TPrexeThreaded = class(TThread)
  private
    FCmd: ansistring;
    FParams: array of string;
    FListBox: TListBox;
    FPass: integer;
    FProgressBar: TProgressBar;
    FResult: ansistring;
    FTempString: ansistring;
    FProgressMode: integer;
    FFinished: boolean;
    FExitCode: integer;
    procedure UpdateListBox;
    procedure AddListBoxLine;

  protected
    procedure Execute; override;
  public
    constructor Create(const Cmd: ansistring; Params: array of string; ListBox: TListBox; ProgressBar: TProgressBar = nil; ProgressMode: integer = 0);
    property ResultText: ansistring read FResult;
    property Finished: boolean read FFinished;
    property ExitCode: integer read FExitCode;
  end;

function PrexeThreadedBash(command: ansistring; box: TListBox; progressbar: tprogressbar = nil; progressmode: integer = 0): ansistring;

var
  LastExitCode: integer;


implementation



constructor TPrexeThreaded.Create(const Cmd: ansistring; Params: array of string; ListBox: TListBox; ProgressBar: TProgressBar; ProgressMode: integer);
begin
  inherited Create(True); // Thread suspendiert
  FCmd := Cmd;
  FParams := Copy(Params);
  FListBox := ListBox;       // muss immer übergeben werden
  FProgressBar := ProgressBar; // optional, kann nil sein
  FProgressMode := ProgressMode; // default 0
  FResult := '';
  fpass := 0;
  FFinished := False;
  FreeOnTerminate := False;
  if assigned(fprogressbar) then fprogressbar.Max := 1000;
  Start; // Thread starten
end;



// GUI-Methoden für Synchronize
procedure TPrexeThreaded.UpdateListBox;
const
  pass2step = 4;
  pass3step = 2;
  pass4step = 1;

  basestart3 = pass2step * 40;
  basestart4 = basestart3 + pass3step * 40;

  p_sum = basestart4 + pass4step * 40;
var
  x, Count: integer;
  s: string;
  pass: integer;
begin
  if Assigned(FListBox) then
    FListBox.Items[FListBox.Items.Count - 1] := FTempString;

  if fprogressmode = 1 then
  begin
    s := FListBox.Items[FListBox.Items.Count - 2];

    Count := 0;
    if pos('pass 2', s) > 0 then pass := 2;
    if pos('pass 3', s) > 0 then pass := 3;
    if pos('pass 4', s) > 0 then pass := 4;

    if pass = 2 then
    begin
      s := FTempString;
      for x := 1 to length(s) do if s[x] = 'X' then Inc(Count, pass2step);
      fprogressbar.Position := fprogressbar.Max * Count div p_sum;
    end;

    if pass = 3 then
    begin
      s := FTempString;
      for x := 1 to length(s) do if s[x] = 'X' then Inc(Count, pass3step);
      fprogressbar.Position := fprogressbar.Max * (Count + basestart3) div p_sum;
    end;

    if pass = 4 then
    begin
      s := FTempString;
      for x := 1 to length(s) do if s[x] = 'X' then Inc(Count, pass4step);
      fprogressbar.Position := fprogressbar.Max * (Count + basestart4) div p_sum;
    end;
  end;
end;

procedure TPrexeThreaded.AddListBoxLine;
begin
  if Assigned(FListBox) then listboxaddscroll(FListBox, '');
end;




// ----- Thread Execute -----
procedure TPrexeThreaded.Execute;
const
  BufferSize = 2048;
var
  pr: TProcess;
  buf: array[0..BufferSize - 1] of char;
  bytesRead, cPos, i, StartCount, xpos: integer;
  su, sm: ansistring;
begin
  FExitCode := -1;
  FResult := '';
  xpos := 0;
  FFinished := False;

  // Anzahl der Zeilen vor Thread-Start merken
  // Brauchen eine leere Zeile am anfang


  // Startzeile in ListBox
  if Assigned(FListBox) then
  begin
    Synchronize(@AddListBoxLine);
    StartCount := FListBox.Items.Count - 1;
  end;



  pr := TProcess.Create(nil);
  try
    pr.Executable := FCmd;
    pr.Options := [poUsePipes, poStderrToOutPut, poDefaultErrorMode];
    pr.PipeBufferSize := BufferSize;

    for i := 0 to High(FParams) do
      pr.Parameters.Add(FParams[i]);

    pr.Execute;

    while pr.Running do
    begin
      Sleep(50); // CPU schonen

      bytesRead := pr.Output.Read(buf, BufferSize);
      cPos := 0;

      repeat
        su := '';
        // Alle druckbaren Zeichen sammeln
        while (cPos < bytesRead) and (buf[cPos] > #31) do
        begin
          su := su + buf[cPos];
          Inc(cPos);
        end;

        if su <> '' then
        begin
          if Assigned(FListBox) then
          begin
            sm := FListBox.Items[FListBox.Items.Count - 1];
            Insert(su, sm, xpos + 1);
            Inc(xpos, Length(su));
            Delete(sm, xpos + 1, Length(su));
            FTempString := sm;
            if not terminated then Synchronize(@UpdateListBox);
          end;
        end;

        // Sonderzeichen verarbeiten
        if (cPos < bytesRead) then
        begin
          case buf[cPos] of
            #10: begin // LF
              Inc(cPos);
              xpos := 0;
              if Assigned(FListBox) then
                if not terminated then Synchronize(@AddListBoxLine);
            end;
            #13: begin // CR
              Inc(cPos);
              xpos := 0;
            end;
            #8: begin // Backspace
              Inc(cPos);
              Dec(xpos);
              if xpos < 0 then xpos := 0;
            end;
          end;
        end
        else
          Inc(cPos);

      until cPos >= bytesRead;

      // Thread abbrechen, falls Flag gesetzt
      if terminated then
      begin
        pr.Terminate(0);
        Sleep(500);
        if pr.Running then
          fpKill(pr.ProcessID, SIGKILL);
        Exit;
      end;
    end;

  finally
    // Nur die neuen Zeilen in FResult speichern
    if Assigned(FListBox) then
    begin
      FResult := '';
      for i := StartCount to FListBox.Items.Count - 1 do
        FResult := FResult + FListBox.Items[i] + sLineBreak;
    end;
    pr.WaitOnExit;
    FExitCode := pr.ExitStatus;
    FFinished := True; // Flag setzen
    pr.Free;
  end;
end;




function PrexeThreadedBash(command: ansistring; box: TListBox; progressbar: tprogressbar = nil; progressmode: integer = 0): ansistring;
var
  th: TPrexeThreaded;
begin
  lastexitcode := -1;

  if terminate_all then
    Exit('');



  // Thread starten
  th := TPrexeThreaded.Create('bash', ['-c', command], box, progressbar, progressmode);

  // Polling-Schleife, GUI bleibt aktiv

  while not th.Finished do
  begin
    Sleep(20);
    Application.ProcessMessages;
    if terminate_all then th.Terminate;
  end;
  Result := th.ResultText;
  Lastexitcode := th.FExitCode;
  th.Free;
end;

end.
