unit FarmaNossa.Services.Output;

interface

uses
  System.SysUtils, System.Classes, System.JSON, Data.DB, Uni, MemDS,
  FarmaNossa.Providers.Connection, FarmaNossa.Services.Products, FarmaNossa.Entities.Local,
  FarmaNossa.Services.LocalStock, FarmaNossa.Entities.Product;

type
  TServiceOutput = class
  private
    FConnectionProvider: TConnectionProvider;
  public
    constructor Create;
    destructor Destroy; override;
    function GetOutput(OutputId: Integer): TJSONObject;
    function GetAll(ProdId: Integer = -1; LocalId: Integer = -1;
      Lot: String = ''; FromDate: TDate = 0; ToDate: TDate = 0): TJSONArray;
    function Post(ProdId, LocalId: Integer; Lot: String;
      Quantity: Double): Integer;
    function Update(Id, ProdId, LocalId: Integer; Lot: String;
      Quantity: Double): Integer;
    function Delete(OutputId: Integer): Boolean;
  end;

implementation

// -- tabela saida
//
// DROP TABLE IF EXISTS saida_mercadorias;
//
// CREATE TABLE saida_mercadorias
// (
// codigo serial NOT NULL PRIMARY KEY,
// codigo_produto integer NOT NULL,
// codigo_local integer NOT NULL,
// lote character varying(50) NOT NULL,
// quantidade numeric NOT NULL,
// data_hora timestamp without time zone NOT NULL DEFAULT now(),
// CONSTRAINT saida_mercadorias_codigo_local_fkey FOREIGN KEY (codigo_local)
// REFERENCES local_estoque (codigo),
// CONSTRAINT saida_mercadorias_codigo_produto_fkey FOREIGN KEY (codigo_produto)
// REFERENCES produto (codigo)
// );

{ TServiceOutput }

constructor TServiceOutput.Create;
begin
  FConnectionProvider := TConnectionProvider.Create;
end;

destructor TServiceOutput.Destroy;
begin
  FConnectionProvider.Free;
  inherited;
end;

// Get saída por ID
function TServiceOutput.GetOutput(OutputId: Integer): TJSONObject;
var
  Query: TUniQuery;
  OutputJSON: TJSONObject;
begin
  Query := FConnectionProvider.GetQuery;
  OutputJSON := TJSONObject.Create;

  try
    Query.Close;
    Query.SQL.Text :=
      'SELECT codigo, codigo_produto, codigo_local, lote, quantidade, data_hora FROM saida_mercadorias WHERE codigo = :id';
    Query.ParamByName('id').AsInteger := OutputId;
    Query.Open;

    if not Query.Eof then
    begin
      OutputJSON.AddPair('id', TJSONNumber.Create(Query.FieldByName('codigo')
        .AsInteger));
      OutputJSON.AddPair('product_id',
        TJSONNumber.Create(Query.FieldByName('codigo_produto').AsInteger));
      OutputJSON.AddPair('local_id',
        TJSONNumber.Create(Query.FieldByName('codigo_local').AsInteger));
      OutputJSON.AddPair('lot', Query.FieldByName('lote').AsString);
      OutputJSON.AddPair('quantity',
        TJSONNumber.Create(Query.FieldByName('quantidade').AsFloat));
      OutputJSON.AddPair('created',
        TJSONString.Create(DateTimeToStr(Query.FieldByName('data_hora')
        .AsDateTime)));
    end;

    Result := OutputJSON;
  except
    on E: Exception do
    begin
      OutputJSON.Free;
      Result := nil;
    end;
  end;
end;

// Get All com filtros
function TServiceOutput.GetAll(ProdId: Integer = -1; LocalId: Integer = -1;
  Lot: String = ''; FromDate: TDate = 0; ToDate: TDate = 0): TJSONArray;
var
  Query: TUniQuery;
  OutputArray: TJSONArray;
  OutputJSON: TJSONObject;
  SQLText: String;
  WhereClauses: TStringList;
begin
  Query := FConnectionProvider.GetQuery;
  OutputArray := TJSONArray.Create;
  WhereClauses := TStringList.Create;

  try
    try
      SQLText :=
        'SELECT sm.codigo, sm.codigo_produto, p.descricao as descricao_produto, sm.codigo_local, lo.descricao as descricao_local, sm.lote, sm.quantidade, data_hora FROM saida_mercadorias sm '
        + 'left join produto p on sm.codigo_produto = p.codigo left join local_estoque lo on sm.codigo_local = lo.codigo';

      if ProdId > 0 then
        WhereClauses.Add('codigo_produto = :prod_id');
      if LocalId > 0 then
        WhereClauses.Add('codigo_local = :local_id');
      if Lot <> '' then
        WhereClauses.Add('lote LIKE :lot');
      if FromDate <> 0 then
        WhereClauses.Add('data_hora::date >= :from_date');
      if ToDate <> 0 then
        WhereClauses.Add('data_hora::date <= :to_date');

      if WhereClauses.Count > 0 then
        SQLText := SQLText + ' WHERE ' + String.Join(' AND ',
          WhereClauses.ToStringArray);

      Query.SQL.Text := SQLText;

      if ProdId > 0 then
        Query.ParamByName('prod_id').AsInteger := ProdId;
      if LocalId > 0 then
        Query.ParamByName('local_id').AsInteger := LocalId;
      if Lot <> '' then
        Query.ParamByName('lot').AsString := '%' + Lot + '%';
      if FromDate <> 0 then
        Query.ParamByName('from_date').AsDate := FromDate;
      if ToDate <> 0 then
        Query.ParamByName('to_date').AsDate := ToDate;

      Query.Open;

      while not Query.Eof do
      begin
        OutputJSON := TJSONObject.Create;
        OutputJSON.AddPair('id', TJSONNumber.Create(Query.FieldByName('codigo')
          .AsInteger));
        OutputJSON.AddPair('product_id',
          TJSONNumber.Create(Query.FieldByName('codigo_produto').AsInteger));
        OutputJSON.AddPair('product_desc',
          Query.FieldByName('descricao_produto').AsString);
        OutputJSON.AddPair('local_id',
          TJSONNumber.Create(Query.FieldByName('codigo_local').AsInteger));
        OutputJSON.AddPair('local_desc', Query.FieldByName('descricao_local')
          .AsString);
        OutputJSON.AddPair('lot', Query.FieldByName('lote').AsString);
        OutputJSON.AddPair('quantity',
          TJSONNumber.Create(Query.FieldByName('quantidade').AsFloat));
        OutputJSON.AddPair('created',
          TJSONString.Create(DateTimeToStr(Query.FieldByName('data_hora')
          .AsDateTime)));
        OutputArray.AddElement(OutputJSON);

        Query.Next;
      end;

      Result := OutputArray;
    except
      on E: Exception do
      begin
        OutputArray.Free;
        Result := nil;
      end;
    end;
  finally
    WhereClauses.Free;
  end;
end;

// Create a new output and return the ID
function TServiceOutput.Post(ProdId, LocalId: Integer; Lot: String;
  Quantity: Double): Integer;
var
  Query: TUniQuery;
  SProduct: TServiceProduct;
  SLocal: TServiceLocal;
  Product: TProduct;
  Local: TLocal;
begin
  Query := FConnectionProvider.GetQuery;
  SProduct := TServiceProduct.Create;
  SLocal := TServiceLocal.Create;
  try
    Product := SProduct.GetProductStock(ProdId);

    if Product.Code <= 0 then
    begin
      Result := -2; // código para produto não encontrado
      Exit;
    end;

    if not Product.Status then
    begin
      Result := -3; // código para produto inativo
      Exit;
    end;

    if not Product.OutputStatus then
    begin
      Result := -4; // código para produto que não permite saída
      Exit;
    end;

    if (not Product.NegativeStock) and (Product.Stock - Quantity < 0) then
    begin
      Result := -7; // codigo para produto que não aceita estoque negativo
      Exit;
    end;

    Local := SLocal.GetLocalEntity(LocalId);

    if not Assigned( Local) then
    begin
      Result := -5; // código para local não encontrado
      Exit;
    end;

    if not Local.Status then
    begin
      Result := -6; // código para local inativo
      Exit;
    end;


    try
      Query.Close;
      Query.SQL.Text :=
        'INSERT INTO saida_mercadorias (codigo_produto, codigo_local, lote, quantidade) VALUES (:prod_id, :local_id, :lot, :quantity) RETURNING codigo';
      Query.ParamByName('prod_id').AsInteger := ProdId;
      Query.ParamByName('local_id').AsInteger := LocalId;
      Query.ParamByName('lot').AsString := Lot;
      Query.ParamByName('quantity').AsFloat := Quantity;
      Query.Open;

      Result := Query.FieldByName('codigo').AsInteger;
    except
      on E: Exception do
        Result := -1; // código para erro na operação
    end;
  finally
    SProduct.Free;
    SLocal.Free;
  end;
end;

// Update
function TServiceOutput.Update(Id, ProdId, LocalId: Integer; Lot: String;
  Quantity: Double): Integer;
var
  Query: TUniQuery;
  SProduct: TServiceProduct;
  SLocal: TServiceLocal;
  Product: TProduct;
  Local: TLocal;
  StatusValue, SOutputValue: TJSONValue;
  Status, SOutput: Boolean;
begin
  Query := FConnectionProvider.GetQuery;
  SProduct := TServiceProduct.Create;
  SLocal := TServiceLocal.Create;
  try
    Product := SProduct.GetProductStock(ProdId);

    if Product.Code <= 0 then
    begin
      Result := -2; // código para produto não encontrado
      Exit;
    end;

    if not Product.Status then
    begin
      Result := -3; // código para produto inativo
      Exit;
    end;

    if not Product.OutputStatus then
    begin
      Result := -4; // código para produto que não permite saída
      Exit;
    end;

    if (not Product.NegativeStock) and (Product.Stock - Quantity < 0) then
    begin
      Result := -7; // codigo para produto que não aceita estoque negativo
      Exit;
    end;

     Local := SLocal.GetLocalEntity(LocalId);

    if not Assigned( Local) then
    begin
      Result := -5; // código para local não encontrado
      Exit;
    end;

    if not Local.Status then
    begin
      Result := -6; // código para local inativo
      Exit;
    end;


    try
      Query.Close;
      Query.SQL.Text :=
        'UPDATE saida_mercadorias SET codigo_produto = :prod_id, codigo_local = :local_id, lote = :lot, quantidade = :quantity WHERE codigo = :id RETURNING codigo';
      Query.ParamByName('prod_id').AsInteger := ProdId;
      Query.ParamByName('local_id').AsInteger := LocalId;
      Query.ParamByName('lot').AsString := Lot;
      Query.ParamByName('quantity').AsFloat := Quantity;
      Query.ParamByName('id').AsInteger := Id;
      Query.Open;

      Result := Query.FieldByName('codigo').AsInteger;
    except
      on E: Exception do
        Result := -1; // código para erro na operação
    end;
  finally
    SProduct.Free;
    SLocal.Free;
  end;
end;

// Delete
function TServiceOutput.Delete(OutputId: Integer): Boolean;
var
  Query: TUniQuery;
begin
  Query := FConnectionProvider.GetQuery;
  try
    try
      Query.Close;
      Query.SQL.Text := 'DELETE FROM saida_mercadorias WHERE codigo = :id';
      Query.ParamByName('id').AsInteger := OutputId;
      Query.ExecSQL;

      Result := Query.RowsAffected > 0;
    except
      on E: Exception do
        Result := False;
    end;
  finally
    Query.Free;
  end;
end;

end.
