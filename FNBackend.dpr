program FNBackend;

uses
  Vcl.Forms,
  unit_main in 'unit_main.pas' {UnitMain},
  FarmaNossa.Services.Input in 'services\FarmaNossa.Services.Input.pas',
  FarmaNossa.Services.LocalStock in 'services\FarmaNossa.Services.LocalStock.pas',
  FarmaNossa.Services.Lot in 'services\FarmaNossa.Services.Lot.pas',
  FarmaNossa.Services.Output in 'services\FarmaNossa.Services.Output.pas',
  FarmaNossa.Services.Products in 'services\FarmaNossa.Services.Products.pas',
  FarmaNossa.Services.Report in 'services\FarmaNossa.Services.Report.pas',
  FarmaNossa.Services.Stock in 'services\FarmaNossa.Services.Stock.pas',
  FarmaNossa.Services.Users in 'services\FarmaNossa.Services.Users.pas',
  FarmaNossa.Providers.Authorization in 'providers\FarmaNossa.Providers.Authorization.pas',
  FarmaNossa.Providers.Connection in 'providers\FarmaNossa.Providers.Connection.pas',
  FarmaNossa.Entities.Product in 'entities\FarmaNossa.Entities.Product.pas',
  Controllers.Input in 'controllers\Controllers.Input.pas',
  Controllers.local in 'controllers\Controllers.local.pas',
  Controllers.login in 'controllers\Controllers.login.pas',
  Controllers.Output in 'controllers\Controllers.Output.pas',
  Controllers.product in 'controllers\Controllers.product.pas',
  Controllers.Report in 'controllers\Controllers.Report.pas',
  Controllers.Stock in 'controllers\Controllers.Stock.pas',
  Controllers.user in 'controllers\Controllers.user.pas',
  FarmaNossa.Configs.Login in 'Configs\FarmaNossa.Configs.Login.pas',
  FarmaNossa.Services.Variable in 'services\FarmaNossa.Services.Variable.pas',
  View.ConfigDB in 'Views\View.ConfigDB.pas' {ViewDBAccess};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TUnitMain, UnitMain);
  Application.Run;

   ReportMemoryLeaksOnShutdown := True;
end.
