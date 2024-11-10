object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 231
  ClientWidth = 505
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object UniConnection: TUniConnection
    ProviderName = 'postgreSQL'
    Port = 5432
    Database = 'farmanossa'
    Username = 'postgres'
    Server = 'localhost'
    Connected = True
    Left = 376
    Top = 104
    EncryptedPassword = 'CDFFCFFFCFFFCAFF'
  end
  object UniQuery: TUniQuery
    Connection = UniConnection
    Left = 320
    Top = 72
  end
  object UniDataSource: TUniDataSource
    Left = 456
    Top = 160
  end
  object UniTable1: TUniTable
    Connection = UniConnection
    Left = 320
    Top = 168
  end
end
