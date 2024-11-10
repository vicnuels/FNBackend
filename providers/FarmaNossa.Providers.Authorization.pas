unit FarmaNossa.Providers.Authorization;

interface

uses Horse, Horse.JWT, Horse.BasicAuthentication, FarmaNossa.Services.Users;

function Authorization: THorseCallback;
function BasicAuthorization: THorseCallback;

implementation

uses FarmaNossa.Configs.Login;

function DoBasicAuthentication(const Username, Password: string): Boolean;
var
  Users : TServiceUser;
begin
  Users := TServiceUser.Create;
  try
//    Writeln(username, password);
    Result := Users.Validate(username, password);  // erro
  finally
   Users.Free;
  end;
end;

function BasicAuthorization: THorseCallback;
begin
  Result := HorseBasicAuthentication(DoBasicAuthentication);
end;

function Authorization: THorseCallback;
var
  Config: TConfigLogin;
begin
  Result := HorseJWT(Config.Secret);
end;

end.

