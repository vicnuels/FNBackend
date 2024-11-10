unit Controllers.Output;

interface

uses
  Horse, System.SysUtils, System.Classes, System.JSON, FarmaNossa.Services.Output,
  Horse.Commons;

procedure Registry;

implementation

procedure DoGetOutput(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  OutputService: TServiceOutput;
  OutputId: Integer;
  OutputJSON: TJSONObject;
begin
  OutputService := TServiceOutput.Create;
  try
    OutputId := StrToIntDef(Req.Params['id'], 0);
    if OutputId = 0 then
    begin
      Res.Status(400).Send('Invalid ID');
      Exit;
    end;

    OutputJSON := OutputService.GetOutput(OutputId);
    if OutputJSON.Count > 0 then
      Res.Send<TJSONObject>(OutputJSON)
    else
      Res.Status(404).Send('Output not found');
  finally
    OutputService.Free;
  end;
end;

procedure GetAllOutputs(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  OutputService: TServiceOutput;
  ProdId, LocalId: Integer;
  Lot: String;
  FromDate, ToDate: TDate;
  OutputArray: TJSONArray;
begin
  OutputService := TServiceOutput.Create;
  try
    ProdId := StrToIntDef(Req.Query['prod_id'], -1);
    LocalId := StrToIntDef(Req.Query['local_id'], -1);
    Lot := Req.Query['lot'];
    FromDate := StrToDateDef(Req.Query['from_date'], 0);
    ToDate := StrToDateDef(Req.Query['to_date'], 0);

    OutputArray := OutputService.GetAll(ProdId, LocalId, Lot, FromDate, ToDate);
    Res.Send<TJSONArray>(OutputArray);
  finally
    OutputService.Free;
  end;
end;

procedure DoPostOutput(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  OutputService: TServiceOutput;
  Body: TJSONObject;
  Response: TJSONObject;
  ProdId, LocalId: Integer;
  Lot: String;
  Quantity: Double;
  NewOutputId: Integer;
begin
  OutputService := TServiceOutput.Create;
  try
    Body := Req.Body<TJSONObject>;

    if (not Body.TryGetValue<Integer>('product_id', ProdID)) or
    (not Body.TryGetValue<Integer>('local_id', LocalId)) or
    (not Body.TryGetValue<String>('lot', Lot)) or
    (not Body.TryGetValue<Double>('quantity', Quantity))  then
       begin
          Res.Status(THTTPStatus.BadRequest).Send('Erro: Campos obrigatórios não fornecidos.');
          Exit;
      end;

    NewOutputId := OutputService.Post(ProdId, LocalId, Lot, Quantity);
    Response := TJSONObject.Create;
    case NewOutputId of
      -1:
      begin
        Response.AddPair('error', TJSONBool.Create(True));
        Response.AddPair('message', TJSONString.Create('Erro ao lançar saída'));
        Res.Status(THTTPStatus.InternalServerError).Send<TJSONObject>(Response);
        exit;
      end;
      -2:
      begin
        Response.AddPair('error', TJSONBool.Create(True));
        Response.AddPair('message', TJSONString.Create('Produdo não encontrado'));
        Res.Status(THTTPStatus.NotAcceptable).Send<TJSONObject>(Response);
        exit;
      end;
      -3:
      begin
        Response.AddPair('error', TJSONBool.Create(True));
        Response.AddPair('message', TJSONString.Create('Produdo inativo'));
        Res.Status(THTTPStatus.NotAcceptable).Send<TJSONObject>(Response);
        exit;
      end;
      -4:
      begin
        Response.AddPair('error', TJSONBool.Create(True));
        Response.AddPair('message', TJSONString.Create('Produto que não permite saída'));
        Res.Status(THTTPStatus.NotAcceptable).Send<TJSONObject>(Response);
        exit;
      end;
      -5:
      begin
        Response.AddPair('error', TJSONBool.Create(True));
        Response.AddPair('message', TJSONString.Create('Local não encontrado'));
        Res.Status(THTTPStatus.NotAcceptable).Send<TJSONObject>(Response) ;
        exit;
      end;
      -6:
      begin
        Response.AddPair('error', TJSONBool.Create(True));
        Response.AddPair('message', TJSONString.Create('Local inativo'));
        Res.Status(THTTPStatus.NotAcceptable).Send<TJSONObject>(Response);
        exit;
      end;
      -7:
      begin
        Response.AddPair('error', TJSONBool.Create(True));
        Response.AddPair('message', TJSONString.Create('O produto não aceita estoque negativo. Quantidade de saida maior que o Estoque.'));
        Res.Status(THTTPStatus.NotAcceptable).Send<TJSONObject>(Response);
        exit;
      end;
    end;

    Response.AddPair('id', TJSONNumber.Create(NewOutputId)) ;
    if NewOutputId >= 0 then
      Res.Status(THTTPStatus.Created).Send<TJSONObject>(Response)
    else
      Res.Status(500).Send('Error creating output');
  finally
    OutputService.Free;
//    Response.Free;
  end;
end;

procedure DoPutOutput(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  OutputService: TServiceOutput;
  OutputId, ProdId, LocalId: Integer;
  Lot: String;
  Quantity: Double;
  Body: TJSONObject;
  ResultPut: Integer;
  Response: TJSONObject;
begin
  OutputService := TServiceOutput.Create;
  try
    OutputId := StrToIntDef(Req.Params['id'], 0);
    if OutputId = 0 then
    begin
      Res.Status(400).Send('Invalid ID');
      Exit;
    end;

    Body := Req.Body<TJSONObject>;

    if (not Body.TryGetValue<Integer>('product_id', ProdID)) or
    (not Body.TryGetValue<Integer>('local_id', LocalId)) or
    (not Body.TryGetValue<String>('lot', Lot)) or
    (not Body.TryGetValue<Double>('quantity', Quantity))  then
       begin
          Res.Status(THTTPStatus.BadRequest).Send('Erro: Campos obrigatórios não fornecidos.');
          Exit;
      end;
    ResultPut:= OutputService.Update(OutputId, ProdId, LocalId, Lot, Quantity);

    Response := TJSONObject.Create;
    case ResultPut of
      -1:
      begin
        Response.AddPair('error', TJSONBool.Create(True));
        Response.AddPair('message', TJSONString.Create('Erro ao lançar saída'));
        Res.Status(THTTPStatus.InternalServerError).Send<TJSONObject>(Response);;
        exit;
      end;
      -2:
      begin
        Response.AddPair('error', TJSONBool.Create(True));
        Response.AddPair('message', TJSONString.Create('Produdo não encontrado'));
        Res.Status(THTTPStatus.NotAcceptable).Send<TJSONObject>(Response);
        exit;
      end;
      -3:
      begin
        Response.AddPair('error', TJSONBool.Create(True));
        Response.AddPair('message', TJSONString.Create('Produdo inativo'));
        Res.Status(THTTPStatus.NotAcceptable).Send<TJSONObject>(Response);
        exit;
      end;
      -4:
      begin
        Response.AddPair('error', TJSONBool.Create(True));
        Response.AddPair('message', TJSONString.Create('Produto que não permite saída'));
        Res.Status(THTTPStatus.NotAcceptable).Send<TJSONObject>(Response);
        exit;
      end;
      -5:
      begin
        Response.AddPair('error', TJSONBool.Create(True));
        Response.AddPair('message', TJSONString.Create('Local não encontrado'));
        Res.Status(THTTPStatus.NotAcceptable).Send<TJSONObject>(Response);
        exit;
      end;
      -6:
      begin
        Response.AddPair('error', TJSONBool.Create(True));
        Response.AddPair('message', TJSONString.Create('Local inativo'));
        Res.Status(THTTPStatus.NotAcceptable).Send<TJSONObject>(Response);
        exit;
      end;
    end;

    if ResultPut >= 0 then
      begin
        Response.AddPair('id', TJSONNumber.Create(ResultPut)) ;
        Res.Status(THTTPStatus.Accepted).Send<TJSONObject>(Response);
      end
    else
      Res.Status(500).Send('Error updating output');
  finally
    OutputService.Free;
//    Response.Free;
  end;
end;

procedure DeleteOutput(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  OutputService: TServiceOutput;
  OutputId: Integer;
  Success: Boolean;
begin
  OutputService := TServiceOutput.Create;
  try
    OutputId := StrToIntDef(Req.Params['id'], 0);
    if OutputId = 0 then
    begin
      Res.Status(400).Send('Invalid ID');
      Exit;
    end;

    Success := OutputService.Delete(OutputId);
    if Success then
      Res.Status(200).Send('Output deleted successfully')
    else
      Res.Status(500).Send('Error deleting output');
  finally
    OutputService.Free;
  end;
end;

procedure Registry;
begin
  THorse.Get('/output/:id', DoGetOutput);
  THorse.Get('/output', GetAllOutputs);
  THorse.Post('/output', DoPostOutput);
  THorse.Put('/output/:id', DoPutOutput);
  THorse.Delete('/output/:id', DeleteOutput);
end;

end.

