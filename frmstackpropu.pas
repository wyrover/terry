unit frmstackpropu;

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  DefaultTranslator, Dialogs, StdCtrls, ExtCtrls, ComCtrls, Menus, Buttons,
  GDIPAPI, gdip_gfx, stackitemu;

type
  _uproc = procedure(AData: string) of object;

  { TfrmStackProp }

  TfrmStackProp = class(TForm)
    bbAddIcon: TBitBtn;
    bbDelIcon: TBitBtn;
    bbEditIcon: TBitBtn;
    bbIconDown: TBitBtn;
    bbIconUp: TBitBtn;
    btnBrowseImage1: TButton;
    btnClearImage: TButton;
    btnDefaultColor: TButton;
    btnOK: TButton;
    btnApply: TButton;
    btnCancel: TButton;
    btnSelectColor: TButton;
    cboMode: TComboBox;
    chbPreview: TCheckBox;
    edImage: TEdit;
    edCaption: TEdit;
    iPic: TPaintBox;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    lblImage: TLabel;
    lblDistort: TLabel;
    lblCaption: TLabel;
    lblAnimationSpeed: TLabel;
    lblStyle: TLabel;
    lblDir: TLabel;
    lblOffset: TLabel;
    list: TListBox;
    pages: TPageControl;
    tbAnimationSpeed: TTrackBar;
    tbDistort: TTrackBar;
    tbOffset: TTrackBar;
    tsSubitems: TTabSheet;
    tsProperties: TTabSheet;
    tsColor: TTabSheet;
    tbBr: TTrackBar;
    tbCont: TTrackBar;
    tbHue: TTrackBar;
    tbSat: TTrackBar;
    procedure bbAddIconClick(Sender: TObject);
    procedure bbDelIconClick(Sender: TObject);
    procedure bbEditIconClick(Sender: TObject);
    procedure bbIconDownClick(Sender: TObject);
    procedure bbIconUpClick(Sender: TObject);
    procedure btnBrowseImage1Click(Sender: TObject);
    procedure btnDefaultColorClick(Sender: TObject);
    procedure edCaptionChange(Sender: TObject);
    procedure edImageChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnClearImageClick(Sender: TObject);
    procedure btnSelectColorClick(Sender: TObject);
    procedure btn_colorClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure btnApplyClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure listDblClick(Sender: TObject);
    procedure tbHueChange(Sender: TObject);
  private
    cancel_data: string;
    UpdateItemProc: _uproc;
    color_: uint;
    color_data: integer;
    SpecialFolder: integer;
    ItemHWnd: uint;
    FChanged: boolean;
    item: TStackItem;
    procedure SetData(AData: string);
    procedure ReadSubitems;
    procedure OpenColor;
    procedure iPicPaint(Sender: TObject);
    procedure Draw;
    procedure DrawFit(image: Pointer; p: TPaintBox; color_data: integer);
  public
    class procedure Open(AData: string; uproc: _uproc; AItem: TStackItem);
  end;

var
  frmStackProp: TfrmStackProp;

{$t+}
implementation
uses declu, toolu, frmterryu, stackmodeu;
{$R *.lfm}
//------------------------------------------------------------------------------
class procedure TfrmStackProp.Open(AData: string; uproc: _uproc; AItem: TStackItem);
begin
  if AData <> '' then
  try
    if not assigned(frmStackProp) then Application.CreateForm(self, frmStackProp);
    frmStackProp.UpdateItemProc := uproc;
    frmStackProp.item := AItem;
    frmStackProp.SetData(AData);
    frmStackProp.ReadSubitems;
    frmStackProp.Show;
  except
    on e: Exception do frmterry.notify('frmStackProp.Open'#10#13 + e.message);
  end;
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.FormCreate(Sender: TObject);
var
  i: integer;
begin
  FChanged := false;

  font.Name := GetFont;
  font.size := GetFontSize;
  clientheight := btnOK.top + btnOK.Height + 7;
  constraints.minheight := Height;
  constraints.maxheight := Height;
  constraints.minwidth := Width;

  for i := 0 to mc.GetModeCount - 1 do cboMode.Items.Add(mc.GetModeName(i));
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.SetData(AData: string);
begin
  if FChanged then
    if not confirm(Handle, UTF8ToAnsi(XMsgUnsavedIconParams)) then exit;

  cancel_data := AData;
  try ItemHWnd := strtoint(FetchValue(AData, 'hwnd="', '";'));
  except end;
  pages.ActivePageIndex := 0;

  // show parameters //

  edCaption.Text := AnsiToUTF8(FetchValue(AData, 'caption="', '";'));
  edImage.Text := FetchValue(AData, 'image="', '";');

  try
    color_data := DEFAULT_COLOR_DATA;
    color_data := toolu.StringToColor(FetchValue(AData, 'color_data="', '";'));
  except end;
  tbHue.OnChange := nil;
  tbSat.OnChange := nil;
  tbBr.OnChange := nil;
  tbCont.OnChange := nil;
  tbHue.position := byte(color_data);
  tbSat.position := byte(color_data shr 8);
  tbBr.position := byte(color_data shr 16);
  tbCont.position := byte(color_data shr 24);
  tbHue.OnChange := tbHueChange;
  tbSat.OnChange := tbHueChange;
  tbBr.OnChange := tbHueChange;
  tbCont.OnChange := tbHueChange;


  cboMode.ItemIndex := 0;
  try cboMode.ItemIndex := strtoint(FetchValue(AData, 'mode="', '";'));
  except end;

  tbOffset.Position := tbOffset.Min;
  tbAnimationSpeed.Position := tbAnimationSpeed.Min;
  tbDistort.Position := tbDistort.Min;
  try tbOffset.Position := strtoint(FetchValue(AData, 'offset="', '";'));
  except end;
  try tbAnimationSpeed.Position := strtoint(FetchValue(AData, 'animation_speed="', '";'));
  except end;
  try tbDistort.Position := strtoint(FetchValue(AData, 'distort="', '";'));
  except end;
  try chbPreview.Checked := not (FetchValue(AData, 'preview="', '";') = '0');
  except end;

  try
    SpecialFolder := 0;
    SpecialFolder := strtoint(FetchValue(AData, 'special_folder="', '";'));
  except end;

  Draw;

  iPic.OnPaint := iPicPaint;

  // reset 'changed' state //
  FChanged := false;
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.ReadSubitems;
var
  i: integer;
begin
  list.Items.BeginUpdate;
  list.Clear;
  if item.ItemCount > 0 then
    for i := 0 to item.ItemCount - 1 do
      list.Items.Add(AnsiToUTF8(item.GetSubitemCaption(i)));
  list.Items.EndUpdate;
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.bbIconUpClick(Sender: TObject);
var
  i: integer;
begin
  i := list.ItemIndex;
  item.SubitemMoveUp(i);
  ReadSubitems;
  if i > 0 then dec(i);
  list.ItemIndex := i;
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.bbIconDownClick(Sender: TObject);
var
  i: integer;
begin
  i := list.ItemIndex;
  item.SubitemMoveDown(i);
  ReadSubitems;
  if i < list.Items.Count - 1 then inc(i);
  list.ItemIndex := i;
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.bbAddIconClick(Sender: TObject);
begin
  item.AddSubitemDefault;
  ReadSubitems;
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.bbDelIconClick(Sender: TObject);
begin
  item.DeleteSubitem(list.ItemIndex);
  ReadSubitems;
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.bbEditIconClick(Sender: TObject);
begin
  item.SubitemConfigure(list.ItemIndex);
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.listDblClick(Sender: TObject);
begin
  bbEditIcon.Click;
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if (key = 27) and (shift = []) then btnCancel.Click;
  if (key = 13) and (shift = []) then btnOK.Click;
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.btnCancelClick(Sender: TObject);
begin
  if FChanged then
    if assigned(UpdateItemProc) then UpdateItemProc(cancel_data);
  FChanged := false;
  Close;
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.btnOKClick(Sender: TObject);
begin
  btnApply.Click;
  // save settings !!!
  frmterry.BaseCmd(tcSaveSets, 0);
  Close;
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.btnApplyClick(Sender: TObject);
var
  str: string;
begin
  try
    FChanged := false;
    str := TStackItem.Make(ItemHWnd, UTF8ToAnsi(edCaption.Text), UTF8ToAnsi(edImage.Text), color_data,
      cboMode.ItemIndex, tbOffset.Position, tbAnimationSpeed.Position, tbDistort.Position, SpecialFolder, chbPreview.Checked);
    if assigned(UpdateItemProc) then UpdateItemProc(str);
  except
    on e: Exception do frmterry.notify('frmStackProp.btnApplyClick'#10#13 + e.message);
  end;
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SetActiveWindow(frmterry.handle);
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.btn_colorClick(Sender: TObject);
begin
  with TColorDialog.Create(self) do
  begin
    color := color_ and $ffffff;
    if Execute then
    begin
      FChanged := true;
      color_ := uint(Color) or $ff000000;
    end;
    Free;
  end;
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.btnBrowseImage1Click(Sender: TObject);
begin
  with TOpenDialog.Create(self) do
  try
    if edImage.Text = '' then InitialDir:= toolu.UnzipPath('%pp%\images')
    else InitialDir:= ExtractFilePath(toolu.UnzipPath(edImage.Text));
    if execute then edImage.Text := toolu.ZipPath(FileName);
  finally
    free;
  end;
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.edCaptionChange(Sender: TObject);
begin
  FChanged := true;
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.edImageChange(Sender: TObject);
begin
  FChanged := true;
  Draw;
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.btnClearImageClick(Sender: TObject);
begin
  edImage.Clear;
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.btnSelectColorClick(Sender: TObject);
begin
  OpenColor;
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.OpenColor;
begin
  pages.ActivePageIndex := 2;
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.tbHueChange(Sender: TObject);
begin
  FChanged := true;
  color_data := byte(tbHue.Position) +
    byte(tbSat.Position) shl 8 +
    byte(tbBr.Position) shl 16 +
    byte(tbCont.Position) shl 24;
  Draw;
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.btnDefaultColorClick(Sender: TObject);
begin
  color_data := DEFAULT_COLOR_DATA;

  tbHue.OnChange:= nil;
  tbSat.OnChange:= nil;
  tbBr.OnChange:= nil;
  tbCont.OnChange:= nil;
  tbHue.position:= byte(color_data);
  tbSat.position:= byte(color_data shr 8);
  tbBr.position:= byte(color_data shr 16);
  tbCont.position:= byte(color_data shr 24);
  tbHue.OnChange:= tbHueChange;
  tbSat.OnChange:= tbHueChange;
  tbBr.OnChange:= tbHueChange;
  tbCont.OnChange:= tbHueChange;

  tbHueChange(nil);
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.Draw;
var
  str: string;
  img: Pointer;
  w, h: uint;
begin
  try
    img := nil;
    str := UnzipPath(edImage.Text);

    if fileexists(cut(str, ',')) then LoadImage(str, 128, false, True, img, w, h);
    DrawFit(img, iPic, color_data);
    if assigned(img) then GdipDisposeImage(img);
  except
    on e: Exception do frmterry.notify('frmStackProp.Draw'#10#13 + e.message);
  end;
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.iPicPaint(Sender: TObject);
begin
  Draw;
end;
//------------------------------------------------------------------------------
procedure TfrmStackProp.DrawFit(image: Pointer; p: TPaintBox; color_data: integer);
var
  hgdip, hbrush, hattr: Pointer;
  w, h: uint;
  w_coeff, h_coeff: extended;
  matrix: ColorMatrix;
  background: cardinal;
begin
  try
    if assigned(image) then
    begin
      GdipGetImageWidth(image, w);
      GdipGetImageHeight(image, h);
    end
    else
    begin
      w := 128;
      h := 128;
    end;

    w_coeff := 1;
    h_coeff := 1;

    try
      if w / h > (p.Width - 2) / (p.Height - 2) then h_coeff := (p.Width - 2) * h / w / (p.Height - 2);
      if w / h < (p.Width - 2) / (p.Height - 2) then w_coeff := (p.Height - 2) * w / h / (p.Width - 2);
    except
    end;

    GdipCreateFromHDC(p.canvas.handle, hgdip);
    GdipSetInterpolationMode(hgdip, InterpolationModeHighQualityBicubic);

    background := GetRGBColorResolvingParent;
    background := SwapColor(background) or $ff000000;
    GdipCreateSolidFill(background, hbrush);
    GdipFillRectangleI(hgdip, hbrush, 0, 0, p.Width, p.Height);
    GdipDeleteBrush(hbrush);

    if assigned(image) then
    begin
      CreateColorMatrix(color_data, matrix);
      GdipCreateImageAttributes(hattr);
      GdipSetImageAttributesColorMatrix(hattr, ColorAdjustTypeBitmap, true, @matrix, nil, ColorMatrixFlagsDefault);

      GdipDrawImageRectRectI(hgdip, image,
        (p.Width - trunc(p.Width * w_coeff)) div 2, (p.Height - trunc(p.Height * h_coeff)) div 2,
        trunc(p.Width * w_coeff), trunc(p.Height * h_coeff),
        0, 0, w, h, UnitPixel, hattr, nil, nil);

      GdipDisposeImageAttributes(hattr);
    end;

    GdipDeleteGraphics(hgdip);
  except
    on e: Exception do frmterry.notify('frmStackProp.DrawFit'#10#13 + e.message);
  end;
end;
//------------------------------------------------------------------------------
end.

