unit Plan.DBTools;

interface

uses
  System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys,FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs, FireDAC.FMXUI.Wait, Data.DB, FireDAC.Comp.Client;

type
  TPlanDB = class(TObject)

  const
    dbName: string = 'plan.sdb';
  private
    { Private declarations }
    FDConn: TFDConnection;
  public
    { Public declarations }
    constructor Create(Owner: TComponent);
    destructor Destroy; override;
  end;

var
  db: TPlanDB;

implementation

constructor TPlanDB.Create(Owner: TComponent);
var
  q: TFDQuery;
begin
  inherited Create;
  FDConn := TFDConnection.Create(Owner);
  FDConn.DriverName := 'SQLite';
  FDConn.Params.Database := dbName;
  FDConn.Open;

//  if not FDConn.Connected then
//    raise Exception.Create('Could not connect to database.');

  q.Connection := FDConn;
  q.ExecSQL('CREATE TABLE IF NOT EXISTS domains ('
    + 'id INTEGER PRIMARY KEY ASC AUTOINCREMENT,'
    + 'name VARCHAR(128) NOT NULL UNIQUE,'
    + 'active BOOLEAN NOT NULL CHECK (active = 0 or active = 1) DEFAULT 1,'
    + 'num INT NOT NULL'
    + ')'
  );

end;

destructor TPlanDB.Destroy;
begin
  FDConn.Close;
  inherited Destroy;
end;

end.
