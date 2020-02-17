unit Unit3;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.TabControl,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.Layouts, FMX.ListBox, System.Rtti, FMX.Edit;

type
  TProcClick = procedure(Sender: TObject) of object;

  TfrmSettings = class(TForm)
    TabControl1: TTabControl;
    tiColumns: TTabItem;
    tiRows: TTabItem;
    Panel1: TPanel;
    btnSave: TButton;
    btnCancel: TButton;
    btnColCreate: TButton;
    procedure updateColsPositions();
    procedure changeColsPos(Sender: TObject; Step: Integer);
    procedure btnCancelClick(Sender: TObject);
    procedure btnColCreateClick(Sender: TObject);
    procedure btnColDeleteClick(Sender: TObject);
    procedure btnColUpClick(Sender: TObject);
    procedure btnColDownClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    colsList: TList;
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

procedure TfrmSettings.updateColsPositions();
var
  i, colCount: Integer;
  p: TPanel;
  b: TButton;
  j, childCount: Integer;

begin
  colCount := colsList.Count - 1;
  for i:= 0 to colCount do
  begin
    p := colsList.Items[i];
    p.Position.Y := i * panelHeight;

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
  iOld, iNew: Integer;
begin
  b := Sender as TButton;
  p := b.Parent as TPanel;

  iOld := colsList.IndexOf(p);
  iNew := iOld + Step;
  colsList.Move(iOld, iNew);

  updateColsPositions();
end;

procedure TfrmSettings.FormCreate(Sender: TObject);
begin
  colsList := TList.Create;
end;

procedure TfrmSettings.btnCancelClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TfrmSettings.btnColCreateClick(Sender: TObject);
var
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
  p.Parent := tiColumns;
  p.Height := panelHeight;

  createButton('Delete', btnColDeleteClick);
  createButton('Down', btnColDownClick);
  createButton('Up', btnColUpClick);

  e := TEdit.Create(self);
  e.Visible := true;
  e.Align := TAlignLayout.Client;
  e.Parent := p;
  e.Height := p.Height;

  colsList.Add(p);
  updateColsPositions();
end;

procedure TfrmSettings.btnColDeleteClick(Sender: TObject);
var
  b: TButton;
  p: TPanel;
begin
  b := Sender as TButton;
  p := b.Parent as TPanel;

  colsList.Delete(colsList.IndexOf(p));
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
