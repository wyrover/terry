unit notifieru;

interface

uses Windows, Messages, Classes, SysUtils, Forms, declu, toolu, GDIPAPI, gfx, dwm_unit;

type
  TNotifier = class
  private
    FHWnd: uint;
    WindowClassInstance: uint;
    FWndInstance: TFarProc;
    FPrevWndProc: TFarProc;
    FActivating: boolean;
    FX: integer;
    FY: integer;
    FXTarget: integer;
    FYTarget: integer;
    FW: integer;
    FH: integer;
    FShowTime: uint;
    FActive: boolean;
    FAlert: boolean;
    FTimeout: cardinal;
    FMonitor: integer;
    FText: string;
    procedure err(where: string; e: Exception);
  public
    FTextList: TStrings;
    class procedure Cleanup;
    constructor Create;
    destructor Destroy; override;
    function GetMonitorRect(monitor: integer): Windows.TRect;
    procedure Message(Text: string; monitor: integer = 0; alert: boolean = false; silent: boolean = false);
    procedure MessageNoLog(Text: string; monitor: integer = 0; replace: boolean = false);
    procedure Message_Internal(Caption, Text: string; monitor: integer; animate: boolean = True);
    procedure Close;
    procedure Timer;
    procedure WindowProc(var msg: TMessage);
  end;

var Notifier: TNotifier;

implementation
//------------------------------------------------------------------------------
class procedure TNotifier.Cleanup;
begin
  if assigned(Notifier) then Notifier.Free;
  Notifier := nil;
end;
//------------------------------------------------------------------------------
constructor TNotifier.Create;
begin
  inherited;
  FActive := false;
  FTextList := TStringList.Create;
  FText := '';

  // create window //
  FHWnd := 0;
  try
    FHWnd := CreateWindowEx(ws_ex_layered or ws_ex_toolwindow, WINITEM_CLASS, nil, ws_popup, 0, 0, 0, 0, 0, 0, hInstance, nil);
    if IsWindow(FHWnd) then
    begin
      SetWindowLong(FHWnd, GWL_USERDATA, cardinal(self));
      FWndInstance := MakeObjectInstance(WindowProc);
      FPrevWndProc := Pointer(GetWindowLong(FHWnd, GWL_WNDPROC));
      SetWindowLong(FHWnd, GWL_WNDPROC, LongInt(FWndInstance));
    end
    else err('Notifier.Create.CreateWindowEx failed', nil);
  except
    on e: Exception do err('Notifier.Create.CreateWindow', e);
  end;
end;
//------------------------------------------------------------------------------
destructor TNotifier.Destroy;
begin
  try
    // restore window proc
    if assigned(FPrevWndProc) then SetWindowLong(FHWnd, GWL_WNDPROC, LongInt(FPrevWndProc));
    DestroyWindow(FHWnd);
    if assigned(FTextList) then FTextList.Free;
    inherited;
  except
    on e: Exception do err('Notifier.Destroy', e);
  end;
end;
//------------------------------------------------------------------------------
function TNotifier.GetMonitorRect(monitor: integer): Windows.TRect;
begin
  result := screen.DesktopRect;
  if monitor >= screen.MonitorCount then monitor := screen.MonitorCount - 1;
  if monitor >= 0 then Result := screen.Monitors[monitor].WorkareaRect;
end;
//------------------------------------------------------------------------------
procedure TNotifier.Message(Text: string; monitor: integer = 0; alert: boolean = false; silent: boolean = false);
begin
  if alert then AddLog('!' + text) else AddLog(text);
  try
    FTextList.add('[' + formatdatetime('dd/MM/yyyy hh:nn:ss', now) + ']  ' + Text);
    self.FAlert := self.FAlert or alert;

    if not silent or alert then
    begin
      FTimeout := 8000;
      if length(Text) > 50 then FTimeout := 15000
      else if length(Text) > 30 then FTimeout := 11000;
      if FText = '' then FText := Text
      else FText := FText + #13#10#13#10 + Text;
      Message_Internal(declu.PROGRAM_NAME, FText, monitor, false);
    end;
  except
    on e: Exception do err('Notifier.Message', e);
  end;
end;
//------------------------------------------------------------------------------
procedure TNotifier.MessageNoLog(Text: string; monitor: integer = 0; replace: boolean = false);
begin
  try
    FTimeout := 8000;
    if length(Text) > 50 then FTimeout := 15000
    else if length(Text) > 30 then FTimeout := 11000;
    if replace or (FText = '') then FText := Text
    else FText := FText + #13#10#13#10 + Text;
    Message_Internal(declu.PROGRAM_NAME, FText, monitor, false);
  except
    on e: Exception do err('Notifier.MessageNoLog', e);
  end;
end;
//------------------------------------------------------------------------------
procedure TNotifier.Message_Internal(Caption, Text: string; monitor: integer; animate: boolean = True);
var
  hgdip, path, hbrush, hpen: Pointer;
  caption_font, message_font, font_family: Pointer;
  caption_rect, text_rect: TRectF;
  message_margin, wa: Windows.TRect;
  bmp: _SimpleBitmap;
  h_split, radius: integer;
  rgn: HRGN;
  alpha: uint;
  acoeff: integer;
begin
  if FActivating then exit;
  self.FMonitor := monitor;

  FActivating := True;
  radius := 3;
  h_split := 3;
  FW := 240;
  message_margin.left := radius * 2 div 3 + 3;
  message_margin.right := radius * 2 div 3 + 3;
  message_margin.top := radius * 2 div 3 + 3;
  message_margin.bottom := radius * 2 div 3 + 3;

  // context //
  try
    bmp.dc := CreateCompatibleDC(0);
    if bmp.dc = 0 then raise Exception.Create('CreateCompatibleDC failed');
    hgdip := CreateGraphics(bmp.dc, 0);
    if not assigned(hgdip) then raise Exception.Create('CreateGraphics failed');
  except
    on e: Exception do
    begin
      err('Notifier.Message_Internal.Context', e);
      FActivating := False;
      exit;
    end;
  end;

  // context //
  try
    GdipCreateFontFamilyFromName(PWideChar(WideString(GetFont)), nil, font_family);
    GdipCreateFont(font_family, 16, 1, 2, caption_font);
    GdipCreateFont(font_family, 14, 0, 2, message_font);
  except
    on e: Exception do
    begin
      err('Notifier.Message_Internal.Fonts', e);
      FActivating := False;
      exit;
    end;
  end;

  // measure //
  try
    caption_rect.x := 0;
    caption_rect.y := 0;
    caption_rect.Width := FW - message_margin.left - message_margin.right;
    caption_rect.Height := 0;
    GdipMeasureString(hgdip, PWideChar(WideString(Caption)), -1, caption_font, @caption_rect, nil, @caption_rect, nil, nil);
    caption_rect.Height := caption_rect.Height + 1;

    text_rect.x := 0;
    text_rect.y := 0;
    text_rect.Width := FW - message_margin.left - message_margin.right;
    text_rect.Height := 0;
    GdipMeasureString(hgdip, PWideChar(WideString(Text)), -1, message_font, @text_rect, nil, @text_rect, nil, nil);
    text_rect.Height := text_rect.Height + 1;

    caption_rect.x := message_margin.left;
    caption_rect.y := message_margin.top;

    text_rect.x := message_margin.left;
    text_rect.y := caption_rect.y + caption_rect.Height + h_split;

    if assigned(hgdip) then GdipDeleteGraphics(hgdip);
    if bmp.dc > 0 then DeleteDC(bmp.dc);

    FH := message_margin.top + trunc(caption_rect.Height) + h_split +
      trunc(text_rect.Height) + message_margin.bottom;

    // calc position //
    wa := GetMonitorRect(monitor);
    FXTarget := wa.right - FW - 2;
    FX := wa.right - FW div 2 - 2;
    FYTarget := wa.bottom - FH - 2;
    FY := FYTarget;
    if not animate then
    begin
      FX := FXTarget;
      FY := FYTarget;
    end;
  except
    on e: Exception do
    begin
      err('Notifier.Message_Internal.Measure', e);
      FActivating := False;
      exit;
    end;
  end;

  // prepare to paint //
  try
    bmp.topleft.x := FX;
    bmp.topleft.y := FY;
    bmp.Width := FW;
    bmp.Height := FH;
    if not gfx.CreateBitmap(bmp, FHWnd) then raise Exception.Create('CreateBitmap failed');
    hgdip := CreateGraphics(bmp.dc, 0);
    if not assigned(hgdip) then raise Exception.Create('CreateGraphics failed');
    GdipSetTextRenderingHint(hgdip, TextRenderingHintClearTypeGridFit);
    GdipSetSmoothingMode(hgdip, SmoothingModeAntiAlias);
  except
    on e: Exception do
    begin
      err('Notifier.Message_Internal.Prepare', e);
      FActivating := False;
      exit;
    end;
  end;

  // background //
  try
    GdipCreatePath(FillModeAlternate, path);
    AddPathRoundRect(path, 0, 0, FW, FH, radius);
    if dwm.IsCompositionEnabled then alpha := $80000000 else alpha := $ff101010;
    // fill
    GdipCreateSolidFill(alpha, hbrush);
    GdipFillPath(hgdip, hbrush, path);
    GdipDeleteBrush(hbrush);
    // outline
    GdipCreatePen1($60ffffff, 1, UnitPixel, hpen);
    GdipDrawPath(hgdip, hpen, path);
    GdipDeletePen(hpen);
    // cleanup
    GdipDeletePath(path);
  except
    on e: Exception do
    begin
      err('Notifier.Message_Internal.Backgroud', e);
      FActivating := False;
      exit;
    end;
  end;

  // message caption and text //
  try
    if FAlert then GdipCreateSolidFill($ffff5000, hbrush) else GdipCreateSolidFill($ffffffff, hbrush);
    GdipDrawString(hgdip, PWideChar(WideString(Caption)), -1, caption_font, @caption_rect, nil, hbrush);
    GdipDrawString(hgdip, PWideChar(WideString(Text)), -1, message_font, @text_rect, nil, hbrush);
    GdipDeleteBrush(hbrush);
  except
    on e: Exception do
    begin
      err('Notifier.Message_Internal.MessageCaptionAndText', e);
      FActivating := False;
      exit;
    end;
  end;

  // show //
  try
    acoeff := 255;
    if animate then
    begin
      acoeff := 255 - (abs(FX - FXTarget) * 510 div FW);
      if acoeff < 0 then acoeff := 0;
      if acoeff > 255 then acoeff := 255;
    end;
    gfx.UpdateLWindow(FHWnd, bmp, acoeff);
    SetWindowPos(FHWnd, $ffffffff, 0, 0, 0, 0, swp_noactivate + swp_nomove + swp_nosize + swp_showwindow);
    if dwm.IsCompositionEnabled then
    begin
      rgn := CreateRoundRectRgn(0, 0, FW, FH, radius * 2, radius * 2);
      DWM.EnableBlurBehindWindow(FHWnd, rgn);
      DeleteObject(rgn);
    end
    else
      DWM.DisableBlurBehindWindow(FHWnd);
  except
    on e: Exception do
    begin
      err('Notifier.Message_Internal.Show', e);
      FActivating := False;
      exit;
    end;
  end;

  // cleanup //
  try
    GdipDeleteFont(caption_font);
    GdipDeleteFont(message_font);
    GdipDeleteFontFamily(font_family);
    GdipDeleteGraphics(hgdip);
    gfx.DeleteBitmap(bmp);
  except
    on e: Exception do
    begin
      err('Notifier.Message_Internal.Cleanup', e);
      FActivating := False;
      exit;
    end;
  end;

  FShowTime := gettickcount;
  if not FActive then SetTimer(FHWnd, ID_TIMER, 10, nil);
  FActive := True;
  FActivating := False;
end;
//------------------------------------------------------------------------------
procedure TNotifier.Timer;
var
  delta: integer;
  set_pos: boolean;
  acoeff: integer;
  pt: windows.TPoint;
begin
  if FActive then
  try
    acoeff := 255 - (abs(FX - FXTarget) * 510 div FW);
    if acoeff < 0 then acoeff := 0;
    if acoeff > 255 then acoeff := 255;

    set_pos := (FXTarget <> FX) or (FYTarget <> FY);
    if set_pos then
    begin
      delta := abs(FXTarget - FX) div 6;
      if delta < 1 then delta := 1;
      if FX > FXTarget then Dec(FX, delta);
      if FX < FXTarget then Inc(FX, delta);
      delta := abs(FYTarget - FY) div 6;
      if delta < 1 then delta := 1;
      if FY > FYTarget then Dec(FY, delta);
      if FY < FYTarget then Inc(FY, delta);
      UpdateLWindowPosAlpha(FHWnd, FX, FY, acoeff);
    end;

    if (FX <> FXTarget) or (FY <> FYTarget) then FShowTime := gettickcount
    else
    if not FAlert then
    begin
      GetCursorPos(pt);
      if WindowFromPoint(pt) <> FHWnd then
        if gettickcount - FShowTime > FTimeout then Close;
    end;
  except
    on e: Exception do err('Notifier.Timer', e);
  end;
end;
//------------------------------------------------------------------------------
procedure TNotifier.Close;
var
  bmp: _SimpleBitmap;
begin
  try
    bmp.topleft.x := -1;
    bmp.topleft.y := -1;
    bmp.Width := 1;
    bmp.Height := 1;
    if gfx.CreateBitmap(bmp, FHWnd) then
    begin
      gfx.UpdateLWindow(FHWnd, bmp, 255);
      gfx.DeleteBitmap(bmp);
    end;

    DWM.DisableBlurBehindWindow(FHWnd);
    KillTimer(FHWnd, ID_TIMER);
    ShowWindow(FHWnd, 0);
    FActive := False;
    FAlert := False;
    FText := '';
  except
    on e: Exception do err('Notifier.Close', e);
  end;
end;
//------------------------------------------------------------------------------
procedure TNotifier.WindowProc(var msg: TMessage);
begin
  msg.Result := 0;
  if (msg.msg = wm_lbuttondown) or (msg.msg = wm_rbuttonup) then
  begin
    Close;
    exit;
  end
  else if msg.msg = WM_TIMER then
  begin
    Timer;
    exit;
  end;

  msg.Result := DefWindowProc(FHWnd, msg.msg, msg.wParam, msg.lParam);
end;
//------------------------------------------------------------------------------
procedure TNotifier.err(where: string; e: Exception);
begin
  if assigned(e) then
  begin
    AddLog(where + #10#13 + e.message);
    messagebox(FHWnd, PChar(where + #10#13 + e.message), declu.PROGRAM_NAME, MB_ICONERROR)
  end else begin
    AddLog(where);
    messagebox(FHWnd, PChar(where), declu.PROGRAM_NAME, MB_ICONERROR);
  end;
end;
//------------------------------------------------------------------------------
end.

