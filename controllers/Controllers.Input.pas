unit Controllers.Input;

interface

uses
  Horse, System.SysUtils, System.Classes, System.JSON,
  FarmaNossa.Services.Input,
  FarmaNossa.Providers.Authorization,
  Horse.Commons, FarmaNossa.Services.Lot;

procedure Registry;

implementation

procedure DoGetInput(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  InputService: TServiceInput;
  InputId: Integer;
  InputJSON: TJSONObject;
begin
  InputService := TServiceInput.Create;
  try
    InputId := StrToIntDef(Req.Params['id'], 0);
    if InputId = 0 then
    begin
      Res.Status(400).Send('Invalid ID');
      Exit;
    end;

    InputJSON := InputService.GetInput(InputId);
    if InputJSON.Count > 0 then
      Res.Send<TJSONObject>(InputJSON)
    else
      Res.Status(404).Send('Input not found');
  finally
    InputService.Free;
  end;
end;

procedure DoGetLot(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LotService: TServiceLot;
  Lot: String;
  InputJSON: TJSONObject;
begin
  LotService := TServiceLot.Create;
  try
    Lot := Req.Params['lot'];
    if Lot = '' then
    begin
      Res.Status(400).Send('Invalid Lot');
      Exit;
    end;

    InputJSON := LotService.Get(Lot);
    if InputJSON.Count > 0 then
      Res.Send<TJSONObject>(InputJSON)
    else
      Res.Status(404).Send('Lot not found');
  finally
    LotService.Free;
  end;
end;

procedure GetAllInputs(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  InputService: TServiceInput;
  Id, ProdId, LocalId: Integer;
  Lot: String;
  FromDate, ToDate: TDate;
  InputArray: TJSONArray;
begin
  InputService := TServiceInput.Create;
  try
    Id := StrToIntDef(Req.Query['id'], 0);
    ProdId := StrToIntDef(Req.Query['prod_id'], 0);
    LocalId := StrToIntDef(Req.Query['local_id'], 0);
    Lot := Req.Query['lot'];
    FromDate := StrToDateDef(Req.Query['from_date'], 0);
    ToDate := StrToDateDef(Req.Query['to_date'], 0);

    InputArray := InputService.GetAll(Id, ProdId, LocalId, Lot,
      FromDate, ToDate);
    Res.Send<TJSONArray>(InputArray);
  finally
    InputService.Free;
  end;
end;

procedure DoPostInput(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  InputService: TServiceInput;
  Body: TJSONObject;
  Response: TJSONObject;
  ProdId, LocalId: Integer;
  Lot: String;
  SManufactureDate, SExpiryDate: string;
  ManufactureDate, ExpiryDate: TDate;
  Quantity: Double;
  NewInputId: Integer;
begin
  InputService := TServiceInput.Create;
  try
    Body := Req.Body<TJSONObject>;

    if (not Body.TryGetValue<Integer>('product_id', ProdId)) or
      (not Body.TryGetValue<Integer>('local_id', LocalId)) or
      (not Body.TryGetValue<String>('lot', Lot)) or
      (not Body.TryGetValue<Double>('quantity', Quantity)) or
      (not Body.TryGetValue<String>('manufacture_date', SManufactureDate)) or
      (not Body.TryGetValue<String>('expiry_date', SExpiryDate)) then
    begin
      Res.Status(THTTPStatus.MethodNotAllowed)
        .Send('Erro: Campos obrigatórios não fornecidos.');
      Exit;
    end;

    ManufactureDate := StrToDate(Body.GetValue<String>('manufacture_date'));
    ExpiryDate := StrToDate(Body.GetValue<String>('expiry_date'));

    NewInputId := InputService.Post(ProdId, LocalId, Lot, ManufactureDate,
      ExpiryDate, Quantity);
    Response := TJSONObject.Create;
    case NewInputId of
      - 1:
        begin
          Response.AddPair('error', TJSONBool.Create(True));
          Response.AddPair('message',
            TJSONString.Create('Erro ao lançar entrada'));
          Res.Status(THTTPStatus.InternalServerError)
            .Send<TJSONObject>(Response);
          Exit;
        end;
      -2:
        begin
          Response.AddPair('error', TJSONBool.Create(True));
          Response.AddPair('message',
            TJSONString.Create('Produdo não encontrado'));
          Res.Status(THTTPStatus.NotAcceptable).Send<TJSONObject>(Response);
          Exit;
        end;
      -3:
        begin
          Response.AddPair('error', TJSONBool.Create(True));
          Response.AddPair('message', TJSONString.Create('Produdo inativo'));
          Res.Status(THTTPStatus.NotAcceptable).Send<TJSONObject>(Response);
          Exit;
        end;
      -4:
        begin
          Response.AddPair('error', TJSONBool.Create(True));
          Response.AddPair('message',
            TJSONString.Create('Produto que não permite entrada'));
          Res.Status(THTTPStatus.NotAcceptable).Send<TJSONObject>(Response);
          Exit;
        end;
      -5:
        begin
          Response.AddPair('error', TJSONBool.Create(True));
          Response.AddPair('message',
            TJSONString.Create('Local não encontrado'));
          Res.Status(THTTPStatus.NotAcceptable).Send<TJSONObject>(Response);
          Exit;
        end;
      -6:
        begin
          Response.AddPair('error', TJSONBool.Create(True));
          Response.AddPair('message', TJSONString.Create('Local inativo'));
          Res.Status(THTTPStatus.NotAcceptable).Send<TJSONObject>(Response);
          Exit;
        end;
    end;

    Response.AddPair('id', TJSONNumber.Create(NewInputId));
    if NewInputId >= 0 then
      Res.Status(THTTPStatus.Created).Send(Response)
    else
      Res.Status(500).Send('Error creating input');
  finally
    InputService.Free;
  end;
end;

procedure DoPutInput(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  InputService: TServiceInput;
  InputId, ProdId, LocalId: Integer;
  Lot: String;
  SManufactureDate, SExpiryDate: string;
  ManufactureDate, ExpiryDate: TDate;
  Quantity: Double;
  Body: TJSONObject;
  ResultPut: Integer;
  Response: TJSONObject;
begin
  InputService := TServiceInput.Create;
  try
    InputId := StrToIntDef(Req.Params['id'], 0);
    if InputId = 0 then
    begin
      Res.Status(400).Send('Invalid ID');
      Exit;
    end;

    Body := Req.Body<TJSONObject>;

    if (not Body.TryGetValue<Integer>('product_id', ProdId)) or
      (not Body.TryGetValue<Integer>('local_id', LocalId)) or
      (not Body.TryGetValue<String>('lot', Lot)) or
      (not Body.TryGetValue<Double>('quantity', Quantity)) or
      (not Body.TryGetValue<String>('manufacture_date', SManufactureDate)) or
      (not Body.TryGetValue<String>('expiry_date', SExpiryDate)) then
    begin
      Res.Status(THTTPStatus.BadRequest)
        .Send('Erro: Campos obrigatórios não fornecidos.');
      Exit;
    end;
    ManufactureDate := StrToDate(Body.GetValue<String>('manufacture_date'));
    ExpiryDate := StrToDate(Body.GetValue<String>('expiry_date'));

    ResultPut := InputService.Update(InputId, ProdId, LocalId, Lot,
      ManufactureDate, ExpiryDate, Quantity);

    Response := TJSONObject.Create;
    case ResultPut of
      - 1:
        begin
          Response.AddPair('error', TJSONBool.Create(True));
          Response.AddPair('message',
            TJSONString.Create('Erro ao lançar entrada'));
          Res.Status(THTTPStatus.InternalServerError)
            .Send<TJSONObject>(Response);
          Exit;
        end;
      -2:
        begin
          Response.AddPair('error', TJSONBool.Create(True));
          Response.AddPair('message',
            TJSONString.Create('Produdo não encontrado'));
          Res.Status(THTTPStatus.NotAcceptable).Send<TJSONObject>(Response);
          Exit;
        end;
      -3:
        begin
          Response.AddPair('error', TJSONBool.Create(True));
          Response.AddPair('message', TJSONString.Create('Produdo inativo'));
          Res.Status(THTTPStatus.NotAcceptable).Send<TJSONObject>(Response);
          Exit;
        end;
      -4:
        begin
          Response.AddPair('error', TJSONBool.Create(True));
          Response.AddPair('message',
            TJSONString.Create('Produto que não permite entrada'));
          Res.Status(THTTPStatus.NotAcceptable).Send<TJSONObject>(Response);
          Exit;
        end;
      -5:
        begin
          Response.AddPair('error', TJSONBool.Create(True));
          Response.AddPair('message',
            TJSONString.Create('Local não encontrado'));
          Res.Status(THTTPStatus.NotAcceptable).Send<TJSONObject>(Response);
          Exit;
        end;
      -6:
        begin
          Response.AddPair('error', TJSONBool.Create(True));
          Response.AddPair('message', TJSONString.Create('Local inativo'));
          Res.Status(THTTPStatus.NotAcceptable).Send<TJSONObject>(Response);
          Exit;
        end;
    end;

    if ResultPut >= 0 then
    begin
      Response.AddPair('id', TJSONNumber.Create(ResultPut));
      Res.Status(THTTPStatus.Accepted).Send(Response);
    end
    else
      Res.Status(500).Send('Error updating input');
  finally
    InputService.Free;
  end;
end;

procedure DeleteInput(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  InputService: TServiceInput;
  InputId: Integer;
  Success: Boolean;
begin
  InputService := TServiceInput.Create;
  try
    InputId := StrToIntDef(Req.Params['id'], 0);
    if InputId = 0 then
    begin
      Res.Status(400).Send('Invalid ID');
      Exit;
    end;

    Success := InputService.Delete(InputId);
    if Success then
      Res.Status(200).Send('Input deleted successfully')
    else
      Res.Status(500).Send('Error deleting input');
  finally
    InputService.Free;
  end;
end;

procedure Registry;
begin
  THorse.AddCallback(Authorization()).Get('/input/:id', DoGetInput);
  THorse.AddCallback(Authorization()).Get('/lot/:lot', DoGetLot);
  THorse.AddCallback(Authorization()).Get('/input', GetAllInputs);
  THorse.AddCallback(Authorization()).Post('/input', DoPostInput);
  THorse.AddCallback(Authorization()).Put('/input/:id', DoPutInput);
  THorse.AddCallback(Authorization()).Delete('/input/:id', DeleteInput);
end;

end.
