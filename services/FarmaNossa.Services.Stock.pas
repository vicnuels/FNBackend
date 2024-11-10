unit FarmaNossa.Services.Stock;

interface

uses
  System.SysUtils, System.Classes, System.JSON, Data.DB, Uni, MemDS, System.StrUtils,
  FarmaNossa.Providers.Connection, FarmaNossa.Services.Products, System.Math,
  FarmaNossa.Services.LocalStock, FarmaNossa.Entities.Product;

type
  TServiceStock = class
  private
    FConnectionProvider: TConnectionProvider;
  public
    constructor Create;
    destructor Destroy; override;
    function GetAllByLotAndLocal(ProdId: Integer = -1; idOutput: integer = 0): TJSONArray;
    function GetAll(ProdId: Integer = 0; StatusProd: String = '';  ProdDesc: String = '';
      LocalId: Integer = 0;
      ZeroStock: Boolean = true; GreaterThan: Double = NaN;
      LessThan: Double = NaN): TJSONArray;
  end;

implementation

constructor TServiceStock.Create;
begin
  FConnectionProvider := TConnectionProvider.Create;
end;

destructor TServiceStock.Destroy;
begin
  FConnectionProvider.Free;
  inherited;
end;

// Get All com filtros
function TServiceStock.GetAll(ProdId: Integer = 0; StatusProd: String = '';
      ProdDesc: String = ''; LocalId: Integer = 0;
      ZeroStock: Boolean = true; GreaterThan: Double = NaN;
      LessThan: Double = NaN): TJSONArray;
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
      SQLText := 'SELECT ' +
         '    p.codigo AS codigo_produto, ' +
         '    p.descricao AS descricao_produto, ' +
         '    p.estoque_negativo, ' +
         '    p.status, ' +
         '    p.status_entrada, ' +
         '    p.status_saida, ' +
         '    COALESCE(em.total_entrada, 0) - COALESCE(sm.total_saida, 0) AS estoque ' +
         'FROM ' +
         '    produto p ' +
         'LEFT JOIN ( ' +
         '    SELECT ' +
         '        codigo_produto, ' +
         '        SUM(quantidade) AS total_entrada ' +
         '    FROM ' +
         '        entrada_mercadorias ' +
         IfThen(LocalId > 0, 'WHERE codigo_local = :localid', ''  ) +
         '    GROUP BY ' +
         '        codigo_produto ' +
         ') em ON p.codigo = em.codigo_produto ' +
         'LEFT JOIN ( ' +
         '    SELECT ' +
         '        codigo_produto, ' +
         '        SUM(quantidade) AS total_saida ' +
         '    FROM ' +
         '        saida_mercadorias ' +
         IfThen(LocalId > 0, 'WHERE codigo_local = :localid', ''  ) +
         '    GROUP BY ' +
         '        codigo_produto ' +
         ') sm ON p.codigo = sm.codigo_produto ';

      if ProdId > 0 then
        WhereClauses.Add('p.codigo = :prod_id');

      if ProdDesc <> '' then
        WhereClauses.Add('p.descricao like :description');

      if StatusProd.Equals('false') or StatusProd.Equals('true') then
          WhereClauses.Add('status = :status');

      if not ZeroStock then
        WhereClauses.Add('(COALESCE(em.total_entrada, 0) - COALESCE(sm.total_saida, 0)) <> 0');

      if not IsNan(GreaterThan) then
        WhereClauses.Add('(COALESCE(em.total_entrada, 0) - COALESCE(sm.total_saida, 0)) >= ' +
        FloatToStr(GreaterThan));

      if not IsNan(LessThan) then
        WhereClauses.Add('(COALESCE(em.total_entrada, 0) - COALESCE(sm.total_saida, 0)) <= ' +
        FloatToStr(LessThan));

      if WhereClauses.Count > 0 then
        SQLText := SQLText + ' WHERE ' + String.Join(' AND ',
          WhereClauses.ToStringArray);

      Query.SQL.Text := SQLText + ' ORDER BY estoque desc';

      if ProdId > 0 then
        Query.ParamByName('prod_id').AsInteger := ProdId;

      if ProdDesc <> '' then
        Query.ParamByName('description').AsString := ProdDesc + '%';

      if LocalId > 0 then
        Query.ParamByName('localid').AsInteger := LocalId;

      if StatusProd.Equals('false') or StatusProd.Equals('true')  then
          Query.ParamByName('status').AsBoolean := StrToBool( StatusProd);

      Query.Open;

      while not Query.Eof do
      begin
        OutputJSON := TJSONObject.Create;
        OutputJSON.AddPair('product_id',
          TJSONNumber.Create(Query.FieldByName('codigo_produto').AsInteger));

        OutputJSON.AddPair('product_desc',
          Query.FieldByName('descricao_produto').AsString);

        OutputJSON.AddPair('n_stock',
          TJSONBool.Create(Query.FieldByName('estoque_negativo').AsBoolean));

        OutputJSON.AddPair('quantity',
          TJSONNumber.Create(Query.FieldByName('estoque').AsFloat));

        OutputJSON.AddPair('status',
          TJSONBool.Create(Query.FieldByName('status').AsBoolean));

        OutputJSON.AddPair('s_input',
          TJSONBool.Create(Query.FieldByName('status_entrada').AsBoolean));

        OutputJSON .AddPair('s_output',
          TJSONBool.Create(Query.FieldByName('status_saida').AsBoolean));

        OutputArray.AddElement(OutputJSON);

        Query.Next;
      end;

      Result := OutputArray;
    except
      on E: Exception do
      begin
        Writeln(e.Message);
        OutputArray.Free;
        Result := nil;
      end;
    end;
  finally
    WhereClauses.Free;
  end;
end;


function TServiceStock.GetAllByLotAndLocal(ProdId: Integer = -1; idOutput: integer = 0): TJSONArray;
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
      SQLText := 'SELECT ' +
         '  p.codigo AS codigo_produto, ' +
         '  p.descricao AS descricao_produto, ' +
         '  p.estoque_negativo, ' +
         '  em.lote, ' +
         '  em.data_fabricacao, ' +
         '  em.data_vencimento, ' +
         '  em.codigo_local, ' +
         '  le.descricao AS descricao_local, ' +
         '  COALESCE(em.total_entrada, 0) - COALESCE(sm.total_saida, 0) AS estoque ' +
         'FROM ' +
         '  produto p ' +
         'LEFT JOIN ( ' +
         '  SELECT ' +
         '    codigo_produto, ' +
         '    lote, ' +
         '    codigo_local, ' +
         '    data_fabricacao, ' +
         '    data_vencimento, ' +
         '    SUM(quantidade) AS total_entrada ' +
         '  FROM ' +
         '    entrada_mercadorias ' +
         '  GROUP BY ' +
         '    codigo_produto, lote, codigo_local, data_fabricacao, data_vencimento ' +
         ') em ' +
         'ON ' +
         '  p.codigo = em.codigo_produto ' +
         'LEFT JOIN ( ' +
         '  SELECT ' +
         '    codigo_produto, ' +
         '    lote, ' +
         '    codigo_local, ' +
         '    SUM(quantidade) AS total_saida ' +
         '  FROM ' +
         '    saida_mercadorias ' +
         IfThen(idOutput > 0, 'Where codigo <> :idoutput', ''  ) +
         '  GROUP BY ' +
         '    codigo_produto, lote, codigo_local ' +
         ') sm ' +
         'ON ' +
         '  p.codigo = sm.codigo_produto ' +
         '  AND em.lote = sm.lote ' +
         '  AND em.codigo_local = sm.codigo_local ' +
         'LEFT JOIN ' +
         '  local_estoque le ' +
         'ON ' +
         '  em.codigo_local = le.codigo ' +
         'WHERE ' +
         '  ((COALESCE(em.total_entrada, 0) - COALESCE(sm.total_saida, 0) <> 0) ' +
         '  OR (p.estoque_negativo = true and (COALESCE(em.total_entrada, 0) > 0) )) ';

      if ProdId > 0 then
        WhereClauses.Add('p.codigo = :prod_id');

      if WhereClauses.Count > 0 then
        SQLText := SQLText + ' AND ' + String.Join(' AND ',
          WhereClauses.ToStringArray);

      Query.SQL.Text := SQLText + ' ORDER BY em.data_vencimento asc';

      if ProdId > 0 then
        Query.ParamByName('prod_id').AsInteger := ProdId;

      if idOutput > 0 then
        Query.ParamByName('idoutput').AsInteger := idOutput;

      Query.Open;

      while not Query.Eof do
      begin
        OutputJSON := TJSONObject.Create;
        OutputJSON.AddPair('product_id',
          TJSONNumber.Create(Query.FieldByName('codigo_produto').AsInteger));
        OutputJSON.AddPair('product_desc',
          Query.FieldByName('descricao_produto').AsString);
        OutputJSON.AddPair('n_stock',
          TJSONBool.Create(Query.FieldByName('estoque_negativo').AsBoolean));
        OutputJSON.AddPair('local_id',
          TJSONNumber.Create(Query.FieldByName('codigo_local').AsInteger));
        OutputJSON.AddPair('local_desc', Query.FieldByName('descricao_local')
          .AsString);
        OutputJSON.AddPair('lot', Query.FieldByName('lote').AsString);
        OutputJSON.AddPair('quantity',
          TJSONNumber.Create(Query.FieldByName('estoque').AsFloat));
        OutputJSON.AddPair('manufacture_date',
          TJSONString.Create(DateToStr(Query.FieldByName('data_fabricacao')
          .AsDateTime)));
        OutputJSON.AddPair('expiry_date',
          TJSONString.Create(DateToStr(Query.FieldByName('data_vencimento')
          .AsDateTime)));
        OutputArray.AddElement(OutputJSON);

        Query.Next;
      end;

      Result := OutputArray;
    except
      on E: Exception do
      begin
        Writeln(e.Message);
        OutputArray.Free;
        Result := nil;
      end;
    end;
  finally
    WhereClauses.Free;
  end;
end;


end.
