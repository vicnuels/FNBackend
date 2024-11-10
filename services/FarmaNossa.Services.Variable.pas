unit FarmaNossa.Services.Variable;

interface

uses
  Windows, Registry, SysUtils, Messages;

procedure SetEnvVariableInRegistry(const Name, Value: string);
function GetEnvVariableFromRegistry(const Name: string): string;

implementation

procedure SetEnvVariableInRegistry(const Name, Value: string);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey('Environment', True) then
    begin
      Reg.WriteString(Name, Value);
      Reg.CloseKey;
      // Broadcast to notify all applications of the change
      SendMessage(HWND_BROADCAST, WM_SETTINGCHANGE, 0, LPARAM(PChar('Environment')));
    end
    else
      raise Exception.Create('Failed to open registry key');
  finally
    Reg.Free;
  end;
end;

function GetEnvVariableFromRegistry(const Name: string): string;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly('Environment') then
    begin
      Result := Reg.ReadString(Name);
      Reg.CloseKey;
    end
    else
      Result := '';
  finally
    Reg.Free;
  end;
end;

end.
