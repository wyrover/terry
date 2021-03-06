unit itemmgru;

interface
uses Windows, Messages, Classes, SysUtils, Forms, IniFiles, Math,
  declu, DockH, toolu, gfx, GDIPAPI, processhlp,
  customitemu, scitemu, sepitemu, plgitemu, stackitemu, taskitemu;

const
  MAX_ITEM_COUNT = 128;

type
  PItem = ^TItem;
  TItem = record
    h: THandle;
    x: integer;
    y: integer;
    s: integer;
    xe: extended;
    ye: extended;
    se: extended;
  end;

  { TItemManager }

  TItemManager = class
  private
    FItemSize: integer;
    FBigItemSize: integer;
    FZoomWidth: integer;
    FItemSpacing: integer;
    FZoomItems: boolean; // enables zoom //
    FZoomTime: integer;
    ZoomStartTime: integer; // timestamp when zoming in or out has begun
    FReflection: boolean;
    FReflectionSize: integer;
    FItemAnimation: integer;
    FLaunchInterval: integer;
    FActivateRunning: boolean;
    FUseShellContextMenus: boolean;
    FShowHint: boolean;
    FStackAnimationEnabled: boolean;
    FSeparatorAlpha: integer;
    FOccupyFullMonitor: boolean;
    FFont: _FontData;
    FLockMouseEffect: boolean;
    FSetsFilename: string;
    FVisible: boolean;
    FEnabled: boolean;
    FTaskLivePreviews: boolean;
    FTaskThumbSize: integer;
    FTaskGrouping: boolean;
    FTaskSpot: integer;
    // for smooth zooming in and out //
    // 0 <= ZoomItemSizeDiff <= (BigItemSize - ItemSize) //
    ZoomItemSizeDiff: integer;
    // monitor index //
    FMonitor: integer;
    FSite: TBaseSite;
    FSiteVertical: boolean;
    FCenterOffsetPercent: integer;
    FEdgeOffset: integer;
    FWndOffset: integer;
    // Wnd Item Vars //
    FItemsArea: windows.TRect;
    FItemsArea2: windows.TRect;
    FMargin: integer; // dock icons offset from a monitor edge
    FMargin2: integer; // dock icons additional offset from a monitor edge

    procedure err(where: string; e: Exception; Critical: boolean = false);
    procedure notify(message: string);
    procedure DoBaseDraw(flags: integer);
    procedure SetVisible(value: boolean);

    // load/save //
    procedure AllItemsSave;
    procedure ItemSave(HWnd: uint);

    procedure SetItems1;
    procedure RecalcDock;
    procedure SetItems2(force_draw: boolean);

    function  IASize: integer;
    function  ItemFromPoint(Ax, Ay, distance: integer): extended;
    function  ItemRectFromPoint(Ax, Ay: integer): integer;

    // items //
    function  AddItem(data: string; Update: boolean = false): THandle;
    procedure AddTaskWindow(HWndTask: THandle);
  public
    FItemArray: array [0..MAX_ITEM_COUNT - 1] of TItem; // static = more stable
    FItemCount: integer;
    FHoverItemHWnd: THandle; // handle of the item over which the mouse is //
    FSelectedItemHWnd: THandle;
    _itemsDeleted: TFPList;
    _registeredPrograms: TStrings;
    // pos/size of ItemManager //
    x: integer;
    y: integer;
    width: integer;
    height: integer;
    widthZoomed: integer;
    heightZoomed: integer;
    FMonitorRect: Windows.TRect;
    FBaseWindowRect: GDIPAPI.TRect; // rect of the dock main window. updated on every RecalcDock //
    FBaseImageRect: GDIPAPI.TRect; // rect of the dock image. updated on every RecalcDock //
    _ZoomInOutItem: extended; // relative mouse position on last WHMouseMove //
    FZooming: boolean; // true if mouse is over the panel and any items are zoomed //
    FDropDistance: integer;
    FLockDragging: boolean;
    FDraggingItem: boolean; // indicates that item is being dragged //
    FDragHWnd: THandle; // handle of the item that is being dragged //
    FDraggingFile: boolean; // indicates that file is being dragged //
    FDropPlace: integer; // index of free space //
    FDropPlaceEx: integer; // index of a place to drop to //
    FParentHWnd: cardinal;
    FBaseCmd: TBaseCmd;

    property Visible: boolean read FVisible write SetVisible;
    property ItemsArea: windows.TRect read FItemsArea write FItemsArea;
    property ItemsArea2: windows.TRect read FItemsArea2 write FItemsArea2;
    property Margin: integer read FMargin write FMargin;
    property Margin2: integer read FMargin2 write FMargin2;
    property WndOffset: integer read FWndOffset write FWndOffset;

    constructor Create(AEnabled, AVisible: boolean; Handle: THandle; ABaseCmd: TBaseCmd;
      ItemSize, BigItemSize, ZoomWidth, ZoomTime, ItemSpacing: integer;
      ZoomItems, Reflection: boolean;
      ReflectionSize, LaunchInterval, ItemAnimation, SeparatorAlpha: integer;
      ActivateRunning, UseShellContextMenus, LockDragging, StackAnimationEnabled: boolean;
      TaskLivePreviews, TaskGrouping: boolean; TaskThumbSize, TaskSpot: integer;
      ShowHint: boolean; Font: _FontData);
    destructor Destroy; override;
    procedure Enable(value: boolean);
    procedure SetParam(id: TGParam; value: integer);
    procedure command(cmd, params: string);
    function  GetRect: windows.TRect;
    function  GetZoomEdge: integer;

    procedure Timer;
    procedure SetTheme;
    procedure ItemsChanged(FullUpdate: boolean = false);

    // load & save //
    procedure Load(fsets: string);
    procedure Save(fsets: string);

    // task item procs //
    procedure Taskbar;
    procedure ClearTaskbar;

    // items //
    function  ItemIndex(HWnd: HANDLE): integer;
    function  ItemHWnd(index: integer): HANDLE;
    procedure Clear;
    procedure ClearDeleted;
    procedure UnDelete;
    procedure CheckDeleted;
    function  ZOrder(InsertAfter: uint): uint;
    procedure InsertItems(list: TStrings);
    procedure InsertItem(AData: string);
    function  CreateItem(data: string): THandle;
    procedure DeleteItem(HWnd: THandle);

    // mouse effects //
    procedure SetDropPlaceFromPoint(pt: windows.TPoint);
    procedure SetDropPlace(index: integer);
    procedure SetDropPlaceEx(index: integer);
    procedure Zoom(x, y: integer);
    procedure UnZoom(do_now: boolean = false);
    function  CheckMouseOn: boolean;
    procedure WHMouseMove(pt: windows.TPoint; allow_zoom: boolean = true);
    procedure DragEnter;
    procedure DragOver;
    procedure DragLeave;
    procedure WMDeactivateApp;

    // Win Item Procs //
    procedure Undock(HWnd: HANDLE);
    procedure DockAdd(HWnd: THandle);
    procedure Dock(HWnd: HANDLE);
    function  IsItem(HWnd: HANDLE): HANDLE;
    function  ItemDropFile(HWndItem: HANDLE; pt: windows.TPoint; filename: string): boolean;
    function  ItemDropFiles(HWndItem: HANDLE; pt: windows.TPoint; files: TStrings): boolean;
    function  ItemCmd(HWnd: HANDLE; id: TGParam; param: integer): integer;
    function  AllItemCmd(id: TGParam; param: integer): integer;
    procedure SetFont(var Value: _FontData);
    procedure PluginCallCreate(HWnd: HANDLE);
    function  GetPluginFile(HWnd: HANDLE): string;
    procedure SetPluginImage(HWnd: HANDLE; lpImageNew: Pointer; AutoDelete: boolean);
    procedure SetPluginOverlay(HWnd: HANDLE; lpOverlayNew: Pointer; AutoDelete: boolean);
    procedure PluginAnimate(HWnd: HANDLE);
    procedure SetPluginCaption(HWnd: HANDLE; NewCaption: string);
    function  GetPluginCaption(HWnd: HANDLE): string;
    function  GetPluginRect(HWnd: HANDLE; var r: windows.TRect): boolean;
    function  IsPluginUndocked(HWnd: HANDLE): boolean;
    function  IsSeparator(HWnd: HANDLE): boolean;
end;

implementation
//------------------------------------------------------------------------------
constructor TItemManager.Create(AEnabled, AVisible: boolean; Handle: THandle; ABaseCmd: TBaseCmd;
      ItemSize, BigItemSize, ZoomWidth, ZoomTime, ItemSpacing: integer;
      ZoomItems, Reflection: boolean;
      ReflectionSize, LaunchInterval, ItemAnimation, SeparatorAlpha: integer;
      ActivateRunning, UseShellContextMenus, LockDragging, StackAnimationEnabled: boolean;
      TaskLivePreviews, TaskGrouping: boolean; TaskThumbSize, TaskSpot: integer;
      ShowHint: boolean; Font: _FontData);
begin
  inherited Create;

  // creation parameters
  FEnabled := AEnabled;
  FVisible := AVisible;
  FParentHWnd := Handle;
  FBaseCmd := ABaseCmd;
  FItemSize := ItemSize;
  FBigItemSize := BigItemSize;
  FZoomWidth := ZoomWidth;
  FZoomTime := ZoomTime;
  if FZoomTime < 1 then FZoomTime := 1;
  FItemSpacing := ItemSpacing;
  FZoomItems := ZoomItems;
  FReflection := Reflection;
  FReflectionSize := ReflectionSize;
  FLaunchInterval := LaunchInterval;
  FItemAnimation := ItemAnimation;
  FSeparatorAlpha := SeparatorAlpha;
  FActivateRunning := ActivateRunning;
  FUseShellContextMenus := UseShellContextMenus;
  FLockDragging := LockDragging;
  FStackAnimationEnabled := StackAnimationEnabled;
  FTaskLivePreviews := TaskLivePreviews;
  FTaskGrouping := TaskGrouping;
  FTaskThumbSize := TaskThumbSize;
  FTaskSpot := TaskSpot;
  FShowHint := ShowHint;
  CopyFontData(Font, FFont);

  // init
  FItemCount := 0;
  FZooming := false;
  ZoomItemSizeDiff := 0;
  FMonitor := 0;
  FDropDistance := 80;
  FDropPlace := NOT_AN_ITEM;
  FDropPlaceEx := NOT_AN_ITEM;
  FHoverItemHWnd := 0;
  FSelectedItemHWnd := 0;
  FDraggingItem := false;
  FDragHWnd := 0;
  FDraggingFile := false;
  FLockMouseEffect := false;
  FCenterOffsetPercent := 50;
  FEdgeOffset := 0;
  FWndOffset := 0;
  _itemsDeleted := TFPList.Create;
  _registeredPrograms := TStringList.Create;
end;
//------------------------------------------------------------------------------
destructor TItemManager.Destroy;
begin
  FEnabled := false;
  Clear;
  ClearDeleted;
  _itemsDeleted.Free;
  _registeredPrograms.free;
  inherited;
end;
//------------------------------------------------------------------------------
procedure TItemManager.Enable(value: boolean);
begin
  FEnabled := value;
end;
//------------------------------------------------------------------------------
procedure TItemManager.err(where: string; e: Exception; Critical: boolean = false);
begin
  if assigned(e) then where := where + ' '#10#13 + e.Message else where := where + ' '#10#13'Error';
  if Critical then
  begin
    messagebox(FParentHWnd,
      pchar(UTF8ToAnsi(XErrorCritical + ' ' + XErrorContactDeveloper) + #10#13#10#13 + where),
      PROGRAM_NAME, MB_ICONERROR);
    halt;
  end else
    raise Exception.Create(where);
end;
//------------------------------------------------------------------------------
procedure TItemManager.notify(message: string);
begin
  dockh.notify(0, pchar(message));
end;
//------------------------------------------------------------------------------
procedure TItemManager.SetParam(id: TGParam; value: integer);
begin
  try
    AllItemCmd(id, value);

    case id of
      gpItemSize:
        begin
          FItemSize := value;
          ItemsChanged(true);
        end;
      gpBigItemSize:            FBigItemSize := value;
      gpZoomWidth:
        begin
          FZoomWidth := value;
          WHMouseMove(classes.point(-100, -100));
        end;
      gpItemSpacing:
        begin
          FItemSpacing := value;
          ItemsChanged(true);
        end;
      gpZoomEnabled:
        begin
          FZoomItems := boolean(value);
          ItemsChanged(true);
        end;
      gpMonitor:
        begin
          FMonitor := value;
          ItemsChanged(true);
          Unzoom(true);
        end;
      gpSite:
        begin
          FSite := TBaseSite(value);
          FSiteVertical := (FSite = bsLeft) or (FSite = bsRight);
          ItemsChanged(true);
          Unzoom(true);
        end;
      gpCenterOffsetPercent:
        begin
          FCenterOffsetPercent := value;
          ItemsChanged;
        end;
      gpEdgeOffset:
        begin
          FEdgeOffset := value;
          ItemsChanged;
        end;
      gpDropDistance:           FDropDistance := value;
      gpLockDragging:           FLockDragging := boolean(value);
      gpReflectionEnabled:
        begin
          FReflection := boolean(value);
          ItemsChanged(true);
        end;
      gpReflectionSize:         FReflectionSize := value;
      gpTaskbar:                if value = 0 then ClearTaskbar;
      gpTaskLivePreviews:
        begin
          ClearTaskbar;
          FTaskLivePreviews := value <> 0;
        end;
      gpTaskThumbSize: FTaskThumbSize := value;
      gpTaskSpot: FTaskSpot := value;
      gpTaskGrouping:
        begin
          ClearTaskbar;
          FTaskGrouping := value <> 0;
        end;
      gpItemAnimationType:          FItemAnimation := value;
      gpLaunchInterval:         FLaunchInterval := value;
      gpActivateRunning:        FActivateRunning := value <> 0;
      gpUseShellContextMenus:   FUseShellContextMenus := value <> 0;
      gpShowHint:               FShowHint := value <> 0;
      gpStackAnimationEnabled:     FStackAnimationEnabled := value <> 0;
      gpZoomTime:
        begin
          FZoomTime := value;
          if FZoomTime < 1 then FZoomTime := 1;
				end;
			gpLockMouseEffect:        FLockMouseEffect := value <> 0;
      gpSeparatorAlpha:         FSeparatorAlpha := value;
      gpOccupyFullMonitor:      FOccupyFullMonitor := value <> 0;
    end;
  except
    on e: Exception do err('ItemManager.SetParam', e);
  end;
end;
//------------------------------------------------------------------------------
procedure TItemManager.command(cmd, params: string);
var
  data: string;
begin
  if FEnabled then
  try
    if cmd = 'clear' then Clear;
    if cmd = 'load' then
    begin
      if params <> '' then Load(params);
    end;
    if cmd = 'shortcut' then AddItem('class="shortcut";', true);
    if cmd = 'separator' then AddItem('class="separator";', true);
    if cmd = 'plugin' then AddItem('class="plugin";file="' + params + '";', true);
    if cmd = 'stack' then
    begin
      if length(params) = 0 then data := 'class="stack";'
      else data := 'class="stack";caption="::::";special_folder="' + params + '";';
      AddItem(data, true);
    end;
  except
    on e: Exception do err('ItemManager.Command::' + cmd + '(' + params + ')', e);
  end;
end;
//------------------------------------------------------------------------------
procedure TItemManager.DoBaseDraw(flags: integer);
begin
  if assigned(FBaseCmd) then FBaseCmd(tcRepaintBase, flags);
end;
//------------------------------------------------------------------------------
//
//
//
//   LOAD AND SAVE
//
//
//
//------------------------------------------------------------------------------
procedure TItemManager.Load(fsets: string);
var
  idx: integer;
  cls_name, data: string;
  ini: TIniFile;
  list: TStrings;
  stack: TStackItem;
begin
  if fsets = '' then exit;
  FDraggingItem := false;
  FDraggingFile := false;
  FDragHWnd := 0;

  try
    FSetsFilename := fsets;
    ini := TIniFile.Create(FSetsFilename);
    list := TStringList.Create;
    ini.ReadSections(list);
  except
    on e: Exception do err('ItemManager.Load.ReadIni', e, true);
  end;

  // read FItemArray //
  try
    idx := 0;
    while idx < list.count do
    begin
      if pos('item', list.strings[idx]) = 1 then
      begin
        cls_name := ini.ReadString(list.strings[idx], 'class', 'shortcut');
        data := 'class="' + cls_name + '";inifile="' + FSetsFilename + '";inisection="' + list.strings[idx] + '";';
        AddItem(data, false);
      end;
      inc(idx);
    end;
    ini.free;
  except
    on e: Exception do err('ItemManager.Load.ReadItems', e, true);
  end;

  // create default FItemArray if nothing loaded //
  try
    if FItemCount = 0 then
    begin
      // "end session" stack //
      AddItem(TStackItem.Make(0, 'End session', ''));
      stack := TStackItem(GetWindowLong(FItemArray[FItemCount - 1].h, GWL_USERDATA));
      if stack is TStackItem then
      begin
        stack.AddSubitem(TShortcutItem.Make(0, 'Shutdown', '/shutdown', '', '', 'images\default\shutdown.png'));
        stack.AddSubitem(TShortcutItem.Make(0, 'Reboot', '/reboot', '', '', 'images\default\reboot.png'));
        stack.AddSubitem(TShortcutItem.Make(0, 'Suspend', '/suspend', '', '', 'images\default\suspend.png'));
        stack.AddSubitem(TShortcutItem.Make(0, 'Hibernate', '/hibernate', '', '', 'images\default\hibernate.png'));
      end;
      // basic FItemArray //
      AddItem(TShortcutItem.Make(0, UTF8ToAnsi(XStartButtonText), '/startmenu', '', '', 'images\default\start.png'));
      AddItem(TShortcutItem.Make(0, 'Computer', 'CSIDL_DRIVES', '', '', ''));
      AddItem(TShortcutItem.Make(0, 'Control panel', 'CSIDL_CONTROLS', '', '', ''));
      AddItem(TShortcutItem.Make(0, 'Parameters', 'ms-settings:', '', '', '%sysdir%\shell32.dll,315'));
      AddItem(TShortcutItem.Make(0, 'Documents', '%doc%', '', '', ''));
      AddItem(TShortcutItem.Make(0, 'Recycle bin', 'CSIDL_BITBUCKET', '', '', ''));
      AddItem(TShortcutItem.Make(0, 'Dock settings', '/sets', '', '', 'images\default\settings.png'));
      AddItem(TShortcutItem.Make(0, 'Theme', '/theme', '', '', 'images\default\theme.png'));
      AddItem(TSeparatorItem.Make);
      AddItem(TShortcutItem.Make(0, 'Tray', '/tray', '', '', 'images\default\tray.png'));
      AddItem(TShortcutItem.Make(0, '', '', '', '', 'images\default\{LANGID}.png'));
      AddItem(TShortcutItem.Make(0, '', '/networks', '', '', 'images\default\network-{NETWORK}.png'));
      AddItem(TShortcutItem.Make(0, '', '/volume', '', '', 'images\default\audio-volume-{VOLUME}.png'));
    end;
  except
    on e: Exception do err('ItemManager.Load.Default', e);
  end;

  ItemsChanged;
end;
//------------------------------------------------------------------------------
procedure TItemManager.Save(fsets: string);
begin
  try
    if fsets <> '' then FSetsFilename := toolu.UnzipPath(fsets);
    AllItemsSave;
  except
    on e: Exception do err('ItemManager.Save', e);
  end;
end;
//------------------------------------------------------------------------------
procedure TItemManager.AllItemsSave;
var
  idx: integer;
begin
  if FEnabled and (FItemCount > 0) then
  try
    for idx := 0 to FItemCount - 1 do
    begin
      if FItemArray[idx].h <> 0 then
        TCustomItem(GetWindowLong(FItemArray[idx].h, GWL_USERDATA)).Save(pchar(FSetsFilename), pchar('item' + inttostr(idx + 1)));
    end;
  except
    on e: Exception do raise Exception.Create('ItemManager.AllItemsSave::' + inttostr(idx) + #10#13 + e.message);
  end;
end;
//------------------------------------------------------------------------------
procedure TItemManager.ItemSave(HWnd: uint);
var
  index: integer;
  Inst: TCustomItem;
begin
  try
    index := ItemIndex(HWnd);
    Inst := TCustomItem(GetWindowLong(HWnd, GWL_USERDATA));
    if Inst is TCustomItem then Inst.Save(pchar(FSetsFilename), pchar('item' + inttostr(index + 1)));
  except
    on e: Exception do raise Exception.Create('ItemManager.ItemSave::' + inttostr(index) + #10#13 + e.message);
  end;
end;
//------------------------------------------------------------------------------
//
//
//
//   ITEMS
//
//
//
//------------------------------------------------------------------------------
// clears the entire items array //
procedure TItemManager.Clear;
var
  idx: integer;
  Inst: TCustomItem;
begin
  if FItemCount > 0 then
  try
    for idx := 0 to FItemCount - 1 do
    begin
      Inst := TCustomItem(GetWindowLong(FItemArray[idx].h, GWL_USERDATA));
      Inst.Freed := true;
      FreeAndNil(Inst);
      FItemArray[idx].h := 0;
    end;
    FItemCount := 0;
  except
    on e: Exception do err('ItemManager.Clear', e);
  end;
end;
//------------------------------------------------------------------------------
// clears the "deleted items" array //
procedure TItemManager.ClearDeleted;
var
  idx: integer;
  Inst: TCustomItem;
begin
  if _itemsDeleted.Count > 0 then
  try
    for idx := 0 to _itemsDeleted.Count - 1 do
    begin
      Inst := TCustomItem(GetWindowLong(THandle(_itemsDeleted.Items[idx]), GWL_USERDATA));
      if Inst is TCustomItem then
      begin
        Inst.Freed := true;
        FreeAndNil(Inst);
      end;
    end;
    _itemsDeleted.Clear;
  except
    on e: Exception do err('ItemManager.ClearDeleted', e);
  end;
end;
//------------------------------------------------------------------------------
// restore deleted item in FILO order //
procedure TItemManager.UnDelete;
begin
  try
    CheckDeleted;

    // restore most recent deleted item //
    if _itemsDeleted.Count > 0 then
    begin
      DockAdd(THandle(_itemsDeleted.Items[_itemsDeleted.Count - 1]));
      _itemsDeleted.Delete(_itemsDeleted.Count - 1);
      ItemsChanged;
    end;
  except
    on e: Exception do err('ItemManager.UnDelete', e);
  end;
end;
//------------------------------------------------------------------------------
// clears out unwanted items from "deleted items" array //
procedure TItemManager.CheckDeleted;
var
  idx: integer;
  Inst: TCustomItem;
begin
  try
    // clear task FItemArray //
    if _itemsDeleted.Count > 0 then
      for idx := _itemsDeleted.Count - 1 downto 0 do
      begin
        Inst := TCustomItem(GetWindowLong(THandle(_itemsDeleted.Items[idx]), GWL_USERDATA));
        if Inst is TTaskItem then
        begin
          FreeAndNil(Inst);
          _itemsDeleted.Delete(idx);
        end;
      end;
  except
    on e: Exception do err('ItemManager.CheckDeleted', e);
  end;
end;
//------------------------------------------------------------------------------
function TItemManager.ItemIndex(HWnd: HANDLE): integer;
var
  idx: integer;
begin
  try
    result := NOT_AN_ITEM;
    if (HWnd = 0) or (FItemCount <= 0) then exit;

    for idx := 0 to FItemCount - 1 do
    begin
      if FItemArray[idx].h = HWnd then
      begin
        result := idx;
        break;
      end;
    end;
  except
    on e: Exception do err('ItemManager.ItemIndex', e);
  end;
end;
//------------------------------------------------------------------------------
function TItemManager.ItemHWnd(index: integer): HANDLE;
begin
  result := 0;
  if (index >= 0) and (index < FItemCount) then result := FItemArray[index].h;
end;
//------------------------------------------------------------------------------
function TItemManager.ZOrder(InsertAfter: uint): uint;
var
  idx: integer;
begin
  result := 0;
  if FEnabled then
  try
    if FItemCount > 0 then result := ItemHWnd(0);
    idx := 0;
    while idx < FItemCount do
    begin
      SetWindowPos(ItemHWnd(idx), InsertAfter, 0, 0, 0, 0, SWP_NO_FLAGS);
      inc(idx);
    end;
  except
    on e: Exception do err('ItemManager.ZOrder', e);
  end;
end;
//------------------------------------------------------------------------------
procedure TItemManager.Timer;
var
  elapsed: integer;
  doUpdate: boolean;
  item: integer;
  Inst: TCustomItem;
begin
  if not FEnabled then exit;
  doUpdate := false;

  // zoom in/out smoothly //
  if FZoomItems or (ZoomItemSizeDiff > 0) then
  try
      if FZooming and (ZoomItemSizeDiff < FBigItemSize - FItemSize) then
      begin
        doUpdate := true;
        elapsed := abs(GetTickCount - ZoomStartTime);
        if elapsed > FZoomTime then elapsed := FZoomTime;
        ZoomItemSizeDiff := (FBigItemSize - FItemSize) * elapsed div FZoomTime;
      end;

      if not FZooming and (ZoomItemSizeDiff > 0) then
      begin
        doUpdate := true;
        elapsed := abs(GetTickCount - ZoomStartTime);
        if elapsed > FZoomTime then elapsed := FZoomTime;
        ZoomItemSizeDiff := FBigItemSize - FItemSize - (FBigItemSize - FItemSize) * elapsed div FZoomTime;
      end;
  except
    on e: Exception do err('ItemManager.Timer.SmoothZoom', e);
  end;

  try
    item := 0;
    while item < FItemCount do
    begin
      Inst := TCustomItem(GetWindowLong(FItemArray[item].h, GWL_USERDATA));
      if Inst is TCustomItem then Inst.Timer;
      inc(item);
    end;
  except
    on e: Exception do err('ItemManager.Timer.ItemTimer', e);
  end;

  if doUpdate then ItemsChanged;
end;
//------------------------------------------------------------------------------
procedure TItemManager.SetTheme;
begin
  AllItemCmd(tcThemeChanged, 0);
  ItemsChanged(true);
end;
//------------------------------------------------------------------------------
procedure TItemManager.ItemsChanged(FullUpdate: boolean = false);
begin
  if FEnabled then
  try
    SetItems1;
    RecalcDock;
    SetItems2(FullUpdate);
    DoBaseDraw(ifthen(FullUpdate, 1, 0));
  except
    on e: Exception do err('ItemManager.ItemsChanged', e);
  end;
end;
//------------------------------------------------------------------------------
procedure TItemManager.SetVisible(value: boolean);
begin
  if FVisible <> value then
  begin
    UnZoom(true);
    AllItemCmd(icHover, 0);
    AllItemCmd(icSelect, 0);
    AllItemCmd(icVisible, integer(value));
    FHoverItemHWnd := 0;
    FSelectedItemHWnd := 0;
  end;
  FVisible := value;
  ItemsChanged;
end;
//------------------------------------------------------------------------------
procedure TItemManager.SetItems1;
  function getHalfBubble: extended;
  var
    i: extended;
  begin
    result := ZoomItemSizeDiff / 2;
    i := 0.5;
    while i < FZoomWidth / 2 do
    begin
      result := result + (ZoomItemSizeDiff - 1) * (cos(PI * i * 2 / FZoomWidth) + 1) / 2;
      i := i + 1;
    end;
  end;

var
  i, itemPos: integer;
  sizeInc: extended;
  offset: extended;
begin
  if not FEnabled then exit;

  try
    if FSiteVertical then
    begin
      y := FMonitorRect.Top + (FMonitorRect.Bottom - FMonitorRect.Top - IASize) * FCenterOffsetPercent div 100;
    end else begin
      x := FMonitorRect.Left + (FMonitorRect.Right - FMonitorRect.Left - IASize) * FCenterOffsetPercent div 100;
    end;

    // zoomed bubble additional size //
    offset := getHalfBubble;

    // calc FItemArray' pos and size //
    i := 0;
    while i < FItemCount do
    begin
      // icon size //
      sizeInc := 0;
      if ZoomItemSizeDiff > 0 then
      begin
        if (i < trunc(_ZoomInOutItem) - FZoomWidth / 2) or (i > trunc(_ZoomInOutItem) + FZoomWidth / 2) then sizeInc := 0
        else if i = trunc(_ZoomInOutItem) then sizeInc := ZoomItemSizeDiff
        else if i < trunc(_ZoomInOutItem) then sizeInc := (ZoomItemSizeDiff - 1) * (cos(PI * 2 * (i - _ZoomInOutItem + 1) / FZoomWidth) + 1) / 2
        else if i > trunc(_ZoomInOutItem) then sizeInc := (ZoomItemSizeDiff - 1) * (cos(PI * 2 * (i - _ZoomInOutItem) / FZoomWidth) + 1) / 2;
      end;
      FItemArray[i].se := FItemSize + sizeInc;
      FItemArray[i].s := round(FItemArray[i].se);

      // icon position when not FZooming //
      itemPos := FItemSpacing div 2 + i * (FItemSize + FItemSpacing);
      if FSite = bsBottom then
      begin
        FItemArray[i].y := FMonitorRect.Bottom - FItemArray[i].s - FMargin + FWndOffset - FEdgeOffset;
        if not IsSeparator(FItemArray[i].h) then FItemArray[i].y -= FMargin2;
        FItemArray[i].x := x + itemPos;
      end
      else
      if FSite = bsTop then
      begin
        FItemArray[i].y := FMonitorRect.Top + FMargin + FEdgeOffset - FWndOffset;
        if not IsSeparator(FItemArray[i].h) then FItemArray[i].y += FMargin2;
        FItemArray[i].x := x + itemPos;
      end
      else
      if FSite = bsLeft then
      begin
        FItemArray[i].x := FMonitorRect.Left + FMargin + FEdgeOffset - FWndOffset;
        if not IsSeparator(FItemArray[i].h) then FItemArray[i].x += FMargin2;
        FItemArray[i].y := y + itemPos;
      end
      else
      if FSite = bsRight then
      begin
        FItemArray[i].x := FMonitorRect.Right - FItemArray[i].s - FMargin + FWndOffset - FEdgeOffset;
        if not IsSeparator(FItemArray[i].h) then FItemArray[i].x -= FMargin2;
        FItemArray[i].y := y + itemPos;
      end;

      // icon position when FZooming (icons out of bubble and center bubble icon) //
      if ZoomItemSizeDiff > 0 then
      begin
        if FSiteVertical then
        begin
          if i < trunc(_ZoomInOutItem) then FItemArray[i].ye := FItemArray[i].y - offset
          else if i > trunc(_ZoomInOutItem) then FItemArray[i].ye := FItemArray[i].y + offset
          else if i = trunc(_ZoomInOutItem) then FItemArray[i].ye := FItemArray[i].y - ZoomItemSizeDiff * frac(_ZoomInOutItem);
          FItemArray[i].y := round(FItemArray[i].ye);
        end
        else
        begin
          if i < trunc(_ZoomInOutItem) then FItemArray[i].xe := FItemArray[i].x - offset
          else if i > trunc(_ZoomInOutItem) then FItemArray[i].xe := FItemArray[i].x + offset
          else if i = trunc(_ZoomInOutItem) then FItemArray[i].xe := FItemArray[i].x - ZoomItemSizeDiff * frac(_ZoomInOutItem);
          FItemArray[i].x := round(FItemArray[i].xe);
        end;
      end;

      inc(i);
    end;

    // icons positions while FZooming (within bubble, excluding center bubble icon) //
    if ZoomItemSizeDiff > 0 then
    begin
      i := trunc(_ZoomInOutItem) - 1;
      while (i > trunc(_ZoomInOutItem) - FZoomWidth / 2) and (i >= 0)  do
      begin
        if FSiteVertical then
        begin
          FItemArray[i].ye := FItemArray[i + 1].ye - FItemArray[i].se - FItemSpacing;
          FItemArray[i].y := round(FItemArray[i].ye);
        end
        else
        begin
          FItemArray[i].xe := FItemArray[i + 1].xe - FItemArray[i].se - FItemSpacing;
          FItemArray[i].x := round(FItemArray[i].xe);
        end;
        dec(i);
      end;
      i := trunc(_ZoomInOutItem) + 1;
      while (i <= trunc(_ZoomInOutItem) + FZoomWidth / 2) and (i < FItemCount)  do
      begin
        if FSiteVertical then
        begin
          FItemArray[i].ye := FItemArray[i - 1].ye + FItemArray[i - 1].se + FItemSpacing;
          if i = trunc(_ZoomInOutItem) + FZoomWidth / 2 then FItemArray[i].y := FItemArray[i].y + FItemSize - FItemArray[i].s
          else FItemArray[i].y := round(FItemArray[i].ye);
        end
        else
        begin
          FItemArray[i].xe := FItemArray[i - 1].xe + FItemArray[i - 1].se + FItemSpacing;
          if i = trunc(_ZoomInOutItem) + FZoomWidth / 2 then FItemArray[i].x := FItemArray[i].x + FItemSize - FItemArray[i].s
          else FItemArray[i].x := round(FItemArray[i].xe);
        end;
        inc(i);
      end;
    end;

  except
    on e: Exception do err('ItemManager.SetItems1', e);
  end;
end;
//------------------------------------------------------------------------------
procedure TItemManager.RecalcDock;
begin
  if FEnabled then
  try
    // width if vertical and height if horizontal //
    width := 0;
    height := 0;
    widthZoomed := 0;
    heightZoomed := 0;
    if FSite = bsLeft then
    begin
      width := FItemsArea.Left + FItemsArea2.Left + FItemSize + FItemsArea.Right + FItemsArea2.Right;
      widthZoomed := max(width, FItemsArea.Left + FItemsArea2.Left + FItemSize + ZoomItemSizeDiff);
    end else
    if FSite = bsRight then
    begin
      width := FItemsArea.Left + FItemsArea2.Left + FItemSize + FItemsArea.Right + FItemsArea2.Right;
      widthZoomed := max(width, FItemsArea.Right + FItemsArea2.Right + FItemSize + ZoomItemSizeDiff);
    end else
    if FSite = bsTop then
    begin
      height := FItemsArea.Top + FItemsArea2.Top + FItemSize + FItemsArea.Bottom + FItemsArea2.Bottom;
      heightZoomed := max(height, FItemsArea.Top + FItemsArea2.Top + FItemSize + ZoomItemSizeDiff);
    end else
    begin
      height := FItemsArea.Top + FItemsArea2.Top + FItemSize + FItemsArea.Bottom + FItemsArea2.Bottom;
      heightZoomed := max(height, FItemsArea.Bottom + FItemsArea2.Bottom + FItemSize + ZoomItemSizeDiff);
    end;

    // self XY relative to FBaseWindowRect //
    if FSiteVertical then
    begin
      // x
      x := 0;
      if FSite = bsLeft then x := FMargin - FItemsArea.Left - FItemsArea2.Left;
      // y, height
      if FOccupyFullMonitor then
      begin
        y := 0;
        height := FMonitorRect.Bottom - FMonitorRect.Top;
      end else
      begin
        if FItemCount > 0 then
        begin
          y := FItemArray[0].y - FItemSpacing div 2 - FItemsArea.Top - FItemsArea2.Top - FMonitorRect.Top;
          height := FItemsArea.Top + FItemsArea2.Top + FItemArray[FItemCount - 1].y + FItemArray[FItemCount - 1].s - FItemArray[0].y +
            FItemSpacing + FItemsArea.Bottom + FItemsArea2.Bottom;
        end
        else
        begin
          height := FItemSize + FItemsArea.Top + FItemsArea.Bottom + FItemsArea2.Top + FItemsArea2.Bottom;
          y := (FMonitorRect.Bottom - FMonitorRect.Top - IASize) * FCenterOffsetPercent div 100 -
            FItemsArea.Top - FItemsArea2.Top + (IASize - height + FItemsArea.Top + FItemsArea.Bottom + FItemsArea2.Top + FItemsArea2.Bottom - FItemSpacing) div 2;
        end;
      end;

    end else
    begin

      // y
      y := 0;
      if FSite = bsTop then y := FMargin - FItemsArea.Top - FItemsArea2.Top;
      // x, width
      if FOccupyFullMonitor then
      begin
        x := 0;
        width := FMonitorRect.Right - FMonitorRect.Left;
      end else
      begin
        if FItemCount > 0 then
        begin
          x := FItemArray[0].x - FItemSpacing div 2 - FItemsArea.Left - FItemsArea2.Left - FMonitorRect.Left;
          width := FItemsArea.Left + FItemsArea2.Left + FItemArray[FItemCount - 1].x + FItemArray[FItemCount - 1].s - FItemArray[0].x +
            FItemSpacing + FItemsArea.Right + FItemsArea2.Right;
        end
        else
        begin
          width := FItemSize + FItemsArea.Left + FItemsArea.Right + FItemsArea2.Left + FItemsArea2.Right;
          x := (FMonitorRect.Right - FMonitorRect.Left - IASize) * FCenterOffsetPercent div 100 -
            FItemsArea.Left - FItemsArea2.Left +
            (IASize - width + FItemsArea.Left + FItemsArea.Right + FItemsArea2.Left + FItemsArea2.Right - FItemSpacing) div 2;
        end;
      end;

    end;

    // background image rect //
    FBaseImageRect.x := x;
    FBaseImageRect.y := y;
    FBaseImageRect.Width := Width;
    FBaseImageRect.Height := Height;

    // main form rect //
    if FSiteVertical then
    begin
      FBaseWindowRect.Width := Width;
      if FSite = bsRight then FBaseWindowRect.Width += FMargin - FItemsArea.Right - FItemsArea2.Right;
      FBaseWindowRect.Height := FMonitorRect.Bottom - FMonitorRect.Top;
    end else begin
      FBaseWindowRect.Width := FMonitorRect.Right - FMonitorRect.Left;
      FBaseWindowRect.Height := Height;
      if FSite = bsBottom then FBaseWindowRect.Height += FMargin - FItemsArea.Bottom - FItemsArea2.Bottom;
    end;

    FBaseWindowRect.x := FMonitorRect.Left;
    FBaseWindowRect.y := FMonitorRect.Top;
    if FSite = bsLeft then FBaseWindowRect.x := FMonitorRect.Left - FWndOffset + FEdgeOffset
    else if FSite = bsTop then FBaseWindowRect.y := FMonitorRect.Top - FWndOffset + FEdgeOffset
    else if FSite = bsRight then FBaseWindowRect.x := FMonitorRect.Right - FBaseWindowRect.Width + FWndOffset - FEdgeOffset
    else if FSite = bsBottom then FBaseWindowRect.y := FMonitorRect.Bottom - FBaseWindowRect.Height + FWndOffset - FEdgeOffset;
  except
    on e: Exception do raise Exception.Create('ItemManager.RecalcDock'#10#13 + e.message);
  end;
end;
//------------------------------------------------------------------------------
function TItemManager.GetRect: windows.TRect;
begin
  result.Left := FBaseWindowRect.X + X;
  result.Top := FBaseWindowRect.Y + Y;
  result.Right := result.Left + Width;
  result.Bottom := result.Top + Height;
  case FSite of
    bsLeft: result.Right := max(result.Right, GetZoomEdge);
    bsTop: result.Bottom := max(result.Bottom, GetZoomEdge);
    bsRight: result.Left := min(result.Left, GetZoomEdge);
    bsBottom: result.Top := min(result.Top, GetZoomEdge);
  end;
end;
//------------------------------------------------------------------------------
function TItemManager.GetZoomEdge: integer;
begin
  case FSite of
    bsLeft: result := FBaseWindowRect.X + x + widthZoomed;
    bsTop: result := FBaseWindowRect.Y + y + heightZoomed;
    bsRight: result := FBaseWindowRect.X + x + width - widthZoomed;
    bsBottom: result := FBaseWindowRect.Y + y + height - heightZoomed;
  end;
end;
//------------------------------------------------------------------------------
procedure TItemManager.SetItems2(force_draw: boolean);
var
  idx: integer;
  wpi, show_items: uint;
begin
  if FEnabled then
  try
    idx := FItemCount;
    wpi := BeginDeferWindowPos(idx);
    show_items := swp_hidewindow;
    if FVisible then show_items := swp_showwindow;

    // draw FItemArray //
    idx := 0;
    while idx < FItemCount do
    begin
      if FItemArray[idx].h <> 0 then
        TCustomItem(GetWindowLong(FItemArray[idx].h, GWL_USERDATA)).Draw(
          FItemArray[idx].x, FItemArray[idx].y, FItemArray[idx].s, force_draw, wpi, show_items);
      inc(idx);
    end;

    EndDeferWindowPos(wpi);
  except
    on e: Exception do err('ItemManager.SetItems2', e);
  end;
end;
//------------------------------------------------------------------------------
// insert the list of the items at DropPlace position
// if DropPlace not exists, then insert at the end of the items array
procedure TItemManager.InsertItems(list: TStrings);
var
  i, dplace: integer;
begin
  if not FEnabled then exit;

  dplace := FDropPlace;
  for i := 0 to list.Count - 1 do
  begin
    InsertItem(list.strings[i]);
    if dplace <> NOT_AN_ITEM then
      if i < list.Count - 1 then
      begin
        inc(dplace);
        SetDropPlace(dplace);
        SetDropPlaceEx(dplace);
      end;
  end;
end;
//------------------------------------------------------------------------------
// insert item at current DropPlace
// or at the end if DropPlace not exists (e.g. DropPlace = NOT_AN_ITEM)
procedure TItemManager.InsertItem(AData: string);
begin
  if FEnabled then AddItem(AData, true);
end;
//------------------------------------------------------------------------------
// create an item and put it onto dock
function TItemManager.AddItem(data: string; Update: boolean = false): THandle;
begin
  result := 0;
  if FItemCount > MAX_ITEM_COUNT then exit;
  AllItemCmd(icHover, 0); // hide hint //
  AllItemCmd(icSelect, 0);

  result := CreateItem(data);
  if result <> THandle(0) then
  begin
    DockAdd(result);
    PluginCallCreate(result);
  end;
  if Update then ItemsChanged(true);
end;
//------------------------------------------------------------------------------
procedure TItemManager.PluginCallCreate(HWnd: HANDLE);
var
  Inst: TCustomItem;
begin
  try
    Inst := TCustomItem(GetWindowLong(HWnd, GWL_USERDATA));
    if Inst is TPluginItem then TPluginItem(Inst).CallCreate;
  except
    on e: Exception do raise Exception.Create('ItemManager.PluginCallCreate'#10#13 + e.message);
  end;
end;
//------------------------------------------------------------------------------
// create item and return its window handle
// item should be defined by a string. example:
// class="shortcut";caption="Cmd";command="cmd.exe";
//
// if class = stack there could be more than 1 string
// in this case each one starting from the 2nd should be of shortcut class
function TItemManager.CreateItem(data: string): THandle;
var
  class_name, str: string;
  Inst: TCustomItem;
  icp: TDItemCreateParams;
begin
  result := 0;
  Inst := nil;
  try
    class_name := AnsiLowerCase(FetchValue(data, 'class="', '"'));

    icp.ItemSize := FItemSize;
    icp.BigItemSize := FBigItemSize;
    icp.ItemSpacing := FItemSpacing;
    icp.LaunchInterval := FLaunchInterval;
    icp.ActivateRunning := FActivateRunning;
    icp.UseShellContextMenus := FUseShellContextMenus;
    icp.Site := integer(FSite);
    icp.Reflection := FReflection;
    icp.ReflectionSize := FReflectionSize;
    icp.ShowHint := FShowHint;
    icp.AnimationType := FItemAnimation;
    icp.LockDragging := FLockDragging;
    icp.StackAnimationEnabled := FStackAnimationEnabled;
    icp.SeparatorAlpha := FSeparatorAlpha;
    icp.TaskLivePreviews := FTaskLivePreviews;
    icp.TaskThumbSize := FTaskThumbSize;
    icp.TaskGrouping := FTaskGrouping;
    CopyFontData(FFont, icp.Font);

    if class_name = 'shortcut' then Inst := TShortcutItem.Create(data, FParentHWnd, icp)
    else
    if class_name = 'separator' then Inst := TSeparatorItem.Create(data, FParentHWnd, icp)
    else
    if class_name = 'plugin' then Inst := TPluginItem.Create(data, FParentHWnd, icp)
    else
    if class_name = 'stack' then Inst := TStackItem.Create(data, FParentHWnd, icp)
    else
    if class_name = 'task' then Inst := TTaskItem.Create(data, FParentHWnd, icp);
  except
    on e: Exception do raise Exception.Create('ItemManager.CreateItem.' + class_name + #10#13 + e.message);
  end;

  try
    if assigned(Inst) then
      if Inst.Freed then // if something went wrong
      begin
        FreeAndNil(Inst);
      end else // if everything is okay
      begin
        result := Inst.HWnd;
        // add to registered programs list
        str := Inst.RegisterProgram;
        if str <> '' then _registeredPrograms.Add(AnsiLowerCase(str));
      end;
  except
    on e: Exception do raise Exception.Create('ItemManager.CreateItem.Fin'#10#13 + e.message);
  end;
end;
//------------------------------------------------------------------------------
// do not call directly !!!
// items call this using DockH.DockDeleteItem
// use TCustomItem.Delete instead
procedure TItemManager.DeleteItem(HWnd: THandle);
var
  index, rpIndex: integer;
  Inst: TCustomItem;
begin
  if FEnabled then
  try
    index := ItemIndex(HWnd);
    // add to "deleted" list //
    _itemsDeleted.Add(Pointer(HWnd));
    // remove from registered programs list
    Inst := TCustomItem(GetWindowLong(HWnd, GWL_USERDATA));
    rpIndex := _registeredPrograms.IndexOf(AnsiLowerCase(Inst.RegisterProgram));
    if rpIndex >= 0 then _registeredPrograms.Delete(rpIndex);

    if index <> NOT_AN_ITEM then
    begin
      // erase it from "FItemArray" list //
      while index < FItemCount - 1 do
      begin
        FItemArray[index].h := FItemArray[index + 1].h;
        FItemArray[index].x := FItemArray[index + 1].x;
        FItemArray[index].y := FItemArray[index + 1].y;
        FItemArray[index].s := FItemArray[index + 1].s;
        inc(index);
      end;
      // decrement item count
      dec(FItemCount);
    end;

    // update dock //
    ItemsChanged;
  except
    on e: Exception do raise Exception.Create('ItemManager.DeleteItem'#10#13 + e.message);
  end;
end;
//------------------------------------------------------------------------------
//
//
//     Misc
//
//
//------------------------------------------------------------------------------
// calculate and set DropPlace and DropPlaceEx
procedure TItemManager.SetDropPlaceFromPoint(pt: windows.TPoint);
var
  tmp: extended;
  prevDropPlace, prevDropPlaceEx: integer;
begin
  prevDropPlace := FDropPlace;
  prevDropPlaceEx := FDropPlaceEx;

  if FEnabled then
  try
    // FDropPlace //
    tmp := ItemFromPoint(pt.x, pt.y, FDropDistance);
    if tmp = NOT_AN_ITEM then
    begin
      FDropPlace := NOT_AN_ITEM;
    end else begin
      if FDropPlace = NOT_AN_ITEM then FDropPlace := round(tmp)
      else
      if (abs(FDropPlace + 0.5 - tmp) > 1.2) or (tmp = -1) then FDropPlace := round(tmp - 0.5);
      // "+0.5" to count from the center of the FDropPlace. And "-0.5" to compensate the "+0.5"
    end;

    if FDropPlace <> NOT_AN_ITEM then
    begin
      if FDropPlace < 0 then FDropPlace := 0;
      if FItemCount < 1 then FDropPlace := 0
      else begin
        if FDraggingFile then
        begin
          if prevDropPlace = NOT_AN_ITEM then
          begin
            if FDropPlace > FItemCount then FDropPlace := NOT_AN_ITEM;
          end else begin
            if FDropPlace >= FItemCount then FDropPlace := NOT_AN_ITEM;
          end;
        end else
        if prevDropPlace = NOT_AN_ITEM then
        begin
          if FDropPlace > FItemCount then FDropPlace := FItemCount;
        end else begin
          if FDropPlace >= FItemCount then FDropPlace := FItemCount - 1;
        end;
      end;
    end;
    if prevDropPlace <> FDropPlace then SetDropPlace(FDropPlace);

    // FDropPlaceEx //
    tmp := ItemRectFromPoint(pt.x, pt.y);
    if tmp = NOT_AN_ITEM then tmp := FDropPlace;
    if tmp = NOT_AN_ITEM then FDropPlaceEx := NOT_AN_ITEM else FDropPlaceEx := round(tmp);
    if FDropPlaceEx <> NOT_AN_ITEM then
    begin
      if FDropPlaceEx < 0 then FDropPlaceEx := 0;
      if FDropPlaceEx > FItemCount - 1 then FDropPlaceEx := NOT_AN_ITEM;
    end;
    if prevDropPlaceEx <> FDropPlaceEx then SetDropPlaceEx(FDropPlaceEx);
  except
    on e: Exception do err('ItemManager.CalcDropPlace', e);
  end;
end;
//------------------------------------------------------------------------------
// physically create/move/delete empty item at DropPlace
procedure TItemManager.SetDropPlace(index: integer);
var
  i, currentDropPlace: integer;
begin
  try
    AllItemCmd(icDropIndicator, 0);

    FDropPlace := index;
    // seek for current FDropPlace in the FItemArray array (item.h = 0) //
    currentDropPlace := NOT_AN_ITEM;
    if FItemCount > 0 then
      for i := 0 to FItemCount - 1 do
      begin
        if FItemArray[i].h = 0 then
        begin
          currentDropPlace := i;
          break;
        end;
      end;

    if (currentDropPlace = NOT_AN_ITEM) and (FDropPlace = NOT_AN_ITEM) then exit;
    if currentDropPlace = FDropPlace then exit;

    // add empty item //
    if (currentDropPlace = NOT_AN_ITEM) and (FDropPlace <> NOT_AN_ITEM) then
    begin
      if FDropPlace > FItemCount then FDropPlace := FItemCount;
      FItemArray[FItemCount].h := 0;
      FItemArray[FItemCount].s := FItemSize;
      if FDropPlace < FItemCount then
      begin
        for i := FItemCount downto FDropPlace + 1 do FItemArray[i].h := FItemArray[i - 1].h;
      end;
      inc(FItemCount);
      FItemArray[FDropPlace].h := 0;
      ItemsChanged(true);
      exit;
    end;

    // move empty item //
    if (currentDropPlace <> NOT_AN_ITEM) and (FDropPlace <> NOT_AN_ITEM) then
    begin
      if FDropPlace < currentDropPlace then
      begin
        for i := currentDropPlace downto FDropPlace + 1 do FItemArray[i].h := FItemArray[i - 1].h;
      end;
      if FDropPlace > currentDropPlace then
      begin
        for i := currentDropPlace to FDropPlace - 1 do FItemArray[i].h := FItemArray[i + 1].h;
      end;
      FItemArray[FDropPlace].h := 0;
      ItemsChanged;
      exit
    end;

    // delete empty item //
    if (currentDropPlace <> NOT_AN_ITEM) and (FDropPlace = NOT_AN_ITEM) then
    begin
      if currentDropPlace < FItemCount - 1 then
      begin
        for i := currentDropPlace to FItemCount - 2 do FItemArray[i].h := FItemArray[i + 1].h;
      end;
      dec(FItemCount);
      ItemsChanged(true);
    end;
  except
    on e: Exception do err('ItemManager.SetDropPlace', e);
  end;
end;
//------------------------------------------------------------------------------
// set appropriate indicator for an item at DropPlaceEx
procedure TItemManager.SetDropPlaceEx(index: integer);
var
  DragInst, Inst: TCustomItem;
  atype: integer;
begin
  try
    FDropPlaceEx := index;
    atype := 0;

    // correct disallowed drop cases //
    if FDropPlaceEx <> NOT_AN_ITEM then
      if FDraggingItem then
      begin
        Inst := TCustomItem(GetWindowLong(FItemArray[FDropPlaceEx].h, GWL_USERDATA));
        DragInst := TCustomItem(GetWindowLong(FDragHWnd, GWL_USERDATA));
        if ((Inst is TStackItem) and (DragInst is TStackItem)) or
          ((Inst is TStackItem) and (DragInst is TShortcutItem)) or
          ((Inst is TShortcutItem) and (DragInst is TShortcutItem)) then atype := DII_ADD; // add
        if atype = 0 then FDropPlaceEx := FDropPlace;
      end;

    if FDraggingItem then
    begin
      AllItemCmd(icDropIndicator, 0);
      if atype > 0 then ItemCmd(FItemArray[FDropPlaceEx].h, icDropIndicator, atype);
    end;
  except
    on e: Exception do err('ItemManager.SetDropPlaceEx', e);
  end;
end;
//------------------------------------------------------------------------------
// items area width or height //
function TItemManager.IASize: integer;
begin
  result := FItemCount * (FItemSize + FItemSpacing);
end;
//------------------------------------------------------------------------------
// calculate item index based on mouse position
// do not care of the current items positions
function TItemManager.ItemFromPoint(Ax, Ay, distance: integer): extended;
var
  BasePoint: integer; // left or top of the first item
  rItemArea: windows.TRect;
begin
  result := NOT_AN_ITEM;
  if not FEnabled then exit;

  try
    if FItemCount = 0 then
    begin
      rItemArea := DockGetRect;
      if PtInRect(rItemArea, classes.Point(Ax, Ay)) then result := 0;
      exit;
    end;

    // calc position relative to the beginning of the first item //

    if FSiteVertical then
    begin
      BasePoint := FMonitorRect.Top + (FMonitorRect.Bottom - FMonitorRect.Top - IASize) * FCenterOffsetPercent div 100;
      result := (Ay - BasePoint) / (FItemSize + FItemSpacing);
    end else begin
      BasePoint := FMonitorRect.Left + (FMonitorRect.Right - FMonitorRect.Left - IASize) * FCenterOffsetPercent div 100;
      result := (Ax - BasePoint) / (FItemSize + FItemSpacing);
    end;
    if result < -1 then result := NOT_AN_ITEM;
    if result >= FItemCount + 1 then result := NOT_AN_ITEM;

    // check boundaries //

    rItemArea := FItemsArea;
    if FSite = bsLeft then rItemArea.Right := 0
    else if FSite = bsTop then rItemArea.Bottom := 0
    else if FSite = bsRight then rItemArea.Left := 0
    else if FSite = bsBottom then rItemArea.Top := 0;

    if FSite = bsBottom then
    begin
      if (Ay < FBaseWindowRect.Y + FBaseWindowRect.Height - FMargin - FItemSize - rItemArea.Top - ZoomItemSizeDiff - distance) or
        (Ay > FBaseWindowRect.Y + FBaseWindowRect.Height + distance) or
        (Ax < BasePoint - FBigItemSize) or
        (Ax > BasePoint + width)
        then result := NOT_AN_ITEM;
    end else
    if FSite = bsLeft then
    begin
      if (Ax < FBaseWindowRect.X - distance) or
        (Ax > FBaseWindowRect.X + x + FMargin + FItemSize + rItemArea.Right + ZoomItemSizeDiff + distance) or
        (Ay < BasePoint - FBigItemSize) or
        (Ay > BasePoint + height)
        then result := NOT_AN_ITEM;
    end else
    if FSite = bsRight then
    begin
      if (Ax < FBaseWindowRect.X + FBaseWindowRect.Width - FMargin - FItemSize - rItemArea.Left - ZoomItemSizeDiff - distance) or
        (Ax > FBaseWindowRect.X + FBaseWindowRect.Width + distance) or
        (Ay < BasePoint - FBigItemSize) or
        (Ay > BasePoint + height)
        then result := NOT_AN_ITEM;
    end else
    begin
      if (Ay < FBaseWindowRect.Y - distance) or
        (Ay > FBaseWindowRect.Y + y + FMargin + FItemSize + rItemArea.Bottom + ZoomItemSizeDiff + distance) or
        (Ax < BasePoint - FBigItemSize) or
        (Ax > BasePoint + width)
        then result := NOT_AN_ITEM;
    end;

  except
    on e: Exception do err('ItemManager.ItemFromPoint', e);
  end;
end;
//------------------------------------------------------------------------------
// calculate item index based on mouse position and items positions
function TItemManager.ItemRectFromPoint(Ax, Ay: integer): integer;
var
  idx: integer;
  Inst: TCustomItem;
begin
  result := NOT_AN_ITEM;
  if not FEnabled then exit;

  try
    if FItemCount = 0 then
    begin
      if PtInRect(DockGetRect, classes.Point(Ax, Ay)) then result := 0;
      exit;
    end;

    // calc position relative to the beginning of the first item //

    for idx := 0 to FItemCount - 1 do
    begin
      Inst := TCustomItem(GetWindowLong(FItemArray[idx].h, GWL_USERDATA));
      if Inst is TCustomItem then
        if PtInRect(Inst.ScreenRect, classes.Point(Ax, Ay)) then
        begin
          result := idx;
          break;
        end;
    end;
  except
    on e: Exception do err('ItemManager.ItemFromPoint', e);
  end;
end;
//------------------------------------------------------------------------------
// enter/exit zooming mode, maintain zooming
procedure TItemManager.Zoom(x, y: integer);
var
  item, saved: extended;
begin
  if FEnabled and not FDraggingFile then
  try
    item := NOT_AN_ITEM;
    if FZooming or CheckMouseOn or FDraggingItem then
    begin
      item := ItemFromPoint(x, y, ifthen(FDraggingItem, FDropDistance, 0));
      if item <> NOT_AN_ITEM then
      begin
        if item < 0 then item := NOT_AN_ITEM;
        if item >= FItemCount then item := NOT_AN_ITEM;
      end;
    end;

    // enter FZooming mode //
    if not FZooming and (item <> NOT_AN_ITEM) then
    begin
      ZoomStartTime := GetTickCount;
      _ZoomInOutItem := item;
      FZooming := true;
    end;

    if FZooming then
    begin
      if item = NOT_AN_ITEM then Unzoom
      else begin
          if ZoomItemSizeDiff = FBigItemSize - FItemSize then
          begin
              if _ZoomInOutItem <> item then
              begin
                _ZoomInOutItem := item;
                ItemsChanged;
              end;
          end
          else _ZoomInOutItem := item;
      end;
    end;
  except
    on e: Exception do err('ItemManager.Zoom', e);
  end;
end;
//------------------------------------------------------------------------------
// exit zooming mode
procedure TItemManager.UnZoom(do_now: boolean = false);
begin
  if FEnabled and (FZooming or do_now) then
  begin
    FZooming := false;
    ZoomStartTime := GetTickCount;
    if (FItemCount <= 0) or do_now then
    begin
      ZoomItemSizeDiff := 0;
      ItemsChanged;
    end;
  end;
end;
//------------------------------------------------------------------------------
// check mouse is over the dock
function TItemManager.CheckMouseOn: boolean;
var
  pt: windows.TPoint;
  wnd: uint;
  item: integer;
begin
  result := false;
  if FEnabled then
  try
    windows.GetCursorPos(pt);
    wnd := WindowFromPoint(pt);
    if FDraggingItem or FDraggingFile or FZooming then
      item := trunc(ItemFromPoint(pt.x, pt.y, ifthen(FDraggingItem or FDraggingFile, FDropDistance, 0)))
    else
      item := ItemIndex(wnd);
    result := (item <> NOT_AN_ITEM) or (wnd = FParentHWnd);
  except
    on e: Exception do err('ItemManager.CheckMouseOn', e);
  end;
end;
//------------------------------------------------------------------------------
// entry point for MouseMove events
procedure TItemManager.WHMouseMove(pt: windows.Tpoint; allow_zoom: boolean = true);
var
  wnd: cardinal;
begin
  try
    if not FEnabled or not FVisible then exit;

    if FItemCount > 0 then
    begin
      // hint //
      wnd := WindowFromPoint(pt);
      if ItemIndex(wnd) = NOT_AN_ITEM then wnd := 0;
      if wnd <> FHoverItemHWnd then
      begin
        if FHoverItemHWnd <> 0 then ItemCmd(FHoverItemHWnd, icHover, 0);
        if wnd <> 0 then ItemCmd(wnd, icHover, 1);
      end;
      FHoverItemHWnd := wnd;
      // zoom //
      if allow_zoom and FZoomItems then Zoom(pt.x, pt.y);
    end;

    // drop place //
    if FDraggingItem or FDraggingFile then
    begin
      SetDropPlaceFromPoint(pt);
      if allow_zoom and FZoomItems then Zoom(pt.x, pt.y);
    end;
  except
    on e: Exception do raise Exception.Create('ItemManager.WHMouseMove'#10#13 + e.message);
  end;
end;
//------------------------------------------------------------------------------
procedure TItemManager.DragEnter;
begin
  FDraggingItem := false;
  FDraggingFile := true;
  DragOver;
end;
//------------------------------------------------------------------------------
procedure TItemManager.DragLeave;
begin
  FDraggingItem := false;
  FDraggingFile := false;
  SetDropPlaceEx(NOT_AN_ITEM);
  SetDropPlace(NOT_AN_ITEM);
  ItemsChanged;
  ItemCmd(FSelectedItemHWnd, icDragLeave, 0);
  ItemCmd(FSelectedItemHWnd, icSelect, 0);
  FSelectedItemHWnd := 0;
  AllItemCmd(icHover, 0);
end;
//------------------------------------------------------------------------------
procedure TItemManager.DragOver;
var
  pt: windows.TPoint;
  wnd: THandle;
begin
  if FEnabled then
  try
    GetCursorPos(pt);
    if not FLockMouseEffect then WHMouseMove(pt);
    wnd := WindowFromPoint(pt);
    wnd := IsItem(wnd);
    if wnd <> FSelectedItemHWnd then
    begin
      ItemCmd(FSelectedItemHWnd, icSelect, 0);
      ItemCmd(FSelectedItemHWnd, icDragLeave, 0);
      FSelectedItemHWnd := wnd;
      ItemCmd(FSelectedItemHWnd, icSelect, 1);
      ItemCmd(FSelectedItemHWnd, icDragEnter, 0);
    end;
    ItemCmd(wnd, icDragOver, 0);
  except
    on e: Exception do err('ItemManager.DragOver', e);
  end;
end;
//------------------------------------------------------------------------------
procedure TItemManager.WMDeactivateApp;
var
  idx: integer;
begin
  if not CheckMouseOn then
  begin
    Unzoom;
    AllItemCmd(icHover, 0);
  end;

  if FEnabled then
  try
    idx := 0;
    while idx < FItemCount do
    begin
      if FItemArray[idx].h <> 0 then postmessage(FItemArray[idx].h, WM_ACTIVATEAPP, 0, 0);
      inc(idx);
    end;
  except
    on e: Exception do err('ItemManager.WMDeactivate', e);
  end;
end;
//------------------------------------------------------------------------------
//
//
//
//   Window Item Procs
//
//
//
//------------------------------------------------------------------------------
// detach the item
procedure TItemManager.Undock(HWnd: HANDLE);
var
  index: integer;
  pt: windows.TPoint;
begin
  if FEnabled and not FDraggingItem then
  try
    FDraggingFile := false;
    FDraggingItem := true;
    FDragHWnd := HWnd;
    index := ItemIndex(HWnd);
    try if index <> NOT_AN_ITEM then
      begin
        FItemArray[index].h := 0;
        SetDropPlace(index);
        SetDropPlaceEx(index);
      end;
    except end;
  except
    on e: Exception do err('ItemManager.UndockWindowItem', e);
  end;
end;
//------------------------------------------------------------------------------
// add new item to dock
// if there is a DropPlace, then put item there
// if DropPlace not exists, then put item at the end of the items array
procedure TItemManager.DockAdd(HWnd: THandle);
begin
  if (FDropPlace < 0) or (FDropPlace >= FItemCount) then SetDropPlace(FItemCount);
  FItemArray[FDropPlace].h := HWnd;
  FItemArray[FDropPlace].s := FItemSize;
  ItemCmd(HWnd, icFree, 0); // enable item
  ItemCmd(HWnd, icUndock, 0);
  SetWindowPos(HWnd, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE + SWP_NOSIZE + SWP_NOSENDCHANGING);
  SetDropPlaceEx(NOT_AN_ITEM);
  SetDropPlace(NOT_AN_ITEM);
  ItemsChanged;
end;
//------------------------------------------------------------------------------
// put the item to dock
// if necessary create a new stack or put into existing one
procedure TItemManager.Dock(HWnd: HANDLE);
var
  idx: integer;
  DragInst, Inst, NewInst: TCustomItem;
  NewItemHWnd: THandle;
  pt: windows.TPoint;
begin
  //if not FEnabled or (FDragHWnd <> HWnd) then exit;
  if FEnabled then
  try
    SetWindowPos(HWnd, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE + SWP_NOSIZE + SWP_NOSENDCHANGING);
    GetCursorPos(pt);
    SetDropPlaceFromPoint(pt);

    DragInst := TCustomItem(GetWindowLong(HWnd, GWL_USERDATA));

    // delete //
    if (FDropPlace < 0) or (FDropPlace >= FItemCount) then
    begin
      DragInst.Delete;
    end else
    // put to a free slot //
    if FDropPlace = FDropPlaceEx then
    begin
      FItemArray[FDropPlace].h := HWnd;
      ItemCmd(HWnd, icUndock, 0);
    end else
    // combine with existing item //
    begin
      Inst := TCustomItem(GetWindowLong(FItemArray[FDropPlaceEx].h, GWL_USERDATA));
      // shortcut to stack //
      if (DragInst is TShortcutItem) and (Inst is TStackItem) then
      begin
        TStackItem(Inst).AddSubitem(TShortcutItem(DragInst).ToString);
        DragInst.Delete;
      end else
      // stack to stack //
      if (DragInst is TStackItem) and (Inst is TStackItem) then
      begin
        idx := 0;
        while idx < TStackItem(DragInst).ItemCount do
        begin
          TStackItem(Inst).AddSubitem(TStackItem(DragInst).SubitemToString(idx));
          inc(idx);
        end;
        DragInst.Delete;
      end else
      // shortcut to shortcut //
      if (DragInst is TShortcutItem) and (Inst is TShortcutItem) then
      begin
        if (FDropPlace >= 0) and (FDropPlace < FItemCount) then
        begin
          NewItemHWnd := CreateItem(TStackItem.Make(0, '', ''));
          if NewItemHWnd <> THandle(0) then
          begin
            FItemArray[FDropPlace].h := NewItemHWnd;
            NewInst := TCustomItem(GetWindowLong(NewItemHWnd, GWL_USERDATA));
            TStackItem(NewInst).AddSubitem(TShortcutItem(Inst).ToString);
            TStackItem(NewInst).AddSubitem(TShortcutItem(DragInst).ToString);
            DragInst.Delete;
            Inst.Delete;
            ItemsChanged(true);
          end;
        end;
      end else begin
          if (FDropPlace >= 0) and (FDropPlace < FItemCount) then
          begin
            FItemArray[FDropPlace].h := HWnd;
            ItemCmd(HWnd, icUndock, 0);
          end else begin
            DragInst.Delete;
          end;
      end;
    end;

    FDraggingItem := false;
    FDragHWnd := 0;
    SetDropPlaceEx(NOT_AN_ITEM);
    SetDropPlace(NOT_AN_ITEM);
    ItemsChanged;
  except
    on e: Exception do err('ItemManager.DockWindowItem', e);
  end;
end;
//------------------------------------------------------------------------------
// search all items and their subitems for a given HWnd
// if item is found - result is HWnd
// if subitem is found - result is its parent item HWnd
// if no match found result is 0
function TItemManager.IsItem(HWnd: HANDLE): HANDLE;
var
  idx: integer;
  Inst: TCustomItem;
begin
  result := THandle(0);
  if FEnabled then
  try
    idx := 0;
    while idx < FItemCount do
    begin
      if FItemArray[idx].h = HWnd then
      begin
        result := HWnd;
        break;
      end;

      Inst := TCustomItem(GetWindowLong(FItemArray[idx].h, GWL_USERDATA));
      if Inst is TCustomItem then result := Inst.cmd(icIsItem, integer(HWnd));
      if result <> 0 then break;
      inc(idx);
    end;
  except
    on e: Exception do err('ItemManager.IsItem', e);
  end;
end;
//------------------------------------------------------------------------------
function TItemManager.ItemDropFile(HWndItem: HANDLE; pt: windows.TPoint; filename: string): boolean;
var
  Inst: TCustomItem;
  HWndChild: HANDLE;
begin
  try
    result := false;
    HWndChild := HWndItem;
    HWndItem := IsItem(HWndItem);
    if HWndItem <> THandle(0) then
    begin
      Inst := TCustomItem(GetWindowLong(HWndItem, GWL_USERDATA));
      if Inst is TCustomItem then result := Inst.DropFile(HWndChild, pt, filename);
    end;
  except
    on e: Exception do err('ItemManager.ItemDrop', e);
  end;
end;
//------------------------------------------------------------------------------
function TItemManager.ItemDropFiles(HWndItem: HANDLE; pt: windows.TPoint; files: TStrings): boolean;
var
  idx: integer;
  Inst: TCustomItem;
  HWndChild: HANDLE;
begin
  try
    result := false;
    HWndChild := HWndItem;
    HWndItem := IsItem(HWndItem);
    if HWndItem <> THandle(0) then
    begin
      Inst := TCustomItem(GetWindowLong(HWndItem, GWL_USERDATA));
      if Inst is TCustomItem then
        for idx := 0 to files.Count - 1 do
          result := result or Inst.DropFile(HWndChild, pt, files.strings[idx]);
    end;
  except
    on e: Exception do err('ItemManager.ItemDrop', e);
  end;
end;
//------------------------------------------------------------------------------
function TItemManager.ItemCmd(HWnd: HANDLE; id: TGParam; param: integer): integer;
var
  Inst: TCustomItem;
begin
  try
    result := 0;
    Inst := TCustomItem(GetWindowLong(HWnd, GWL_USERDATA));
    if Inst is TCustomItem then result := Inst.cmd(id, param);
  except
    on e: Exception do err('ItemManager.ItemCmd', e);
  end;
end;
//------------------------------------------------------------------------------
function TItemManager.AllItemCmd(id: TGParam; param: integer): integer;
var
  item: integer;
  Inst: TCustomItem;
begin
  result := 0;
  if FEnabled then
  try
    item := 0;
    while item < FItemCount do
    begin
      Inst := TCustomItem(GetWindowLong(FItemArray[item].h, GWL_USERDATA));
      if Inst is TCustomItem then result := Inst.cmd(id, param);
      inc(item);
    end;
  except
    on e: Exception do err('ItemManager.AllItemCmd', e);
  end;
end;
//------------------------------------------------------------------------------
procedure TItemManager.SetFont(var Value: _FontData);
var
  item: integer;
  Inst: TCustomItem;
begin
  try
    CopyFontData(Value, FFont);
    item := 0;
    while item < FItemCount do
    begin
      Inst := TCustomItem(GetWindowLong(FItemArray[item].h, GWL_USERDATA));
      if Inst is TCustomItem then Inst.SetFont(Value);
      inc(item);
    end;
  except
    on e: Exception do err('ItemManager.SetFont', e);
  end;
end;
//------------------------------------------------------------------------------
function TItemManager.GetPluginFile(HWnd: HANDLE): string;
var
  Inst: TCustomItem;
begin
  try
    result := '';
    Inst := TCustomItem(GetWindowLong(HWnd, GWL_USERDATA));
    if Inst is TPluginItem then result := TPluginItem(Inst).Filename;
  except
    on e: Exception do err('ItemManager.GetPluginFile', e);
  end;
end;
//------------------------------------------------------------------------------
procedure TItemManager.SetPluginImage(HWnd: HANDLE; lpImageNew: Pointer; AutoDelete: boolean);
var
  Inst: TCustomItem;
begin
  try
    Inst := TCustomItem(GetWindowLong(HWnd, GWL_USERDATA));
    if Inst is TPluginItem then TPluginItem(Inst).UpdateImage(lpImageNew, AutoDelete);
  except
    on e: Exception do err('ItemManager.SetPluginImage', e);
  end;
end;
//------------------------------------------------------------------------------
procedure TItemManager.SetPluginOverlay(HWnd: HANDLE; lpOverlayNew: Pointer; AutoDelete: boolean);
var
  Inst: TCustomItem;
begin
  try
    if HWnd <> 0 then Inst := TCustomItem(GetWindowLong(HWnd, GWL_USERDATA));
    if Inst is TPluginItem then TPluginItem(Inst).UpdateOverlay(lpOverlayNew, AutoDelete);
  except
    on e: Exception do err('ItemManager.SetPluginOverlay', e);
  end;
end;
//------------------------------------------------------------------------------
procedure TItemManager.PluginAnimate(HWnd: HANDLE);
var
  Inst: TCustomItem;
begin
  try
    Inst := TCustomItem(GetWindowLong(HWnd, GWL_USERDATA));
    if (Inst is TCustomItem) and (FItemAnimation > 0) then Inst.Animate;
  except
    on e: Exception do err('ItemManager.PluginAnimate', e);
  end;
end;
//------------------------------------------------------------------------------
procedure TItemManager.SetPluginCaption(HWnd: HANDLE; NewCaption: string);
var
  Inst: TCustomItem;
begin
  try
    Inst := TCustomItem(GetWindowLong(HWnd, GWL_USERDATA));
    if Inst is TCustomItem then Inst.Caption := NewCaption;
  except
    on e: Exception do err('ItemManager.SetPluginCaption', e);
  end;
end;
//------------------------------------------------------------------------------
function TItemManager.GetPluginCaption(HWnd: HANDLE): string;
var
  Inst: TCustomItem;
begin
  try
    result := '';
    Inst := TCustomItem(GetWindowLong(HWnd, GWL_USERDATA));
    if Inst is TCustomItem then result := Inst.Caption;
  except
    on e: Exception do err('ItemManager.GetPluginCaption', e);
  end;
end;
//------------------------------------------------------------------------------
function TItemManager.GetPluginRect(HWnd: HANDLE; var r: windows.TRect): boolean;
var
  Inst: TCustomItem;
begin
  try
    result := Visible;
    r := classes.Rect(0, 0, 0, 0);
    Inst := TCustomItem(GetWindowLong(HWnd, GWL_USERDATA));
    if Inst is TCustomItem then r := Inst.ScreenRect;
  except
    on e: Exception do err('ItemManager.GetPluginRect', e);
  end;
end;
//------------------------------------------------------------------------------
function TItemManager.IsPluginUndocked(HWnd: HANDLE): boolean;
var
  Inst: TCustomItem;
begin
  try
    result := false;
    Inst := TCustomItem(GetWindowLong(HWnd, GWL_USERDATA));
    if Inst is TCustomItem then result := Inst.Floating;
  except
    on e: Exception do err('ItemManager.IsPluginUndocked', e);
  end;
end;
//------------------------------------------------------------------------------
function TItemManager.IsSeparator(HWnd: HANDLE): boolean;
begin
  try
    result := TCustomItem(GetWindowLong(HWnd, GWL_USERDATA)) is TSeparatorItem;
  except
    on e: Exception do err('ItemManager.IsSeparator', e);
  end;
end;
//------------------------------------------------------------------------------
//
//
//
//   Task Item Procs
//
//
//
//------------------------------------------------------------------------------
procedure TItemManager.Taskbar;
var
  index: integer;
  Inst: TCustomItem;
begin
  if FDraggingItem then exit;
  try
    // remove deleted windows //
    try
      index := 0;
      while index < FItemCount do
      begin
        Inst := TCustomItem(GetWindowLong(FItemArray[index].h, GWL_USERDATA));
        if Inst is TTaskItem then TTaskItem(Inst).RemoveNonExisting;
        inc(index);
      end;
      Inst := nil;
    except
      on e: Exception do err('ItemManager.RemoveTaskWindow', e);
    end;

    // add existing windows //
    index := 0;
    while index < ProcessHelper.GetAppWindowsCount do
    begin
      AddTaskWindow(ProcessHelper.GetAppWindowHandle(index));
      inc(index);
    end;

    // delete empty items and update not empty ones
    index := FItemCount - 1;
    while index >= 0 do
    begin
      Inst := TCustomItem(GetWindowLong(FItemArray[index].h, GWL_USERDATA));
      if Inst is TTaskItem then
        if TTaskItem(Inst).IsEmpty then TTaskItem(Inst).Delete else TTaskItem(Inst).UpdateItem;
      dec(index);
    end;
  except
    on e: Exception do err('ItemManager.Taskbar', e);
  end;
end;
//------------------------------------------------------------------------------
procedure TItemManager.AddTaskWindow(HWndTask: THandle);
var
  index, found, spot: integer;
  HWndItem: THandle;
  Inst: TCustomItem;
  str: string;
begin
  try
    // do not add registered programs, so check for it
    str := AnsiLowerCase(ProcessHelper.GetWindowProcessName(HWndTask));
    index := _registeredPrograms.IndexOf(str);
    if index < 0 then index := _registeredPrograms.IndexOf(ExtractFileName(str));
    if index >= 0 then exit;

    // search existing TaskItem for the given window
    found := -1;
    index := 0;
    while index < FItemCount do
    begin
      Inst := TCustomItem(GetWindowLong(FItemArray[index].h, GWL_USERDATA));
      if Inst is TTaskItem then
        if TTaskItem(Inst).WindowInList(HWndTask) then
        begin
          found := index;
          break;
        end;
      inc(index);
    end;

    // if there is no item for the window - add a new item //
    if found = -1 then
    begin
      // determine where to place a newly created item
      index := FTaskSpot;
      if (index < 0) or (index >= FItemCount) then
        index := NOT_AN_ITEM
      else
      begin
        while index < FItemCount do
	      begin
	        Inst := TCustomItem(GetWindowLong(FItemArray[index].h, GWL_USERDATA));
	        if not (Inst is TTaskItem) then break;
	        inc(index);
	      end;
        if index >= FItemCount then index := NOT_AN_ITEM
			end;

			SetDropPlace(index);
      HWndItem := AddItem(TTaskItem.Make, true);
      Inst := TCustomItem(GetWindowLong(HWndItem, GWL_USERDATA));
      if Inst is TTaskItem then TTaskItem(Inst).UpdateTaskItem(HWndTask);
    end;
  except
    on e: Exception do err('ItemManager.AddTaskWindow', e);
  end;
end;
//------------------------------------------------------------------------------
procedure TItemManager.ClearTaskbar;
var
  idx: integer;
  Inst: TCustomItem;
begin
  idx := FItemCount - 1;
  while idx >= 0 do
  begin
    Inst := TCustomItem(GetWindowLong(FItemArray[idx].h, GWL_USERDATA));
    if Inst is TTaskItem then Inst.Delete;
    dec(idx);
  end;
end;
//------------------------------------------------------------------------------
end.
