unit FarmaNossa.Entities.Product;

interface

uses
  System.SysUtils;

type
  TProduct = class
  private
    FCode: Integer;
    FDescription: string;
    FStatus: Boolean;
    FNegativeStock: Boolean;
    FInputStatus: Boolean;
    FOutputStatus: Boolean;
    FStock: Double;
    procedure SetCode(Value: Integer);
  public
    property Code: Integer read FCode write SetCode;
    property Description: string read FDescription write FDescription;
    property Status: Boolean read FStatus write FStatus;
    property NegativeStock: Boolean read FNegativeStock write FNegativeStock;
    property InputStatus: Boolean read FInputStatus write FInputStatus;
    property OutputStatus: Boolean read FInputStatus write FOutputStatus;
    property Stock: Double read FStock write FStock;
  end;

implementation

procedure TProduct.SetCode(Value: Integer);
begin
  if Value > 0 then
    FCode := Value
  else
    raise Exception.Create('Invalid Code');
end;

end.

