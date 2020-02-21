unit Plan.DBTools;

interface

uses
  System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys,FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs, FireDAC.FMXUI.Wait, Data.DB, FireDAC.Comp.Client,
  Generics.Collections;

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
  public
    { Public declarations }
    constructor Create(Owner: TComponent);
    destructor Destroy; override;

    function loadDomains(): TDomainList;
    function loadPeriods(): TPeriodList;
    function saveDomains(domains: TDomainList);
    function savePeriods(periods: TPeriodList);

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
  q.ExecSQL('CREATE TABLE IF NOT EXISTS domains ( '
    + 'id INTEGER PRIMARY KEY ASC AUTOINCREMENT, '
    + 'name VARCHAR(128) NOT NULL UNIQUE, '
    + 'active BOOLEAN NOT NULL CHECK (active = 0 or active = 1) DEFAULT 1, '
    + 'num INT NOT NULL '
    + ')'
  );

  q.ExecSQL('CREATE TABLE IF NOT EXISTS periods ( '
    + 'id INTEGER PRIMARY KEY ASC, '
    + 'name VARCHAR(128) NOT NULL UNIQUE, '
    + 'active BOOLEAN NOT NULL CHECK (active = 0 or active = 1) DEFAULT 1 '
    + ')'
  );

  q.ExecSQL('CREATE TABLE IF NOT EXISTS period_dates ( '
    + 'id INTEGER PRIMARY KEY ASC AUTOINCREMENT, '
    + 'period INTEGER NOT NULL REFERENCES periods (id), '
    + 'alive BOOLEAN NOT NULL CHECK (alive = 0 or alive = 1) DEFAULT 1, '
    + 'start_date DATETIME NOT NULL '
    + ')'
  );

  q.ExecSQL('CREATE TABLE IF NOT EXISTS doings ( '
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
  q: TFDQuery;
  domain: TDomain;
begin
  try
    q.Connection := FDConn;
    q.SQL.Text := 'SELECT id, name, active, num FROM domains WHERE active = 1';
    q.Open();

    result := TDomainList.Create;

    while not q.Eof do
    begin
      domain.id := q.FieldByName('id').AsInteger;
      domain.name := q.FieldByName('name').AsString;
      domain.num := q.FieldByName('num').AsInteger;
      domain.active := q.FieldByName('active').AsBoolean;
      domain.recstate := TRecordState.Nothing;
      result.Add(domain);
      q.Next;
    end;

  finally
    q.Close;
    q.DisposeOf;
  end;
end;

function TPlanDB.loadPeriods(): TPeriodList;
var
  q: TFDQuery;
  period: TPeriod;
begin
  try
    q.Connection := FDConn;
    q.SQL.Text := 'SELECT id, name, active FROM periods';
    q.Open();

    result := TPeriodList.Create;

    while not q.Eof do
    begin
      period.id := q.FieldByName('id').AsInteger;
      period.name := q.FieldByName('name').AsString;
      period.active := q.FieldByName('active').AsBoolean;
      period.recstate := TRecordState.Nothing;
      result.Add(period);
      q.Next;
    end;

  finally
    q.Close;
    q.DisposeOf;
  end;
end;

function TPlanDB.saveDomains(domains: TDomainList);
var
  q: TFDQuery;
  domain: TDomain;

  i, k: integer;
begin
  q.Connection := FDConn;

  k := domains.Count - 1;
  for i := 0 to k do
  begin
    domain := domains[i];
    case domain.recstate of
      TRecordState.Nothing : continue;
      TRecordState.New :
      begin
        q.ExecSQL('INSERT INTO domains (name, num) VALUES (:name, :num)');
      end;

    end;
  end;


  while not q.Eof do
  begin
    domain.id := q.FieldByName('id').AsInteger;
    domain.name := q.FieldByName('name').AsString;
    domain.num := q.FieldByName('num').AsInteger;
    domain.active := q.FieldByName('active').AsBoolean;
    result.Add(domain);
    q.Next;
  end;

end;

end.
