unit Plan.DBTools;

interface

uses
  System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys,FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs, FireDAC.Stan.Param, FireDAC.FMXUI.Wait, Data.DB,
  FireDAC.Comp.Client, Generics.Collections;

type
  TRecordState = (Nothing, New, Deleted, Updated);

  TDomain = record
    id: integer;
    name: string;
    active: boolean;
    num: integer;
    FRecState: TRecordState;
    constructor Create(RecState: TRecordState);
    procedure SetRecState(Value: TRecordState);
    property recstate: TRecordState read FRecState write SetRecState;
  end;
  TDomainList = TList<TDomain>;

  TPeriod = record
    id: integer;
    name: string;
    active: boolean;
    FRecState: TRecordState;
    constructor Create(RecState: TRecordState);
    procedure SetRecState(Value: TRecordState);
    property recstate: TRecordState read FRecState write SetRecState;
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
    constructor Create;
    destructor Destroy; override;

    function loadDomains(): TDomainList;
    function loadPeriods(): TPeriodList;
    procedure saveDomains(domains: TDomainList);
    procedure savePeriods(periods: TPeriodList);

  end;

var
  db: TPlanDB;

implementation

uses FireDAC.DApt;

//uses FireDAC.ConsoleUI.Wait, FireDAC.Stan.Def, FireDAC.DApt, FireDAC.Stan.Async,
//  FireDAC.Phys.Oracle, FireDAC.Phys.MSSQL, FireDAC.Stan.Consts;

constructor TDomain.Create(RecState: TRecordState);
begin
  id := 0;
  name := '';
  active := true;
  num := 0;
  FRecState := RecState;
end;

procedure TDomain.SetRecState(Value: TRecordState);
begin
  if FRecState <> TRecordState.New then
  begin
    FRecState := Value;
  end;
end;

constructor TPeriod.Create(RecState: TRecordState);
begin
  id := 0;
  name := '';
  active := true;
  FRecState := RecState;
end;

procedure TPeriod.SetRecState(Value: TRecordState);
begin
  if FRecState <> TRecordState.New then
  begin
    FRecState := Value;
  end;
end;

constructor TPlanDB.Create;
var
  periodsCnt: integer;
begin
  inherited Create;
  FDConn := TFDConnection.Create(nil);
  FDConn.DriverName := 'SQLite';
  FDConn.Params.Database := dbName;
  FDConn.Open;

//  if not FDConn.Connected then
//    raise Exception.Create('Could not connect to database.');

  query := TFDQuery.Create(nil);
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

  periodsCnt := 0;
  try
    query.SQL.Text := 'SELECT count(1) cnt FROM periods';
    query.Open();
    periodsCnt := query.FieldByName('cnt').AsInteger;
  except
    query.Close;
    query.SQL.Clear;
    raise;
  end;
  query.Close;
  query.SQL.Clear;

  if periodsCnt = 0 then
  begin
    query.ExecSQL('INSERT INTO periods(id, name) values (:id, :name)', [1, 'After life']);
    query.ExecSQL('INSERT INTO periods(id, name) values (:id, :name)', [2, 'Life']);
    query.ExecSQL('INSERT INTO periods(id, name) values (:id, :name)', [3, '5 years']);
    query.ExecSQL('INSERT INTO periods(id, name) values (:id, :name)', [4, 'Year']);
    query.ExecSQL('INSERT INTO periods(id, name) values (:id, :name)', [5, 'Half-year']);
    query.ExecSQL('INSERT INTO periods(id, name) values (:id, :name)', [6, 'Quarter']);
    query.ExecSQL('INSERT INTO periods(id, name) values (:id, :name)', [7, 'Month']);
    query.ExecSQL('INSERT INTO periods(id, name) values (:id, :name)', [8, 'Week']);
    query.ExecSQL('INSERT INTO periods(id, name) values (:id, :name)', [9, 'Day']);
  end;

end;

destructor TPlanDB.Destroy;
begin
  query.Free;
  FDConn.Close;
  FDConn.Free;
  inherited Destroy;
end;

function TPlanDB.loadDomains(): TDomainList;
var
  domain: TDomain;
begin
  try
    query.SQL.Text := 'SELECT id, name, active, num FROM domains WHERE active = 1 ORDER BY num ASC';
    query.Open();

    result := TDomainList.Create;

    while not query.Eof do
    begin
      domain := TDomain.Create(TRecordState.Nothing);
      domain.id := query.FieldByName('id').AsInteger;
      domain.name := query.FieldByName('name').AsString;
      domain.num := query.FieldByName('num').AsInteger;
      domain.active := query.FieldByName('active').AsBoolean;
      result.Add(domain);
      query.Next;
    end;

  except
    query.Close;
    query.SQL.Clear;
    raise;
  end;

  query.Close;
  query.SQL.Clear;
end;

function TPlanDB.loadPeriods(): TPeriodList;
var
  period: TPeriod;
begin
  try
    query.SQL.Text := 'SELECT id, name, active FROM periods ORDER BY id ASC';
    query.Open();

    result := TPeriodList.Create;

    while not query.Eof do
    begin
      period := TPeriod.Create(TRecordState.Nothing);
      period.id := query.FieldByName('id').AsInteger;
      period.name := query.FieldByName('name').AsString;
      period.active := query.FieldByName('active').AsBoolean;
      result.Add(period);
      query.Next;
    end;

  except
    query.Close;
    query.SQL.Clear;
    raise;
  end;

  query.Close;
  query.SQL.Clear;
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
          query.ParamByName('name').AsString := domain.name;
          query.ParamByName('num').AsInteger := domain.num;
          query.Execute;
          query.Params.Clear;
          query.SQL.Clear;
        end;
        TRecordState.Deleted:
        begin
          query.SQL.Text := 'UPDATE domains SET active = 0 WHERE id = :id';
          query.ParamByName('id').AsInteger := domain.id;
          query.Execute;
          query.Params.Clear;
          query.SQL.Clear;
        end;
        TRecordState.Updated:
        begin
          query.SQL.Text := 'UPDATE domains SET name = :name, num = :num WHERE id = :id';
          query.ParamByName('name').AsString := domain.name;
          query.ParamByName('num').AsInteger := domain.num;
          query.ParamByName('id').AsInteger := domain.id;
          query.Execute;
          query.Params.Clear;
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
          query.ParamByName('active').AsBoolean := period.active;
          query.ParamByName('id').AsInteger := period.id;
          query.Execute;
          query.Params.Clear;
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
