{*************************************************************************
                Copyright (c) PilotLogic Software House

  Package pl_ExControls
  This file is part of CodeTyphon Studio (https://www.pilotlogic.com/)

 ***** BEGIN LICENSE BLOCK *****
 * Version: LGPL-2.1 with link exception (Modified LGPL)
 *
 * The contents of this file are subject to the 
 * GNU LIBRARY GENERAL PUBLIC LICENSE Version 2.1 (the "License")
 * with the following modification:
 * 
 * As a special exception, the copyright holders of this library give you
 * permission to link this library with independent modules to produce an
 * executable, regardless of the license terms of these independent modules,
 * and to copy and distribute the resulting executable under terms of your choice,
 * provided that you also meet, for each linked independent module, the terms
 * and conditions of the license of that module. An independent module is a
 * module which is not derived from or based on this library. If you modify this
 * library, you may extend this exception to your version of the library, but
 * you are not obligated to do so. If you do not wish to do so, delete this
 * exception statement from your version.
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * ***** END LICENSE BLOCK *****
 
***************************************************************************}


{*************************************************************************
 *  Modified 2026.08.17  (repeat function)                               *
 *************************************************************************}

Unit TplScrollbarUnit;

{$MODE objfpc}{$H+}

Interface

Uses
   LCLIntf, LCLType, LMessages,
   SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
   ExtCtrls, TplButtonUnit, plUtils;

Type
   TplScrollbarThumb = Class(TplButton)
   Private
      FDown: boolean;
      FOldX, FOldY: integer;
      FTopLimit: integer;
      FBottomLimit: integer;
   Protected
      Procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: integer); Override;
      Procedure MouseMove(Shift: TShiftState; X, Y: integer); Override;
      Procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: integer); Override;
   Public
      Constructor Create(AOwner: TComponent); Override;
      Property Color;
   End;

   TplScrollbarTrack = Class(TCustomControl)
   Private
      FThumb: TplScrollbarThumb;
      FKind: TScrollBarKind;
      FSmallChange: integer;
      FLargeChange: integer;
      FMin: integer;
      FMax: integer;
      FPosition: integer;
      Procedure SetSmallChange(Value: integer);
      Procedure SetLargeChange(Value: integer);
      Procedure SetMin(Value: integer);
      Procedure SetMax(Value: integer);
      Procedure SetPosition(Value: integer);
      Procedure SetKind(Value: TScrollBarKind);
      Procedure WMSize(Var Message: TLMSize); Message LM_SIZE;
      Function ThumbFromPosition: integer;
      Function PositionFromThumb: integer;
      Procedure DoPositionChange;

      Procedure DoThumbColor(Value: TColor);
      Procedure DoHScroll(Var Message: TLMScroll);
      Procedure DoVScroll(Var Message: TLMScroll);
      Procedure DoGetPos(Var Message: TLMessage);
      Procedure DoGetRange(Var Message: TLMessage);
      Procedure DoSetPos(Var Message: TLMessage);
      Procedure DoSetRange(Var Message: TLMessage);
      Procedure DoKeyDown(Var Message: TLMKeyDown);
   Public
      Constructor Create(AOwner: TComponent); Override;
      Destructor Destroy; Override;
      Procedure Paint; Override;
   Published
      Property Align;
      Property Color;
      Property ParentColor;
      Property Min: integer Read FMin Write SetMin;
      Property Max: integer Read FMax Write SetMax;
      Property SmallChange: integer Read FSmallChange Write SetSmallChange;
      Property LargeChange: integer Read FLargeChange Write SetLargeChange;
      Property Position: integer Read FPosition Write SetPosition;
      Property Kind: TScrollBarKind Read FKind Write SetKind;
   End;

   TplScrollbarButton = Class(TplButton)
   Private
       FNewDown: boolean;
   FTimer: TTimer;
   FOnDown: TNotifyEvent;
           Procedure DoTimer(Sender: TObject);
   Protected
      Procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: integer); Override;
      Procedure MouseMove(Shift: TShiftState; X, Y: integer); Override;
      Procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: integer); Override;
   Public
      Constructor Create(AOwner: TComponent); Override;
      Destructor Destroy; Override;
   Published
      Property Align;
      Property OnDown: TNotifyEvent Read FOnDown Write FOnDown;
   End;

   TplOnScroll = Procedure(Sender: TObject; ScrollPos: integer) Of Object;

   TplScrollbar = Class(TCustomControl)
   Private
      FTrack: TplScrollbarTrack;
      FBtnOne: TplScrollbarButton;
      FBtnTwo: TplScrollbarButton;
      FMin: integer;
      FMax: integer;
      FSmallChange: integer;
      FLargeChange: integer;
      FPosition: integer;
      FKind: TScrollBarKind;
      FOnScroll: TplOnScroll;
      Procedure SetSmallChange(Value: integer);
      Procedure SetLargeChange(Value: integer);
      Procedure SetMin(Value: integer);
      Procedure SetMax(Value: integer);
      Procedure SetPosition(Value: integer);
      Procedure SetKind(Value: TScrollBarKind);
      Procedure BtnOneClick(Sender: TObject);
      Procedure BtnTwoClick(Sender: TObject);
      Procedure EnableBtnOne(Value: boolean);
      Procedure EnableBtnTwo(Value: boolean);
      Procedure DoScroll;
      Procedure DoFindSizes;

      Procedure CNHScroll(Var Message: TLMScroll); Message LM_HSCROLL;
      Procedure CNVScroll(Var Message: TLMScroll); Message LM_VSCROLL;
      Procedure WMKeyDown(Var Message: TLMKeyDown); Message LM_KEYDOWN;
   Public
      Constructor Create(AOwner: TComponent); Override;
      Destructor Destroy; Override;
      Procedure Paint; Override;
   Published
      Property Min: integer Read FMin Write SetMin Default 0;
      Property Max: integer Read FMax Write SetMax Default 100;
      Property SmallChange: integer Read FSmallChange Write SetSmallChange Default 1;
      Property LargeChange: integer Read FLargeChange Write SetLargeChange Default 1;
      Property Position: integer Read FPosition Write SetPosition Default 0;
      Property Kind: TScrollBarKind Read FKind Write SetKind Default sbHorizontal;
      Property OnScroll: TplOnScroll Read FOnScroll Write FOnScroll;

      Property Align;
      Property ParentColor;
      Property OnDragDrop;
      Property OnDragOver;
      Property OnEndDrag;
      Property OnEnter;
      Property OnExit;
      Property OnKeyDown;
      Property OnKeyUp;
      Property OnStartDrag;
   End;

Implementation

{$R TplScrollbarUnit.res}

Const
   cnBtnSize = 17;

Constructor TplScrollbarThumb.Create(AOwner: TComponent);
Begin
   Inherited Create(AOwner);
End;

Procedure TplScrollbarThumb.MouseMove(Shift: TShiftState; X, Y: integer);
Var
   iTop: integer;
Begin
   If TplScrollbarTrack(Parent).Kind = sbVertical Then
   Begin
      FTopLimit := 0;
      FBottomLimit := TplScrollbarTrack(Parent).Height;
      If FDown = True Then
      Begin
         iTop := Top + Y - FOldY;
         If iTop < FTopLimit Then
         Begin
            iTop := FTopLimit;
         End;
         If (iTop > FBottomLimit) Or ((iTop + Height) > FBottomLimit) Then
         Begin
            iTop := FBottomLimit - Height;
         End;
         Top := iTop;
      End;
   End
   Else
   Begin
      FTopLimit := 0;
      FBottomLimit := TplScrollbarTrack(Parent).Width;
      If FDown = True Then
      Begin
         iTop := Left + X - FOldX;
         If iTop < FTopLimit Then
         Begin
            iTop := FTopLimit;
         End;
         If (iTop > FBottomLimit) Or ((iTop + Width) > FBottomLimit) Then
         Begin
            iTop := FBottomLimit - Width;
         End;
         Left := iTop;
      End;
   End;
   TplScrollbarTrack(Parent).FPosition := TplScrollbarTrack(Parent).PositionFromThumb;
   TplScrollbarTrack(Parent).DoPositionChange;
   Inherited MouseMove(Shift, X, Y);
End;

Procedure TplScrollbarThumb.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: integer);
Begin
   FDown := False;
   Inherited MouseUp(Button, Shift, X, Y);
End;

Procedure TplScrollbarThumb.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: integer);
Begin
   If (Button = mbleft) And Not FDown Then
      FDown := True;
   FOldX := X;
   FOldy := Y;
   Inherited MouseDown(Button, Shift, X, Y);
End;

Constructor TplScrollbarTrack.Create(AOwner: TComponent);
Begin
   Inherited Create(AOwner);
   Color := clSilver;

   FThumb := TplScrollbarThumb.Create(Self);
   FThumb.Width := cnBtnSize;
   FThumb.Height := cnBtnSize;
   InsertControl(FThumb);

   FMin := 0;
   FMax := 100;
   FSmallChange := 1;
   FLargeChange := 1;
   FPosition := 0;
   FThumb.Top := ThumbFromPosition;
End;

Destructor TplScrollbarTrack.Destroy;
Begin
   FThumb.Free;
   Inherited Destroy;
End;

Procedure TplScrollbarTrack.Paint;
Begin
   Canvas.Brush.Color := DefiScrollbarColor;
   Canvas.FillRect(ClientRect);
   Frame3DBorder(Canvas, ClientRect, clGray, clwhite, 1);
End;

Procedure TplScrollbarTrack.SetSmallChange(Value: integer);
Begin
   If Value <> FSmallChange Then
   Begin
      FSmallChange := Value;
   End;
End;

Procedure TplScrollbarTrack.SetLargeChange(Value: integer);
Begin
   If Value <> FLargeChange Then
   Begin
      FLargeChange := Value;
   End;
End;

Procedure TplScrollbarTrack.SetMin(Value: integer);
Begin
   If Value <> FMin Then
   Begin
      FMin := Value;
      FThumb.Top := ThumbFromPosition;
   End;
End;

Procedure TplScrollbarTrack.SetMax(Value: integer);
Begin
   If Value <> FMax Then
   Begin
      FMax := Value;
      FThumb.Top := ThumbFromPosition;
   End;
End;

Procedure TplScrollbarTrack.SetPosition(Value: integer);
Begin
   FPosition := Value;
   If Position > Max Then
   Begin
      Position := Max;
   End;
   If Position < Min Then
   Begin
      Position := Min;
   End;
   Case FKind Of
      sbVertical: FThumb.Top := ThumbFromPosition;
      sbHorizontal: FThumb.Left := ThumbFromPosition;
   End;
End;

Procedure TplScrollbarTrack.SetKind(Value: TScrollBarKind);
Begin
   If Value <> FKind Then
   Begin
      FKind := Value;
      Case FKind Of
         sbVertical: FThumb.Height := cnBtnSize;
         sbHorizontal: FThumb.Width := cnBtnSize;
      End;
   End;
   Position := FPosition;
End;

Procedure TplScrollbarTrack.WMSize(Var Message: TLMSize);
Begin
   If FKind = sbVertical Then
   Begin
      FThumb.Width := Width;
   End
   Else
   Begin
      FThumb.Height := Height;
   End;
End;

Function TplScrollbarTrack.ThumbFromPosition: integer;
Var
   iHW, iMin, iMax, iPosition, iResult: integer;
Begin
   iHW := 0;
   Case FKind Of
      sbVertical: iHW := Height - FThumb.Height;
      sbHorizontal: iHW := Width - FThumb.Width;
   End;
   iMin := FMin;
   iMax := FMax;
   iPosition := FPosition;
   iResult := Round((iHW / (iMax - iMin)) * iPosition);
   Result := iResult;
End;

Function TplScrollbarTrack.PositionFromThumb: integer;
Var
   iHW, iMin, iMax, iPosition, iResult: integer;
Begin
   iHW := 0;
   Case FKind Of
      sbVertical: iHW := Height - FThumb.Height;
      sbHorizontal: iHW := Width - FThumb.Width;
   End;
   iMin := FMin;
   iMax := FMax;
   iPosition := 0;
   Case FKind Of
      sbVertical: iPosition := FThumb.Top;
      sbHorizontal: iPosition := FThumb.Left;
   End;
   iResult := Round(iPosition / iHW * (iMax - iMin));
   Result := iResult;
End;

Procedure TplScrollbarTrack.DoPositionChange;
Begin
   TplScrollbar(Parent).FPosition := Position;
   TplScrollbar(Parent).DoScroll;
End;

Procedure TplScrollbarTrack.DoThumbColor(Value: TColor);
Begin
   FThumb.Color := Value;
End;

Procedure TplScrollbarTrack.DoHScroll(Var Message: TLMScroll);
Var
   iPosition: integer;
Begin
   Case Message.ScrollCode Of
      SB_BOTTOM: Position := Max;
      SB_LINELEFT:
         Begin
            iPosition := Position;
            Dec(iPosition, SmallChange);
            Position := iPosition;
         End;
      SB_LINERIGHT:
         Begin
            iPosition := Position;
            Inc(iPosition, SmallChange);
            Position := iPosition;
         End;
      SB_PAGELEFT:
         Begin
            iPosition := Position;
            Dec(iPosition, LargeChange);
            Position := iPosition;
         End;
      SB_PAGERIGHT:
         Begin
            iPosition := Position;
            Inc(iPosition, LargeChange);
            Position := iPosition;
         End;
      SB_THUMBPOSITION, SB_THUMBTRACK: Position := Message.Pos;
      SB_TOP: Position := Min;
   End;
   Message.Result := 0;
End;

Procedure TplScrollbarTrack.DoVScroll(Var Message: TLMScroll);
Var
   iPosition: integer;
Begin
   Case Message.ScrollCode Of
      SB_BOTTOM: Position := Max;
      SB_LINEUP:
         Begin
            iPosition := Position;
            Dec(iPosition, SmallChange);
            Position := iPosition;
         End;
      SB_LINEDOWN:
         Begin
            iPosition := Position;
            Inc(iPosition, SmallChange);
            Position := iPosition;
         End;
      SB_PAGEUP:
         Begin
            iPosition := Position;
            Dec(iPosition, LargeChange);
            Position := iPosition;
         End;
      SB_PAGEDOWN:
         Begin
            iPosition := Position;
            Inc(iPosition, LargeChange);
            Position := iPosition;
         End;
      SB_THUMBPOSITION, SB_THUMBTRACK: Position := Message.Pos;
      SB_TOP: Position := Min;
   End;
   Message.Result := 0;
End;

Procedure TplScrollbarTrack.DoGetPos(Var Message: TLMessage);
Begin
   Message.Result := Position;
End;

Procedure TplScrollbarTrack.DoGetRange(Var Message: TLMessage);
Begin
   Message.WParam := Min;
   Message.LParam := Max;
End;

Procedure TplScrollbarTrack.DoSetPos(Var Message: TLMessage);
Begin
   Position := Message.WParam;
End;

Procedure TplScrollbarTrack.DoSetRange(Var Message: TLMessage);
Begin
   Min := Message.WParam;
   Max := Message.LParam;
End;

Procedure TplScrollbarTrack.DoKeyDown(Var Message: TLMKeyDown);
Var
   iPosition: integer;
Begin
   iPosition := Position;
   Case Message.CharCode Of
      VK_PRIOR: Dec(iPosition, LargeChange);
      VK_NEXT: Inc(iPosition, LargeChange);
      VK_UP: If FKind = sbVertical Then
            Dec(iPosition, SmallChange);
      VK_DOWN: If FKind = sbVertical Then
            Inc(iPosition, SmallChange);
      VK_LEFT: If FKind = sbHorizontal Then
            Dec(iPosition, SmallChange);
      VK_RIGHT: If FKind = sbHorizontal Then
            Inc(iPosition, SmallChange);
   End;
   Position := iPosition;
End;

Constructor TplScrollbarButton.Create(AOwner: TComponent);
Begin
   Inherited Create(AOwner);
   FTimer := TTimer.Create(Self);
   FTimer.Enabled := False;
   FTimer.Interval := 3;
   FTimer.OnTimer := @DoTimer;
End;

Destructor TplScrollbarButton.Destroy;
Begin
   FTimer.Enabled := False;
   FTimer.Free;
   Inherited Destroy;
End;

Procedure TplScrollbarButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: integer);
Begin
   Inherited MouseDown(Button, Shift, X, Y);
     FNewDown := True;
      ftimer.interval := 2;
     FTimer.Enabled := True;
End;



Procedure TplScrollbarButton.MouseMove(Shift: TShiftState; X, Y: integer);
Begin
   Inherited MouseMove(Shift, X, Y);
End;

Procedure TplScrollbarButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: integer);
Begin
   Inherited MouseUp(Button, Shift, X, Y);
   FNewDown := False;
   FTimer.Enabled := False;
End;



Procedure TplScrollbarButton.DoTimer(Sender: TObject);
Begin
   If FNewDown = True Then
   Begin
      If Assigned(FOnDown) Then
         FOnDown(Self);
      TplScrollbar(Parent).DoScroll;
      ftimer.interval := 150;
       FNewDown := false;
   End else
   begin
   ftimer.Interval:=30;
   If Assigned(FOnDown) Then
         FOnDown(Self);
   TplScrollbar(Parent).DoScroll;
   end;

End;





Constructor TplScrollbar.Create(AOwner: TComponent);
Begin
   Inherited Create(AOwner);

   self.SetInitialBounds(0, 0, 150, 12);

   FTrack := TplScrollbarTrack.Create(Self);
   InsertControl(FTrack);

   FBtnOne := TplScrollbarButton.Create(Self);
   FBtnOne.Glyph.LoadFromResourceName(hInstance, 'THUMB_LEFT_ENABLED');
   FBtnOne.OnDown := @BtnOneClick;
   InsertControl(FBtnOne);

   FBtnTwo := TplScrollbarButton.Create(Self);
   FBtnTwo.Glyph.LoadFromResourceName(hInstance, 'THUMB_RIGHT_ENABLED');
   FBtnTwo.OnDown := @BtnTwoClick;
   InsertControl(FBtnTwo);

   FBtnOne.Enabled := True;
   FBtnTwo.Enabled := True;

   Color := ecLightKaki;
   Kind := sbHorizontal;

   Min := 0;
   Max := 100;
   Position := 0;
   SmallChange := 1;
   LargeChange := 1;
End;

Destructor TplScrollbar.Destroy;
Begin
   FTrack.Free;
   FBtnOne.Free;
   FBtnTwo.Free;
   Inherited Destroy;
End;

Procedure TplScrollbar.SetSmallChange(Value: integer);
Begin
   If Value <> FSmallChange Then
   Begin
      FSmallChange := Value;
      FTrack.SmallChange := FSmallChange;
   End;
End;

Procedure TplScrollbar.SetLargeChange(Value: integer);
Begin
   If Value <> FLargeChange Then
   Begin
      FLargeChange := Value;
      FTrack.LargeChange := FLargeChange;
   End;
End;

Procedure TplScrollbar.SetMin(Value: integer);
Begin
   If Value <> FMin Then
   Begin
      FMin := Value;
      FTrack.Min := FMin;
   End;
End;

Procedure TplScrollbar.SetMax(Value: integer);
Begin
   If Value <> FMax Then
   Begin
      FMax := Value;
      FTrack.Max := FMax;
   End;
End;

Procedure TplScrollbar.SetPosition(Value: integer);
Begin
   FPosition := Value;
   If Position < Min Then
   Begin
      Position := Min;
   End;
   If Position > Max Then
   Begin
      Position := Max;
   End;
   FTrack.Position := FPosition;
End;

Procedure TplScrollbar.SetKind(Value: TScrollBarKind);
Var
   iw, ih: integer;
Begin

   If FKind = Value Then
      exit;

   iw := Height;
   ih := Width;

   FKind := Value;

   If (csDesigning In ComponentState) Or (csLoading In ComponentState) Then
   Begin
      FTrack.Kind := FKind;

      If FKind = sbVertical Then
      Begin
         FBtnOne.Glyph.LoadFromResourceName(hInstance, 'THUMB_UP_ENABLED');
         FBtnOne.Refresh;
         FBtnTwo.Glyph.LoadFromResourceName(hInstance, 'THUMB_DOWN_ENABLED');
         FBtnTwo.Refresh;
      End
      Else
      Begin
         FBtnOne.Glyph.LoadFromResourceName(hInstance, 'THUMB_LEFT_ENABLED');
         FBtnOne.Refresh;
         FBtnTwo.Glyph.LoadFromResourceName(hInstance, 'THUMB_RIGHT_ENABLED');
         FBtnTwo.Refresh;
      End;

   End
   Else
   Begin
      If FKind = sbVertical Then
      Begin
         FBtnOne.Glyph.LoadFromResourceName(hInstance, 'THUMB_UP_ENABLED');
         FBtnTwo.Glyph.LoadFromResourceName(hInstance, 'THUMB_DOWN_ENABLED');
      End
      Else
      Begin
         FBtnOne.Glyph.LoadFromResourceName(hInstance, 'THUMB_LEFT_ENABLED');
         FBtnTwo.Glyph.LoadFromResourceName(hInstance, 'THUMB_RIGHT_ENABLED');
      End;

      SetBounds(left, top, iw, ih);

      FBtnOne.Refresh;
      FBtnOne.Repaint;

      FBtnTwo.Repaint;
      FBtnTwo.Refresh;

      FTrack.Kind := FKind;
      FTrack.Repaint;
   End;

End;

Procedure TplScrollbar.BtnOneClick(Sender: TObject);
Var
   iPosition: integer;
Begin
   iPosition := Position;
   Dec(iPosition, SmallChange);
   Position := iPosition;
End;

Procedure TplScrollbar.BtnTwoClick(Sender: TObject);
Var
   iPosition: integer;
Begin
   iPosition := Position;
   Inc(iPosition, SmallChange);
   Position := iPosition;
End;

Procedure TplScrollbar.EnableBtnOne(Value: boolean);
Begin
   If Value = True Then
   Begin
      FBtnOne.Enabled := True;
      Case FKind Of
         sbVertical: FBtnOne.Glyph.LoadFromResourceName(hInstance, 'THUMB_UP_ENABLED');
         sbHorizontal: FBtnOne.Glyph.LoadFromResourceName(hInstance, 'THUMB_LEFT_ENABLED');
      End;
   End
   Else
   Begin
      Case FKind Of
         sbVertical: FBtnOne.Glyph.LoadFromResourceName(hInstance, 'THUMB_UP_DISABLED');
         sbHorizontal: FBtnOne.Glyph.LoadFromResourceName(hInstance, 'THUMB_LEFT_DISABLED');
      End;
      FBtnOne.Enabled := False;
   End;
End;

Procedure TplScrollbar.EnableBtnTwo(Value: boolean);
Begin
   If Value = True Then
   Begin
      FBtnTwo.Enabled := True;
      Case FKind Of
         sbVertical: FBtnTwo.Glyph.LoadFromResourceName(hInstance, 'THUMB_DOWN_ENABLED');
         sbHorizontal: FBtnTwo.Glyph.LoadFromResourceName(hInstance, 'THUMB_RIGHT_ENABLED');
      End;
   End
   Else
   Begin
      Case FKind Of
         sbVertical: FBtnTwo.Glyph.LoadFromResourceName(hInstance, 'THUMB_DOWN_DISABLED');
         sbHorizontal: FBtnTwo.Glyph.LoadFromResourceName(hInstance, 'THUMB_RIGHT_DISABLED');
      End;
      FBtnTwo.Enabled := False;
   End;
End;

Procedure TplScrollbar.DoFindSizes;
Begin
   If FKind = sbVertical Then
   Begin
      FTrack.SetBounds(0, cnBtnSize - 1, Width, ABS(Height - (2 * cnBtnSize) + 2));
      FBtnOne.SetBounds(0, 0, Width, cnBtnSize);
      FBtnTwo.SetBounds(0, ABS(Height - cnBtnSize), Width, cnBtnSize);
   End
   Else
   Begin
      FTrack.SetBounds(cnBtnSize - 1, 0, ABS(Width - (2 * cnBtnSize) + 2), Height);
      FBtnOne.SetBounds(0, 0, cnBtnSize, Height);
      FBtnTwo.SetBounds(ABS(Width - cnBtnSize), 0, cnBtnSize, Height);
   End;
   Position := FPosition;
End;

Procedure TplScrollbar.DoScroll;
Begin
   If Assigned(FOnScroll) Then
      FOnScroll(Self, Position);
End;

Procedure TplScrollbar.CNHScroll(Var Message: TLMScroll);
Begin
   FTrack.DoHScroll(Message);
End;

Procedure TplScrollbar.CNVScroll(Var Message: TLMScroll);
Begin
   FTrack.DoVScroll(Message);
End;

Procedure TplScrollbar.WMKeyDown(Var Message: TLMKeyDown);
Begin
   FTrack.DoKeyDown(Message);
End;

Procedure TplScrollbar.Paint;
Begin
   DoFindSizes;
   Inherited;
End;

End.
