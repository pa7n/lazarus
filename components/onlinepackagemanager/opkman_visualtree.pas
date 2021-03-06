{
 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.        *
 *                                                                         *
 ***************************************************************************

 Author: Balázs Székely
 Abstract:
   Implementation of the visual tree, which displays the package sructure
   downloaded from the remote repository.
}
unit opkman_visualtree;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Menus, Dialogs, Forms, LCLIntf, contnrs,
  PackageIntf, Buttons, opkman_VirtualTrees, opkman_common, opkman_serializablepackages;


type
  PData = ^TData;
  TData = record
    DataType: Integer;
    Repository: String;
    PackageState: TPackageState;
    PackageName: String;
    PackageDisplayName: String;
    Category: String;
    PackageFileName: String;
    Version: String;
    InstalledVersion: String;
    UpdateVersion: String;
    Description: String;
    Author: String;
    LazCompatibility: String;
    FPCCompatibility: String;
    SupportedWidgetSet: String;
    PackageType: TPackageType;
    Dependencies: String;
    License: String;
    RepositoryFileName: String;
    RepositoryFileSize: Int64;
    RepositoryFileHash: String;
    RepositoryDate: TDate;
    HomePageURL: String;
    DownloadURL: String;
    DownloadZipURL: String;
    ForceUpadate: Boolean;
    HasUpdate: Boolean;
    SVNURL: String;
    IsInstalled: Boolean;
    ButtonID: Integer;
    Button: TSpeedButton;
  end;

  TFilterBy = (fbPackageName, fbPackageFileName, fbPackageCategory, fbPackageState,
               fbVersion, fbDescription, fbAuthor, fbLazCompatibility, fbFPCCompatibility,
               fbSupportedWidgetsets, fbPackageType, fbDependecies, fbLicense);

  { TVisualTree }
  TOnChecking = procedure(Sender: TObject; const AIsAllChecked: Boolean) of object;
  TVisualTree = class
  private
    FVST: TVirtualStringTree;
    FHoverNode: PVirtualNode;
    FHoverColumn: Integer;
    FLink: String;
    FLinkClicked: Boolean;
    FSortCol: Integer;
    FSortDir: opkman_VirtualTrees.TSortDirection;
    FCheckingNodes: Boolean;
    FOnChecking: TOnChecking;
    FOnChecked: TNotifyEvent;
    procedure VSTBeforeCellPaint(Sender: TBaseVirtualTree;
      TargetCanvas: TCanvas; Node: PVirtualNode; {%H-}Column: TColumnIndex;
      {%H-}CellPaintMode: TVTCellPaintMode; CellRect: TRect; var {%H-}ContentRect: TRect);
    procedure VSTChecking(Sender: TBaseVirtualTree; {%H-}Node: PVirtualNode;
      var NewState: TCheckState; var {%H-}Allowed: Boolean);
    procedure VSTChecked(Sender: TBaseVirtualTree; {%H-}Node: PVirtualNode);
    procedure VSTCompareNodes(Sender: TBaseVirtualTree; Node1,
      Node2: PVirtualNode; Column: TColumnIndex; var Result: Integer);
    procedure VSTGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode;
      {%H-}Kind: TVTImageKind; Column: TColumnIndex; var {%H-}Ghosted: Boolean;
      var ImageIndex: Integer);
    procedure VSTGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; {%H-}TextType: TVSTTextType; var CellText: String);
    procedure VSTHeaderClick(Sender: TVTHeader; Column: TColumnIndex;
      Button: TMouseButton; {%H-}Shift: TShiftState; {%H-}X, {%H-}Y: Integer);
    procedure VSTPaintText(Sender: TBaseVirtualTree;
      const TargetCanvas: TCanvas; Node: PVirtualNode; {%H-}Column: TColumnIndex;
      {%H-}TextType: TVSTTextType);
    procedure VSTFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure VSTMouseMove(Sender: TObject; {%H-}Shift: TShiftState; X, Y: Integer);
    procedure VSTMouseDown(Sender: TObject; Button: TMouseButton; {%H-}Shift: TShiftState; X, Y: Integer);
    procedure VSTGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
      var LineBreakStyle: TVTTooltipLineBreakStyle; var HintText: String);
    procedure VSTAfterCellPaint(Sender: TBaseVirtualTree;  {%H-}TargetCanvas: TCanvas;
      Node: PVirtualNode; Column: TColumnIndex; const {%H-}CellRect: TRect);
    procedure VSTCollapsed(Sender: TBaseVirtualTree; {%H-}Node: PVirtualNode);
    procedure VSTExpanding(Sender: TBaseVirtualTree; {%H-}Node: PVirtualNode; var {%H-}Allowed: Boolean);
    procedure VSTCollapsing(Sender: TBaseVirtualTree; {%H-}Node: PVirtualNode; var {%H-}Allowed: Boolean);
    procedure VSTOnDblClick(Sender: TObject);
    procedure VSTScroll(Sender: TBaseVirtualTree; {%H-}DeltaX, {%H-}DeltaY: Integer);
    function GetDisplayString(const AStr: String): String;
    function IsAllChecked(const AChecking: PVirtualNode): Boolean;
    procedure ButtonClick(Sender: TObject);
    procedure ShowButtons;
    procedure HideButtons;
    function TranslateCategories(const AStr: String): String;
  public
    constructor Create(const AParent: TWinControl; const AImgList: TImageList;
      APopupMenu: TPopupMenu);
    destructor Destroy; override;
  public
    procedure PopulateTree;
    procedure CheckNodes(const Checked: Boolean);
    procedure FilterTree(const AFilterBy: TFilterBy; const AText: String; const AExtraParam: Integer = -1);
    procedure ResetFilter;
    procedure ExpandEx;
    procedure CollapseEx;
    procedure GetPackageList;
    procedure UpdatePackageStates;
    procedure UpdatePackageUStatus;
    function ResolveDependencies: TModalResult;
  published
    property OnChecking: TOnChecking read FOnChecking write FOnChecking;
    property OnChecked: TNotifyEvent read FOnChecked write FOnChecked;
    property VST: TVirtualStringTree read FVST;
  end;

var
  VisualTree: TVisualTree = nil;

implementation
uses opkman_const, opkman_options, opkman_packagedetailsfrm;

{ TVisualTree }

constructor TVisualTree.Create(const AParent: TWinControl; const AImgList: TImageList;
  APopupMenu: TPopupMenu);
begin
  FVST := TVirtualStringTree.Create(nil);
  with FVST do
   begin
     Parent := AParent;
     Align := alClient;
     Anchors := [akLeft, akTop, akRight];
     Images := AImgList;
     PopupMenu := APopupMenu;
     Color := clBtnFace;
     DefaultNodeHeight := 25;
     Indent := 22;
     TabOrder := 1;
     DefaultText := '';
     Header.AutoSizeIndex := 4;
     Header.Height := 25;
     with Header.Columns.Add do
     begin
       Position := 0;
       Width := 250;
       Text := rsMainFrm_VSTHeaderColumn_PackageName;
     end;
     with Header.Columns.Add do
     begin
       Position := 1;
       Alignment := taCenter;
       Width := 80;
       Options := Options - [coResizable];
       Text := rsMainFrm_VSTHeaderColumn_Installed;
     end;
     with Header.Columns.Add do
     begin
       Position := 2;
       Alignment := taCenter;
       Width := 85;
       Options := Options - [coResizable];
       Text := rsMainFrm_VSTHeaderColumn_Repository;
     end;
     with Header.Columns.Add do
     begin
       Position := 3;
       Alignment := taCenter;
       Width := 80;
       Options := Options - [coResizable];
       Text := rsMainFrm_VSTHeaderColumn_Update;
     end;
     with Header.Columns.Add do
     begin
        Position := 4;
        Width := 280;
        Options := Options - [coResizable];
        Text := rsMainFrm_VSTHeaderColumn_Data;
      end;
     with Header.Columns.Add do
     begin
        Position := 5;
        Width := 25;
        Options := Options - [coResizable];
        Text := rsMainFrm_VSTHeaderColumn_Button;
        Options := Options - [coResizable];
      end;
     Header.Options := [hoAutoResize, hoColumnResize, hoRestrictDrag, hoShowSortGlyphs, hoVisible, hoAutoSpring];
     {$IFDEF LCLCarbon}
     Header.Options := Header.Options - [hoShowSortGlyphs];
     {$ENDIF}
     Header.SortColumn := 0;
     HintMode := hmHint;
     ShowHint := True;
     TabOrder := 2;
     TreeOptions.MiscOptions := [toCheckSupport, toFullRepaintOnResize, toInitOnSave, toToggleOnDblClick, toWheelPanning];
     TreeOptions.PaintOptions := [toHideFocusRect, toAlwaysHideSelection, toPopupMode, toShowButtons, toShowDropmark, toShowRoot, toThemeAware, toUseBlendedImages];
     TreeOptions.SelectionOptions := [toFullRowSelect, toRightClickSelect];
     TreeOptions.AutoOptions := [toAutoTristateTracking];
     OnBeforeCellPaint := @VSTBeforeCellPaint;
     OnChecking := @VSTChecking;
     OnChecked := @VSTChecked;
     OnCompareNodes := @VSTCompareNodes;
     OnGetText := @VSTGetText;
     OnPaintText := @VSTPaintText;
     OnGetImageIndex := @VSTGetImageIndex;
     OnHeaderClick := @VSTHeaderClick;
     OnMouseMove := @VSTMouseMove;
     OnMouseDown := @VSTMouseDown;
     OnDblClick := @VSTOnDblClick;
     OnGetHint := @VSTGetHint;
     OnAfterCellPaint := @VSTAfterCellPaint;
     OnCollapsed := @VSTCollapsed;
     OnExpanding := @VSTExpanding;
     OnCollapsing := @VSTCollapsing;
     OnScroll := @VSTScroll;
     OnFreeNode := @VSTFreeNode;
   end;
end;

destructor TVisualTree.Destroy;
begin
  FVST.Free;
  inherited Destroy;
end;

procedure TVisualTree.PopulateTree;

  procedure CreateButton(AUniqueID: Integer; AData: PData);
  begin
    AData^.Button := TSpeedButton.Create(FVST);
    AData^.Button.Caption := '...';
    AData^.Button.Parent := FVST;
    AData^.Button.Visible := True;
    AData^.Button.Tag := AUniqueID;
    AData^.Button.OnClick := @ButtonClick;
    AData^.ButtonID := AUniqueID;
  end;
var
  I, J: Integer;
  RootNode, Node, ChildNode, GrandChildNode: PVirtualNode;
  RootData, Data, ChildData, GrandChildData: PData;
  PackageFile: TPackageFile;
  UniqueID: Integer;
begin
  FVST.OnExpanding := nil;
  FVST.OnCollapsed := nil;
  FVST.OnCollapsing := nil;
  try
    FVST.Clear;
    FVST.NodeDataSize := SizeOf(TData);
    UniqueID := 0;
    //add repository(DataType = 0)
    RootNode := FVST.AddChild(nil);
    RootData := FVST.GetNodeData(RootNode);
    RootData^.Repository := Options.RemoteRepository;
    RootData^.DataType := 0;
    for I := 0 to SerializablePackages.Count - 1 do
    begin
       //add package(DataType = 1)
       Node := FVST.AddChild(RootNode);
       Node^.CheckType := ctTriStateCheckBox;
       Data := FVST.GetNodeData(Node);
       Data^.PackageName := SerializablePackages.Items[I].Name;
       Data^.PackageDisplayName := SerializablePackages.Items[I].DisplayName;
       Data^.PackageState := SerializablePackages.Items[I].PackageState;
       Data^.DataType := 1;
       Data^.HasUpdate := False;
       for J := 0 to SerializablePackages.Items[I].PackageFiles.Count - 1 do
       begin
         //add packagefiles(DataType = 2)
         PackageFile := TPackageFile(SerializablePackages.Items[I].PackageFiles.Items[J]);
         ChildNode := FVST.AddChild(Node);
         ChildNode^.CheckType := ctTriStateCheckBox;
         ChildData := FVST.GetNodeData(ChildNode);
         ChildData^.PackageFileName := PackageFile.Name;
         ChildData^.InstalledVersion := PackageFile.InstalledFileVersion;
         ChildData^.UpdateVersion := PackageFile.UpdateVersion;
         ChildData^.Version := PackageFile.VersionAsString;
         ChildData^.PackageState := PackageFile.PackageState;
         ChildData^.DataType := 2;
         //add description(DataType = 3)
         GrandChildNode := FVST.AddChild(ChildNode);
         GrandChildData := FVST.GetNodeData(GrandChildNode);
         GrandChildData^.Description := PackageFile.Description;
         GrandChildData^.DataType := 3;
         Inc(UniqueID);
         CreateButton(UniqueID, GrandChildData);
         //add author(DataType = 4)
         GrandChildNode := FVST.AddChild(ChildNode);
         GrandChildData := FVST.GetNodeData(GrandChildNode);
         GrandChildData^.Author := PackageFile.Author;
         GrandChildData^.DataType := 4;
         //add lazcompatibility(DataType = 5)
         GrandChildNode := FVST.AddChild(ChildNode);
         GrandChildData := FVST.GetNodeData(GrandChildNode);
         GrandChildData^.LazCompatibility := PackageFile.LazCompatibility;
         GrandChildData^.DataType := 5;
         //add fpccompatibility(DataType = 6)
         GrandChildNode := FVST.AddChild(ChildNode);
         GrandChildData := FVST.GetNodeData(GrandChildNode);
         GrandChildData^.FPCCompatibility := PackageFile.FPCCompatibility;
         GrandChildData^.DataType := 6;
         //add widgetset(DataType = 7)
         GrandChildNode := FVST.AddChild(ChildNode);
         GrandChildData := FVST.GetNodeData(GrandChildNode);
         GrandChildData^.SupportedWidgetSet := PackageFile.SupportedWidgetSet;
         GrandChildData^.DataType := 7;
         //add packagetype(DataType = 8)
         GrandChildNode := FVST.AddChild(ChildNode);
         GrandChildData := FVST.GetNodeData(GrandChildNode);
         GrandChildData^.PackageType := PackageFile.PackageType;
         GrandChildData^.DataType := 8;
         //add license(DataType = 9)
         GrandChildNode := FVST.AddChild(ChildNode);
         GrandChildData := FVST.GetNodeData(GrandChildNode);
         GrandChildData^.License := PackageFile.License;
         GrandChildData^.DataType := 9;
         Inc(UniqueID);
         CreateButton(UniqueID, GrandChildData);
         //add dependencies(DataType = 10)
         GrandChildNode := FVST.AddChild(ChildNode);
         GrandChildData := FVST.GetNodeData(GrandChildNode);
         GrandChildData^.Dependencies := PackageFile.DependenciesAsString;
         GrandChildData^.DataType := 10;
       end;
       //add miscellaneous(DataType = 11)
       ChildNode := FVST.AddChild(Node);
       ChildData := FVST.GetNodeData(ChildNode);
       ChildData^.DataType := 11;
       //add category(DataType = 12)
       GrandChildNode := FVST.AddChild(ChildNode);
       GrandChildData := FVST.GetNodeData(GrandChildNode);
       GrandChildData^.Category := SerializablePackages.Items[I].Category;
       GrandChildData^.DataType := 12;
       //add Repository Filename(DataType = 13)
       GrandChildNode := FVST.AddChild(ChildNode);
       GrandChildData := FVST.GetNodeData(GrandChildNode);
       GrandChildData^.RepositoryFileName := SerializablePackages.Items[I].RepositoryFileName;
       GrandChildData^.DataType := 13;
       //add Repository Filesize(DataType = 14)
       GrandChildNode := FVST.AddChild(ChildNode);
       GrandChildData := FVST.GetNodeData(GrandChildNode);
       GrandChildData^.RepositoryFileSize := SerializablePackages.Items[I].RepositoryFileSize;
       GrandChildData^.DataType := 14;
       //add Repository Hash(DataType = 15)
       GrandChildNode := FVST.AddChild(ChildNode);
       GrandChildData := FVST.GetNodeData(GrandChildNode);
       GrandChildData^.RepositoryFileHash := SerializablePackages.Items[I].RepositoryFileHash;
       GrandChildData^.DataType := 15;
       //add Repository Date(DataType = 16)
       GrandChildNode := FVST.AddChild(ChildNode);
       GrandChildData := FVST.GetNodeData(GrandChildNode);
       GrandChildData^.RepositoryDate := SerializablePackages.Items[I].RepositoryDate;
       GrandChildData^.DataType := 16;
       FVST.Expanded[ChildNode] := True;
       //add HomePageURL(DataType = 17)
       GrandChildNode := FVST.AddChild(ChildNode);
       GrandChildData := FVST.GetNodeData(GrandChildNode);
       GrandChildData^.HomePageURL := SerializablePackages.Items[I].HomePageURL;
       GrandChildData^.DataType := 17;
       //add DownloadURL(DataType = 18)
       GrandChildNode := FVST.AddChild(ChildNode);
       GrandChildData := FVST.GetNodeData(GrandChildNode);
       GrandChildData^.DownloadURL := SerializablePackages.Items[I].DownloadURL;
       GrandChildData^.DataType := 18;
       //add SVNURL(DataType = 19)
       GrandChildNode := FVST.AddChild(ChildNode);
       GrandChildData := FVST.GetNodeData(GrandChildNode);
       GrandChildData^.SVNURL := SerializablePackages.Items[I].SVNURL;
       GrandChildData^.DataType := 19;
    end;
    FVST.SortTree(0, opkman_VirtualTrees.sdAscending);
    ExpandEx;
    CollapseEx;
  finally
    FVST.OnCollapsing := @VSTCollapsing;
    FVST.OnCollapsed := @VSTCollapsed;
    FVST.OnExpanding := @VSTExpanding;
  end;
  HideButtons;
end;

function TVisualTree.IsAllChecked(const AChecking: PVirtualNode): Boolean;
var
  Node: PVirtualNode;
begin
  Result := True;
  Node := FVST.GetFirst;
  while Assigned(Node) do
  begin
    if (FVST.CheckState[Node] = csUncheckedNormal) and (Node <> AChecking) then
    begin
      Result := False;
      Break;
    end;
    Node := FVST.GetNext(Node);
  end;
end;

procedure TVisualTree.ButtonClick(Sender: TObject);
var
  Node, ParentNode: PVirtualNode;
  Data, ParentData: PData;
  ButtonID: Integer;
  Text: String;
  FrmCaption: String;
begin
  ButtonID := (Sender as TSpeedButton).Tag;
  Node := VST.GetFirst;
  while Assigned(Node) do
  begin
    Data := VST.GetNodeData(Node);
    if Data^.ButtonID = ButtonID then
    begin
      ParentNode := Node^.Parent;
      ParentData := VST.GetNodeData(ParentNode);
      case Data^.DataType of
        3: begin
             Text := Data^.Description;
             FrmCaption := rsMainFrm_VSTText_Desc + ' "' + ParentData^.PackageFileName  + '"';
           end;
        9: begin
             Text := Data^.License;
             FrmCaption := rsMainFrm_VSTText_Lic  + ' "' + ParentData^.PackageFileName  + '"';
           end;
      end;
      Break;
    end;
    Node := VST.GetNext(Node);
  end;

  PackageDetailsFrm := TPackageDetailsFrm.Create(TForm(FVST.Parent.Parent));
  try
    PackageDetailsFrm.Caption := FrmCaption;
    PackageDetailsFrm.mDetails.Text := Text;
    PackageDetailsFrm.ShowModal;
  finally
    PackageDetailsFrm.Free;
  end;
end;

procedure TVisualTree.ShowButtons;
var
  Node: PVirtualNode;
  Data: PData;
  R: TRect;
  Text: String;
begin
  Node := VST.GetFirst;
  while Assigned(Node) do
  begin
    Data := VST.GetNodeData(Node);
    if Assigned(Data^.Button) then
    begin
      case Data^.DataType of
        3: Text := Data^.Description;
        9: Text := Data^.License;
      end;
      R := FVST.GetDisplayRect(Node, 5, false);
      Data^.Button.Visible := ((R.Bottom > FVST.Top) and (R.Bottom < FVST.Top + FVST.Height)) and
                              (vsVisible in Node^.States) and
                              (Trim(Text) <> '');
      FVST.InvalidateNode(Node);
    end;
    Node := VST.GetNext(Node);
  end;
end;

procedure TVisualTree.HideButtons;
var
  Node: PVirtualNode;
  Data: PData;
begin
  Node := VST.GetFirst;
  while Assigned(Node) do
  begin
    Data := VST.GetNodeData(Node);
    if Assigned(Data^.Button) then
      Data^.Button.Visible := False;
    Node := VST.GetNext(Node);
  end;
end;

function TVisualTree.TranslateCategories(const AStr: String): String;
var
  SL: TStringList;
  I, J: Integer;
  Str: String;
begin
  if Categories[0] = CategoriesEng[0] then
  begin
    Result := AStr;
    Exit;
  end;
  Result := '';
  SL := TStringList.Create;
  try
    SL.Delimiter := ',';
    SL.StrictDelimiter := True;
    SL.DelimitedText := AStr;
    for I := 0 to SL.Count - 1 do
    begin
      Str := Trim(SL.Strings[I]);
      for J := 0 to MaxCategories - 1 do
      begin
        if Str = CategoriesEng[J] then
        begin
          if Result = '' then
            Result := Categories[J]
          else
            Result := Result + ', ' + Categories[J];
          Break;
        end;
      end;
    end;
  finally
    SL.Free;
  end;
  if Result = '' then
    Result := AStr;
end;

procedure TVisualTree.VSTScroll(Sender: TBaseVirtualTree; DeltaX,
  DeltaY: Integer);
begin
  ShowButtons;
end;

procedure TVisualTree.VSTCollapsed(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  ShowButtons;
end;

procedure TVisualTree.VSTExpanding(Sender: TBaseVirtualTree;
  Node: PVirtualNode; var Allowed: Boolean);
begin
  HideButtons;
end;

procedure TVisualTree.VSTCollapsing(Sender: TBaseVirtualTree;
  Node: PVirtualNode; var Allowed: Boolean);
begin
  HideButtons;
end;

procedure TVisualTree.VSTAfterCellPaint(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  const CellRect: TRect);
var
  Data: PData;
  R: TRect;
  Text: String;
begin
  if Column = 5 then
  begin
    Data := FVST.GetNodeData(Node);
    if Assigned(Data^.Button)  then
    begin
      R := FVST.GetDisplayRect(Node, Column, false);
      Data^.Button.Left   := R.Left + 1;
      Data^.Button.Width  := R.Right - R.Left -2;
      Data^.Button.Top    := R.Top + 1;
      Data^.Button.Height := R.Bottom - R.Top - 2;
      case Data^.DataType of
        3: Text := Data^.Description;
        9: Text := Data^.License;
      end;
      Data^.Button.Visible := ((R.Bottom > FVST.Top) and (R.Bottom < FVST.Top + FVST.Height)) and (Trim(Text) <> '');
    end;
  end;
end;

procedure TVisualTree.CheckNodes(const Checked: Boolean);
var
  Node: PVirtualNode;
begin
  FCheckingNodes := True;
  try
    Node := FVST.GetFirst;
    while Assigned(Node) do
    begin
      if Checked then
        FVST.CheckState[Node] := csCheckedNormal
      else
        FVST.CheckState[Node] := csUncheckedNormal;
      Node := FVST.GetNext(Node);
    end;
  finally
    FCheckingNodes := False;
  end;
end;

procedure TVisualTree.FilterTree(const AFilterBy: TFilterBy; const AText:
  String; const AExtraParam: Integer = -1);

  function IsAtLeastOneChildVisible(const ANode: PVirtualNode): Boolean;
  var
    Level: Integer;
    Node: PVirtualNode;
    Data: PData;
  begin
    Result := False;
    Level := FVST.GetNodeLevel(ANode);
    Node := FVST.GetFirstChild(ANode);
    while Assigned(Node) do
    begin
      Data := FVST.GetNodeData(Node);
      case Level of
        0: if (vsVisible in Node^.States) then
           begin
             Result := True;
             Break;
           end;
        1: if (vsVisible in Node^.States) and (Data^.DataType = 2) then
           begin
             Result := True;
             Break;
           end;
      end;
      Node := FVST.GetNextSibling(Node);
    end;
  end;

  procedure HideShowParentNodes(const ANode: PVirtualNode; AShow: Boolean);
  var
    Level: Integer;
    RepositoryNode, PackageNode, PackageFileNode: PVirtualNode;
  begin
    RepositoryNode := nil;
    PackageNode := nil;
    PackageFileNode := nil;
    Level := FVST.GetNodeLevel(ANode);
    case Level of
      1: begin
           RepositoryNode := ANode^.Parent;
           PackageNode := ANode;
         end;
      2: begin
           RepositoryNode := ANode^.Parent^.Parent;
           PackageNode := ANode^.Parent;
           PackageFileNode := ANode;
         end;
      3: begin
           RepositoryNode := ANode^.Parent^.Parent^.Parent;
           PackageNode := ANode^.Parent^.Parent;
           PackageFileNode := ANode^.Parent;
         end;
    end;
    if Level = 1 then
    begin
      if AShow then
        FVST.IsVisible[RepositoryNode] := True
      else
        if not IsAtLeastOneChildVisible(RepositoryNode) then
          FVST.IsVisible[RepositoryNode] := False;
    end
    else if Level = 2 then
    begin
      if AShow then
      begin
        FVST.IsVisible[PackageNode] := True;
        FVST.IsVisible[RepositoryNode] := True;
      end
      else
      begin
        if not IsAtLeastOneChildVisible(PackageNode) then
        begin
          FVST.IsVisible[PackageNode] := False;
          HideShowParentNodes(PackageNode, AShow);
        end;
      end;
    end
    else if Level = 3 then
    begin
      if AShow then
      begin
        FVST.IsVisible[PackageFileNode] := True;
        FVST.IsVisible[PackageNode] := True;
        FVST.IsVisible[RepositoryNode] := True;
      end
      else
      begin
        FVST.IsVisible[PackageFileNode] := False;
        HideShowParentNodes(PackageFileNode, AShow);
      end;
    end;
  end;

  procedure FilterNode(Node: PVirtualNode; ADataText: String);
  var
    P: Integer;
  begin
    P := Pos(UpperCase(AText), UpperCase(ADataText));
    if P > 0 then
      FVST.IsVisible[Node] := True
    else
      FVST.IsVisible[Node] := False;
    if AText = 'PackageCategory' then //special case for categories
    begin
      if (P > 0) then
      begin
        FVST.IsVisible[Node^.Parent^.Parent] := True;
        FVST.IsVisible[Node^.Parent^.Parent^.Parent] := True;
      end
      else
      begin
        FVST.IsVisible[Node^.Parent^.Parent] := False;
        if not IsAtLeastOneChildVisible(Node^.Parent^.Parent^.Parent) then
          FVST.IsVisible[Node^.Parent^.Parent^.Parent] := False
      end;
    end
    else
      HideShowParentNodes(Node, P > 0)
  end;

var
  Node: PVirtualNode;
  Data: PData;
begin
  Node := FVST.GetFirst;
  while Assigned(Node) do
  begin
    Data := FVST.GetNodeData(Node);
    case AFilterBy of
      fbPackageName:
        begin
          if (Data^.DataType = 1) then
            FilterNode(Node, Data^.PackageName);
        end;
      fbPackageFileName:
        begin
          if (Data^.DataType = 2) then
            FilterNode(Node, Data^.PackageFileName);
        end;
      fbPackageCategory:
        begin
          if Data^.DataType = 12 then
          begin
            if Pos(UpperCase(CategoriesEng[AExtraParam]), UpperCase(Data^.Category)) > 0 then
              FilterNode(Node, 'PackageCategory')
            else
              FilterNode(Node, '')
          end;
        end;
     fbPackageState:
       begin
         if Data^.DataType = 2 then
         begin
           if Data^.PackageState = TPackageState(AExtraParam) then
             FilterNode(Node, 'PackageState')
           else
             FilterNode(Node, '');
         end;
       end;
     fbVersion:
       begin
         if Data^.DataType = 2 then
           FilterNode(Node, Data^.Version);
       end;
     fbDescription:
       begin
         if Data^.DataType = 3 then
           FilterNode(Node, Data^.Description);
       end;
     fbAuthor:
       begin
         if Data^.DataType = 4 then
           FilterNode(Node, Data^.Author);
       end;
     fbLazCompatibility:
       begin
         if Data^.DataType = 5 then
           FilterNode(Node, Data^.LazCompatibility);
       end;
     fbFPCCompatibility:
       begin
         if Data^.DataType = 6 then
           FilterNode(Node, Data^.FPCCompatibility);
       end;
     fbSupportedWidgetsets:
       begin
         if Data^.DataType = 7 then
           FilterNode(Node, Data^.SupportedWidgetSet);
       end;
     fbPackageType:
       begin
         if Data^.DataType = 8 then
         begin
           if Data^.PackageType = TPackageType(AExtraParam) then
             FilterNode(Node, 'PackageType')
           else
             FilterNode(Node, '');
         end;
       end;
     fbLicense:
       begin
          if Data^.DataType = 9 then
           FilterNode(Node, Data^.License);
       end;
     fbDependecies:
       begin
          if Data^.DataType = 10 then
           FilterNode(Node, Data^.Dependencies);
       end;
   end;
   Node := FVST.GetNext(Node);
  end;
  HideButtons;
  Node := FVST.GetFirst;
  if Node <> nil then
    FVST.TopNode := Node;
end;

procedure TVisualTree.ResetFilter;
var
  Node: PVirtualNode;
begin
  Node := FVST.GetFirst;
  while Assigned(Node) do
  begin
    FVST.IsVisible[Node] := True;
    Node := FVST.GetNext(Node);
  end;
  Node := FVST.GetFirst;
  HideButtons;
  CollapseEx;
  if Node <> nil then
    FVST.TopNode := Node;
end;

procedure TVisualTree.ExpandEx;
var
  Node: PVirtualNode;
  Data: PData;
begin
  Node := FVST.GetFirst;
  while Assigned(Node) do
  begin
    Data := FVST.GetNodeData(Node);
    if (Data^.DataType = 0) or (Data^.DataType = 1) or (Data^.DataType = 11) then
      VST.Expanded[Node] := True;
    Node := FVST.GetNext(Node);
  end;
  Node := FVST.GetFirst;
  if Node <> nil then
    FVST.TopNode := Node;
end;

procedure TVisualTree.CollapseEx;
var
  Node: PVirtualNode;
  Data: PData;
begin
  FVST.FullCollapse;
  Node := FVST.GetFirst(True);
  while Assigned(Node) do
  begin
    Data := FVST.GetNodeData(Node);
    if (Data^.DataType = 0) or (Data^.DataType = 11) then
      VST.Expanded[Node] := True;
    Node := FVST.GetNext(Node);
  end;
end;

procedure TVisualTree.GetPackageList;
var
  Node: PVirtualNode;
  Data: PData;
  Package: TPackage;
  PackageFile: TPackageFile;
begin
  Node := FVST.GetFirst;
  while Assigned(Node) do
  begin
    Data := FVST.GetNodeData(Node);
    if Data^.DataType = 1 then
    begin
      Package := SerializablePackages.FindPackage(Data^.PackageName, fpbPackageName);
      if Package <> nil then
      begin
        if (FVST.CheckState[Node] = csCheckedNormal) or (FVST.CheckState[Node] = csMixedNormal) then
          Package.Checked := True
        else if FVST.CheckState[Node] = csUncheckedNormal then
          Package.Checked := False
      end;
    end;
    if Data^.DataType = 2 then
    begin
      PackageFile := SerializablePackages.FindPackageFile(Data^.PackageFileName);
      if PackageFile <> nil then
      begin
        if FVST.CheckState[Node] = csCheckedNormal then
          PackageFile.Checked := True
        else if FVST.CheckState[Node] = csUncheckedNormal then
          PackageFile.Checked := False
      end;
    end;
    Node := FVST.GetNext(Node);
  end;
end;

procedure TVisualTree.UpdatePackageStates;
var
  Node: PVirtualNode;
  Data: PData;
  Package: TPackage;
  PackageFile: TPackageFile;
begin
  SerializablePackages.GetPackageStates;
  Node := FVST.GetFirst;
  while Assigned(Node) do
  begin
    Data := FVST.GetNodeData(Node);
    if (Data^.DataType = 1) then
    begin
      Package := SerializablePackages.FindPackage(Data^.PackageName, fpbPackageName);
      if Package <> nil then
      begin
        Data^.PackageState := Package.PackageState;
        FVST.ReinitNode(Node, False);
        FVST.RepaintNode(Node);
      end;
    end;
    if Data^.DataType = 2 then
    begin
      PackageFile := SerializablePackages.FindPackageFile(Data^.PackageFileName);
      if PackageFile <> nil then
      begin
        Data^.InstalledVersion := PackageFile.InstalledFileVersion;
        Data^.PackageState := PackageFile.PackageState;
        FVST.ReinitNode(Node, False);
        FVST.RepaintNode(Node);
      end;
    end;
    Node := FVST.GetNext(Node);
  end;
end;

procedure TVisualTree.UpdatePackageUStatus;
var
  Node, ParentNode: PVirtualNode;
  Data, ParentData: PData;
  Package: TPackage;
  PackageFile: TPackageFile;
begin
  Node := FVST.GetFirst;
  while Assigned(Node) do
  begin
    Data := FVST.GetNodeData(Node);
    if (Data^.DataType = 1) then
    begin
      Package := SerializablePackages.FindPackage(Data^.PackageName, fpbPackageName);
      if Package <> nil then
      begin
        Data^.DownloadZipURL := Package.DownloadZipURL;
        Data^.ForceUpadate := Package.ForceNotify;
        FVST.ReinitNode(Node, False);
        FVST.RepaintNode(Node);
        if Package.ForceNotify then
        begin
          Data^.HasUpdate := True;
          FVST.ReinitNode(Node, False);
          FVST.RepaintNode(Node);
        end;
      end;
    end;
    if Data^.DataType = 2 then
    begin
      PackageFile := SerializablePackages.FindPackageFile(Data^.PackageFileName);
      if PackageFile <> nil then
      begin
        Data^.UpdateVersion := PackageFile.UpdateVersion;
        FVST.ReinitNode(Node, False);
        FVST.RepaintNode(Node);
        if Data^.UpdateVersion > Data^.InstalledVersion then
        begin
          ParentNode := Node^.Parent;
          ParentData := FVST.GetNodeData(ParentNode);
          ParentData^.HasUpdate := True;
          FVST.ReinitNode(ParentNode, False);
          FVST.RepaintNode(ParentNode);
        end;
      end;
    end;
    Node := FVST.GetNext(Node);
  end;
end;

procedure TVisualTree.VSTBeforeCellPaint(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  CellPaintMode: TVTCellPaintMode; CellRect: TRect; var ContentRect: TRect);
var
  Data, ParentData: PData;
  ParentNode: PVirtualNode;
begin
  Data := Sender.GetNodeData(Node);
  if (Data^.DataType = 0) or (Data^.DataType = 1) or (Data^.DataType = 2) then
  begin
    if (Node = Sender.FocusedNode) then
    begin
      case Column of
        0: begin
             if Data^.DataType = 0 then
               TargetCanvas.Brush.Color := $00E5E5E5 //00D8D8D8
             else
               TargetCanvas.Brush.Color := $00E5E5E5;
             TargetCanvas.FillRect(CellRect);
             TargetCanvas.Brush.Color := FVST.Colors.FocusedSelectionColor;
             TargetCanvas.FillRect(ContentRect)
           end
        else
           begin
             TargetCanvas.Brush.Color := FVST.Colors.FocusedSelectionColor;
             TargetCanvas.FillRect(CellRect)
           end;
      end;
    end
    else
    begin
      case Column of
        0, 1, 2, 4, 5:
          begin
            if Data^.DataType = 0 then
              TargetCanvas.Brush.Color := $00E5E5E5 //00D8D8D8
            else
              TargetCanvas.Brush.Color := $00E5E5E5;
          end;
        3:begin
            TargetCanvas.Brush.Color := $00E5E5E5;
            if (Data^.DataType = 2) then
            begin
              ParentNode := Node^.Parent;
              ParentData := FVST.GetNodeData(ParentNode);
              if (Data^.UpdateVersion > Data^.InstalledVersion) or (ParentData^.ForceUpadate) then
                ParentData^.HasUpdate := True
              else
                ParentData^.HasUpdate := False;
            end
          end;
      end;
      TargetCanvas.FillRect(CellRect);
    end;
  end
  else
  begin
    if (Node = Sender.FocusedNode) then
    begin
      TargetCanvas.Brush.Color := FVST.Colors.FocusedSelectionColor;
      if Column = 0 then
        TargetCanvas.FillRect(ContentRect)
      else
        TargetCanvas.FillRect(CellRect);
    end
    else
    begin
      TargetCanvas.Brush.Style := bsClear;
      TargetCanvas.FillRect(CellRect);
    end;
  end;
end;

procedure TVisualTree.VSTChecking(Sender: TBaseVirtualTree; Node: PVirtualNode;
  var NewState: TCheckState; var Allowed: Boolean);
begin
  if FCheckingNodes then
    Exit;
  if NewState = csUncheckedNormal then
  begin
    if Assigned(FOnChecking) then
      FOnChecking(Self, False);
  end
  else if NewState = csCheckedNormal then
  begin
    if IsAllChecked(Node) then
      FOnChecking(Self, True);
  end;
end;

procedure TVisualTree.VSTChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  if Assigned(FOnChecked) then
    FOnChecked(Self);
end;

function TVisualTree.ResolveDependencies: TModalResult;
var
  Node, NodeSearch: PVirtualNode;
  Data, DataSearch: PData;
  Msg: String;
  PackageList: TObjectList;
  PackageFileName: String;
  DependencyPackage: TPackageFile;
  I: Integer;
begin
  Result := mrNone;
  Node := FVST.GetFirst;
  while Assigned(Node) do
  begin
    if VST.CheckState[Node] = csCheckedNormal then
    begin
      Data := FVST.GetNodeData(Node);
      if Data^.DataType = 2 then
      begin
        PackageList := TObjectList.Create(True);
        try
          SerializablePackages.GetPackageDependencies(Data^.PackageFileName, PackageList, True, True);
          for I := 0 to PackageList.Count - 1 do
          begin
            PackageFileName := TPackageDependency(PackageList.Items[I]).PackageFileName + '.lpk';
            NodeSearch := VST.GetFirst;
            while Assigned(NodeSearch) do
            begin
              if NodeSearch <> Node then
              begin
                DataSearch := FVST.GetNodeData(NodeSearch);
                if DataSearch^.DataType = 2 then
                begin
                  DependencyPackage := SerializablePackages.FindPackageFile(DataSearch^.PackageFileName);
                  if (FVST.CheckState[NodeSearch] <> csCheckedNormal) and
                       (UpperCase(DataSearch^.PackageFileName) = UpperCase(PackageFileName)) and
                         ((SerializablePackages.IsDependencyOk(TPackageDependency(PackageList.Items[I]), DependencyPackage)) and
                           ((not (DependencyPackage.PackageState = psInstalled)) or ((DependencyPackage.PackageState = psInstalled) and (not (SerializablePackages.IsInstalledVersionOk(TPackageDependency(PackageList.Items[I]), DataSearch^.InstalledVersion)))))) then
                  begin
                    if (Result = mrNone) or (Result = mrYes) then
                    begin
                      Msg := rsProgressFrm_lbPackage_Caption + ' "' + Data^.PackageFileName + '" ' + rsMainFrm_rsPackageDependency0 + ' "' + DataSearch^.PackageFileName + '". ' + rsMainFrm_rsPackageDependency1;
                      Result := MessageDlgEx(Msg, mtConfirmation, [mbYes, mbYesToAll, mbNo, mbNoToAll, mbCancel], TForm(FVST.Parent.Parent));
                      if Result in [mrNo, mrNoToAll] then
                        MessageDlgEx(rsMainFrm_rsPackageDependency2, mtInformation, [mbOk], TForm(FVST.Parent.Parent));
                      if (Result = mrNoToAll) or (Result = mrCancel) then
                        Exit;
                    end;
                    if Result in [mrYes, mrYesToAll] then
                    begin
                      FVST.CheckState[NodeSearch] := csCheckedNormal;
                      FVST.ReinitNode(NodeSearch, False);
                      FVST.RepaintNode(NodeSearch);
                    end;
                  end;
                end;
              end;
              NodeSearch := FVST.GetNext(NodeSearch);
            end;
          end;
        finally
          PackageList.Free;
        end;
      end;
    end;
    Node := FVST.GetNext(Node);
  end;
end;

procedure TVisualTree.VSTCompareNodes(Sender: TBaseVirtualTree; Node1,
  Node2: PVirtualNode; Column: TColumnIndex; var Result: Integer);
var
  Data1: PData;
  Data2: PData;
begin
  Data1 := Sender.GetNodeData(Node1);
  Data2 := Sender.GetNodeData(Node2);
  case Column of
    0: begin
         if (Data1^.DataType = 1) and (Data1^.DataType = 1) then
           Result := CompareText(Data1^.PackageName, Data2^.PackageName);
         if (Data1^.DataType < Data2^.DataType) then
           Result := 0
         else if (Data1^.DataType > Data2^.DataType) then
           Result := 1
         else if (Data1^.DataType = 2) and (Data1^.DataType = 2) then
           Result := CompareText(Data1^.PackageFileName, Data2^.PackageFileName);
       end;
    3: if (Data1^.DataType = 1) and (Data1^.DataType = 1) then
         Result := Ord(Data2^.HasUpdate) - Ord(Data1^.HasUpdate);
  end;
end;

procedure TVisualTree.VSTGetImageIndex(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
  var Ghosted: Boolean; var ImageIndex: Integer);
var
  Data: PData;
begin
  Data := FVST.GetNodeData(Node);
  if Column = 0 then
    ImageIndex := Data^.DataType
end;

function TVisualTree.GetDisplayString(const AStr: String): String;
var
  SL: TStringList;
  I: Integer;
begin
  Result := '';
  SL := TStringList.Create;
  try
    SL.Text := AStr;
    for I := 0 to SL.Count - 1 do
      if Result = '' then
        Result := SL.Strings[I]
      else
        Result := Result + ' ' + SL.Strings[I];
  finally
    SL.Free;
  end;
end;

procedure TVisualTree.VSTGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
var
  Data: PData;
begin
  Data := FVST.GetNodeData(Node);
  if Column = 0 then
  begin
    case Data^.DataType of
      0: CellText := Data^.Repository;
      1: if Trim(Data^.PackageDisplayName) = '' then
           CellText := Data^.PackageName
         else
           CellText := Data^.PackageDisplayName;
      2: CellText := Data^.PackageFileName;
      3: CellText := rsMainFrm_VSTText_Description;
      4: CellText := rsMainFrm_VSTText_Author;
      5: CellText := rsMainFrm_VSTText_LazCompatibility;
      6: CellText := rsMainFrm_VSTText_FPCCompatibility;
      7: CellText := rsMainFrm_VSTText_SupportedWidgetsets;
      8: CellText := rsMainFrm_VSTText_Packagetype;
      9: CellText := rsMainFrm_VSTText_License;
     10: CellText := rsMainFrm_VSTText_Dependecies;
     11: CellText := rsMainFrm_VSTText_PackageInfo;
     12: CellText := rsMainFrm_VSTText_Category;
     13: CellText := rsMainFrm_VSTText_RepositoryFilename;
     14: CellText := rsMainFrm_VSTText_RepositoryFileSize;
     15: CellText := rsMainFrm_VSTText_RepositoryFileHash;
     16: CellText := rsMainFrm_VSTText_RepositoryFileDate;
     17: CellText := rsMainFrm_VSTText_HomePageURL;
     18: CellText := rsMainFrm_VSTText_DownloadURL;
     19: CellText := rsMainFrm_VSTText_SVNURL;
    end;
  end
  else if Column = 1 then
  begin
    if Data^.InstalledVersion = '' then
      Data^.InstalledVersion := '-';
    if Data^.DataType = 2 then
      CellText := Data^.InstalledVersion
    else
      CellText := '';
  end
  else if Column = 2 then
  begin
    if Data^.DataType = 2 then
      CellText := Data^.Version
    else
      CellText := '';
  end
  else if Column = 3 then
  begin
    case Data^.DataType of
      1: if Data^.HasUpdate then
           CellText := 'NEW';
      2: begin
           if Data^.UpdateVersion = '' then
             Data^.UpdateVersion := '-';
           if Data^.DataType = 2 then
             CellText := Data^.UpdateVersion
           else
             CellText := '';
         end
      else
        CellText := '';
    end
  end
  else if Column = 4 then
  begin
    case Data^.DataType of
      0: CellText := '';
      1: CellText := '';
      2: case Ord(Data^.PackageState) of
           0: CellText := rsMainFrm_VSTText_PackageState0;
           1: CellText := rsMainFrm_VSTText_PackageState1;
           2: CellText := rsMainFrm_VSTText_PackageState2;
           3: begin
                Data^.IsInstalled := Data^.InstalledVersion >= Data^.UpdateVersion;
                if Data^.IsInstalled then
                  CellText := rsMainFrm_VSTText_PackageState4
                else
                  CellText := rsMainFrm_VSTText_PackageState3
              end;
         end;
      3: CellText := GetDisplayString(Data^.Description);
      4: CellText := Data^.Author;
      5: CellText := Data^.LazCompatibility;
      6: CellText := Data^.FPCCompatibility;
      7: CellText := Data^.SupportedWidgetSet;
      8: case Data^.PackageType of
           ptRunAndDesignTime: CellText := rsMainFrm_VSTText_PackageType0;
           ptDesignTime:       CellText := rsMainFrm_VSTText_PackageType1;
           ptRunTime:          CellText := rsMainFrm_VSTText_PackageType2;
           ptRunTimeOnly:      CellText := rsMainFrm_VSTText_PackageType3;
         end;
      9: CellText := GetDisplayString(Data^.License);
     10: CellText := Data^.Dependencies;
     11: CellText := '';
     12: CellText := TranslateCategories(Data^.Category);
     13: CellText := Data^.RepositoryFileName;
     14: CellText := FormatSize(Data^.RepositoryFileSize);
     15: CellText := Data^.RepositoryFileHash;
     16: CellText := FormatDateTime('YYYY.MM.DD', Data^.RepositoryDate);
     17: CellText := Data^.HomePageURL;
     18: CellText := Data^.DownloadURL;
     19: CellText := Data^.SVNURL;
    end;
  end
  else if Column = 5 then
  begin
    CellText := '';
  end
end;

procedure TVisualTree.VSTHeaderClick(Sender: TVTHeader; Column: TColumnIndex;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Column <> 0) and (Column <> 3) then
    Exit;
  if Button = mbLeft then
  begin
    with Sender, Treeview do
    begin
      if (SortColumn = NoColumn) or (SortColumn <> Column) then
      begin
        SortColumn    := Column;
        SortDirection := opkman_VirtualTrees.sdAscending;
      end
      else
      begin
        if SortDirection = opkman_VirtualTrees.sdAscending then
          SortDirection := opkman_VirtualTrees.sdDescending
        else
          SortDirection := opkman_VirtualTrees.sdAscending;
        FSortDir := SortDirection;
      end;
      SortTree(SortColumn, SortDirection, False);
      FSortCol := Sender.SortColumn;
    end;
  end;
end;

procedure TVisualTree.VSTPaintText(Sender: TBaseVirtualTree;
  const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  TextType: TVSTTextType);
var
  Data, ParentData: PData;
begin
  Data := FVST.GetNodeData(Node);
  case column of
    3: begin

         case Data^.DataType of
           1: TargetCanvas.Font.Style := TargetCanvas.Font.Style + [fsBold];
           2: begin
                ParentData := FVST.GetNodeData(Node^.Parent);
                if (Data^.UpdateVersion > Data^.InstalledVersion) or (ParentData^.HasUpdate) then
                  TargetCanvas.Font.Style := TargetCanvas.Font.Style + [fsBold]
                else
                  TargetCanvas.Font.Style := TargetCanvas.Font.Style - [fsBold];
              end;
         end;
         if Node <> Sender.FocusedNode then
           TargetCanvas.Font.Color := clBlack
         else
           TargetCanvas.Font.Color := clWhite;
       end;
    4: begin
         if (FHoverNode = Node) and (FHoverColumn = Column) and ((Data^.DataType = 17) or (Data^.DataType = 18)) then
         begin
           TargetCanvas.Font.Style := TargetCanvas.Font.Style + [fsUnderline];
           if  Node <> Sender.FocusedNode then
             TargetCanvas.Font.Color := clBlue
           else
             TargetCanvas.Font.Color := clWhite;
         end
         else if (Data^.DataType = 2) and (Data^.IsInstalled) then
         begin
           TargetCanvas.Font.Style := TargetCanvas.Font.Style + [fsBold];
           if  Node <> Sender.FocusedNode then
             TargetCanvas.Font.Color := clGreen
           else
             TargetCanvas.Font.Color := clWhite;
         end;
       end
    else
      begin
        if  Node <> Sender.FocusedNode then
          TargetCanvas.Font.Color := FVST.Font.Color
        else
          TargetCanvas.Font.Color := clWhite;
      end;
  end;
end;

procedure TVisualTree.VSTFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
var
  Data: PData;
begin
  Data := FVST.GetNodeData(Node);
  if Assigned(Data^.Button) then
    Data^.Button.Visible := False;
  Finalize(Data^);
end;

procedure TVisualTree.VSTMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
 I, L, R: Integer;
begin
  FHoverColumn := -1;
  FHoverNode:= VST.GetNodeAt(X, Y);
  for I := 0 to VST.Header.Columns.Count - 1 do
  begin
    VST.Header.Columns.GetColumnBounds(I, L, R);
    if (X >= L) and (X <= R) then
    begin
      FHoverColumn := I;
      Break;
    end;
  end;
end;

procedure TVisualTree.VSTMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
 Node: PVirtualNode;
 Data: PData;
 I, L, R: Integer;
begin
  if Button = mbLeft then
  begin
    Node := FVST.GetNodeAt(X, Y);
    if Node <> nil then
    begin
      Data := FVST.GetNodeData(Node);
      if (Data^.DataType = 17) or (Data^.DataType = 18) then
      begin
        for I := 0 to VST.Header.Columns.Count - 1 do
         begin
           VST.Header.Columns.GetColumnBounds(I, L, R);
           if (X >= L) and (X <= R) and (I = 4) then
           begin
             FLinkClicked := True;
             if (Data^.DataType = 17) and (Trim(Data^.HomePageURL) <> '') then
             begin
               FLink := Data^.HomePageURL;
               Break
             end
             else if (Data^.DataType = 18) and (Trim(Data^.DownloadURL) <> '') then
             begin
               FLink := Data^.DownloadURL;
               Break;
             end;
           end;
         end;
      end;
    end;
  end;
end;

procedure TVisualTree.VSTGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle;
  var HintText: String);
var
  Data: PData;
begin
  Data := FVST.GetNodeData(Node);
  if (Column <> 4) then
    Exit;
  LineBreakStyle := hlbForceMultiLine;
  case Data^.DataType of
    3: HintText := Data^.Description;
   10: HintText := Data^.License;
   else
       HintText := '';
  end;
end;

procedure TVisualTree.VSTOnDblClick(Sender: TObject);
begin
  if FLinkClicked then
  begin
    FLinkClicked := False;
    FHoverColumn := -1;
    FHoverNode := nil;
    OpenDocument(FLink);
  end;
end;


end.

