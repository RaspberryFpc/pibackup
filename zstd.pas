Unit Zstd;

{$mode objfpc}{$H+}

interface

uses
  baseunix,stdctrls,rkutils;

procedure CompressFileZstdWithProgress(const InFile, OutFile: string; Level, ThreadCount: integer; UseLongMode: boolean;listbox:Tlistbox);
procedure DecompressFileZstdWithProgress(const InFile, OutFile: string);

const
  ZSTD_LIB = 'libzstd.so';

  const
  ZSTD_c_compressionLevel = 100;
  ZSTD_c_nbWorkers = 400; // 🔁 Diese Zeile brauchst du!
  ZSTD_c_enableLongDistanceMatching = 160;

  ZSTD_e_continue = 0;
  ZSTD_e_end = 2;

type
  TZSTD_DStream = Pointer;
  TZSTD_CCtx = Pointer;
  TZSTD_DCtx = Pointer;

  TZSTD_inBuffer = record
    src: Pointer;
    size: NativeUInt;
    pos: NativeUInt;
  end;
  PZSTD_inBuffer = ^TZSTD_inBuffer;

  TZSTD_outBuffer = record
    dst: Pointer;
    size: NativeUInt;
    pos: NativeUInt;
  end;
 PZSTD_outBuffer = ^TZSTD_outBuffer;

 // === Kompression ===
function ZSTD_createCCtx(): TZSTD_CCtx; cdecl; external ZSTD_LIB;
function ZSTD_freeCCtx(cctx: TZSTD_CCtx): NativeUInt; cdecl; external ZSTD_LIB;
function ZSTD_CCtx_setParameter(cctx: TZSTD_CCtx; param: cint; value: cint): NativeUInt; cdecl; external ZSTD_LIB;
function ZSTD_compressStream2(cctx: TZSTD_CCtx; output: PZSTD_outBuffer;
  input: PZSTD_inBuffer; endOp: Integer): NativeUInt; cdecl; external ZSTD_LIB;
function ZSTD_initDStream(dstream: TZSTD_DStream): size_t; cdecl; external ZSTD_LIB;
function ZSTD_versionNumber: Cardinal; cdecl; external ZSTD_LIB;

// === Dekompression ===
function ZSTD_createDCtx(): TZSTD_DCtx; cdecl; external ZSTD_LIB;
function ZSTD_freeDCtx(dctx: TZSTD_DCtx): NativeUInt; cdecl; external ZSTD_LIB;
function ZSTD_decompressStream(dctx: TZSTD_DCtx;
  var output: TZSTD_outBuffer; var input: TZSTD_inBuffer): NativeUInt; cdecl; external ZSTD_LIB;

// === Fehlerbehandlung ===
function ZSTD_isError(code: NativeUInt): cint; cdecl; external ZSTD_LIB;
function ZSTD_getErrorName(code: NativeUInt): PChar; cdecl; external ZSTD_LIB;

implementation

uses
  Classes, SysUtils, DateUtils;

function GetCPUCount: Integer;
var
  f: TextFile;
  line: string;
begin
  Result := 0;
  AssignFile(f, '/proc/cpuinfo');
  Reset(f);
  try
    while not Eof(f) do
    begin
      ReadLn(f, line);
      if Pos('processor', line) = 1 then
        Inc(Result);
    end;
  finally
    CloseFile(f);
  end;
  if Result = 0 then
    Result := 1;
end;


const
 BuSize = 32 * 1024 * 1024; // 32 MiB für schnellere Verarbeitung
var
InBuf, OutBuf: array[0..BuSize - 1] of Byte;

procedure CompressFileZstdWithProgress(const InFile, OutFile: string; Level, ThreadCount: integer; UseLongMode: boolean; Listbox: TListBox);
const
  BarWidth = 30;
var
  input, output: record
    src: Pointer;
    size, pos: SizeUInt;
  end;
  linepos, n: Integer;
  fIn, fOut: TFileStream;
  cctx: Pointer;
  readBytes: Integer;
  totalRead, totalWritten, fileSize,fsize: Int64;
  ret: SizeUInt;
  startTime, lastUpdateTime: TDateTime;
  elapsedSecs, etaSecs, speed: Double;
  progress, compressionRatio: Double;
  bar, s: string;
  i: Integer;
begin
  // Threads auf maximalen Wert setzen, falls gewünscht
  ThreadCount := GetCPUCount;

  listbox.Items.Add('');
  Listboxaddscroll(listbox,'');

  n := ListBox.ClientHeight div ListBox.ItemHeight;
  linepos := ListBox.Items.Count - n + 2;
  if linepos < 0 then linepos := 0;

  fIn := TFileStream.Create(InFile, fmOpenRead);
  fOut := TFileStream.Create(OutFile, fmCreate);
  try
    fileSize := fIn.Size;
    totalRead := 0;
    totalWritten := 0;
    startTime := Now;
    lastUpdateTime := 0;

    cctx := ZSTD_createCCtx();
    if cctx = nil then raise Exception.Create('ZSTD_createCCtx failed');

    // Version info (optional)
    Listbox.Items.Add('ZSTD_versionNumber: ' + IntToStr(ZSTD_versionNumber));
    ListboxAddScroll(Listbox, '');
    // Set compression level
    ret := ZSTD_CCtx_setParameter(cctx, ZSTD_c_compressionLevel, Level);
    if ZSTD_isError(ret) <> 0 then
      raise Exception.Create('Set compression level failed: ' + StrPas(ZSTD_getErrorName(ret)));

    // Set thread count
    ret := ZSTD_CCtx_setParameter(cctx, ZSTD_c_nbWorkers, ThreadCount);
    if ZSTD_isError(ret) <> 0 then
      raise Exception.Create('Set thread count failed: ' + StrPas(ZSTD_getErrorName(ret)));

    // Enable long mode
    if UseLongMode then
    begin
      ret := ZSTD_CCtx_setParameter(cctx, ZSTD_c_enableLongDistanceMatching, 1);
      if ZSTD_isError(ret) <> 0 then
        raise Exception.Create('Enable long mode failed: ' + StrPas(ZSTD_getErrorName(ret)));
    end;

     //  ret := ZSTD_CCtx_setParameter(cctx, ZSTD_c_ldmWindowLog, 27); // 2^27 = 128 MiB     ist default

    // Hauptschleife
    repeat
      if terminate_all then
        raise Exception.Create('Vorgang abgebrochen.');

      readBytes := fIn.Read(InBuf, BuSize);
      input.src := @InBuf;
      input.size := readBytes;
      input.pos := 0;

      repeat
        output.src := @OutBuf;
        output.size := BuSize;
        output.pos := 0;

        ret := ZSTD_compressStream2(cctx, @output, @input, 0);
        if ZSTD_isError(ret) <> 0 then
          raise Exception.Create('Compress error: ' + StrPas(ZSTD_getErrorName(ret)));

        fOut.Write(OutBuf, output.pos);
        totalWritten += output.pos;
      until input.pos >= input.size;

      totalRead += input.pos;

      // Nur einmal pro Sekunde aktualisieren
      if SecondSpan(Now, lastUpdateTime) >= 1.0 then
      begin
        lastUpdateTime := Now;

        progress := totalRead / fileSize;
        elapsedSecs := SecondSpan(Now, startTime);
        speed := totalRead / 1024 / 1024 / elapsedSecs; // MiB/s

        if progress > 0 then
          etaSecs := (elapsedSecs / progress) - elapsedSecs
        else
          etaSecs := 0;

        if totalRead > 0 then
          compressionRatio := totalWritten / totalRead
        else
          compressionRatio := 1.0;

        // Fortschrittsbalken
        bar := '[';
        for i := 1 to BarWidth do
          if i <= Round(progress * BarWidth) then bar += '█' else bar += ' ';
        bar += ']';

        s := Format('%6.1f MiB / %6.1f MiB  %3d%% %s  ETA: %s  %.1f MiB/s  %3d%%',
          [totalRead / 1024 / 1024, fileSize / 1024 / 1024,
           Round(progress * 100), bar,
           FormatDateTime('nn:ss', etaSecs / 86400),
           speed,
           Round(compressionRatio * 100)]
        );
        listboxupdate(listbox,s);
      end;

    until readBytes = 0;

    // Stream beenden
    repeat
      output.src := @OutBuf;
      output.size := BuSize;
      output.pos := 0;

      ret := ZSTD_compressStream2(cctx, @output, @input, 2); // ZSTD_e_end
      if ZSTD_isError(ret) <> 0 then
        raise Exception.Create('Compress end error: ' + StrPas(ZSTD_getErrorName(ret)));

      fOut.Write(OutBuf, output.pos);
      totalWritten += output.pos;
    until ret = 0;

    ZSTD_freeCCtx(cctx);

   listboxaddscroll(listbox,'Size compressed file: ' +  inttostr(totalWritten div (1024*1024)) + ' MiB');

  finally
    fIn.Free;
    fOut.Free;
  end;
end;





procedure DecompressFileZstdWithProgress(const InFile, OutFile: string);
const
  BufferSize = 65536;
  BarWidth = 30;
var
  fIn, fOut: TFileStream;
  dctx: TZSTD_DCtx;
  InBuf, OutBuf: array[0..BufferSize - 1] of byte;
  input: TZSTD_inBuffer;
  output: TZSTD_outBuffer;
  readBytes: integer;
  ret: SizeUInt;
  totalRead, fileSize: Int64;
  startTime: TDateTime;
  elapsedSecs, etaSecs, progress: Double;
  bar: string;
  i: Integer;
begin
  fIn := TFileStream.Create(InFile, fmOpenRead);
  fOut := TFileStream.Create(OutFile, fmCreate);
  try
    fileSize := fIn.Size;
    totalRead := 0;
    startTime := Now;

    dctx := ZSTD_createDCtx;
    if dctx = nil then raise Exception.Create('ZSTD_createDCtx failed');

    ZSTD_initDStream(dctx);

    input.src := @InBuf;
    input.size := 0;
    input.pos := 0;

    repeat
      // Nur lesen, wenn alles aus input verarbeitet wurde
      if input.pos >= input.size then
      begin
        readBytes := fIn.Read(InBuf, BufferSize);
        input.src := @InBuf;
        input.size := readBytes;
        input.pos := 0;
        totalRead += readBytes;
      end;

      output.dst := @OutBuf;
      output.size := BufferSize;
      output.pos := 0;

      ret := ZSTD_decompressStream(dctx, output, input);
      if ZSTD_isError(ret) <> 0 then
        raise Exception.Create('Decompress error: ' + StrPas(ZSTD_getErrorName(ret)));

      fOut.Write(OutBuf, output.pos);

      // 📊 Fortschrittsanzeige auf Basis des komprimierten Inputs
      progress := totalRead / fileSize;
      elapsedSecs := SecondSpan(Now, startTime);
      if progress > 0 then
        etaSecs := (elapsedSecs / progress) - elapsedSecs
      else
        etaSecs := 0;

      bar := '[';
      for i := 1 to BarWidth do
        if i <= Round(progress * BarWidth) then bar += '█' else bar += ' ';
      bar += ']';

      Write(#13);
      Write(Format('%6.1f MiB / %6.1f MiB  %3d%% %s  ETA: %s',
        [totalRead / 1024 / 1024, fileSize / 1024 / 1024,
         Round(progress * 100), bar, FormatDateTime('nn:ss', etaSecs / 86400)]));

    until (readBytes = 0) and (input.pos >= input.size);

    ZSTD_freeDCtx(dctx);
    WriteLn(#13 + 'Dekomprimierung abgeschlossen in ', FormatDateTime('hh:nn:ss', Now - startTime));

  finally
    fIn.Free;
    fOut.Free;
  end;
end;





























end.

