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
    procedure addDomainItem(domain: TDomain);
    procedure updateColsPositions();
    procedure changeColsPos(Sender: TObject; Step: Integer);
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
  private
    { Private declarations }
    domainItemList: TDomainItemList;
  public
    { Public declarations }
  end;

const
  panelHeight: Integer = 30;

var
  frmSettings: TfrmSettings;

implementation

{$R *.fmx}
{$R *.LgXhdpiTb.fmx ANDROID}
{$R *.SmXhdpiPh.fmx ANDROID}
{$R *.Windows.fmx MSWINDOWS}
{$R *.LgXhdpiPh.fmx ANDROID}

procedure TfrmSettings.addDomainItem(domain: TDomain);
var
  domainItem: TDomainItem;
  p: TPanel;
  e: TEdit;

  procedure createButton(name: string; procClick: TProcClick);
  var
    b: TButton;
  begin
    b := TButton.Create(self);
    b.Text := name;
    b.Visible := true;
    b.Align := TAlignLayout.MostRight;
    b.Parent := pCols;
    b.Height := p.Height;
    b.Width := 56;
    b.OnClick := procClick;
    b.TagString := name;
  end;

begin
  p := TPanel.Create(self);
  p.Align := TAlignLayout.Horizontal;
  p.Visible := true;
  p.Parent := parent;
  p.Height := panelHeight;

  createButton('Delete', btnColDeleteClick);
  createButton('Down', btnColDownClick);
  createButton('Up', btnColUpClick);

  e := TEdit.Create(self);
  e.Visible := true;
  e.Align := TAlignLayout.Client;
  e.Parent := p;
  e.Height := p.Height;

  domainItem.domain := domain;
  domainItem.panel := p;
  domainItemList.Add(domainItem);
  updateColsPositions();
end;

procedure TfrmSettings.updateColsPositions();
var
  i, colCount: Integer;
  p: TPanel;
  b: TButton;
  j, childCount: Integer;

begin
  colCount := domainItemList.Count;
  sbCols.Max := panelHeight * colCount - pCols.Height;

  dec(colCount);
  for i:= 0 to colCount do
  begin
    p := domainItemList.Items[i].panel;
    p.Position.Y := i * panelHeight - sbCols.Value;

    childCount := p.ChildrenCount - 1;
    for j:= 0 to childCount do
    begin
      if p.Children.Items[j].TagString = 'Up' then begin
        b := p.Children.Items[j] as TButton;
        b.Enabled := i <> 0;
      end
      else if p.Children.Items[j].TagString = 'Down' then begin
        b := p.Children.Items[j] as TButton;
        b.Enabled := i <> colCount;
      end;
    end;
  end;
end;

procedure TfrmSettings.changeColsPos(Sender: TObject; Step: Integer);
var
  b: TButton;
  p: TPanel;
  i, k: Integer;
begin
  b := Sender as TButton;
  p := b.Parent as TPanel;

  k := domainItemList.Count - 1;
  for i := 0 to k do
  begin
    if domainItemList.Items[i].panel = p then
    begin
      domainItemList.Move(i, i + Step);
      break;
    end;
  end;

  updateColsPositions();
end;

procedure TfrmSettings.FormCreate(Sender: TObject);
begin
  domainItemList := TDomainItemList.Create;
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
  Self.Close;
end;

procedure TfrmSettings.btnColCreateClick(Sender: TObject);
var
  domain: TDomain;
begin
  addDomainItem(domain);
  updateColsPositions();
end;

procedure TfrmSettings.btnColDeleteClick(Sender: TObject);
var
  b: TButton;
  p: TPanel;
  i, k: Integer;
begin
  b := Sender as TButton;
  p := b.Parent as TPanel;

  k := domainItemList.Count - 1;
  for i := 0 to k do
  begin
    if domainItemList.Items[i].panel = p then
    begin
      domainItemList.Delete(i);
      break;
    end;
  end;
  p.Destroy;

  updateColsPositions();
end;

procedure TfrmSettings.btnColUpClick(Sender: TObject);
begin
  changeColsPos(Sender, -1);
end;

procedure TfrmSettings.btnColDownClick(Sender: TObject);
begin
  changeColsPos(Sender, 1);
end;

end.
