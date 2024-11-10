unit FarmaNossa.Services.Products;

interface

uses
  System.SysUtils, System.Classes, System.JSON, Data.DB, Uni, MemDS,
  FarmaNossa.Providers.Connection, FarmaNossa.Entities.Product,
  System.Generics.Collections;
type
  TServiceProduct = class
  private
    FConnectionProvider: TConnectionProvider;
  public
    constructor Create;
    destructor Destroy; override;
    function GetProduct(ProdId: Integer): TJSONObject;
    function GetAll (Desc: String = ''; Id: String = ''; Status: String = ''; N_stock: String = ''; S_input: String = ''; S_output: String = ''): TJSONArray;
    function Post(Desc: String; Status, N_stock, S_input, S_output: Boolean): Integer;
    function Update(ID: Integer; Desc: String; Status, N_stock, S_input, S_output: Boolean): Boolean;
    function Delete(ProdId: Integer): Boolean;
    function GetProductStock(ProdId: Integer): TProduct;
    function GetAllStock (Desc: String = ''; Status: String = ''; N_stock: String = ''; S_input: String = ''; S_output: String = ''): TObjectList<TProduct>;
  end;

implementation

{ TServiceUser }

//DROP TABLE IF EXISTS produto;
//CREATE TABLE produto
//(
//  codigo serial NOT NULL,
//  descricao character varying(255) NOT NULL,
//  status boolean NOT NULL,
//  estoque_negativo boolean NOT NULL,
//  status_entrada boolean NOT NULL,
//  status_saida boolean NOT NULL,
//  CONSTRAINT produto_pkey PRIMARY KEY (codigo)
//);

constructor TServiceProduct.Create;
begin
  FConnectionProvider := TConnectionProvider.Create;
end;

destructor TServiceProduct.Destroy;
begin
  FConnectionProvider.Free;
  inherited;
end;

// pegar apenas um produto por id
function TServiceProduct.GetProduct(ProdId: Integer): TJSONObject;
var
  Query: TUniQuery;
  ProdJSON: TJSONObject;
begin
  Query := FConnectionProvider.GetQuery;
  ProdJSON := TJSONObject.Create;

  try
    Query.Close;
    Query.SQL.Text := 'SELECT codigo, descricao, status, estoque_negativo, status_entrada, status_saida FROM produto WHERE codigo = :id';
    Query.ParamByName('Id').AsInteger := ProdId;
    Query.Open;

    if not Query.Eof then
    begin
      ProdJSON.AddPair('id', TJSONNumber.Create(Query.FieldByName('codigo').AsInteger));
      ProdJSON.AddPair('description', Query.FieldByName('descricao').AsString);
      ProdJSON.AddPair('status', TJSONBool.Create( Query.FieldByName('status').AsBoolean));
      ProdJSON.AddPair('n_stock', TJSONBool.Create( Query.FieldByName('estoque_negativo').AsBoolean));
      ProdJSON.AddPair('s_input', TJSONBool.Create( Query.FieldByName('status_entrada').AsBoolean));
      ProdJSON.AddPair('s_output', TJSONBool.Create( Query.FieldByName('status_saida').AsBoolean));
    end;

    Result := ProdJSON;
  except
    on E: Exception do
    begin
      ProdJSON.Free;
      Result := nil;
    end;
  end;
end;

// pegar todos os produtos
function TServiceProduct.GetAll(Desc: String = ''; Id: String = ''; Status: String = ''; N_stock: String = ''; S_input: String = ''; S_output: String = ''): TJSONArray;
var
  Query: TUniQuery;
  ProdArray: TJSONArray;
  ProdJSON: TJSONObject;
  SQLText: String;
  WhereClauses: TStringList;
begin
  Query := FConnectionProvider.GetQuery;
  ProdArray := TJSONArray.Create;
  WhereClauses := TStringList.Create;

  try
      try
        SQLText := 'SELECT codigo, status, descricao, estoque_negativo, status_entrada, status_saida FROM produto';

        if Desc <> '' then
          WhereClauses.Add('descricao LIKE :desc');

        if (Id <> '') And (id.ToInteger > 0) then
          WhereClauses.Add('codigo::varchar like :id');

        if Status.Equals('false') or Status.Equals('true') then
          WhereClauses.Add('status = :status');

        if N_stock.Equals('false') or N_stock.Equals('true') then
          WhereClauses.Add('estoque_negativo = :n_stock');

        if S_input.Equals('false') or S_input.Equals('true') then
          WhereClauses.Add('status_entrada = :s_input');

        if S_output.Equals('false') or S_output.Equals('true') then
          WhereClauses.Add('status_saida = :s_output');

        if WhereClauses.Count > 0 then
          SQLText := SQLText + ' WHERE ' + String.Join(' AND ', WhereClauses.ToStringArray);

        Query.SQL.Text := SQLText;

        if Desc <> '' then
          Query.ParamByName('desc').AsString := '%' + Desc + '%';

        if (Id <> '') And (id.ToInteger > 0) then
          Query.ParamByName('id').AsString := Id + '%';

        if Status.Equals('false') or Status.Equals('true')  then
          Query.ParamByName('status').AsBoolean := StrToBool( status);

        if N_stock.Equals('false') or N_stock.Equals('true')  then
          Query.ParamByName('n_stock').AsBoolean := StrToBool( N_stock);

        if S_input.Equals('false') or S_input.Equals('true') then
          Query.ParamByName('s_input').AsBoolean := StrToBool(S_input);

        if S_output.Equals('false') or S_output.Equals('true') then
          Query.ParamByName('s_output').AsBoolean := StrToBool(S_output);

        Query.Open;

        while not Query.Eof do
        begin
          ProdJSON := TJSONObject.Create;
          ProdJSON.AddPair('id', TJSONNumber.Create(Query.FieldByName('codigo').AsInteger));
          ProdJSON.AddPair('description', Query.FieldByName('descricao').AsString);
          ProdJSON.AddPair('status', TJSONBool.Create( Query.FieldByName('status').AsBoolean));
          ProdJSON.AddPair('n_stock', TJSONBool.Create(Query.FieldByName('estoque_negativo').AsBoolean));
          ProdJSON.AddPair('s_input', TJSONBool.Create(Query.FieldByName('status_entrada').AsBoolean));
          ProdJSON.AddPair('s_output', TJSONBool.Create(Query.FieldByName('status_saida').AsBoolean));
          ProdArray.AddElement(ProdJSON);

          Query.Next;
        end;

        Result := ProdArray;
      except
        on E: Exception do
        begin
          ProdArray.Free;
          Result := nil;
        end;
      end;
  finally
    WhereClauses.Free;
  end;
end;


// criar um novo produto e retornar o ID
function TServiceProduct.Post(Desc: String; Status, N_stock, S_input, S_output: Boolean): Integer;
var
  Query: TUniQuery;
begin
  Query := FConnectionProvider.GetQuery();

  try
    Query.Close;
    Query.SQL.Text := 'INSERT INTO produto (descricao, status, estoque_negativo, status_entrada, status_saida) VALUES (:desc, :status, :n_stock, :s_input, :s_output) RETURNING codigo';
    Query.ParamByName('desc').AsString := Desc;
    Query.ParamByName('status').AsBoolean := Status;
    Query.ParamByName('n_stock').AsBoolean := n_stock;
    Query.ParamByName('s_input').AsBoolean := s_input;
    Query.ParamByName('s_output').AsBoolean := S_output;
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


end;

// atualizar um produto existente
function TServiceProduct.Update(id: Integer; Desc: String; Status, N_stock, S_input, S_output: Boolean): Boolean;
var
  Query: TUniQuery;
begin
  Query := FConnectionProvider.GetQuery;
      try
        Query.Close;
        Query.SQL.Text := 'UPDATE produto SET descricao = :desc, status = :status, estoque_negativo = :n_stock, status_entrada = :s_input, status_saida = :s_output  where codigo = :id';
        Query.ParamByName('desc').AsString := Desc;
        Query.ParamByName('status').AsBoolean := Status;
        Query.ParamByName('n_stock').AsBoolean := n_stock;
        Query.ParamByName('s_input').AsBoolean := s_input;
        Query.ParamByName('s_output').AsBoolean := S_output;
        Query.ParamByName('id').AsInteger := id;
        Query.ExecSQL;
        Result := Query.RowsAffected > 0;
      except
        on E: Exception do
        begin
          Result := False;
        end;
      end;
end;

// deletar um produto
function TServiceProduct.Delete(ProdId: Integer): Boolean;
var
  Query: TUniQuery;
begin
  Query := FConnectionProvider.GetQuery;

  try
    Query.Close;
    Query.SQL.Text := 'DELETE FROM produto p WHERE p.codigo = :id and (select count(*) from entrada_mercadorias where codigo_produto = :id) = 0 and (select count(*) from saida_mercadorias where codigo_produto = :id) = 0';
    Query.ParamByName('id').AsInteger := ProdId;
    Query.ExecSQL;
    Result := Query.RowsAffected > 0;
  except
    on E: Exception do
        begin
          Result := False;
        end;
  end;
end;

// pegar um produto
function TServiceProduct.GetProductStock(ProdId: Integer): TProduct;
var
  Query: TUniQuery;
  Product: TProduct;
begin
  Query := FConnectionProvider.GetQuery;

  try
    Query.Close;
    Query.SQL.Text :=  'SELECT ' +
      '  p.codigo, ' +
      '  p.descricao, ' +
      '  p.status, ' +
      '  p.estoque_negativo, ' +
      '  p.status_entrada, ' +
      '  p.status_saida, ' +
      '  (COALESCE(em.total_entrada, 0) - COALESCE(sm.total_saida, 0)) AS estoque ' +
      'FROM ' +
      '  produto p ' +
      'LEFT JOIN ' +
      '  (SELECT ' +
      '     codigo_produto, ' +
      '     SUM(quantidade) AS total_entrada ' +
      '   FROM ' +
      '     entrada_mercadorias ' +
      '   GROUP BY ' +
      '     codigo_produto) em ON p.codigo = em.codigo_produto ' +
      'LEFT JOIN ' +
      '  (SELECT ' +
      '     codigo_produto, ' +
      '     SUM(quantidade) AS total_saida ' +
      '   FROM ' +
      '     saida_mercadorias ' +
      '   GROUP BY ' +
      '     codigo_produto) sm ON p.codigo = sm.codigo_produto ' +
      'WHERE ' +
      '  p.codigo = :id';
    Query.ParamByName('id').AsInteger := ProdId;

    Query.Open;

    if Query.FieldByName('codigo').AsInteger < 0 then
    begin
      Result := nil;
      Exit;
    end;

    try
      if not Query.Eof then
      begin
        Product := TProduct.Create;
        Product.Code := Query.FieldByName('codigo').AsInteger;
        Product.Description := Query.FieldByName('descricao').AsString;
        Product.Status := Query.FieldByName('status').AsBoolean;
        Product.NegativeStock := Query.FieldByName('estoque_negativo').AsBoolean;
        Product.InputStatus := Query.FieldByName('status_entrada').AsBoolean;
        Product.OutputStatus := Query.FieldByName('status_saida').AsBoolean;
        Product.Stock := Query.FieldByName('estoque').AsFloat;
      end;

      Result := Product;
    finally
      Product.Free;
    end;

  except
    on E: Exception do
        begin
          Result := Nil;
        end;
  end;
end;

// pegar todos os produtos
function TServiceProduct.GetAllStock(Desc: String = ''; Status: String = ''; N_stock: String = ''; S_input: String = ''; S_output: String = ''): TObjectList<TProduct>;
var
  Query: TUniQuery;
  Products: TObjectList<TProduct>;
  Product: TProduct;
  SQLText: String;
  WhereClauses: TStringList;
begin
  Query := FConnectionProvider.GetQuery;
  Products := TObjectList<TProduct>.Create;
  WhereClauses := TStringList.Create;

  try
      try
        SQLText := 'SELECT ' +
        '    p.codigo, ' +
        '    p.descricao, ' +
        '    p.status, ' +
        '    p.estoque_negativo, ' +
        '    p.status_entrada, ' +
        '    p.status_saida, ' +
        '    COALESCE(em.total_entrada, 0) - COALESCE(sm.total_saida, 0) AS estoque ' +
        'FROM ' +
        '    produto p ' +
        'LEFT JOIN ' +
        '    (SELECT ' +
        '         codigo_produto, ' +
        '         SUM(quantidade) AS total_entrada ' +
        '     FROM ' +
        '         entrada_mercadorias ' +
        '     GROUP BY ' +
        '         codigo_produto) em ' +
        'ON ' +
        '    p.codigo = em.codigo_produto ' +
        'LEFT JOIN ' +
        '    (SELECT ' +
        '         codigo_produto, ' +
        '         SUM(quantidade) AS total_saida ' +
        '     FROM ' +
        '         saida_mercadorias ' +
        '     GROUP BY ' +
        '         codigo_produto) sm ' +
        'ON ' +
        '    p.codigo = sm.codigo_produto;';

        if Desc <> '' then
          WhereClauses.Add('descricao LIKE :desc');

        if Status.Equals('false') or Status.Equals('true') then
          WhereClauses.Add('p.status = :status');

        if N_stock.Equals('false') or N_stock.Equals('true') then
          WhereClauses.Add('p.estoque_negativo = :n_stock');

        if S_input.Equals('false') or S_input.Equals('true') then
          WhereClauses.Add('p.status_entrada = :s_input');

        if S_output.Equals('false') or S_output.Equals('true') then
          WhereClauses.Add('p.status_saida = :s_output');

        if WhereClauses.Count > 0 then
          SQLText := SQLText + ' WHERE ' + String.Join(' AND ', WhereClauses.ToStringArray);

        Query.SQL.Text := SQLText;

        if Desc <> '' then
          Query.ParamByName('desc').AsString := '%' + Desc + '%';

        if Status.Equals('false') or Status.Equals('true')  then
          Query.ParamByName('status').AsBoolean := StrToBool( status);

        if N_stock.Equals('false') or N_stock.Equals('true')  then
          Query.ParamByName('n_stock').AsBoolean := StrToBool( N_stock);

        if S_input.Equals('false') or S_input.Equals('true') then
          Query.ParamByName('s_input').AsBoolean := StrToBool(S_input);

        if S_output.Equals('false') or S_output.Equals('true') then
          Query.ParamByName('s_output').AsBoolean := StrToBool(S_output);

        Query.Open;

        while not Query.Eof do
        begin
          Product := TProduct.Create;
          Product.Code := Query.FieldByName('codigo').AsInteger;
          Product.Description := Query.FieldByName('descricao').AsString;
          Product.Status := Query.FieldByName('status').AsBoolean;
          Product.NegativeStock := Query.FieldByName('estoque_negativo').AsBoolean;
          Product.InputStatus := Query.FieldByName('status_entrada').AsBoolean;
          Product.OutputStatus := Query.FieldByName('status_saida').AsBoolean;
          Products.Add(Product);

          Query.Next;
        end;

        Result := Products;
      except
        on E: Exception do
        begin
          Products.Free;
          Result := nil;
        end;
      end;
  finally
    WhereClauses.Free;
  end;
end;



end.

