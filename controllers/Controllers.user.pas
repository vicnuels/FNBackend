unit Controllers.user;

interface

uses
  Horse, FarmaNossa.Providers.Authorization, FarmaNossa.Services.Users,
  SysUtils, System.JSON;

procedure Registry;

implementation

procedure DoGetuser(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  user: TServiceUser;
  UserJson: TJSONArray;
  Name, Id: String;
begin
  user := TServiceUser.Create;
  try
    Name := Req.Query.Field('name').AsString;
    Id := Req.Query.Field('id').AsString;

    UserJson := user.GetAll(Name, Id);
    if UserJson.Count = 0 then
      Res.Send('Not Found').Status(404)
    else
      Res.Send<TJSONAncestor>(UserJson.Clone);
  finally
    UserJson.Free;
    user.Free;
  end;

end;

procedure DoGetByIduser(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Id: String;
  user: TServiceUser;
  UserJson: TJSONObject;
begin
  Id := Req.Params['id'];
  if Length(Id) <= 0 then
    Res.Send('No Id').Status(400)
  else
  begin
    user := TServiceUser.Create;
    try
      UserJson := user.GetUser(Id.ToInteger());
      if UserJson.Count = 0 then
        Res.Send('Not Found').Status(404)
      else
        Res.Send<TJSONAncestor>(UserJson.Clone);
    finally
      user.Free;
      UserJson.Free;
    end;
  end;

end;

procedure DoPostuser(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  UserJson: TJSONObject;
  IdNewUser: Integer;
  user: TServiceUser;
begin
  UserJson := Req.Body<TJSONObject>;
  if Length(UserJson.GetValue('name').Value) <= 0 then
    Res.Send('Not found').Status(404)
  Else
  begin
    try
      user := TServiceUser.Create;
      IdNewUser := user.Post(UserJson.GetValue<String>('name'),
        UserJson.GetValue<String>('login'),
        UserJson.GetValue<String>('password'));
      if IdNewUser >= 0 then
        Res.Send(IdNewUser.ToString).Status(201)
      else
        case IdNewUser of
          - 1:
            Res.Send('Erro: Falha ao criar novo usuário.').Status(400);
          -2:
            Res.Send('Erro: O login já existe. Por favor, escolha um login diferente.')
              .Status(409);
        else
          Res.Send('Not Created').Status(400);
        end;
    finally
      user.Free;
    end;

  end;

end;

procedure DoPutuser(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Id, Name, Password: string;
  user: TServiceUser;
  UserUpdate: TJSONObject;
  Result: Boolean;
begin
  Id := Req.Params['id'];
  if Id.ToInteger <= 0 then
    Res.Send('ID invalid')
  else

  UserUpdate := Req.Body<TJSONObject>;

  Password :=  UserUpdate.GetValue<string>('password');
  Name :=  UserUpdate.GetValue<string>('name');

  if Name.IsEmpty or Password.IsEmpty then
    begin
      Res.Send('name and password are required').Status(404)
    end;

  begin
    try
      UserUpdate := Req.Body<TJSONObject>;
      user := TServiceUser.Create;
      Result := user.Update(Id.ToInteger, UserUpdate.GetValue<String>('name'),
        UserUpdate.GetValue<String>('password'));
      if Result then
        Res.Send('Updated').Status(202)
      else
        Res.Send('Not Update').Status(304);
    finally
      user.Free;
    end;
  end;

end;

procedure DoDeleteuser(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Id: string;
  user: TServiceUser;
  StatusDeleted: Boolean;
begin
  Id := Req.Params['id'];
  if Id.ToInteger > 0 then
  begin
    try
      user := TServiceUser.Create;
      StatusDeleted := user.Delete(Id.ToInteger());
      if StatusDeleted then
        Res.Send('Deleted').Status(200)
      else
        Res.Send('Not Deleted').Status(404);
    finally

    end;

  end
  else
    Res.Send('Not Deleted').Status(400);

end;

procedure Registry;
begin
  THorse.AddCallback(Authorization()).Get('user', DoGetuser)
    .AddCallback(Authorization()).Post('user', DoPostuser)
    .AddCallback(Authorization()).Get('user/:id', DoGetByIduser)
    .AddCallback(Authorization()).Put('user/:id', DoPutuser)
    .AddCallback(Authorization()).Delete('user/:id', DoDeleteuser)
end;

end.
