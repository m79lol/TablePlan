unit Unit3;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.TabControl,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.Layouts, System.Rtti,
  FMX.Edit, Plan.DBTools, Generics.Collections;

type
  TProcClick = procedure(Sender: TObject) of object;

  TDomainItem = record
    panel: TPanel;
    domain: TDomain;
  end;
  TDomainItemList = TList<TDomainItem>;

  TfrmSettings = class(TForm)
    tc: TTabControl;
    tiColumns: TTabItem;
    tiRows: TTabItem;
    pBtns: TPanel;
    btnSave: TButton;
    btnCancel: TButton;
    btnColCreate: TButton;
    sbCols: TScrollBar;
    pCols: TPanel;
    pRowsInner: TPanel;
    cbAfter: TCheckBox;
    cbLife: TCheckBox;
    cb5Years: TCheckBox;
    cbYear: TCheckBox;
    cbHalf: TCheckBox;
    cbQuarter: TCheckBox;
    cbMonth: TCheckBox;
    cbWeek: TCheckBox;
    cbDays: TCheckBox;
    sbRows: TScrollBar;
    pRows: TPanel;
    function findDomainItemBy(const panel: TPanel): integer;
    procedure addDomainItem(const domain: TDomain);
    procedure updateColsPositions();
    procedure changeColsPos(Sender: TObject; const Step: Integer);
    procedure btnCancelClick(Sender: TObject);
    procedure btnColCreateClick(Sender: TObject);
    procedure btnColDeleteClick(Sender: TObject);
    procedure btnColUpClick(Sender: TObject);
    procedure btnColDownClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure sbColsChange(Sender: TObject);
    procedure sbRowsChange(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnSaveClick(Sender: TObject);
    procedure edColChange(Sender: TObject);

  private
    { Private declarations }
    domainItems: TDomainItemList;
    deletedDomains: TDomainList;
  public
    { Public declarations }
  end;

const
    panelHeight: Integer = 30;
    btnUpName: string = 'Up';
    btnDownName: string = 'Down';
    btnDeleteName: string = 'Delete';

var
  frmSettings: TfrmSettings;

implementation

{$R *.fmx}
{$R *.LgXhdpiTb.fmx ANDROID}
{$R *.SmXhdpiPh.fmx ANDROID}
{$R *.Windows.fmx MSWINDOWS}
{$R *.LgXhdpiPh.fmx ANDROID}

function TfrmSettings.findDomainItemBy(const panel: TPanel): integer;
var
  i, k: integer;
begin
  k := domainItems.Count - 1;
  for i := 0 to k do
  begin
    if domainItems.Items[i].panel = panel then
    begin
      result := i;
      exit;
    end;
  end;
  raise Exception.Create('Can''t find domain item by panel');
end;

procedure TfrmSettings.addDomainItem(const domain: TDomain);
var
  domainItem: TDomainItem;
  p: TPanel;
  e: TEdit;

  procedure createButton(const name: string; procClick: TProcClick);
  var
    b: TButton;
  begin
    b := TButton.Create(self);
    b.Text := name;
    b.Visible := true;
    b.Align := TAlignLayout.MostRight;
    b.Parent := p;
    b.Height := p.Height;
    b.Width := 56;
    b.OnClick := procClick;
    b.TagString := name;
  end;

begin
  p := TPanel.Create(self);
  p.Align := TAlignLayout.Horizontal;
  p.Visible := true;
  p.Parent := pCols;
  p.Height := panelHeight;

  createButton(btnDeleteName, btnColDeleteClick);
  createButton(btnDownName, btnColDownClick);
  createButton(btnUpName, btnColUpClick);

  e := TEdit.Create(self);
  e.Visible := true;
  e.Align := TAlignLayout.Client;
  e.Parent := p;
  e.Height := p.Height;
  e.Text := domain.name;
  e.OnChange := edColChange;

  domainItem.domain := domain;
  domainItem.panel := p;
  domainItems.Add(domainItem);
end;

procedure TfrmSettings.updateColsPositions();
var
  i, colCount: Integer;
  p: TPanel;
  b: TButton;
  j, childCount: Integer;

  domainItem: TDomainItem;

begin
  colCount := domainItems.Count;
  sbCols.Max := panelHeight * colCount - pCols.Height;

  dec(colCount);
  for i:= 0 to colCount do
  begin
    domainItem := domainItems.Items[i];
    p := domainItem.panel;
    p.Position.Y := i * panelHeight - sbCols.Value;

    childCount := p.ChildrenCount - 1;
    for j:= 0 to childCount do
    begin
      if p.Children.Items[j].TagString = btnUpName then begin
        b := p.Children.Items[j] as TButton;
        b.Enabled := i <> 0;
      end
      else if p.Children.Items[j].TagString = btnDownName then begin
        b := p.Children.Items[j] as TButton;
        b.Enabled := i <> colCount;
      end;
    end;

    domainItem.domain.num := i + 1;
    domainItems.Items[i] := domainItem;
  end;
end;

procedure TfrmSettings.changeColsPos(Sender: TObject; const step: Integer);
var
  b: TButton;
  p: TPanel;
  i: Integer;
  domainItem: TDomainItem;
begin
  b := Sender as TButton;
  p := b.Parent as TPanel;

  i := findDomainItemBy(p);
  domainItem := domainItems.Items[i];
  domainItem.domain.recstate := TRecordState.Updated;
  domainItems.Items[i] := domainItem;

  domainItems.Move(i, i + step);
  updateColsPositions();
end;

procedure TfrmSettings.edColChange(Sender: TObject);
var
  e: TEdit;
  p: TPanel;
  i: Integer;
  domainItem: TDomainItem;
begin
  e := Sender as TEdit;
  p := e.Parent as TPanel;

  i := findDomainItemBy(p);
  domainItem := domainItems.Items[i];
  domainItem.domain.recstate := TRecordState.Updated;
  domainItem.domain.name := e.Text;
  domainItems.Items[i] := domainItem;
end;

procedure TfrmSettings.FormClose(Sender: TObject; var Action: TCloseAction);
var
  i, k: integer;
begin
  k := domainItems.Count - 1;
  for i := 0 to k do
  begin
    domainItems.Items[i].panel.Destroy;
  end;
  deletedDomains.Clear;
  domainItems.Clear;
end;

procedure TfrmSettings.FormCreate(Sender: TObject);
begin
  domainItems := TDomainItemList.Create;
  deletedDomains := TDomainList.Create;
  sbCols.SmallChange := panelHeight;
  sbRows.SmallChange := panelHeight;
end;

procedure TfrmSettings.FormResize(Sender: TObject);
var
  isInnerBigger: boolean;
begin
  isInnerBigger := pRowsInner.Height > pRows.Height;
  sbRows.Enabled := isInnerBigger;
  sbRows.Visible := isInnerBigger;

  if isInnerBigger then
  begin
    sbRows.Max := pRowsInner.Height - pRows.Height;
  end
  else
  begin
    sbRows.Max := 0;
  end;
end;

procedure TfrmSettings.FormShow(Sender: TObject);
var
  domainList: TDomainList;
  i, k: integer;
begin
  domainList := db.loadDomains;
  k := domainList.Count - 1;
  for i := 0 to k do
  begin
    addDomainItem(domainList.Items[i]);
  end;
  updateColsPositions();
end;

procedure TfrmSettings.sbColsChange(Sender: TObject);
begin
  updateColsPositions();
end;

procedure TfrmSettings.sbRowsChange(Sender: TObject);
begin
  pRows.Position.Y := -sbRows.Value;
end;

procedure TfrmSettings.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmSettings.btnColCreateClick(Sender: TObject);
var
  domain: TDomain;
begin
  domain := TDomain.Create(TRecordState.New);
  addDomainItem(domain);
  updateColsPositions();
end;

procedure TfrmSettings.btnColDeleteClick(Sender: TObject);
var
  b: TButton;
  p: TPanel;
  i: Integer;
  domain: TDomain;
begin
  b := Sender as TButton;
  p := b.Parent as TPanel;

  i := findDomainItemBy(p);
  domain := domainItems.Items[i].domain;
  if domain.recstate <> TRecordState.New then
  begin
    domain.active := false;
    domain.recstate := TRecordState.Deleted;
    deletedDomains.Add(domain);
  end;
  domainItems.Delete(i);
  p.Destroy;

  updateColsPositions();
end;

procedure TfrmSettings.btnColUpClick(Sender: TObject);
begin
  changeColsPos(Sender, -1);
end;

procedure TfrmSettings.btnSaveClick(Sender: TObject);
var
  domains: TDomainList;
  i, k: integer;
begin
  domains := TDomainList.Create();

  k := deletedDomains.Count - 1;
  for i := 0 to k do
  begin
    domains.Add(deletedDomains.Items[i]);
  end;

  k := domainItems.Count - 1;
  for i := 0 to k do
  begin
    domains.Add(domainItems.Items[i].domain);
  end;

  db.saveDomains(domains);
  domains.Clear;
  Close;
end;

procedure TfrmSettings.btnColDownClick(Sender: TObject);
begin
  changeColsPos(Sender, 1);
end;

end.
