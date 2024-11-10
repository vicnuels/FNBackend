unit FarmaNossa.Services.Report;

interface

uses
  System.SysUtils, System.Classes, System.JSON, Data.DB, Uni, MemDS, System.StrUtils,
  FarmaNossa.Providers.Connection, FarmaNossa.Services.Products, System.Math,
  FarmaNossa.Services.LocalStock, FarmaNossa.Entities.Product;

type
  TServiceReport = class
  private
    FConnectionProvider: TConnectionProvider;
  public
    constructor Create;
    destructor Destroy; override;
    function GetStockProd(Id: Integer = 0; ProdId: Integer = -1;
      LocalId: Integer = -1; Lot: String = ''; FromDate: TDate = 0;
      ToDate: TDate = 0): TJSONArray;
    // 2. Relação de produtos para conferência de estoque
    function GetStockChecking(ProdId: Integer = 0; Desc: String = ''): TJSONArray;
    function GetStockLotChecking(ProdId: Integer = 0; Desc: String = '';  LocalId: Integer = 0 ): TJSONArray;
    function GetAllByLotAndLocal(ProdId: Integer = 0; LocalId: Integer = 0 ): TJSONArray;
  end;

implementation

constructor TServiceReport.Create;
begin
  FConnectionProvider := TConnectionProvider.Create;
end;

destructor TServiceReport.Destroy;
begin
  FConnectionProvider.Free;
  inherited;
end;

// 1. Ficha de estoque do produto
function TServiceReport.GetStockProd(Id: Integer = 0; ProdId: Integer = -1;
      LocalId: Integer = -1; Lot: String = ''; FromDate: TDate = 0;
      ToDate: TDate = 0): TJSONArray;
var
  Query: TUniQuery;
  JSONArray: TJSONArray;
  JSONObject: TJSONObject;
  SQLText, InputWhere: String;
  WhereClausesInput, WhereClausesOutput: TStringList;
begin
  Query := FConnectionProvider.GetQuery;
  WhereClausesInput := TStringList.Create;
  WhereClausesOutput := TStringList.Create;
  try
    try
      if (Id > 0) then
        begin
         WhereClausesInput.Add('em.codigo::varchar like :id');
         WhereClausesOutput.Add('sm.codigo::varchar like :id');
        end;

      if ProdId > 0 then begin
           WhereClausesInput.Add('em.codigo_produto = :prod_id');
           WhereClausesOutput.Add('sm.codigo_produto = :prod_id');
      end;

      if LocalId > 0 then  begin
        WhereClausesInput.Add('em.codigo_local = :local_id');
        WhereClausesOutput.Add('sm.codigo_local = :local_id');
      end;

      if Lot <> '' then
      begin
        WhereClausesInput.Add('em.lote LIKE :lot');
        WhereClausesOutput.Add('sm.lote LIKE :lot');
      end;

      if FromDate <> 0 then
      begin
        WhereClausesInput.Add('em.emissao >= :from_date');
        WhereClausesOutput.Add('sm.emissao >= :from_date');
      end;

      if ToDate <> 0 then
      begin
        WhereClausesInput.Add('em.emissao::date <= :to_date');
        WhereClausesOutput.Add('sm.emissao::date <= :to_date');
      end;

      if WhereClausesInput.Count > 0 then
        InputWhere := ' WHERE ' + String.Join(' AND ',
          WhereClausesInput.ToStringArray);

      SQLText := 'SELECT ' +
      '    ''E'' AS tipo, ' +
      '    em.codigo, ' +
      '    em.codigo_local, ' +
      '    lo.descricao AS descricao_local, ' +
      '    em.codigo_produto, ' +
      '    p.descricao AS descricao_produto, ' +
      '    em.lote, ' +
      '    em.data_fabricacao, ' +
      '    em.data_vencimento, ' +
      '    em.data_hora::date AS emissao, ' +
      '    em.data_hora::time AS hora, ' +
      '    em.quantidade ' +
      'FROM ' +
      '    entrada_mercadorias em ' +
      'LEFT JOIN ' +
      '    produto p ON em.codigo_produto = p.codigo ' +
      'LEFT JOIN ' +
      '    local_estoque lo ON em.codigo_local = lo.codigo ' +
      InputWhere +
      ' UNION ALL ' +
      'SELECT ' +
      '    ''S'' AS tipo, ' +
      '    sm.codigo, ' +
      '    sm.codigo_local, ' +
      '    lo.descricao AS descricao_local, ' +
      '    sm.codigo_produto, ' +
      '    p.descricao AS descricao_produto, ' +
      '    sm.lote, ' +
      '    e.data_fabricacao, ' +
      '    e.data_vencimento, ' +
      '    sm.data_hora::date AS emissao, ' +
      '    sm.data_hora::time AS hora, ' +
      '    sm.quantidade ' +
      'FROM ' +
      '    saida_mercadorias sm ' +
      'JOIN ' +
      '    entrada_mercadorias e ON sm.codigo_produto = e.codigo_produto AND sm.lote = e.lote AND sm.codigo_local = e.codigo_local ' +
      'LEFT JOIN ' +
      '    produto p ON sm.codigo_produto = p.codigo ' +
      'LEFT JOIN ' +
      '    local_estoque lo ON sm.codigo_local = lo.codigo ' ;

      if WhereClausesOutput.Count > 0 then
        SQLText := SQLText + ' WHERE ' + String.Join(' AND ',
          WhereClausesOutput.ToStringArray);

      Query.SQL.Text := SQLText +
      ' ORDER BY ' +
      '    emissao DESC, hora DESC ';

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

      JSONArray := TJSONArray.Create;
      while not Query.Eof do
      begin
        JSONObject := TJSONObject.Create;
        JSONObject.AddPair('type', Query.FieldByName('tipo').AsString);
        JSONObject.AddPair('id', TJSONNumber.Create(Query.FieldByName('codigo').AsInteger));
        JSONObject.AddPair('local_id', TJSONNumber.Create(Query.FieldByName('codigo_local').AsInteger));
        JSONObject.AddPair('local_desc', Query.FieldByName('descricao_local').AsString);
        JSONObject.AddPair('product_id', TJSONNumber.Create(Query.FieldByName('codigo_produto').AsInteger));
        JSONObject.AddPair('product_desc', Query.FieldByName('descricao_produto').AsString);
        JSONObject.AddPair('lot', Query.FieldByName('lote').AsString);
        JSONObject.AddPair('manufacture_date', DateToStr(Query.FieldByName('data_fabricacao').AsDateTime));
        JSONObject.AddPair('expiry_date', DateToStr(Query.FieldByName('data_vencimento').AsDateTime));
        JSONObject.AddPair('created_at', DateToStr(Query.FieldByName('emissao').AsDateTime));
        JSONObject.AddPair('created_time', Query.FieldByName('hora').AsString);
        JSONObject.AddPair('quantity', TJSONNumber.Create(Query.FieldByName('quantidade').AsFloat));
        JSONArray.AddElement(JSONObject);

        Query.Next;
      end;

      Result := JSONArray;
    except
      on E: Exception do
      begin
        Writeln(e.Message);
        Result := nil;
      end;
    end;
  finally
    WhereClausesInput.Free;
    WhereClausesOutput.Free;
  end;
end;

// 2. Relação de produtos para conferência de estoque
function TServiceReport.GetStockChecking(ProdId: Integer = 0;  Desc: String = ''): TJSONArray;
var
  Query: TUniQuery;
  JsonArray: TJSONArray;
  JSON: TJSONObject;
  SQLText: String;
  WhereClauses: TStringList;
begin
  Query := FConnectionProvider.GetQuery;
  JsonArray := TJSONArray.Create;
  WhereClauses := TStringList.Create;

  try
    try
      SQLText := 'SELECT ' +
         '  p.codigo AS codigo_produto, ' +
         '  p.descricao AS descricao_produto, ' +
         '  COALESCE(em.total_entrada, 0) - COALESCE(sm.total_saida, 0) AS estoque ' +
         'FROM ' +
         '  produto p ' +
         'LEFT JOIN ( ' +
         '  SELECT ' +
         '    codigo_produto, ' +
         '    SUM(quantidade) AS total_entrada ' +
         '  FROM ' +
         '    entrada_mercadorias ' +
         '  GROUP BY ' +
         '    codigo_produto' +
         ') em ' +
         'ON ' +
         '  p.codigo = em.codigo_produto ' +
         'LEFT JOIN ( ' +
         '  SELECT ' +
         '    codigo_produto, ' +
         '    SUM(quantidade) AS total_saida ' +
         '  FROM ' +
         '    saida_mercadorias ' +
         '  GROUP BY ' +
         '    codigo_produto' +
         ') sm ' +
         'ON ' +
         '  p.codigo = sm.codigo_produto ';

      if ProdId > 0 then
        WhereClauses.Add('p.codigo = :prod_id');

      if Desc <> '' then
          WhereClauses.Add('p.descricao LIKE :desc');

      if WhereClauses.Count > 0 then
        SQLText := SQLText + ' WHERE ' + String.Join(' AND ',
          WhereClauses.ToStringArray);

      Query.SQL.Text := SQLText + ' ORDER BY p.codigo asc';

      if ProdId > 0 then
        Query.ParamByName('prod_id').AsInteger := ProdId;

      if Desc <> '' then
          Query.ParamByName('desc').AsString := '%' + Desc + '%';

      Query.Open;

      while not Query.Eof do
      begin
        JSON := TJSONObject.Create;
        JSON.AddPair('product_id',
          TJSONNumber.Create(Query.FieldByName('codigo_produto').AsInteger));
        JSON.AddPair('product_desc',
          Query.FieldByName('descricao_produto').AsString);
        JSON.AddPair('quantity',
          TJSONNumber.Create(Query.FieldByName('estoque').AsFloat));
        JsonArray.AddElement(JSON);
        Query.Next;
      end;

      Result := JsonArray;
    except
      on E: Exception do
      begin
        Writeln(e.Message);
        JsonArray.Free;
        Result := nil;
      end;
    end;
  finally
    WhereClauses.Free;
  end;
end;

// 3. Relação de produtos para conferência de estoque consolidado por lote
function TServiceReport.GetStockLotChecking(ProdId: Integer = 0; Desc: String = '';  LocalId: Integer = 0 ): TJSONArray;
var
  Query: TUniQuery;
  JsonArray: TJSONArray;
  JSON: TJSONObject;
  SQLText: String;
  WhereClauses: TStringList;
begin
  Query := FConnectionProvider.GetQuery;
  JsonArray := TJSONArray.Create;
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
         '  COALESCE(em.total_entrada, 0) - COALESCE(sm.total_saida, 0) AS estoque ' +
         'FROM ' +
         '  produto p ' +
         'LEFT JOIN ( ' +
         '  SELECT ' +
         '    codigo_produto, ' +
         '    lote, ' +
         '    data_fabricacao, ' +
         '    data_vencimento, ' +
         '    SUM(quantidade) AS total_entrada ' +
         '  FROM ' +
         '    entrada_mercadorias ' +
         IfThen(LocalId > 0, 'Where codigo_local <> :localid', ''  ) +
         '  GROUP BY ' +
         '    codigo_produto, lote, data_fabricacao, data_vencimento ' +
         ') em ' +
         'ON ' +
         '  p.codigo = em.codigo_produto ' +
         'LEFT JOIN ( ' +
         '  SELECT ' +
         '    codigo_produto, ' +
         '    lote, ' +
         '    SUM(quantidade) AS total_saida ' +
         '  FROM ' +
         '    saida_mercadorias ' +
         IfThen(LocalId > 0, 'Where codigo_local <> :localid', ''  ) +
         '  GROUP BY ' +
         '    codigo_produto, lote ' +
         ') sm ' +
         'ON ' +
         '  p.codigo = sm.codigo_produto ' +
         '  AND em.lote = sm.lote ' +
         ' WHERE (em.lote is not null)  and COALESCE(em.total_entrada, 0) - COALESCE(sm.total_saida, 0) <> 0 ';

      if ProdId > 0 then
        WhereClauses.Add('p.codigo = :prod_id');

      if Desc <> '' then
          WhereClauses.Add('p.descricao LIKE :desc');

      if WhereClauses.Count > 0 then
        SQLText := SQLText + ' AND ' + String.Join(' AND ',
          WhereClauses.ToStringArray);

      Query.SQL.Text := SQLText + ' ORDER BY em.data_vencimento asc';

      if ProdId > 0 then
        Query.ParamByName('prod_id').AsInteger := ProdId;

      if Desc <> '' then
          Query.ParamByName('desc').AsString := '%' + Desc + '%';

      if LocalId > 0 then
        Query.ParamByName('localid').AsInteger := LocalId;


//      Writeln(Query.SQL.Text);
      Query.Open;

      while not Query.Eof do
      begin
        JSON := TJSONObject.Create;
        JSON.AddPair('product_id',
          TJSONNumber.Create(Query.FieldByName('codigo_produto').AsInteger));
        JSON.AddPair('product_desc',
          Query.FieldByName('descricao_produto').AsString);
        JSON.AddPair('quantity',
          TJSONNumber.Create(Query.FieldByName('estoque').AsFloat));
        JSON.AddPair('lot', Query.FieldByName('lote').AsString);
        JSON.AddPair('manufacture_date',
          TJSONString.Create(DateToStr(Query.FieldByName('data_fabricacao')
          .AsDateTime)));
        JSON.AddPair('expiry_date',
          TJSONString.Create(DateToStr(Query.FieldByName('data_vencimento')
          .AsDateTime)));
        JsonArray.AddElement(JSON);
        Query.Next;
      end;

      Result := JsonArray;
    except
      on E: Exception do
      begin
        Writeln(e.Message);
        JsonArray.Free;
        Result := nil;
      end;
    end;
  finally
    WhereClauses.Free;
  end;
end;

function TServiceReport.GetAllByLotAndLocal(ProdId,
  LocalId: Integer): TJSONArray;
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
         IfThen(LocalId > 0, 'Where codigo_local <> :localid', ''  ) +
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
         IfThen(LocalId > 0, 'Where codigo_local <> :localid', ''  ) +
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
         '  ((COALESCE(em.total_entrada, 0) - COALESCE(sm.total_saida, 0) <> 0)) ';

      if ProdId > 0 then
        WhereClauses.Add('p.codigo = :prod_id');

      if WhereClauses.Count > 0 then
        SQLText := SQLText + ' AND ' + String.Join(' AND ',
          WhereClauses.ToStringArray);

      Query.SQL.Text := SQLText + ' ORDER BY em.data_vencimento asc';

      if ProdId > 0 then
        Query.ParamByName('prod_id').AsInteger := ProdId;

      if LocalId > 0 then
        Query.ParamByName('localid').AsInteger := LocalId;

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
