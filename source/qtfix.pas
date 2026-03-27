unit qtfix;

{$mode objfpc}{$H+}

interface

implementation

uses
  {$IFDEF UNIX}
  ctypes;
  {$ENDIF}


{$IFDEF UNIX}
const
  libc = 'c';

function setenv(name: PChar; value: PChar; overwrite: cint): cint; cdecl; external libc name 'setenv';
{$ENDIF}

initialization
  {$IFDEF UNIX}
  setenv('QT_QPA_PLATFORM', 'xcb', 1);
  setenv('QT_AUTO_SCREEN_SCALE_FACTOR', '0', 1);
  setenv('QT_SCALE_FACTOR', '1', 1);

  // 🔥 Fix für deine Fehlermeldung
  setenv('XDG_RUNTIME_DIR', '/run/user/0', 1);
  {$ENDIF}

end.
