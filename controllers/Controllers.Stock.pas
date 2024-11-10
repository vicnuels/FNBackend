unit Controllers.Stock;

interface

uses
  Horse, System.SysUtils, System.Classes, System.JSON,
  FarmaNossa.Services.Stock, System.StrUtils,
  FarmaNossa.Providers.Authorization, System.Math,
  Horse.Commons, FarmaNossa.Services.Lot;

procedure Registry;

implementation

procedure DoGetStock(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  StockService: TServiceStock;
  ProdId, LocalId: Integer;
  GreaterThan, LessThan: Double;
  SZeroStock, Status, Desc: String;
  ZeroStock: Boolean;
  InputJSON: TJSONArray;
begin
  StockService := TServiceStock.Create;
  try
    ProdId := StrToIntDef(Req.Query['product'], 0);
    LocalId:= StrToIntDef(Req.Query['local'], 0);
    SZeroStock := Req.Query['zerostock'];
    Desc := Req.Query['description'];
    if SZeroStock.Equals('false') or SZeroStock.Equals('true')  then
      ZeroStock := StrToBool(SZeroStock)
    else
      ZeroStock := true;

    Status := Req.Query['status'];
    GreaterThan := StrToFloatDef(Req.Query['greaterthan'], NaN);
    LessThan := StrToFloatDef(Req.Query['lessthan'], NaN);

    InputJSON := StockService.GetAll(ProdId, Status, Desc, LocalId, ZeroStock, GreaterThan, LessThan);
    if InputJSON.Count > 0 then
      Res.Send<TJSONArray>(InputJSON)
    else
      Res.Status(404).Send('Stock not found');
  finally
    StockService.Free;
  end;
end;

procedure DoGetByIdProdStock(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  StockService: TServiceStock;
  ProdId, OutputId: Integer;
  InputJSON: TJSONArray;
begin
  StockService := TServiceStock.Create;
  try
    ProdId := StrToIntDef(Req.Params['id'], 0);
    OutputId := StrToIntDef(Req.Query['output'], 0);
    if ProdId = 0 then
    begin
      Res.Status(400).Send('Invalid ID');
      Exit;
    end;

    InputJSON := StockService.GetAllByLotAndLocal(ProdId, OutputId);
    if InputJSON.Count > 0 then
      Res.Send<TJSONArray>(InputJSON)
    else
      Res.Status(404).Send('Stock not found');
  finally
    StockService.Free;
//    InputJSON.FreeInstance;
  end;
end;


procedure Registry;
begin
  THorse
    .AddCallback(Authorization())
    .Get('stock', DoGetStock)
    .AddCallback(Authorization())
    .Get('stock/product/:id', DoGetByIdProdStock)
end;

end.