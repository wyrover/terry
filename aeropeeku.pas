unit aeropeeku;

interface

uses Windows, Messages, Classes, SysUtils, Forms, uxTheme, themes,
  declu, dwm_unit, GDIPAPI, gdip_gfx, toolu, processhlp;

type
  TAPWLayout = (apwlHorizontal, apwlVertical);

  TAeroPeekWindowItem = packed record
    hwnd: THandle;            // target window handle
    ThumbnailId: THandle;     // live preview thumbnail handle
    rect: windows.TRect;      // whole item rect
    rectSel: windows.TRect;   // whole item selection rect
    rectTitle: windows.TRect; // window title rect
    rectThumb: windows.TRect; // live thumbnail rect
    rectClose: windows.TRect; // close button rect
    Foreground: boolean;
  end;

  { TAeroPeekWindow }

  TAeroPeekWindow = class
  private
    FHWnd: uint;
    WindowClassInstance: uint;
    FWndInstance: TFarProc;
    FPrevWndProc: TFarProc;
    FBorder, FShadow, ThumbW, ThumbH, ItemSplit: integer;
    Fx: integer;
    Fy: integer;
    FXTarget: integer;
    FYTarget: integer;
    FWidth: integer;
    FHeight: integer;
    FWTarget: integer;
    FHTarget: integer;
    FTitleHeight: integer;
    FRadius: integer;
    FCloseButtonSize: integer;
    FCloseButtonOffset: integer;
    FCloseButtonDownIndex: integer;
    FActivating: boolean;
    FActive: boolean;
    FMonitor: integer;
    FSite: integer;
    FAnimate: boolean;
    FForegroundWindowIndex: integer;
    FColor1, FColor2: cardinal;
    FCompositionEnabled: boolean;
    FFontFamily: string;
    FFontSize: integer;
    FLayout: TAPWLayout;
    FItemCount: integer;
    items: array of TAeroPeekWindowItem;
    procedure DrawCloseButton(hgdip: pointer; rect: GDIPAPI.TRect; Pressed: boolean);
    procedure Paint;
    function GetMonitorRect(AMonitor: integer): Windows.TRect;
    procedure RegisterThumbnails;
    procedure SetItems(AppList: TFPList);
    procedure Timer;
    procedure UnRegisterThumbnails;
    procedure WindowProc(var msg: TMessage);
    procedure err(where: string; e: Exception);
  public
    property Handle: uint read FHWnd;
    property Active: boolean read FActive;

    class function Open(AppList: TFPList; AX, AY: integer; AMonitor: integer; Site: integer): boolean;
    class procedure SetPosition(AX, AY: integer; AMonitor: integer);
    class procedure Close(Timeout: cardinal = 0);
    class function IsActive: boolean;
    class procedure Cleanup;

    constructor Create;
    destructor Destroy; override;
    function OpenWindow(AppList: TFPList; AX, AY: integer; AMonitor: integer; Site: integer): boolean;
    procedure SetWindowPosition(AX, AY: integer; AMonitor: integer);
    procedure CloseWindow;
  end;

var AeroPeekWindow: TAeroPeekWindow;

implementation
uses frmmainu;
//------------------------------------------------------------------------------
// open (show) AeroPeekWindow
class function TAeroPeekWindow.Open(AppList: TFPList; AX, AY: integer; AMonitor: integer; Site: integer): boolean;
begin
  result := false;
  if not assigned(AeroPeekWindow) then AeroPeekWindow := TAeroPeekWindow.Create;
  if assigned(AeroPeekWindow) then result := AeroPeekWindow.OpenWindow(AppList, AX, AY, AMonitor, Site);
end;
//------------------------------------------------------------------------------
// set new position
class procedure TAeroPeekWindow.SetPosition(AX, AY: integer; AMonitor: integer);
begin
  if assigned(AeroPeekWindow) then AeroPeekWindow.SetWindowPosition(AX, AY, AMonitor);
end;
//------------------------------------------------------------------------------
// close AeroPeekWindow
// if Timeout set then close after timeout has elapsed
class procedure TAeroPeekWindow.Close(Timeout: cardinal = 0);
begin
  if assigned(AeroPeekWindow) then
  begin
    if Timeout = 0 then AeroPeekWindow.CloseWindow
    else SetTimer(AeroPeekWindow.Handle, ID_TIMER_CLOSE, Timeout, nil);
  end;
end;
//------------------------------------------------------------------------------
// check if AeroPeekWindow is visible
class function TAeroPeekWindow.IsActive: boolean;
begin
  result := false;
  if assigned(AeroPeekWindow) then result := AeroPeekWindow.Active;
end;
//------------------------------------------------------------------------------
// destroy window
class procedure TAeroPeekWindow.Cleanup;
begin
  if assigned(AeroPeekWindow) then AeroPeekWindow.Free;
  AeroPeekWindow := nil;
end;
//------------------------------------------------------------------------------
constructor TAeroPeekWindow.Create;
begin
  inherited;
  FActive := false;
  FAnimate := true;
  FFontFamily := toolu.GetFont;
  FFontSize := round(toolu.GetFontSize * 1.6);
  FCloseButtonDownIndex := -1;
  FItemCount := 0;

  // create window //
  FHWnd := 0;
  try
    FHWnd := CreateWindowEx(WS_EX_LAYERED + WS_EX_TOOLWINDOW, WINITEM_CLASS, nil, WS_POPUP, -100, -100, 1, 1, 0, 0, hInstance, nil);
    if IsWindow(FHWnd) then
    begin
      SetWindowLong(FHWnd, GWL_USERDATA, cardinal(self));
      FWndInstance := MakeObjectInstance(WindowProc);
      FPrevWndProc := Pointer(GetWindowLong(FHWnd, GWL_WNDPROC));
      SetWindowLong(FHWnd, GWL_WNDPROC, LongInt(FWndInstance));

      //if dwm.CompositionEnabled then dwm.ExtendFrameIntoClientArea(FHWnd, rect(-1,-1,-1,-1));
      //SetLayeredWindowAttributes(FHWnd, 0, 255, LWA_ALPHA);
    end
    else err('AeroPeekWindow.Create.CreateWindowEx failed', nil);
  except
    on e: Exception do err('AeroPeekWindow.Create.CreateWindow', e);
  end;
end;
//------------------------------------------------------------------------------
destructor TAeroPeekWindow.Destroy;
begin
  try
    // restore window proc
    if assigned(FPrevWndProc) then SetWindowLong(FHWnd, GWL_WNDPROC, LongInt(FPrevWndProc));
    DestroyWindow(FHWnd);
    inherited;
  except
    on e: Exception do err('AeroPeekWindow.Destroy', e);
  end;
end;
//------------------------------------------------------------------------------
function TAeroPeekWindow.GetMonitorRect(AMonitor: integer): Windows.TRect;
begin
  result := screen.DesktopRect;
  if AMonitor >= screen.MonitorCount then AMonitor := screen.MonitorCount - 1;
  if AMonitor >= 0 then Result := screen.Monitors[AMonitor].WorkareaRect;
end;
//------------------------------------------------------------------------------
procedure TAeroPeekWindow.RegisterThumbnails;
var
  index: integer;
  ThumbnailId: THandle;
begin
  if FCompositionEnabled then
    for index := 0 to FItemCount - 1 do
      dwm.RegisterThumbnail(FHWnd, items[index].hwnd, items[index].rectThumb, true, items[index].ThumbnailId);
end;
//------------------------------------------------------------------------------
procedure TAeroPeekWindow.UnRegisterThumbnails;
var
  index: integer;
begin
  if FItemCount > 0 then
    for index := 0 to FItemCount - 1 do dwm.UnregisterThumbnail(items[index].ThumbnailId);
end;
//------------------------------------------------------------------------------
procedure TAeroPeekWindow.DrawCloseButton(hgdip: pointer; rect: GDIPAPI.TRect; Pressed: boolean);
var
  brush, pen, path: Pointer;
  crossRect: GDIPAPI.TRect;
  color1, color2: cardinal;
begin
  if Pressed then
  begin
    color1 := $ffff3030;
    color2 := $ffff3030;
  end else begin
    color1 := $ffffa0a0;
    color2 := $ffff3030;
  end;
  // button
  GdipCreatePath(FillModeWinding, path);
  AddPathRoundRect(path, rect, 2);
  GdipCreateLineBrushFromRectI(@rect, color1, color2, LinearGradientModeVertical, WrapModeTileFlipY, brush);
  GdipFillPath(hgdip, brush, path);
  GdipDeleteBrush(brush);
  GdipCreatePen1($a0000000, 1, UnitPixel, pen);
  GdipDrawPath(hgdip, pen, path);
  GdipDeletePen(pen);
  //
  GdipResetPath(path);
  AddPathRoundRect(path, rect.x + 1, rect.y + 1, rect.width - 2, rect.height - 2, 2);
  GdipCreatePen1($60ffffff, 1, UnitPixel, pen);
  GdipDrawPath(hgdip, pen, path);
  GdipDeletePen(pen);
  GdipDeletePath(path);
  // cross
  crossRect.Width := rect.Width div 2;
  crossRect.Height := rect.Height div 2;
  crossRect.X := rect.X + (rect.Width - crossRect.Width) div 2;
  crossRect.Y := rect.Y + (rect.Height - crossRect.Height) div 2;
  GdipCreatePen1($a0000000, 4, UnitPixel, pen);
  GdipDrawLineI(hgdip, pen, crossRect.X, crossRect.Y, crossRect.X + crossRect.Width, crossRect.Y + crossRect.Height);
  GdipDrawLineI(hgdip, pen, crossRect.X, crossRect.Y + crossRect.Height, crossRect.X + crossRect.Width, crossRect.Y);
  GdipDeletePen(pen);
  GdipCreatePen1($c0ffffff, 2, UnitPixel, pen);
  GdipDrawLineI(hgdip, pen, crossRect.X + 1, crossRect.Y + 1, crossRect.X + crossRect.Width - 1, crossRect.Y + crossRect.Height - 1);
  GdipDrawLineI(hgdip, pen, crossRect.X + 1, crossRect.Y - 1 + crossRect.Height, crossRect.X + crossRect.Width - 1, crossRect.Y + 1);
  GdipDeletePen(pen);
end;
//------------------------------------------------------------------------------
procedure TAeroPeekWindow.Paint;
var
  bmp: _SimpleBitmap;
  hgdip, brush, pen, path, epath, family, font, format: Pointer;
  titleRect: GDIPAPI.TRectF;
  rect: GDIPAPI.TRect;
  pt: GDIPAPI.TPoint;
  shadowEndColor: array [0..0] of ARGB;
  rgn: HRGN;
  count, index: integer;
  title: string;
begin
  try
    // prepare //
    bmp.topleft.x := Fx;
    bmp.topleft.y := Fy;
    bmp.Width := FWidth;
    bmp.Height := FHeight;
    if not gdip_gfx.CreateBitmap(bmp) then raise Exception.Create('CreateBitmap failed');
    hgdip := CreateGraphics(bmp.dc, 0);
    if not assigned(hgdip) then raise Exception.Create('CreateGraphics failed');
    GdipSetTextRenderingHint(hgdip, TextRenderingHintAntiAlias);
    GdipSetSmoothingMode(hgdip, SmoothingModeAntiAlias);

    //
    GdipCreatePath(FillModeWinding, path);
    AddPathRoundRect(path, FShadow, FShadow, FWidth - FShadow * 2, FHeight - FShadow * 2, FRadius);

    // shadow
    if FShadow > 0 then
    begin
      // FShadow path
      GdipCreatePath(FillModeWinding, epath);
      AddPathRoundRect(epath, 0, 0, FWidth, FHeight, trunc(FRadius * 2.5));
      GdipSetClipPath(hgdip, path, CombineModeReplace);
      GdipSetClipPath(hgdip, epath, CombineModeComplement);
      // FShadow gradient
      GdipCreatePathGradientFromPath(epath, brush);
      GdipSetPathGradientCenterColor(brush, $ff000000);
      shadowEndColor[0] := 0;
      count := 1;
      GdipSetPathGradientSurroundColorsWithCount(brush, @shadowEndColor, count);
      pt := MakePoint(FWidth div 2 + 1, FHeight div 2 + 1);
      GdipSetPathGradientCenterPointI(brush, @pt);
      GdipSetPathGradientFocusScales(brush, 1 - 0.25 * FHeight / FWidth, 1 - 0.25);
      GdipFillPath(hgdip, brush, epath);
      GdipResetClip(hgdip);
      GdipDeleteBrush(brush);
      GdipDeletePath(epath);
    end;

    // background fill
    rect := GDIPAPI.MakeRect(FShadow, FShadow, FWidth - FShadow * 2, FHeight - FShadow * 2);
    GdipCreateLineBrushFromRectI(@rect, FColor1, FColor2, LinearGradientModeVertical, WrapModeTileFlipY, brush);
    GdipFillPath(hgdip, brush, path);
    GdipDeleteBrush(brush);
    // dark border
    GdipCreatePen1($a0000000, 1, UnitPixel, pen);
    GdipDrawPath(hgdip, pen, path);
    GdipDeletePen(pen);
    // light border
    GdipResetPath(path);
    AddPathRoundRect(path, FShadow + 1, FShadow + 1, FWidth - FShadow * 2 - 2, FHeight - FShadow * 2 - 2, FRadius);
    GdipCreatePen1($a0ffffff, 1, UnitPixel, pen);
    GdipDrawPath(hgdip, pen, path);
    GdipDeletePen(pen);
    GdipDeletePath(path);

    // item selection
    if (FItemCount > 0) and (FForegroundWindowIndex > -1) then
    begin
      GdipCreatePath(FillModeWinding, path);
      // selection fill
      rect := WinRectToGDIPRect(items[FForegroundWindowIndex].rectSel);
      AddPathRoundRect(path, rect, FRadius div 2);
      GdipCreateSolidFill($40b0d0ff, brush);
      GdipFillPath(hgdip, brush, path);
      GdipDeleteBrush(brush);
      // selection border
      GdipCreatePen1($a0b0d0ff, 1, UnitPixel, pen);
      GdipDrawPath(hgdip, pen, path);
      GdipDeletePen(pen);
      GdipDeletePath(path);
    end;

    // titles, close buttons
    GdipCreateFontFamilyFromName(PWideChar(WideString(FFontFamily)), nil, family);
    GdipCreateFont(family, FFontSize, 0, 2, font);
    GdipCreateSolidFill($ffffffff, brush);
    GdipCreateStringFormat(0, 0, format);
    GdipSetStringFormatFlags(format, StringFormatFlagsNoWrap);
    for index := 0 to FItemCount - 1 do
    begin
      // window title
      titleRect := WinRectToGDIPRectF(items[index].rectTitle);
      title := ProcessHelper.GetWindowText(items[index].hwnd);
      GdipDrawString(hgdip, PWideChar(WideString(title)), -1, font, @titleRect, format, brush);
      // close button
      rect := WinRectToGDIPRect(items[index].rectClose);
      DrawCloseButton(hgdip, rect, FCloseButtonDownIndex = index);
    end;
    GdipDeleteStringFormat(format);
    GdipDeleteBrush(brush);
    GdipDeleteFont(font);
    GdipDeleteFontFamily(family);

    // update window //
    UpdateLWindow(FHWnd, bmp, 255);
    GdipDeleteGraphics(hgdip);
    gdip_gfx.DeleteBitmap(bmp);
    if not FCompositionEnabled then SetWindowPos(FHWnd, $ffffffff, Fx, Fy, FWidth, FHeight, swp_noactivate + swp_showwindow);

    // enable blur behind
    if FCompositionEnabled then
    begin
      rgn := CreateRoundRectRgn(FShadow, FShadow, FWidth - FShadow, FHeight - FShadow, FRadius * 2, FRadius * 2);
      dwm.EnableBlurBehindWindow(FHWnd, rgn);
      DeleteObject(rgn);
    end;
  except
    on e: Exception do err('AeroPeekWindow.Paint', e);
  end;
end;
//------------------------------------------------------------------------------
procedure TAeroPeekWindow.SetItems(AppList: TFPList);
var
  index: integer;
  wa: windows.TRect;
  maxw, maxh: integer;
  //
  title: string;
  dc: HDC;
  hgdip, family, font: pointer;
  rect: GDIPAPI.TRectF;
begin
  FCloseButtonSize := 17;
  if FCompositionEnabled then
  begin
    FBorder := 22;
    FShadow := 8;
    FTitleHeight := 30;
    ItemSplit := 16;
    FCloseButtonOffset := 0;
    FRadius := 6;
    ThumbW := 200;
    wa := GetMonitorRect(FMonitor);
    ThumbH := round(ThumbW * (wa.Bottom - wa.Top) / (wa.Right - wa.Left));
  end else begin
    FBorder := 10;
    FShadow := 0;
    FTitleHeight := 21;
    ItemSplit := 10;
    FCloseButtonOffset := 2;
    FRadius := 2;
    ThumbW := 200;
    ThumbH := 0;
  end;

  FItemCount := AppList.Count;
  FForegroundWindowIndex := -1;
  maxw := 0;
  maxh := 0;

  SetLength(items, FItemCount);
  if FItemCount > 0 then
  begin
    // store target windows' handles
    for index := 0 to FItemCount - 1 do items[index].hwnd := THandle(AppList.Items[index]);

    // get max title width (if "no live preview" mode)
    if not FCompositionEnabled then
    begin
      dc := CreateCompatibleDC(0);
      if dc <> 0 then
      begin
        GdipCreateFromHDC(dc, hgdip);
        GdipCreateFontFamilyFromName(PWideChar(WideString(FFontFamily)), nil, family);
        GdipCreateFont(family, FFontSize, 0, 2, font);
        for index := 0 to FItemCount - 1 do
        begin
          title := ProcessHelper.GetWindowText(items[index].hwnd);
          rect.x := 0;
          rect.y := 0;
          rect.Width := 0;
          rect.Height := 0;
          GdipMeasureString(hgdip, PWideChar(WideString(title)), -1, font, @rect, nil, @rect, nil, nil);
          if round(rect.Width) + 5 + FCloseButtonSize > ThumbW then ThumbW := round(rect.Width) + 5 + FCloseButtonSize;
        end;
        GdipDeleteGraphics(hgdip);
        GdipDeleteFont(font);
        GdipDeleteFontFamily(family);
        DeleteDC(dc);
      end;
    end;

    // set item props
    for index := 0 to FItemCount - 1 do
    begin
      if FLayout = apwlHorizontal then
      begin
        items[index].rect.Left := FBorder + index * (ThumbW + ItemSplit);
        items[index].rect.Top := FBorder;
      end else begin
        items[index].rect.Left := FBorder;
        items[index].rect.Top := FBorder + index * (FTitleHeight + ThumbH + ItemSplit);
      end;
      items[index].rect.Right := items[index].rect.Left + ThumbW;
      items[index].rect.Bottom := items[index].rect.Top + FTitleHeight + ThumbH;
      if items[index].rect.Right - items[index].rect.Left > maxw then maxw := items[index].rect.Right - items[index].rect.Left;
      if items[index].rect.Bottom - items[index].rect.Top > maxh then maxh := items[index].rect.Bottom - items[index].rect.Top;

      items[index].rectSel := items[index].rect;
      items[index].rectSel.Left -= 5;
      items[index].rectSel.Top -= 5;
      items[index].rectSel.Right += 5;
      items[index].rectSel.Bottom += 5;

      items[index].rectThumb := items[index].rect;
      items[index].rectThumb.Top += FTitleHeight;

      items[index].rectTitle := items[index].rect;
      items[index].rectTitle.Right -= FCloseButtonSize + 5;
      items[index].rectTitle.Bottom := items[index].rectTitle.Top + FTitleHeight;

      items[index].rectClose := items[index].rect;
      items[index].rectClose.Top += FCloseButtonOffset;
      items[index].rectClose.Left := items[index].rectClose.Right - FCloseButtonSize;
      items[index].rectClose.Bottom := items[index].rectClose.Top + FCloseButtonSize;

      if IsWindowVisible(items[index].hwnd) and not IsIconic(items[index].hwnd) then
         if ProcessHelper.WindowOnTop(items[index].hwnd) then FForegroundWindowIndex := index;
    end;

    // calc width and height
    if FLayout = apwlHorizontal then
    begin
      FWTarget := FBorder * 2 + items[FItemCount - 1].rect.Right - items[0].rect.Left;
      FHTarget := FBorder * 2 + maxh;
    end else begin
      FWTarget := FBorder * 2 + maxw;
      FHTarget := FBorder * 2 + items[FItemCount - 1].rect.Bottom - items[0].rect.Top;
    end;
  end;
  if not FAnimate then
  begin
    FWidth := FWTarget;
    FHeight := FHTarget;
  end;
end;
//------------------------------------------------------------------------------
function TAeroPeekWindow.OpenWindow(AppList: TFPList; AX, AY: integer; AMonitor: integer; Site: integer): boolean;
var
  idx: integer;
  wa: windows.TRect;
  opaque: bool;
  hwnd: THandle;
begin
  result := false;
  if not FActivating then
  try
    try
      FActivating := true;
      FCompositionEnabled := dwm.CompositionEnabled;
      FAnimate := FCompositionEnabled;
      KillTimer(FHWnd, ID_TIMER_CLOSE);

      UnRegisterThumbnails;

      // read window list
      if AppList.Count = 0 then
      begin
        CloseWindow;
        exit;
      end;

      // size
      FMonitor := AMonitor;
      FSite := Site;
      FLayout := apwlHorizontal;
      if not FCompositionEnabled or (FSite = 0) or (FSite = 2) then FLayout := apwlVertical;
      SetItems(AppList);
      if not FActive then
      begin
        FWidth := FWTarget;
        FHeight := FHTarget;
      end;

      // position (default is bottom)
      FXTarget := AX - FWTarget div 2;
      FYTarget := AY - FHTarget;
      if FSite = 1 then // top
      begin
        FXTarget := AX - FWTarget div 2;
        FYTarget := AY;
      end else if FSite = 0 then // left
      begin
        FXTarget := AX;
        FYTarget := AY - FHTarget div 2;
      end else if FSite = 2 then // right
      begin
        FXTarget := AX - FWTarget;
        FYTarget := AY - FHTarget div 2;
      end;
      //
      if FAnimate then
      begin
        if not FActive then
        begin
          Fx := FXTarget;
          Fy := FYTarget + 20;
          if Site = 1 then // top
          begin
            Fx := FXTarget;
            Fy := FYTarget - 20;
          end else if Site = 0 then // left
          begin
            Fx := FXTarget - 20;
            Fy := FYTarget;
          end else if Site = 2 then // right
          begin
            Fx := FXTarget + 20;
            Fy := FYTarget;
          end;
        end;
      end
      else
      begin
        Fx := FXTarget;
        Fy := FYTarget;
      end;

      // update colors
      if not FActive then
      begin
        if FCompositionEnabled then
        begin
          FColor1 := $50000000;
          FColor2 := $10ffffff;
        end else begin
          FColor1 := $ff101010;
          FColor2 := $ff808080;
        end;
        dwm.GetColorizationColor(FColor1, opaque);
        if not FCompositionEnabled or opaque then FColor1 := FColor1 or $ff000000;
        if opaque then FColor2 := FColor2 or $ff000000;
      end;

      // show the window
      Paint;
      SetWindowPos(FHWnd, $ffffffff, 0, 0, 0, 0, swp_nomove + swp_nosize + swp_noactivate + swp_showwindow);
      SetActiveWindow(FHWnd);
      if not FActive then SetTimer(FHWnd, ID_TIMER, 10, nil);
      FActive := true;

      // register thumbnails
      RegisterThumbnails;
    finally
      FActivating := false;
    end;
  except
    on e: Exception do err('AeroPeekWindow.Message', e);
  end;
end;
//------------------------------------------------------------------------------
procedure TAeroPeekWindow.SetWindowPosition(AX, AY: integer; AMonitor: integer);
begin
  if FActive then
  begin
    FXTarget := AX - FWTarget div 2;
    FYTarget := AY - FHTarget;
    if FSite = 1 then // top
    begin
      FXTarget := AX - FWTarget div 2;
      FYTarget := AY;
    end else if FSite = 0 then // left
    begin
      FXTarget := AX;
      FYTarget := AY - FHTarget div 2;
    end else if FSite = 2 then // right
    begin
      FXTarget := AX - FWTarget;
      FYTarget := AY - FHTarget div 2;
    end;
    Fx := FXTarget;
    Fy := FYTarget;

    if FCompositionEnabled then UpdateLWindowPosAlpha(FHWnd, Fx, Fy, 255)
    else SetWindowPos(FHWnd, $ffffffff, Fx, Fy, 0, 0, swp_nosize + swp_noactivate + swp_showwindow);
  end;
end;
//------------------------------------------------------------------------------
procedure TAeroPeekWindow.CloseWindow;
begin
  try
    KillTimer(FHWnd, ID_TIMER_CLOSE);
    KillTimer(FHWnd, ID_TIMER);
    UnRegisterThumbnails;
    ShowWindow(FHWnd, 0);
    FActive := False;
    TAeroPeekWindow.Cleanup;
  except
    on e: Exception do err('AeroPeekWindow.CloseI', e);
  end;
end;
//------------------------------------------------------------------------------
procedure TAeroPeekWindow.Timer;
var
  delta: integer;
  rect: windows.TRect;
begin
  if FActive and not FActivating then
  try
    if (FXTarget <> Fx) or (FYTarget <> Fy) or (FWTarget <> FWidth) or (FHTarget <> FHeight) then
    begin
      delta := abs(FXTarget - Fx) div 4;
      if delta < 1 then delta := 1;
      if Fx > FXTarget then Dec(Fx, delta);
      if Fx < FXTarget then Inc(Fx, delta);

      delta := abs(FYTarget - Fy) div 4;
      if delta < 1 then delta := 1;
      if Fy > FYTarget then Dec(Fy, delta);
      if Fy < FYTarget then Inc(Fy, delta);

      delta := abs(FWTarget - FWidth) div 4;
      if delta < 1 then delta := 1;
      if FWidth > FWTarget then Dec(FWidth, delta);
      if FWidth < FWTarget then Inc(FWidth, delta);

      delta := abs(FHTarget - FHeight) div 4;
      if delta < 1 then delta := 1;
      if FHeight > FHTarget then Dec(FHeight, delta);
      if FHeight < FHTarget then Inc(FHeight, delta);

      Paint;
    end;
  except
    on e: Exception do err('AeroPeekWindow.Timer', e);
  end;
end;
//------------------------------------------------------------------------------
procedure TAeroPeekWindow.WindowProc(var msg: TMessage);
var
  index: integer;
  pt: windows.TPoint;
  rect: windows.TRect;
begin
  msg.Result := 0;

  // WM_LBUTTONDOWN
  if msg.msg = WM_LBUTTONDOWN then
  begin
    pt.x := TSmallPoint(msg.lParam).x;
    pt.y := TSmallPoint(msg.lParam).y;
    for index := 0 to FItemCount - 1 do
    begin
      if PtInRect(items[index].rectSel, pt) then
      begin
        if PtInRect(items[index].rectClose, pt) then
        begin
          FCloseButtonDownIndex := index;
          Paint;
        end;
      end;
    end;
    exit;
  end
  // WM_LBUTTONUP
  else if msg.msg = WM_LBUTTONUP then
  begin
    FCloseButtonDownIndex := -1;
    Paint;
    pt.x := TSmallPoint(msg.lParam).x;
    pt.y := TSmallPoint(msg.lParam).y;
    for index := 0 to FItemCount - 1 do
    begin
      if PtInRect(items[index].rectSel, pt) then
      begin
        if PtInRect(items[index].rectClose, pt) then ProcessHelper.CloseWindow(items[index].hwnd)
        else ProcessHelper.ActivateWindow(items[index].hwnd);
      end;
    end;
    CloseWindow;
    exit;
  end
  // WM_TIMER
  else if msg.msg = WM_TIMER then
  begin
    if msg.wParam = ID_TIMER then Timer;

    if msg.wParam = ID_TIMER_CLOSE then
    begin
      GetCursorPos(pt);
      if WindowFromPoint(pt) <> FHWnd then CloseWindow;
    end;

    exit;
  end;

  msg.Result := DefWindowProc(FHWnd, msg.msg, msg.wParam, msg.lParam);
end;
//------------------------------------------------------------------------------
procedure TAeroPeekWindow.err(where: string; e: Exception);
begin
  if assigned(e) then
  begin
    AddLog(where + #10#13 + e.message);
    messagebox(0, PChar(where + #10#13 + e.message), declu.PROGRAM_NAME, MB_ICONERROR)
  end else begin
    AddLog(where);
    messagebox(0, PChar(where), declu.PROGRAM_NAME, MB_ICONERROR);
  end;
end;
//------------------------------------------------------------------------------
end.

