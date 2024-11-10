unit FarmaNossa.Configs.Login;

interface

type
  TConfigLogin = record
  private
    function GetExpires: Integer;
    function GetSecret: string;
  public
    property Expires: Integer read GetExpires;
    property Secret: string read GetSecret;
  end;

implementation

uses System.SysUtils;

function TConfigLogin.GetExpires: Integer;
begin
  Result := 24 //GetEnvironmentVariable('LOGIN_EXPIRE').ToInteger;   // em horas
end;

function TConfigLogin.GetSecret: string;
begin
  Result := 'secrete';//GetEnvironmentVariable('LOGIN_SECRET');
end;

end.
