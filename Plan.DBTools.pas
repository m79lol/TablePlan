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
begin
  inherited Create;
  FDConn := TFDConnection.Create(Owner);
  FDConn.DriverName := 'SQLite';
  FDConn.Params.Database := dbName;
  FDConn.Open;
end;

destructor TPlanDB.Destroy;
begin
  FDConn.Close;
  inherited Destroy;
end;

end.
