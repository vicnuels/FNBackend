unit Controllers.local;

interface

uses
  FarmaNossa.Providers.Authorization,
  FarmaNossa.Services.LocalStock,
  Horse,
  Horse.Commons,
  SysUtils, System.JSON;

procedure Registry;

implementation

// get all
procedure DoGetLocal(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Desc, Status, Id: String;
  SLocal: TServiceLocal;
  LocaisEstoque: TJSONArray;
begin
  Desc := Req.Query.Field('description').AsString;
  Status := Req.Query.Field('status').AsString;
  Id := Req.Query.Field('id').AsString;
  SLocal := TServiceLocal.Create;
  try
    LocaisEstoque := SLocal.GetAll(Id, Desc, Status);
    Res.Send<TJSONArray>(LocaisEstoque);
  finally
    SLocal.Free;
  end;
end;

// get id
procedure DoGetByIdLocal(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  id: string;
  SLocal: TServiceLocal;
  Local: TJSONObject;
begin
  Id := Req.Params['id'];
  if Id.ToInteger <= 0 then
    Res.Send('ID is not Integer').Status(400)
  else begin
    SLocal := TServiceLocal.Create;
    try
      Local := SLocal.GetLocal(id.ToInteger());
      if Local.Count = 0 then
        Res.Send('Not Found').Status(404)
      else
        Res.Send<TJSONAncestor>(Local.Clone);
    finally
         SLocal.Free;
         Local.Free;
    end;
  end;
end;

// post
procedure DoPostLocal(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  SLocal: TServiceLocal;
  NewLocal: TJSONObject;
  NewLocalId: Integer;
  Description: String;
  Status: Boolean;
begin
  NewLocal := Req.Body<TJSONObject>;
  if (not NewLocal.TryGetValue<string>('description', Description)) or
  (not NewLocal.TryGetValue<Boolean>('status', Status)) then
  begin
    Res.Status(THTTPStatus.BadRequest).Send('Erro: Campos obrigatórios não fornecidos.');
    Exit;
  end;

  SLocal := TServiceLocal.Create;
  try
    NewLocalId := SLocal.Post(Description, Status);
    if NewLocalId < 0 then
      Res.Send('Not created').Status(THTTPStatus.BadRequest)
    else
      Res.Send(NewLocalId.ToString).Status(THTTPStatus.Created)
  finally
    SLocal.Free;
  end;
end;

procedure DoPutLocal(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  SLocal: TServiceLocal;
  UpdatedLocal: TJSONObject;
  Id: string;
  Description: String;
  status_return, Status: Boolean;
begin
  id := Req.Params['id'];
  UpdatedLocal := Req.Body<TJSONObject>;
  try
    if (not UpdatedLocal.TryGetValue<string>('description', Description)) or
       (not UpdatedLocal.TryGetValue<Boolean>('status', Status)) or
       (Id.ToInteger < 0) then
    begin
      Res.Status(THTTPStatus.BadRequest).Send('Erro: Campos obrigatórios não fornecidos.');
      Exit;
    end;

    SLocal := TServiceLocal.Create;
    status_return := SLocal.Update(id.ToInteger, Description, Status);
    if not status_return then
      Res.Send('Not updated').Status(THTTPStatus.NotModified)
    else
      Res.Send('Updated').Status(THTTPStatus.Accepted)
  finally
    SLocal.Free;
  end;
end;

procedure DoDeleteLocal(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  id: string;
  SLocal: TServiceLocal;
  status: Boolean;
begin
  id := Req.Params['id'];
  if Id.ToInteger <= 0 then
    Res.Send('ID is not Integer').Status(400)
  else begin
    try
      SLocal := TServiceLocal.Create;
      status := SLocal.Delete(id.ToInteger());
      if (status) then
        Res.Send('Deleted').Status(THTTPStatus.Accepted)
      else
        Res.Send('Not Deleted').Status(THTTPStatus.NotAcceptable);
    finally
      SLocal.Free;
    end;
  end;
end;

procedure Registry;
begin
  // tem que colocar uma callback em cada endpoint
  THorse
    .AddCallback(Authorization())
    .Get('local', DoGetLocal)
    .AddCallback(Authorization())
    .Post('local', DoPostLocal)
    .AddCallback(Authorization())
    .Get('local/:id', DoGetByIdLocal)
    .AddCallback(Authorization())
    .Put('local/:id', DoPutLocal)
    .AddCallback(Authorization())
    .Delete('local/:id', DoDeleteLocal);
end;

end.
