unit Controllers.login;

interface

procedure Registry;

implementation

uses Horse, FarmaNossa.Providers.Authorization, JOSE.Core.JWT,
  FarmaNossa.Configs.login, System.JSON, System.SysUtils, System.DateUtils,
  JOSE.Core.Builder;

procedure DoGetLogin(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  JWT: TJWT;
  Claims: TJWTClaims;
  Config: TConfigLogin;
begin
  JWT := TJWT.Create;
  Claims := JWT.Claims;
//  Claims.JSON := TJSONObject.Create;
  try
    Claims.IssuedAt := Now;
    Claims.Expiration := IncHour(Now, Config.Expires);
    Res.Send(TJSONObject.Create.AddPair('token',
      TJOSE.SHA256CompactToken(Config.Secret, JWT)));
  finally
    JWT.Free;
  end;

end;

procedure Registry;
begin
  THorse.AddCallback(BasicAuthorization()).Get('/login', DoGetLogin);
end;

end.
