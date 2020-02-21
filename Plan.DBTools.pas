unit Plan.DBTools;

interface

uses
  System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys,FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs, FireDAC.Stan.Param, FireDAC.FMXUI.Wait, Data.DB,
  FireDAC.Comp.Client,Generics.Collections;

type
  TRecordState = (Nothing, New, Deleted, Updated);

  TDomain = record
    id: integer;
    name: string;
    active: boolean;
    num: integer;
    recstate: TRecordState;
  end;
  TDomainList = TList<TDomain>;

  TPeriod = record
    id: integer;
    name: string;
    active: boolean;
    recstate: TRecordState;
  end;
  TPeriodList = TList<TPeriod>;


  TPlanDB = class(TObject)
  const
    dbName: string = 'plan.sdb';
  private
    { Private declarations }
    FDConn: TFDConnection;
    query: TFDQuery;
  public
    { Public declarations }
    constructor Create(Owner: TComponent);
    destructor Destroy; override;

    function loadDomains(): TDomainList;
    function loadPeriods(): TPeriodList;
    procedure saveDomains(domains: TDomainList);
    procedure savePeriods(periods: TPeriodList);

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

//  if not FDConn.Connected then
//    raise Exception.Create('Could not connect to database.');

  query := TFDQuery.Create(Owner);
  query.Connection := FDConn;
//  query.Params.BindMode := pByNumber;

  query.ExecSQL('CREATE TABLE IF NOT EXISTS domains ( '
    + 'id INTEGER PRIMARY KEY ASC AUTOINCREMENT, '
    + 'name VARCHAR(128) NOT NULL UNIQUE, '
    + 'active BOOLEAN NOT NULL CHECK (active = 0 or active = 1) DEFAULT 1, '
    + 'num INT NOT NULL '
    + ')'
  );

  query.ExecSQL('CREATE TABLE IF NOT EXISTS periods ( '
    + 'id INTEGER PRIMARY KEY ASC, '
    + 'name VARCHAR(128) NOT NULL UNIQUE, '
    + 'active BOOLEAN NOT NULL CHECK (active = 0 or active = 1) DEFAULT 1 '
    + ')'
  );

  query.ExecSQL('CREATE TABLE IF NOT EXISTS period_dates ( '
    + 'id INTEGER PRIMARY KEY ASC AUTOINCREMENT, '
    + 'period INTEGER NOT NULL REFERENCES periods (id), '
    + 'alive BOOLEAN NOT NULL CHECK (alive = 0 or alive = 1) DEFAULT 1, '
    + 'start_date DATETIME NOT NULL '
    + ')'
  );

  query.ExecSQL('CREATE TABLE IF NOT EXISTS doings ( '
    + 'id INTEGER PRIMARY KEY ASC AUTOINCREMENT, '
    + 'domain INTEGER NOT NULL REFERENCES domains (id), '
    + 'period INTEGER NOT NULL REFERENCES period_dates (id), '
    + 'num INTEGER NULL DEFAULT NULL, '
    + 'do_date DATETIME NULL DEFAULT NULL, '
    + 'state INTEGER NOT NULL DEFAULT 0, '
    + 'alive BOOLEAN NOT NULL CHECK (alive = 0 or alive = 1) DEFAULT 1, '
    + 'notification INTEGER NULL DEFAULT NULL, '
    + 'link INTEGER NULL DEFAULT NULL REFERENCES doings (id), '
    + 'parent INTEGER NULL DEFAULT NULL REFERENCES doings (id) '
    + ')'
  );

end;

destructor TPlanDB.Destroy;
begin
  FDConn.Close;
  inherited Destroy;
end;

function TPlanDB.loadDomains(): TDomainList;
var
  domain: TDomain;
begin
  try
    query.SQL.Text := 'SELECT id, name, active, num FROM domains WHERE active = 1';
    query.Open();

    result := TDomainList.Create;

    while not query.Eof do
    begin
      domain.id := query.FieldByName('id').AsInteger;
      domain.name := query.FieldByName('name').AsString;
      domain.num := query.FieldByName('num').AsInteger;
      domain.active := query.FieldByName('active').AsBoolean;
      domain.recstate := TRecordState.Nothing;
      result.Add(domain);
      query.Next;
    end;

  finally
    query.Close;
    query.SQL.Clear;
  end;
end;

function TPlanDB.loadPeriods(): TPeriodList;
var
  period: TPeriod;
begin
  try
    query.SQL.Text := 'SELECT id, name, active FROM periods';
    query.Open();

    result := TPeriodList.Create;

    while not query.Eof do
    begin
      period.id := query.FieldByName('id').AsInteger;
      period.name := query.FieldByName('name').AsString;
      period.active := query.FieldByName('active').AsBoolean;
      period.recstate := TRecordState.Nothing;
      result.Add(period);
      query.Next;
    end;

  finally
    query.Close;
    query.SQL.Clear;
  end;
end;

procedure TPlanDB.saveDomains(domains: TDomainList);
var
  domain: TDomain;
  i, k: integer;
begin
  FDConn.StartTransaction;

  try
    k := domains.Count - 1;
    for i := 0 to k do
    begin
      domain := domains[i];
      case domain.recstate of
        TRecordState.Nothing: continue;
        TRecordState.New:
        begin
          query.SQL.Text := 'INSERT INTO domains (name, num) VALUES (:name, :num)';

          query.Params.ArraySize := 1;
          query.Params[0].AsStrings[0] := domain.name;
          query.Params[1].AsIntegers[0] := domain.num;

          query.Execute(query.Params.ArraySize, 0);
          query.SQL.Clear;
        end;
        TRecordState.Deleted:
        begin
          query.SQL.Text := 'UPDATE domains SET active = 0 WHERE id = :id';

          query.Params.ArraySize := 1;
          query.Params[0].AsIntegers[0] := domain.id;

          query.Execute(query.Params.ArraySize, 0);
          query.SQL.Clear;
        end;
        TRecordState.Updated:
        begin
          query.SQL.Text := 'UPDATE domains SET name = :name, num = :num WHERE id = :id';

          query.Params.ArraySize := 1;
          query.Params[0].AsStrings[0] := domain.name;
          query.Params[1].AsIntegers[0] := domain.num;
          query.Params[2].AsIntegers[0] := domain.id;

          query.Execute(query.Params.ArraySize, 0);
          query.SQL.Clear;
        end;
      end;
    end;

    FDConn.Commit;
  except
    FDConn.Rollback;
    raise;
  end;
end;

procedure TPlanDB.savePeriods(periods: TPeriodList);
var
  period: TPeriod;
  i, k: integer;
begin
  FDConn.StartTransaction;

  try
    k := periods.Count - 1;
    for i := 0 to k do
    begin
      period := periods[i];
      case period.recstate of
        TRecordState.Nothing: continue;
        TRecordState.New: continue;
        TRecordState.Deleted: continue;
        TRecordState.Updated:
        begin
          query.SQL.Text := 'UPDATE periods SET active = :active WHERE id = :id';

          query.Params.ArraySize := 1;
          query.Params[0].AsIntegers[0] := Integer(period.active);
          query.Params[1].AsIntegers[0] := period.id;

          query.Execute(query.Params.ArraySize, 0);
          query.SQL.Clear;
        end;
      end;
    end;

    FDConn.Commit;
  except
    FDConn.Rollback;
    raise;
  end;
end;

end.
