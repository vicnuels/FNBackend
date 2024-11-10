unit FarmaNossa.Providers.Connection;

interface

uses
  System.SysUtils, System.Classes, Data.DB, DBAccess, Uni, MemDS,
  PostgreSQLUniProvider, FarmaNossa.Services.Variable,
  UniProvider, ODBCUniProvider, AccessUniProvider;

type
  TConnectionProvider = class
  private
    FUniConnection: TUniConnection;
    FUniQuery: TUniQuery;
    FUniDataSource: TUniDataSource;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ConfigureConnection;
    function GetQuery: TUniQuery;
  end;

type
  TForm1 = class
  private
  public
  end;

implementation

{ TConnectionProvider }

constructor TConnectionProvider.Create;
begin
  inherited Create;

  // Instanciando os componentes
  FUniConnection := TUniConnection.Create(nil);
  FUniQuery := TUniQuery.Create(nil);
  FUniDataSource := TUniDataSource.Create(nil);

  // Configurando o TUniQuery e TUniDataSource para usar a conexão
  FUniQuery.Connection := FUniConnection;
  FUniDataSource.DataSet := FUniQuery;

  ConfigureConnection;

end;

destructor TConnectionProvider.Destroy;
begin
  // Liberando os componentes
  FUniDataSource.Free;
  FUniQuery.Free;
  FUniConnection.Free;

  inherited Destroy;
end;

procedure TConnectionProvider.ConfigureConnection;
var
  Port, Server, DataBase: String;
begin

  Port := Trim(GetEnvVariableFromRegistry('FARMA_NOSSA_DB_PORT'));
  Server := Trim(GetEnvVariableFromRegistry('FARMA_NOSSA_DB_SERVER'));
  DataBase := Trim(GetEnvVariableFromRegistry('FARMA_NOSSA_DB_DATABASE'));

  if (Port = '') or (Server = '') or (DataBase = '') then
  begin
    raise Exception.Create('Configure o banco de dados!');
  end;

  FUniConnection.ProviderName := 'PostgreSQL';
  FUniConnection.Port := Port.ToInteger; // 5432;
  FUniConnection.Server := Server; // 'localhost';
  FUniConnection.DataBase := DataBase; // 'farmanossa';
  FUniConnection.Username := 'postgres';
  FUniConnection.Password := '2005';
  FUniConnection.LoginPrompt := True;

  try
    FUniConnection.Connect;
  except
    on E: Exception do
    begin
      Writeln('Error configuring connection: ' + E.Message);
      raise;
    end;
  end;
end;

function TConnectionProvider.GetQuery: TUniQuery;
begin
  Result := FUniQuery;
end;

end.
