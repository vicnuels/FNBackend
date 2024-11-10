unit View.ConfigDB;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, FarmaNossa.Services.Variable,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls;

type
  TViewDBAccess = class(TForm)
    npFooter: TPanel;
    btnCancel: TBitBtn;
    btnCreate: TBitBtn;
    pnData: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    editServe: TEdit;
    editDB: TEdit;
    editPort: TEdit;
    Label4: TLabel;
    procedure btnCreateClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

procedure TViewDBAccess.btnCancelClick(Sender: TObject);
begin
  Self.Close;
  Self.ModalResult := mrCancel;
end;

procedure TViewDBAccess.btnCreateClick(Sender: TObject);
var
  Port, Server, DataBase: String;
begin
  Port := Trim(editPort.Text);
  Server := Trim(editServe.Text);
  DataBase := Trim(editDB.Text);

  if Server = '' then
  begin
    editServe.SetFocus;
    raise Exception.Create('Digite o endereço do servidor');
  end;

  if Port = '' then
  begin
    editPort.SetFocus;
    raise Exception.Create('Digite a porta do servidor');
  end;

  if DataBase = '' then
  begin
    editDB.SetFocus;
    raise Exception.Create('Digite o nome do Banco de dados');
  end;

  SetEnvVariableInRegistry('FARMA_NOSSA_DB_SERVER', Server);
  SetEnvVariableInRegistry('FARMA_NOSSA_DB_PORT', Port);
  SetEnvVariableInRegistry('FARMA_NOSSA_DB_DATABASE', DataBase);

  Self.Close;
  Self.ModalResult := mrOk;

  ShowMessage('Configurações salvas');

end;

procedure TViewDBAccess.FormCreate(Sender: TObject);
var
  Port, Server, DataBase: String;
begin

  Port := Trim(GetEnvVariableFromRegistry('FARMA_NOSSA_DB_PORT'));
  Server := Trim(GetEnvVariableFromRegistry('FARMA_NOSSA_DB_SERVER'));
  DataBase := Trim(GetEnvVariableFromRegistry('FARMA_NOSSA_DB_DATABASE'));

  if (Port = '') or (Server = '') or (DataBase = '') then
    exit;

  editServe.Text := Server;
  editDB.Text := DataBase;
  editPort.Text := Port;
end;

end.
