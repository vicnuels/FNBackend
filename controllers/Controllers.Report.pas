unit Controllers.Report;

interface

uses
  Horse, System.SysUtils, System.Classes, System.JSON,
  FarmaNossa.Services.Report, System.StrUtils,  System.Math,
  FarmaNossa.Providers.Authorization,  FarmaNossa.Services.Stock,
  Horse.Commons;

procedure Registry;

implementation

// 1. Ficha de estoque do produto
procedure DoGetProductStockSheet(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  Id, ProdId, LocalId: Integer;
  Lot: String;
  FromDate, ToDate: TDate;
  SReport: TServiceReport;
  JsonArray: TJSONArray;
begin
  Id := StrToIntDef(Req.Query['id'], 0);
  ProdId := StrToIntDef(Req.Query['prod_id'], 0);
  LocalId := StrToIntDef(Req.Query['local_id'], 0);
  Lot := Req.Query['lot'];
  FromDate := StrToDateDef(Req.Query['from_date'], 0);
  ToDate := StrToDateDef(Req.Query['to_date'], 0);
  SReport := TServiceReport.Create;
  try
    JsonArray := SReport.GetStockProd(Id, ProdId, LocalId, Lot,
      FromDate, ToDate);
    if JsonArray.Count > 0 then
      Res.Send<TJSONAncestor>(JsonArray)
    else
      Res.Status(404).Send('Stock not found');
  finally
    SReport.Free;
  end;
end;

// 2. Relação de produtos para conferência de estoque
procedure DoGetStockChecking(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  Desc: String;
  Id: Integer;
  SProduct: TServiceReport;
  Products: TJSONArray;
begin
  Desc := Req.Query.Field('description').AsString;
  Id := StrToIntDef( Req.Query.Field('prod_id').AsString, 0);

  SProduct := TServiceReport.Create;
  try
    Products := SProduct.GetStockChecking(id, desc);
    Res.Send<TJSONArray>(Products);
  finally
    SProduct.Free;
  end;
end;

// 3. Relação de produtos para conferência de estoque consolidado por lote
procedure DoGetStockLotChecking(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  StockService: TServiceReport;
  ProdId, LocalId: Integer;
  GreaterThan, LessThan: Double;
  SZeroStock, Status, Desc: String;
  ZeroStock: Boolean;
  InputJSON: TJSONArray;
begin
  StockService := TServiceReport.Create;
  try
    ProdId := StrToIntDef(Req.Query['prod_id'], 0);
    Desc := Req.Query['description'];

    InputJSON := StockService.GetStockLotChecking(ProdId, Desc);
    if InputJSON.Count > 0 then
      Res.Send<TJSONArray>(InputJSON)
    else
      Res.Status(404).Send('Stock not found');
  finally
    StockService.Free;
  end;
end;

// 4. Produtos em estoque - Agrupado por Local de estoque
procedure DoGetStockLotLocalChecking(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  StockService: TServiceReport;
  ProdId, LocalId: Integer;
  InputJSON: TJSONArray;
begin
  StockService := TServiceReport.Create;
  try
    ProdId := StrToIntDef(Req.Query['prod_id'], 0);
    LocalId:= StrToIntDef(Req.Query['local_id'], 0);
//    Desc := Req.Query['description'];

    InputJSON := StockService.GetAllByLotAndLocal(ProdId, Localid);
    if InputJSON.Count > 0 then
      Res.Send<TJSONArray>(InputJSON)
    else
      Res.Status(404).Send('Stock not found');
  finally
    StockService.Free;
  end;
end;

procedure Registry;
begin
  THorse.AddCallback(Authorization()).Get('report/r01', DoGetProductStockSheet);
  THorse.AddCallback(Authorization()).Get('report/r02', DoGetStockChecking);
  THorse.AddCallback(Authorization()).Get('report/r03', DoGetStockLotChecking);
  THorse.AddCallback(Authorization()).Get('report/r04', DoGetStockLotLocalChecking);
end;

end.
