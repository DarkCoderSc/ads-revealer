(*******************************************************************************

    Author:
        ->  Jean-Pierre LESUEUR (@DarkCoderSc)
        https://github.com/DarkCoderSc
        https://gist.github.com/DarkCoderSc
        https://www.phrozen.io/

*******************************************************************************)

unit UntMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees, Vcl.Menus, Vcl.ComCtrls, UntEnumFolderADSThread,
  UntDataStreamObject, System.ImageList, Vcl.ImgList;

type
  TTreeData = record
    Name        : String;
    DataStreams : TEnumDataStream; // Can be NULL (Childs)
    DataStream  : TDataStream;     // Can be NULL (Parents)
  end;
  PTreeData = ^TTreeData;

  TFrmMain = class(TForm)
    VST: TVirtualStringTree;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Quit1: TMenuItem;
    OpenFolder1: TMenuItem;
    N1: TMenuItem;
    StatusBar1: TStatusBar;
    PopupMenu1: TPopupMenu;
    CopyfiletocurrentADS1: TMenuItem;
    BackupcurrentADS1: TMenuItem;
    N2: TMenuItem;
    DeleteCurrentADSItem1: TMenuItem;
    About1: TMenuItem;
    ImageList1: TImageList;
    OpenDialog1: TOpenDialog;
    procedure Quit1Click(Sender: TObject);
    procedure VSTFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex);
    procedure VSTGetNodeDataSize(Sender: TBaseVirtualTree;
      var NodeDataSize: Integer);
    procedure OpenFolder1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure VSTGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure About1Click(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure CopyfiletocurrentADS1Click(Sender: TObject);
    procedure VSTFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure BackupcurrentADS1Click(Sender: TObject);
    procedure DeleteCurrentADSItem1Click(Sender: TObject);
  private
    FEnumFolderADS : TEnumFolderADS;
    FLastPath      : String;

    {@M}
    procedure TerminateThread();
    function CountNodes(ALevel : Integer) : Int64;
    procedure RefreshList();
  public
    {@M}
    procedure RefreshStatusBar();
  end;

var
  FrmMain: TFrmMain;

implementation

uses UntUtils, ShellAPI;

{$R *.dfm}

procedure TFrmMain.RefreshList();
begin
  if NOT DirectoryExists(FLastPath) then
    Exit();
  ///

  self.TerminateThread();

  FEnumFolderADS := TEnumFolderADS.Create(FLastPath);
end;

procedure TFrmMain.RefreshStatusBar();
begin
  self.StatusBar1.Panels.Items[0].Text := Format('File Count: %d', [CountNodes(0)]);
  self.StatusBar1.Panels.Items[1].Text := Format('ADS Files Count: %d', [CountNodes(1)]);
end;

procedure TFrmMain.About1Click(Sender: TObject);
begin
  ShellExecute(0, 'open', 'https://www.phrozen.io', nil, nil, SW_SHOW);
end;

procedure TFrmMain.BackupcurrentADS1Click(Sender: TObject);
var AData     : PTreeData;
    ARet      : Boolean;
    ADestPath : String;
    i         : Integer;
begin
  AData := VST.GetNodeData(VST.FocusedNode);
  if NOT Assigned(AData) then
    Exit();

  ADestPath := BrowseForFolder('Backup ADS file(s) to target folder.');

  if Assigned(AData^.DataStreams) then begin
    // TODO: Multi Error Handling
    for I := 0 to AData^.DataStreams.Items.count -1 do begin
      ARet := AData^.DataStreams.Items.Items[i].BackupTo(ADestPath);
    end;
  end else if Assigned(AData^.DataStream) then begin
    ARet := AData^.DataStream.BackupTo(ADestPath);
  end;

  if ARet then
    Application.MessageBox('File(s) successfully backuped from target ADS.', 'Backup from ADS', MB_ICONINFORMATION)
  else
    Application.MessageBox('Could not backup file(s) from target ADS.', 'Backup from ADS', MB_ICONERROR);
end;

procedure TFrmMain.CopyfiletocurrentADS1Click(Sender: TObject);
var AData : PTreeData;
    ARet  : Boolean;
begin
  if NOT self.OpenDialog1.Execute() then
    Exit();

  AData := VST.GetNodeData(VST.FocusedNode);
  if NOT Assigned(AData) then
    Exit();

  if Assigned(AData^.DataStreams) then begin
    ARet := AData^.DataStreams.CopyToAlternateDataStream(self.OpenDialog1.FileName);
  end else if Assigned(AData^.DataStream) then begin
    ARet := AData^.DataStream.CopyFileTo(self.OpenDialog1.FileName);
  end;

  if ARet then
    Application.MessageBox('File successfully copied to target ADS.', 'Copy to ADS', MB_ICONINFORMATION)
  else
    Application.MessageBox('Could not copy file to target ADS.', 'Copy to ADS', MB_ICONERROR);

  ///
  self.RefreshList();
end;

function TFrmMain.CountNodes(ALevel : Integer) : Int64;
var ANode : PVirtualNode;

  procedure Check();
  begin
    if (VST.GetNodeLevel(ANode) = ALevel) then
      Inc(result);
  end;

begin
  result := 0;
  ///

  ANode := VST.GetFirst(True);
  if (ANode = nil) then
    Exit();

  Check();

  while True do begin
    ANode := VST.GetNext(ANode);
    if (ANode = nil) then
      break;

    Check();
  end;
end;

procedure TFrmMain.DeleteCurrentADSItem1Click(Sender: TObject);
var AData : PTreeData;
    ARet  : Boolean;
    i     : Integer;
begin
  AData := VST.GetNodeData(VST.FocusedNode);
  if NOT Assigned(AData) then
    Exit();

  if Assigned(AData^.DataStreams) then begin
    // TODO: Multi Error Handling
    for I := 0 to AData^.DataStreams.Items.count -1 do begin
      ARet := AData^.DataStreams.Items.Items[i].Delete();
    end;
  end else if Assigned(AData^.DataStream) then begin
    ARet := AData^.DataStream.Delete();
  end;

  if ARet then
    Application.MessageBox('File(s) successfully deleted from target ADS.', 'Delete from ADS', MB_ICONINFORMATION)
  else
    Application.MessageBox('Could not delete file(s) from target ADS.', 'Delete from ADS', MB_ICONERROR);

  self.RefreshList();
end;

procedure TFrmMain.TerminateThread();
var AExitCode : Cardinal;
begin
  if Assigned(FEnumFolderADS) then begin
    GetExitCodeThread(FEnumFolderADS.handle, AExitCode);
    if (AExitCode = STILL_ACTIVE) then begin
      FEnumFolderADS.Terminate();
      FEnumFolderADS.WaitFor();
    end;
  end;

  ///
  FEnumFolderADS := nil;
end;

procedure TFrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  self.TerminateThread();
end;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  FEnumFolderADS := nil;
  FLastPath      := '';
end;

procedure TFrmMain.OpenFolder1Click(Sender: TObject);
begin
  FLastPath := BrowseForFolder('Search for Alternate Data Stream in Folder:');

  self.RefreshList();
end;

procedure TFrmMain.PopupMenu1Popup(Sender: TObject);
var ANode : PVirtualNode;
begin
  ANode := VST.FocusedNode;

  self.CopyfiletocurrentADS1.Enabled := Assigned(ANode);
  self.BackupcurrentADS1.Enabled     := Assigned(ANode);
  self.DeleteCurrentADSItem1.Enabled := Assigned(ANode);

end;

procedure TFrmMain.Quit1Click(Sender: TObject);
begin
  self.Close();
end;

procedure TFrmMain.VSTFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex);
begin
  self.VST.Refresh();
end;

procedure TFrmMain.VSTFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
var AData : PTreeData;
begin
  AData := VST.GetNodeData(Node);
  if Assigned(AData) then begin
    if Assigned(AData^.DataStreams) then
      FreeAndNil(AData^.DataStreams); // Important
  end;
end;

procedure TFrmMain.VSTGetNodeDataSize(Sender: TBaseVirtualTree;
  var NodeDataSize: Integer);
begin
  NodeDataSize := SizeOf(TTreeData);
end;

procedure TFrmMain.VSTGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
var AData : PTreeData;
begin
  AData := VST.GetNodeData(Node);
  if NOT Assigned(AData) then
    Exit();
  ///

  CellText := '';

  case Column of
    0 : begin
      if Assigned(AData^.DataStream) then
        CellText := AData^.DataStream.StreamName
      else
        CellText := AData^.Name;
    end;

    1 : begin
      if Assigned(AData^.DataStream) then
        CellText := FormatSize(AData^.DataStream.StreamSize);
    end;

    2 : begin
      if Assigned(AData^.DataStream) then
        CellText := AData^.DataStream.StreamPath;
    end;
  end;
end;

end.
