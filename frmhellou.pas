unit frmhellou;

{$mode delphi}

interface

uses
  Windows, Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls;

type

  { TfrmHello }

  TfrmHello = class(TForm)
    btnAdd: TButton;
    btnAutorun: TButton;
    btnClose: TButton;
    btnCloseShowTips: TButton;
    btnTop: TButton;
    btnLeft: TButton;
    btnRight: TButton;
    btnBottom: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    procedure btnAutorunClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnBottomClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnCloseShowTipsClick(Sender: TObject);
    procedure btnLeftClick(Sender: TObject);
    procedure btnRightClick(Sender: TObject);
    procedure btnTopClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  private
  public
    class procedure Open;
  end;

var
  frmHello: TfrmHello;

implementation
{$R *.lfm}
uses toolu, frmmainu, frmtipu;
//------------------------------------------------------------------------------
class procedure TfrmHello.Open;
begin
  Application.CreateForm(TfrmHello, frmHello);
  frmHello.Show;
  frmHello.btnAutorun.Enabled := not CheckAutorun;
end;
//------------------------------------------------------------------------------
procedure TfrmHello.btnCloseClick(Sender: TObject);
begin
  close;
  frmHello := nil;
end;
//------------------------------------------------------------------------------
procedure TfrmHello.btnCloseShowTipsClick(Sender: TObject);
begin
  TfrmTip.Open;
  btnClose.Click;
end;
//------------------------------------------------------------------------------
procedure TfrmHello.btnAutorunClick(Sender: TObject);
begin
  SetAutorun(true);
  btnAutorun.Enabled := not CheckAutorun;
end;
//------------------------------------------------------------------------------
procedure TfrmHello.btnAddClick(Sender: TObject);
begin
  frmmain.execute_cmdline('/apps');
end;
//------------------------------------------------------------------------------
procedure TfrmHello.btnLeftClick(Sender: TObject);
begin
  frmmain.execute_cmdline('/site(left)');
end;
//------------------------------------------------------------------------------
procedure TfrmHello.btnRightClick(Sender: TObject);
begin
  frmmain.execute_cmdline('/site(right)');
end;
//------------------------------------------------------------------------------
procedure TfrmHello.btnTopClick(Sender: TObject);
begin
  frmmain.execute_cmdline('/site(top)');
end;
//------------------------------------------------------------------------------
procedure TfrmHello.btnBottomClick(Sender: TObject);
begin
  frmmain.execute_cmdline('/site(bottom)');
end;
//------------------------------------------------------------------------------
procedure TfrmHello.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
end;
//------------------------------------------------------------------------------
end.

