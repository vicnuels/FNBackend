unit FarmaNossa.Services.Users;

interface

uses
  System.SysUtils, System.Classes, System.JSON, Data.DB, Uni, MemDS, Vcl.Dialogs,
  FarmaNossa.Providers.Connection;

type
  TServiceUser = class
  private
    FConnectionProvider: TConnectionProvider;
  public
    constructor Create;
    destructor Destroy; override;
    function Validate(User: String; Password: String): Boolean;
    function GetUser(UserId: Integer): TJSONObject;
    function GetAll(Name: String = ''; Id: String = ''): TJSONArray;
    function Post(Name, UserName, Password: String): Integer;
    function Update(UserId: Integer; UserName, Password: String): Boolean;
    function Delete(UserId: Integer): Boolean;
  end;

implementation

{ TServiceUser }

constructor TServiceUser.Create;
begin
  FConnectionProvider := TConnectionProvider.Create;
end;

destructor TServiceUser.Destroy;
begin
  FConnectionProvider.Free;
  inherited;
end;

// validar acesso do usuário
function TServiceUser.Validate(User: String; Password: String): Boolean;
var
  Query: TUniQuery;
begin
  Query := FConnectionProvider.GetQuery;

  try
    Query.Close;
    // como a senha é criptografada pelo próprio PG, faço uma consulta via função dentro do banco
    Query.SQL.Text := 'SELECT autenticar_usuario(:user, :password)';
    Query.ParamByName('User').AsString := User;
    Query.ParamByName('Password').AsString := Password;
    Query.Open;
    Result := Query.Fields[0].AsBoolean;
  except
    on E: Exception do
    begin
      Result := False;
    end;
  end;
end;

// pegar apenas um usuário por id
function TServiceUser.GetUser(UserId: Integer): TJSONObject;
var
  Query: TUniQuery;
  UserJSON: TJSONObject;
begin
  Query := FConnectionProvider.GetQuery;
  UserJSON := TJSONObject.Create;

  try
    Query.Close;
    Query.SQL.Text := 'SELECT codigo, nome FROM operador WHERE codigo = :id';
    Query.ParamByName('Id').AsInteger := UserId;
    Query.Open;

    if not Query.Eof then
    begin
      UserJSON.AddPair('id', TJSONNumber.Create(Query.FieldByName('codigo').AsInteger));
      UserJSON.AddPair('name', Query.FieldByName('nome').AsString);
    end;

    Result := UserJSON;
  except
    on E: Exception do
    begin
      UserJSON.Free;
      Result := nil;
    end;
  end;
end;

// pegar todos os usuários
function TServiceUser.GetAll(Name: String = ''; Id: String = ''): TJSONArray;
var
  Query: TUniQuery;
  UsersArray: TJSONArray;
  UserJSON: TJSONObject;
  SQLText: String;
  WhereClauses: TStringList;
begin
    Query := FConnectionProvider.GetQuery;
    UsersArray := TJSONArray.Create;
    WhereClauses := TStringList.Create;
    try

      try
        SQLText := 'SELECT codigo, nome FROM operador';

        if Name <> '' then
          WhereClauses.Add('nome like :name');
        if (Id <> '') And (id.ToInteger > 0) then
          WhereClauses.Add('codigo::varchar like :id');

        if WhereClauses.Count > 0 then
          SQLText := SQLText + ' WHERE ' + String.Join(' AND ', WhereClauses.ToStringArray);

        Query.Close;
        Query.SQL.Text := SQLText;

        if Name <> '' then
          Query.ParamByName('name').AsString := '%' + Name + '%';

        if (Id <> '') And (id.ToInteger > 0) then
          Query.ParamByName('id').AsString := Id + '%';

        //  Writeln(Query.SQL.Text);

        Query.Open;

        while not Query.Eof do
        begin
          UserJSON := TJSONObject.Create;
          UserJSON.AddPair('id', TJSONNumber.Create(Query.FieldByName('codigo').AsInteger));
          UserJSON.AddPair('name', Query.FieldByName('nome').AsString);
          UsersArray.AddElement(UserJSON);

          Query.Next;
        end;

        Result := UsersArray;
      except
        on E: Exception do
        begin
          Result := nil;
        end;
      end;
  finally
//      UsersArray.Free;  tem fazer o free na função que usa a getAll
      WhereClauses.Free;
  end;
end;

// criar um novo usuário e retornar o ID
function TServiceUser.Post(Name, UserName, Password: String): Integer;
var
  Query: TUniQuery;
begin
  Query := FConnectionProvider.GetQuery(); // erro

  try
    Query.Close;
    Query.SQL.Text := 'INSERT INTO operador (nome, login, senha) VALUES (:name, :login, :password) RETURNING codigo';
    Query.ParamByName('name').AsString := Name;
    Query.ParamByName('login').AsString := UserName;
    Query.ParamByName('password').AsString := Password;
    Query.Open;

    if not Query.Eof then
      Result := Query.FieldByName('codigo').AsInteger
    else
      Result := -1;

  except
    on E: Exception do
    begin
      if Pos('duplicar valor da chave viola a restrição de unicidade "unique_login"', E.Message) > 0 then
      begin
//        Writeln('Erro: O login já existe.');
        Result := -2; // Código de erro específico para "login" já existente
      end
      else
        Result := -1;
    end;
  end;
end;

// atualizar um usuário existente
function TServiceUser.Update(UserId: Integer; UserName, Password: String): Boolean;
var
  Query: TUniQuery;
begin
  Query := FConnectionProvider.GetQuery;

  try
    Query.Close;
    Query.SQL.Text := 'UPDATE operador SET nome = :name, senha = :password WHERE codigo = :id';
    Query.ParamByName('id').AsInteger := UserId;
    Query.ParamByName('name').AsString := UserName;
    Query.ParamByName('password').AsString := Password;
    Query.ExecSQL;
    Result := Query.RowsAffected > 0;
  except
    on E: Exception do
    begin
      Result := False;
    end;
  end;
end;

// deletar um usuário
function TServiceUser.Delete(UserId: Integer): Boolean;
var
  Query: TUniQuery;
begin
  if UserId = 1 then
  begin
    Result := False;
    exit;
  end;

  Query := FConnectionProvider.GetQuery;

  try
    Query.Close;
    Query.SQL.Text := 'DELETE FROM operador WHERE codigo = :id';
    Query.ParamByName('id').AsInteger := UserId;
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

