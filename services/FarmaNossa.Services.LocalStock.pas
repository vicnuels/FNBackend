unit FarmaNossa.Services.LocalStock;

interface

uses
  System.SysUtils, System.Classes, System.JSON, Data.DB, Uni, MemDS,
  FarmaNossa.Providers.Connection, FarmaNossa.Entities.Local;

type
  TServiceLocal = class
  private
    FConnectionProvider: TConnectionProvider;
  public
    constructor Create;
    destructor Destroy; override;
    function GetLocalEntity(LocalId: Integer): TLocal;
    function GetLocal(LocalId: Integer): TJSONObject;
    function GetAll(Id: String = ''; Desc: String = ''; Status: String = ''): TJSONArray;
    function Post(Desc: String; Status: Boolean): Integer;
    function Update(Id: Integer; Desc: String; Status: Boolean): Boolean;
    function Delete(LocalId: Integer): Boolean;
  end;

implementation

{ TServiceLocal }

constructor TServiceLocal.Create;
begin
  FConnectionProvider := TConnectionProvider.Create;
end;

destructor TServiceLocal.Destroy;
begin
  FConnectionProvider.Free;
  inherited;
end;

// Pegar apenas um local de estoque por ID
function TServiceLocal.GetLocal(LocalId: Integer): TJSONObject;
var
  Query: TUniQuery;
  LocalJSON: TJSONObject;
begin
  Query := FConnectionProvider.GetQuery;
  LocalJSON := TJSONObject.Create;

    try
      Query.Close;
      Query.SQL.Text := 'SELECT codigo, descricao, status FROM local_estoque WHERE codigo = :id';
      Query.ParamByName('Id').AsInteger := LocalId;
      Query.Open;

      if not Query.Eof then
      begin
        LocalJSON.AddPair('id', TJSONNumber.Create(Query.FieldByName('codigo').AsInteger));
        LocalJSON.AddPair('description', Query.FieldByName('descricao').AsString);
        LocalJSON.AddPair('status', TJSONBool.Create(Query.FieldByName('status').AsBoolean));
      end;

      Result := LocalJSON;
    except
      on E: Exception do
      begin
        Result := nil;
      end;
    end;

end;

function TServiceLocal.GetLocalEntity(LocalId: Integer): TLocal;
var
  Query: TUniQuery;
  Local: TLocal;
begin
  Query := FConnectionProvider.GetQuery;
  Local := TLocal.Create;

  try
    try
      Query.Close;
      Query.SQL.Text := 'SELECT codigo, descricao, status FROM local_estoque WHERE codigo = :id';
      Query.ParamByName('Id').AsInteger := LocalId;
      Query.Open;

      if not Query.Eof then
      begin
        Local.Code := Query.FieldByName('codigo').AsInteger;
        Local.Description := Query.FieldByName('descricao').AsString;
        Local.Status := Query.FieldByName('status').AsBoolean;
      end;

      Result := Local;
    except
      on E: Exception do
      begin
        Result := nil;
      end;
    end;
  finally
    Local.Free;
  end;

end;

// Pegar todos os locais de estoque
function TServiceLocal.GetAll(Id: String = ''; Desc: String = ''; Status: String = ''): TJSONArray;
var
  Query: TUniQuery;
  LocalArray: TJSONArray;
  LocalJSON: TJSONObject;
  SQLText: String;
  WhereClauses: TStringList;
begin
  Query := FConnectionProvider.GetQuery;
  LocalArray := TJSONArray.Create;
  WhereClauses := TStringList.Create;

  try
    try
      SQLText := 'SELECT codigo, descricao, status FROM local_estoque';

      if (Id <> '') And (id.ToInteger > 0) then
          WhereClauses.Add('codigo::varchar like :id');
      if Desc <> '' then
        WhereClauses.Add('descricao LIKE :desc');
      if Status.Equals('false') or Status.Equals('true') then
        WhereClauses.Add('status = :status');

      if WhereClauses.Count > 0 then
        SQLText := SQLText + ' WHERE ' + String.Join(' AND ', WhereClauses.ToStringArray);

      Query.SQL.Text := SQLText;

      if (Id <> '') And (id.ToInteger > 0) then
          Query.ParamByName('id').AsString := Id + '%';
      if Desc <> '' then
        Query.ParamByName('desc').AsString := '%' + Desc + '%';
      if Status.Equals('false') or Status.Equals('true') then
        Query.ParamByName('status').AsBoolean := StrToBool(Status);

      Query.Open;

      while not Query.Eof do
      begin
        LocalJSON := TJSONObject.Create;
        LocalJSON.AddPair('id', TJSONNumber.Create(Query.FieldByName('codigo').AsInteger));
        LocalJSON.AddPair('description', Query.FieldByName('descricao').AsString);
        LocalJSON.AddPair('status', TJSONBool.Create(Query.FieldByName('status').AsBoolean));
        LocalArray.AddElement(LocalJSON);

        Query.Next;
      end;

      Result := LocalArray;
    except
      on E: Exception do
      begin
        LocalArray.Free;
        Result := nil;
      end;
    end;
  finally
    WhereClauses.Free;
  end;
end;

// Criar um novo local de estoque e retornar o ID
function TServiceLocal.Post(Desc: String; Status: Boolean): Integer;
var
  Query: TUniQuery;
begin
  Query := FConnectionProvider.GetQuery;

  try
    Query.Close;
    Query.SQL.Text := 'INSERT INTO local_estoque (descricao, status) VALUES (:desc, :status) RETURNING codigo';
    Query.ParamByName('desc').AsString := Desc;
    Query.ParamByName('status').AsBoolean := Status;
    Query.Open;

    if not Query.Eof then
      Result := Query.FieldByName('codigo').AsInteger
    else
      Result := -1;
  except
    on E: Exception do
    begin
      Result := -1;
    end;
  end;
end;

// Atualizar um local de estoque existente
function TServiceLocal.Update(Id: Integer; Desc: String; Status: Boolean): Boolean;
var
  Query: TUniQuery;
begin
  Query := FConnectionProvider.GetQuery;

  try
    Query.Close;
    Query.SQL.Text := 'UPDATE local_estoque SET descricao = :desc, status = :status WHERE codigo = :id';
    Query.ParamByName('desc').AsString := Desc;
    Query.ParamByName('status').AsBoolean := Status;
    Query.ParamByName('id').AsInteger := Id;
    Query.ExecSQL;
    Result := Query.RowsAffected > 0;
  except
    on E: Exception do
    begin
      Result := False;
    end;
  end;
end;

// Deletar um local de estoque
function TServiceLocal.Delete(LocalId: Integer): Boolean;
var
  Query: TUniQuery;
begin
  Query := FConnectionProvider.GetQuery;

  try
    Query.Close;
    Query.SQL.Text := 'DELETE FROM local_estoque l WHERE l.codigo = :id  and (select count(*) from entrada_mercadorias where codigo_local = :id) = 0 and (select count(*) from saida_mercadorias where codigo_local = :id) = 0';
    Query.ParamByName('id').AsInteger := LocalId;
    Query.ExecSQL;
    Result := Query.RowsAffected > 0;
  except
    on E: Exception do
    begin
      Result := False;
    end;
  end;
end;

end.

