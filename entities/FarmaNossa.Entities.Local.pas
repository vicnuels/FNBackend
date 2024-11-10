unit FarmaNossa.Entities.Local;

interface

uses
  System.SysUtils;

type
  TLocal = class
  private
    FCode: Integer;
    FDescription: string;
    FStatus: Boolean;
    procedure SetCode(Value: Integer);
  public
    property Code: Integer read FCode write SetCode;
    property Description: string read FDescription write FDescription;
    property Status: Boolean read FStatus write FStatus;
  end;

implementation

procedure TLocal.SetCode(Value: Integer);
begin
  if Value > 0 then
    FCode := Value
  else
    raise Exception.Create('Invalid Code');
end;

end.

