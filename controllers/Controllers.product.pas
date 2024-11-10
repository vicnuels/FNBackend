unit Controllers.product;

interface

uses
  FarmaNossa.Providers.Authorization,
  FarmaNossa.Services.Products,
  Horse,
  Horse.Commons,
  SysUtils, System.JSON;

procedure Registry;

implementation

// get all
procedure DoGetproduct(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Desc: String;
  Status, N_stock, S_input, S_output, Id: String;
  SProduct: TServiceProduct;
  Products: TJSONArray;
begin
  Desc := Req.Query.Field('description').AsString;
  Id := Req.Query.Field('id').AsString;
  Status := Req.Query.Field('status').AsString;
  N_stock := Req.Query.Field('n_stock').AsString;
  S_input := Req.Query.Field('s_input').AsString;
  S_output := Req.Query.Field('s_output').AsString;

  SProduct := TServiceProduct.Create;
  try
    Products := SProduct.GetAll(Desc, Id, Status, N_stock, S_input, S_output);
    Res.Send<TJSONArray>(Products);
  finally
    SProduct.Free;
  end;
end;

// get id
procedure DoGetByIdproduct(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  id: string;
  SProduct: TServiceProduct;
  Product: TJSONObject;
begin
  Id := Req.Params['id'];
  if Id.ToInteger <= 0 then
    Res.Send('ID is not Interger').Status(400)
  else begin
    SProduct := TServiceProduct.Create;
    try
      Product := SProduct.GetProduct(id.ToInteger());
      if Product.Count = 0 then
        Res.Send('Not Found').Status(404)
      else
        Res.Send<TJSONAncestor>(Product.Clone);
    finally
         SProduct.Free;
         Product.Free;
    end;
  end;
end;

// post
procedure DoPostproduct(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
SProduct: TServiceProduct;
NewProduct: TJSONObject;
NewProductId: Integer;
Description: String;
Status, N_Stock, S_Input, S_Output: Boolean;
begin
  NewProduct := Req.Body<TJSONObject>;
  if (not NewProduct.TryGetValue<string>('description', Description)) or
    (not NewProduct.TryGetValue<Boolean>('status', Status)) or
    (not NewProduct.TryGetValue<Boolean>('n_stock', N_Stock)) or
    (not NewProduct.TryGetValue<Boolean>('s_input', S_Input)) or
    (not NewProduct.TryGetValue<Boolean>('s_output', S_Output)) then
      begin
          Res.Status(THTTPStatus.BadRequest).Send('Erro: Campos obrigatórios não fornecidos.');
          Exit;
      end;

  SProduct := TServiceProduct.Create;
  try

    NewProductId := SProduct.Post(Description, Status, N_Stock, S_Input, S_Output);
    if NewProductId < 0 then
      Res.Send('Product not created').Status(THTTPStatus.BadRequest)
    else
      Res.Send(NewProductId.ToString).Status(THTTPStatus.Created)
  finally
    SProduct.Free;
  end;
end;

procedure DoPutproduct(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
SProduct: TServiceProduct;
NewProduct: TJSONObject;
Id: string;
Description: String;
Status, N_Stock, S_Input, S_Output, status_return: Boolean;
begin
  id := Req.Params['id'];
  NewProduct := Req.Body<TJSONObject>;
   try
      if (not NewProduct.TryGetValue<string>('description', Description)) or
      (not NewProduct.TryGetValue<Boolean>('status', Status)) or
      (not NewProduct.TryGetValue<Boolean>('n_stock', N_Stock)) or
      (not NewProduct.TryGetValue<Boolean>('s_input', S_Input)) or
      (not NewProduct.TryGetValue<Boolean>('s_output', S_Output)) or
      (Id.ToInteger < 0 )then
        begin
            Res.Status(THTTPStatus.BadRequest).Send('Erro: Campos obrigatórios não fornecidos.');
            Exit;
        end;



      SProduct := TServiceProduct.Create;
      status_return := SProduct.Update(id.ToInteger, Description, Status, N_Stock, S_Input, S_Output);
      if not status_return then
        Res.Send('Product not updated').Status(THTTPStatus.NotModified)
      else
        Res.Send('Updated').Status(THTTPStatus.Accepted)
  finally
    SProduct.Free;
  end;

end;

procedure DoDeleteproduct(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  id: string;
  SProduct: TServiceProduct;
  status: Boolean;
begin
  id := Req.Params['id'];
  if Id.ToInteger <= 0 then
    Res.Send('ID is not Interger').Status(400)
  else begin
    try
      SProduct := TServiceProduct.Create;
      status := SProduct.Delete(id.ToInteger());
      if (status) then
        Res.Send('Deleted').Status(THTTPStatus.Accepted)
      else
        Res.Send('Not Deleted').Status(THTTPStatus.NotAcceptable);

    finally
      SProduct.Free;
    end;
  end;

end;

procedure Registry;
begin

  // tem colocar uma callback em cada endpoint
  THorse
    .AddCallback(Authorization())
    .Get('product', DoGetproduct)
    .AddCallback(Authorization())
    .Post('product', DoPostproduct)
    .AddCallback(Authorization())
    .Get('product/:id', DoGetByIdproduct)
    .AddCallback(Authorization())
    .Put('product/:id', DoPutproduct)
    .AddCallback(Authorization())
    .Delete('product/:id', DoDeleteproduct);

end;

end.