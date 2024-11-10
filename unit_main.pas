unit unit_main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, System.StrUtils,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  FarmaNossa.Services.Variable, View.ConfigDB,
  Horse,
  Horse.Jhonson,
  Horse.Compression,
  Horse.HandleException,
  Horse.BasicAuthentication,
  Horse.Commons,
  System.JSON,
  Controllers.user,
  Controllers.login,
  FarmaNossa.Configs.login,
  FarmaNossa.Providers.Authorization,
  FarmaNossa.Services.Users,
  FarmaNossa.Providers.Connection,
  FarmaNossa.Services.Products,
  Controllers.product,
  Controllers.local,
  FarmaNossa.Services.LocalStock,
  FarmaNossa.Services.Input,
  Controllers.Input,
  FarmaNossa.Services.Output,
  Controllers.Output,
  FarmaNossa.Entities.product,
  FarmaNossa.Services.Lot,
  FarmaNossa.Services.Stock,
  Controllers.Stock,
  FarmaNossa.Services.Report,
  Controllers.Report, Vcl.StdCtrls;

type
  TUnitMain = class(TForm)
    Label1: TLabel;
    editPort: TEdit;
    Label2: TLabel;
    btnStart: TButton;
    btnStop: TButton;
    btnConfig: TButton;
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnConfigClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  UnitMain: TUnitMain;

implementation

{$R *.dfm}

procedure TUnitMain.btnConfigClick(Sender: TObject);
var
SViewConfigDb: TViewDBAccess;
begin
  SViewConfigDb := TViewDBAccess.Create(nil);
  try
    SViewConfigDb.ShowModal;
  finally
    SViewConfigDb.Free;
  end;
end;

procedure TUnitMain.btnStartClick(Sender: TObject);
var
  Port: Integer;
  PortDB, Server, DataBase: String;
begin

  PortDB := Trim(GetEnvVariableFromRegistry('FARMA_NOSSA_DB_PORT'));
  Server := Trim(GetEnvVariableFromRegistry('FARMA_NOSSA_DB_SERVER'));
  DataBase := Trim(GetEnvVariableFromRegistry('FARMA_NOSSA_DB_DATABASE'));

  if (PortDB = '') or (Server = '') or (DataBase = '') then
  begin
    raise Exception.Create('Configure o banco de dados!');
  end;


  Port := StrToIntDef(Trim(editPort.Text), 0);
  if Not Port > 0 then
  begin
    ShowMessage('Escolha uma porta');
    exit;
  end;
  SetEnvVariableInRegistry('FARMA_NOSSA_PORT', Port.ToString);
  THorse.Use(Compression()) // antes do Jhonson -  comprimir
    .Use(Jhonson).Use(HandleException); // gerenciar exceçoes

  Controllers.login.Registry;
  Controllers.user.Registry;

  Controllers.product.Registry;
  Controllers.local.Registry;
  Controllers.Input.Registry;
  Controllers.Output.Registry;
  Controllers.Stock.Registry;
  Controllers.Report.Registry;

  btnStart.Enabled := False;
  btnStop.Enabled := True;
  THorse.Listen(1000);
end;

procedure TUnitMain.btnStopClick(Sender: TObject);
begin
  THorse.StopListen;
  btnStart.Enabled := True;
  btnStop.Enabled := False;
end;

procedure TUnitMain.FormCreate(Sender: TObject);
var
Port: String;
begin
  try
    Port :=  GetEnvVariableFromRegistry('FARMA_NOSSA_PORT');
    if Port <> '' then
      editPort.Text :=  Port
    else
      editPort.Text := '1000';
  except on Exception do
    editPort.Text := '1000';
  end;
end;

end.
