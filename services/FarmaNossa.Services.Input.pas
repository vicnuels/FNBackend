unit FarmaNossa.Services.Input;

interface

uses
  System.SysUtils, System.Classes, System.JSON, Data.DB, Uni, MemDS,
  FarmaNossa.Providers.Connection, FarmaNossa.Services.Products,
  FarmaNossa.Services.LocalStock, FarmaNossa.Entities.Product, FarmaNossa.Entities.Local;

type
  TServiceInput = class
  private
    FConnectionProvider: TConnectionProvider;
  public
    constructor Create;
    destructor Destroy; override;
    function GetInput(InputId: Integer): TJSONObject;
    function GetAll(Id: Integer = 0; ProdId: Integer = -1;
      LocalId: Integer = -1; Lot: String = ''; FromDate: TDate = 0;
      ToDate: TDate = 0): TJSONArray;
    function Post(ProdId, LocalId: Integer; Lot: String;
      ManufactureDate, ExpiryDate: TDate; Quantity: Double): Integer;
    function Update(Id, ProdId, LocalId: Integer; Lot: String;
      ManufactureDate, ExpiryDate: TDate; Quantity: Double): Integer;
    function Delete(InputId: Integer): Boolean;
  end;

implementation

{ TServiceInput }

constructor TServiceInput.Create;
begin
  FConnectionProvider := TConnectionProvider.Create;
end;

destructor TServiceInput.Destroy;
begin
  FConnectionProvider.Free;
  inherited;
end;

// Get entrada por ID
function TServiceInput.GetInput(InputId: Integer): TJSONObject;
var
  Query: TUniQuery;
  InputJSON: TJSONObject;
begin
  Query := FConnectionProvider.GetQuery;
  InputJSON := TJSONObject.Create;

  try
    Query.Close;
    Query.SQL.Text :=
      'SELECT codigo, codigo_produto, codigo_local, lote, data_fabricacao, data_vencimento, quantidade, data_hora FROM entrada_mercadorias WHERE codigo = :id';
    Query.ParamByName('id').AsInteger := InputId;
    Query.Open;

    if not Query.Eof then
    begin
      InputJSON.AddPair('id', TJSONNumber.Create(Query.FieldByName('codigo')
        .AsInteger));
      InputJSON.AddPair('product_id',
        TJSONNumber.Create(Query.FieldByName('codigo_produto').AsInteger));
      InputJSON.AddPair('local_id',
        TJSONNumber.Create(Query.FieldByName('codigo_local').AsInteger));
      InputJSON.AddPair('lot', Query.FieldByName('lote').AsString);
      InputJSON.AddPair('manufacture_date',
        TJSONString.Create(DateToStr(Query.FieldByName('data_fabricacao')
        .AsDateTime)));
      InputJSON.AddPair('expiry_date',
        TJSONString.Create(DateToStr(Query.FieldByName('data_vencimento')
        .AsDateTime)));
      InputJSON.AddPair('quantity',
        TJSONNumber.Create(Query.FieldByName('quantidade').AsFloat));
      InputJSON.AddPair('created',
        TJSONString.Create(DateTimeToStr(Query.FieldByName('data_hora')
        .AsDateTime)));
    end;

    Result := InputJSON;
  except
    on E: Exception do
    begin
      InputJSON.Free;
      Result := nil;
    end;
  end;
end;

// Get All com filtros
function TServiceInput.GetAll(Id: Integer = 0; ProdId: Integer = -1;
  LocalId: Integer = -1; Lot: String = ''; FromDate: TDate = 0;
  ToDate: TDate = 0): TJSONArray;
var
  Query: TUniQuery;
  InputArray: TJSONArray;
  InputJSON: TJSONObject;
  SQLText: String;
  WhereClauses: TStringList;
begin
  Query := FConnectionProvider.GetQuery;
  InputArray := TJSONArray.Create;
  WhereClauses := TStringList.Create;

  try
    try
      SQLText :=
        'SELECT em.codigo, em.codigo_produto, p.descricao as descricao_produto, em.codigo_local, lo.descricao as descricao_local, em.lote, em.data_fabricacao, em.data_vencimento, em.quantidade, em.data_hora FROM'
        + ' entrada_mercadorias em left join produto p on em.codigo_produto = p.codigo left join local_estoque lo on em.codigo_local = lo.codigo';

      if (Id > 0) then
        WhereClauses.Add('em.codigo::varchar like :id');


      if ProdId > 0 then
        WhereClauses.Add('em.codigo_produto = :prod_id');
      if LocalId > 0 then
        WhereClauses.Add('em.codigo_local = :local_id');
      if Lot <> '' then
        WhereClauses.Add('em.lote LIKE :lot');
      if FromDate <> 0 then
        WhereClauses.Add('em.data_hora::date >= :from_date');
      if ToDate <> 0 then
        WhereClauses.Add('em.data_hora::date <= :to_date');

      if WhereClauses.Count > 0 then
        SQLText := SQLText + ' WHERE ' + String.Join(' AND ',
          WhereClauses.ToStringArray);

      Query.SQL.Text := SQLText;

      if Id > 0 then
        Query.ParamByName('id').AsString := Id.ToString + '%';

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
        InputJSON := TJSONObject.Create;
        InputJSON.AddPair('id', TJSONNumber.Create(Query.FieldByName('codigo')
          .AsInteger));
        InputJSON.AddPair('product_id',
          TJSONNumber.Create(Query.FieldByName('codigo_produto').AsInteger));
        InputJSON.AddPair('product_desc', Query.FieldByName('descricao_produto')
          .AsString);
        InputJSON.AddPair('local_id',
          TJSONNumber.Create(Query.FieldByName('codigo_local').AsInteger));
        InputJSON.AddPair('local_desc', Query.FieldByName('descricao_local')
          .AsString);
        InputJSON.AddPair('lot', Query.FieldByName('lote').AsString);
        InputJSON.AddPair('manufacture_date',
          TJSONString.Create(DateToStr(Query.FieldByName('data_fabricacao')
          .AsDateTime)));
        InputJSON.AddPair('expiry_date',
          TJSONString.Create(DateToStr(Query.FieldByName('data_vencimento')
          .AsDateTime)));
        InputJSON.AddPair('quantity',
          TJSONNumber.Create(Query.FieldByName('quantidade').AsFloat));
        InputJSON.AddPair('created',
          TJSONString.Create(DateTimeToStr(Query.FieldByName('data_hora')
          .AsDateTime)));
        InputArray.AddElement(InputJSON);

        Query.Next;
      end;

      Result := InputArray;
    except
      on E: Exception do
      begin
        InputArray.Free;
        Result := nil;
      end;
    end;
  finally
    WhereClauses.Free;
  end;
end;

// Create a new input and return the ID
function TServiceInput.Post(ProdId, LocalId: Integer; Lot: String;
  ManufactureDate, ExpiryDate: TDate; Quantity: Double): Integer;
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
        'INSERT INTO entrada_mercadorias (codigo_produto, codigo_local, lote, data_fabricacao, data_vencimento, quantidade) VALUES (:prod_id, :local_id, :lot, :manufacture_date, :expiry_date, :quantity) RETURNING codigo';
      Query.ParamByName('prod_id').AsInteger := ProdId;
      Query.ParamByName('local_id').AsInteger := LocalId;
      Query.ParamByName('lot').AsString := Lot;
      Query.ParamByName('manufacture_date').AsDate := ManufactureDate;
      Query.ParamByName('expiry_date').AsDate := ExpiryDate;
      Query.ParamByName('quantity').AsFloat := Quantity;
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
  finally
    SProduct.Free;
    SLocal.Free;
  end;
end;

// Update an existing input
function TServiceInput.Update(Id, ProdId, LocalId: Integer; Lot: String;
  ManufactureDate, ExpiryDate: TDate; Quantity: Double): Integer;
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
        'UPDATE entrada_mercadorias SET codigo_produto = :prod_id, codigo_local = :local_id, lote = :lot, data_fabricacao = :manufacture_date, data_vencimento = :expiry_date, quantidade = :quantity WHERE codigo = :id';
      Query.ParamByName('prod_id').AsInteger := ProdId;
      Query.ParamByName('local_id').AsInteger := LocalId;
      Query.ParamByName('lot').AsString := Lot;
      Query.ParamByName('manufacture_date').AsDate := ManufactureDate;
      Query.ParamByName('expiry_date').AsDate := ExpiryDate;
      Query.ParamByName('quantity').AsFloat := Quantity;
      Query.ParamByName('id').AsInteger := Id;
      Query.ExecSQL;

      if (Query.RowsAffected > 0) then
        Result := Id
      else
        Result := -1
    except
      on E: Exception do
      begin
        Result := -1;
      end;
    end;
  finally
    SProduct.Free;
    SLocal.Free;
  end;
end;

// Delete an input
function TServiceInput.Delete(InputId: Integer): Boolean;
var
  Query: TUniQuery;
begin
  Query := FConnectionProvider.GetQuery;

  try
    Query.Close;
    Query.SQL.Text := 'DELETE FROM entrada_mercadorias WHERE codigo = :id';
    Query.ParamByName('id').AsInteger := InputId;
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
