unit FarmaNossa.Services.Lot;

interface

uses
  System.SysUtils, System.Classes, System.JSON, Data.DB, Uni, MemDS,
  FarmaNossa.Providers.Connection, FarmaNossa.Services.Products,
  FarmaNossa.Services.LocalStock;

type
  TServiceLot = class
  private
    FConnectionProvider: TConnectionProvider;
  public
    constructor Create;
    destructor Destroy; override;
    function Get(Lot: String): TJSONObject;
    function GetAll(Id: Integer = 0; ProdId: Integer = -1; LocalId: Integer = -1;
      Lot: String = ''; FromDate: TDate = 0; ToDate: TDate = 0): TJSONArray;
  end;

implementation

{ TServiceInput }

constructor TServiceLot.Create;
begin
  FConnectionProvider := TConnectionProvider.Create;
end;

destructor TServiceLot.Destroy;
begin
  FConnectionProvider.Free;
  inherited;
end;

// Get entrada por ID
function TServiceLot.Get(Lot: String): TJSONObject;
var
  Query: TUniQuery;
  InputJSON: TJSONObject;
begin
  Query := FConnectionProvider.GetQuery;
  InputJSON := TJSONObject.Create;

  try
    Query.Close;
    Query.SQL.Text :=
      'SELECT lote, data_fabricacao, data_vencimento FROM entrada_mercadorias WHERE lote = :lot limit 1';
    Query.ParamByName('lot').AsString := Lot;
    Query.Open;

    if not Query.Eof then
    begin
      InputJSON.AddPair('lot', Query.FieldByName('lote').AsString);
      InputJSON.AddPair('manufacture_date',
        TJSONString.Create(DateToStr(Query.FieldByName('data_fabricacao')
        .AsDateTime)));
      InputJSON.AddPair('expiry_date',
        TJSONString.Create(DateToStr(Query.FieldByName('data_vencimento')
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
function TServiceLot.GetAll(Id: Integer = 0; ProdId: Integer = -1; LocalId: Integer = -1;
  Lot: String = ''; FromDate: TDate = 0; ToDate: TDate = 0): TJSONArray;
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
        InputJSON.AddPair('product_desc',
         Query.FieldByName('descricao_produto').AsString);
        InputJSON.AddPair('local_id',
          TJSONNumber.Create(Query.FieldByName('codigo_local').AsInteger));
        InputJSON.AddPair('local_desc',
          Query.FieldByName('descricao_local').AsString);
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



end.
