{
 Test with:
   ./testcodetools --format=plain --suite=TTestFindDeclaration
   ./testcodetools --format=plain --suite=TestFindDeclaration_Basic
   ./testcodetools --format=plain --suite=TestFindDeclaration_ClassOf
   ./testcodetools --format=plain --suite=TestFindDeclaration_With
   ./testcodetools --format=plain --suite=TestFindDeclaration_NestedClasses
   ./testcodetools --format=plain --suite=TestFindDeclaration_ClassHelper
   ./testcodetools --format=plain --suite=TestFindDeclaration_TypeHelper
   ./testcodetools --format=plain --suite=TestFindDeclaration_ObjCClass
   ./testcodetools --format=plain --suite=TestFindDeclaration_ObjCCategory
   ./testcodetools --format=plain --suite=TestFindDeclaration_Generics
   ./testcodetools --format=plain --suite=TestFindDeclaration_FileAtCursor

 FPC tests:
   ./testcodetools --format=plain --suite=TestFindDeclaration_FPCTests
   ./testcodetools --format=plain --suite=TestFindDeclaration_FPCTests --filemask=t*.pp
   ./testcodetools --format=plain --suite=TestFindDeclaration_FPCTests --filemask=tchlp41.pp
 Laz tests:
   ./testcodetools --format=plain --suite=TestFindDeclaration_LazTests
   ./testcodetools --format=plain --suite=TestFindDeclaration_LazTests --filemask=t*.pp
   ./testcodetools --format=plain --suite=TestFindDeclaration_LazTests --filemask=tdefaultproperty1.pp
}
unit TestFinddeclaration;

{$mode objfpc}{$H+}

{off $define VerboseFindDeclarationTests}

interface

uses
  Classes, SysUtils, CodeToolManager, ExprEval, CodeCache, BasicCodeTools,
  CustomCodeTool, CodeTree, FindDeclarationTool, KeywordFuncLists,
  IdentCompletionTool, FileProcs, LazLogger, LazFileUtils, fpcunit,
  testregistry, TestGlobals;

type

  { TTestFindDeclaration }

  TTestFindDeclaration = class(TTestCase)
  private
    procedure FindDeclarations(Filename: string);
    procedure TestFiles(Directory: string);
  published
    procedure TestFindDeclaration_Basic;
    procedure TestFindDeclaration_With;
    procedure TestFindDeclaration_ClassOf;
    procedure TestFindDeclaration_NestedClasses;
    procedure TestFindDeclaration_ClassHelper;
    procedure TestFindDeclaration_TypeHelper;
    procedure TestFindDeclaration_ObjCClass;
    procedure TestFindDeclaration_ObjCCategory;
    procedure TestFindDeclaration_Generics;
    procedure TestFindDeclaration_FileAtCursor;
    procedure TestFindDeclaration_FPCTests;
    procedure TestFindDeclaration_LazTests;
  end;

var
  BugsTestSuite: TTestSuite;
  FindDeclarationTestSuite: TTestSuite;

implementation

{ TTestFindDeclaration }

procedure TTestFindDeclaration.FindDeclarations(Filename: string);

  procedure PrependPath(Prefix: string; var Path: string);
  begin
    if Path<>'' then Path:='.'+Path;
    Path:=Prefix+Path;
  end;

  function NodeAsPath(Tool: TFindDeclarationTool; Node: TCodeTreeNode): string;
  begin
    Result:='';
    while Node<>nil do begin
      case Node.Desc of
      ctnTypeDefinition,ctnVarDefinition,ctnConstDefinition,ctnGenericParameter:
        PrependPath(GetIdentifier(@Tool.Src[Node.StartPos]),Result);
      ctnGenericType:
        PrependPath(GetIdentifier(@Tool.Src[Node.FirstChild.StartPos]),Result);
      ctnInterface,ctnUnit:
        PrependPath(Tool.GetSourceName(false),Result);
      ctnProcedure:
        PrependPath(Tool.ExtractProcName(Node,[]),Result);
      ctnProperty:
        PrependPath(Tool.ExtractPropName(Node,false),Result);
      //else debugln(['NodeAsPath ',Node.DescAsString]);
      end;
      Node:=Node.Parent;
    end;
    //debugln(['NodeAsPath ',Result]);
  end;

var
  Code: TCodeBuffer;
  Tool: TCodeTool;
  CommentP: Integer;
  p: Integer;
  ExpectedPath: String;
  PathPos: Integer;
  CursorPos, FoundCursorPos: TCodeXYPosition;
  FoundTopLine: integer;
  FoundTool: TFindDeclarationTool;
  FoundCleanPos: Integer;
  FoundNode: TCodeTreeNode;
  FoundPath: String;
  Src: String;
  NameStartPos, i, l, IdentifierStartPos: Integer;
  Marker, ExpectedType, NewType: String;
  IdentItem: TIdentifierListItem;
  ItsAKeyword, IsSubIdentifier: boolean;
  ExistingDefinition: TFindContext;
  ListOfPFindContext: TFPList;
  NewExprType: TExpressionType;
begin
  Filename:=TrimAndExpandFilename(Filename);
  {$IFDEF VerboseFindDeclarationTests}
  debugln(['TTestFindDeclaration.FindDeclarations File=',Filename]);
  {$ENDIF}
  Code:=CodeToolBoss.LoadFile(Filename,true,false);
  if Code=nil then
    raise Exception.Create('unable to load '+Filename);
  if not CodeToolBoss.Explore(Code,Tool,true) then begin
    AssertEquals('parse error '+CodeToolBoss.ErrorMessage,false,true);
    exit;
  end;
  CommentP:=1;
  Src:=Tool.Src;
  while CommentP<length(Src) do begin
    CommentP:=FindNextComment(Src,CommentP);
    if CommentP>length(Src) then break;
    p:=CommentP;
    CommentP:=FindCommentEnd(Src,CommentP,Tool.Scanner.NestedComments);
    if Src[p]<>'{' then continue;
    IdentifierStartPos:=p;
    inc(p);
    NameStartPos:=p;
    if not IsIdentStartChar[Src[p]] then continue;
    while (p<=length(Src)) and (IsIdentChar[Src[p]]) do inc(p);
    Marker:=copy(Src,NameStartPos,p-NameStartPos);
    if (p>length(Src)) or (Src[p]<>':') then begin
      AssertEquals('Expected : at '+Tool.CleanPosToStr(p,true),'declaration',Marker);
      continue;
    end;
    inc(p);
    PathPos:=p;
    while (IdentifierStartPos>1) and (IsIdentChar[Src[IdentifierStartPos-1]]) do
      dec(IdentifierStartPos);

    //debugln(['TTestFindDeclaration.FindDeclarations Marker="',Marker,'" params: ',dbgstr(Tool.Src,p,CommentP-p)]);
    if (Marker='declaration') then begin
      ExpectedPath:=copy(Src,PathPos,CommentP-1-PathPos);
      {$IFDEF VerboseFindDeclarationTests}
      debugln(['TTestFindDeclaration.FindDeclarations searching "',Marker,'" at ',Tool.CleanPosToStr(NameStartPos-1),' ExpectedPath=',ExpectedPath]);
      {$ENDIF}
      Tool.CleanPosToCaret(IdentifierStartPos,CursorPos);

      // test FindDeclaration
      if not CodeToolBoss.FindDeclaration(CursorPos.Code,CursorPos.X,CursorPos.Y,
        FoundCursorPos.Code,FoundCursorPos.X,FoundCursorPos.Y,FoundTopLine)
      then begin
        if ExpectedPath<>'' then
          AssertEquals('find declaration failed at '+Tool.CleanPosToStr(IdentifierStartPos,true)+': '+CodeToolBoss.ErrorMessage,true,false);
        continue;
      end else begin
        FoundTool:=CodeToolBoss.GetCodeToolForSource(FoundCursorPos.Code,true,true) as TFindDeclarationTool;
        FoundPath:='';
        if (FoundCursorPos.Y=1) and (FoundCursorPos.X=1) then begin
          // unit
          FoundPath:=ExtractFileNameOnly(FoundCursorPos.Code.Filename);
        end else begin
          FoundTool.CaretToCleanPos(FoundCursorPos,FoundCleanPos);
          FoundNode:=FoundTool.FindDeepestNodeAtPos(FoundCleanPos,true);
          //debugln(['TTestFindDeclaration.FindDeclarations Found: ',FoundTool.CleanPosToStr(FoundNode.StartPos,true)]);
          FoundPath:=NodeAsPath(FoundTool,FoundNode);
        end;
        //debugln(['TTestFindDeclaration.FindDeclarations FoundPath=',FoundPath]);
        AssertEquals('find declaration wrong at '+Tool.CleanPosToStr(IdentifierStartPos,true),LowerCase(ExpectedPath),LowerCase(FoundPath));
      end;

      // test identifier completion
      if (ExpectedPath<>'') then begin
        if not CodeToolBoss.GatherIdentifiers(CursorPos.Code,CursorPos.X,CursorPos.Y)
        then begin
          if ExpectedPath<>'' then
            AssertEquals('GatherIdentifiers failed at '+Tool.CleanPosToStr(IdentifierStartPos,true)+': '+CodeToolBoss.ErrorMessage,false,true);
          continue;
        end else begin
          i:=CodeToolBoss.IdentifierList.GetFilteredCount-1;
          while i>=0 do begin
            IdentItem:=CodeToolBoss.IdentifierList.FilteredItems[i];
            //debugln(['TTestFindDeclaration.FindDeclarations ',IdentItem.Identifier]);
            l:=length(IdentItem.Identifier);
            if ((l=length(ExpectedPath)) or (ExpectedPath[length(ExpectedPath)-l]='.'))
            and (CompareText(IdentItem.Identifier,RightStr(ExpectedPath,l))=0)
            then break;
            dec(i);
          end;
          AssertEquals('GatherIdentifiers misses "'+ExpectedPath+'" at '+Tool.CleanPosToStr(IdentifierStartPos,true),true,i>=0);
        end;
      end;
    end else if Marker='guesstype' then begin
      ExpectedType:=copy(Src,PathPos,CommentP-1-PathPos);
      {$IFDEF VerboseFindDeclarationTests}
      debugln(['TTestFindDeclaration.FindDeclarations "',Marker,'" at ',Tool.CleanPosToStr(NameStartPos-1),' ExpectedType=',ExpectedType]);
      {$ENDIF}
      Tool.CleanPosToCaret(IdentifierStartPos,CursorPos);

      // test GuessTypeOfIdentifier
      ListOfPFindContext:=nil;
      try
        if not CodeToolBoss.GuessTypeOfIdentifier(CursorPos.Code,CursorPos.X,CursorPos.Y,
          ItsAKeyword, IsSubIdentifier, ExistingDefinition, ListOfPFindContext,
          NewExprType, NewType)
        then begin
          if ExpectedType<>'' then
            AssertEquals('GuessTypeOfIdentifier failed at '+Tool.CleanPosToStr(IdentifierStartPos,true)+': '+CodeToolBoss.ErrorMessage,false,true);
          continue;
        end else begin
          //debugln(['TTestFindDeclaration.FindDeclarations FoundPath=',FoundPath]);
          AssertEquals('GuessTypeOfIdentifier wrong at '+Tool.CleanPosToStr(IdentifierStartPos,true),LowerCase(ExpectedType),LowerCase(NewType));
        end;
      finally
        FreeListOfPFindContext(ListOfPFindContext);
      end;

    end else begin
      AssertEquals('Unknown marker at '+Tool.CleanPosToStr(IdentifierStartPos,true),'declaration',Marker);
      continue;
    end;
  end;
end;

procedure TTestFindDeclaration.TestFiles(Directory: string);
const
  fmparam = '--filemask=';
var
  Info: TSearchRec;
  aFilename, Param, aFileMask: String;
  i: Integer;
  Verbose: Boolean;
begin
  aFileMask:='t*.p*';
  Verbose:=false;
  for i:=1 to ParamCount do begin
    Param:=ParamStr(i);
    if LeftStr(Param,length(fmparam))=fmparam then
      aFileMask:=copy(Param,length(fmparam)+1,100);
    if Param='-v' then
      Verbose:=true;
  end;
  Directory:=AppendPathDelim(Directory);

  if FindFirstUTF8(Directory+aFileMask,faAnyFile,Info)=0 then begin
    repeat
      if faDirectory and Info.Attr>0 then continue;
      aFilename:=Info.Name;
      if not FilenameIsPascalUnit(aFilename) then continue;
      if Verbose then
        debugln(['TTestFindDeclaration.TestFiles File="',aFilename,'"']);
      FindDeclarations(Directory+aFilename);
    until FindNextUTF8(Info)<>0;
  end;
end;

procedure TTestFindDeclaration.TestFindDeclaration_Basic;
begin
  FindDeclarations('moduletests/fdt_basic.pas');
end;

procedure TTestFindDeclaration.TestFindDeclaration_With;
begin
  FindDeclarations('moduletests/fdt_with.pas');
end;

procedure TTestFindDeclaration.TestFindDeclaration_ClassOf;
begin
  FindDeclarations('moduletests/fdt_classof.pas');
end;

procedure TTestFindDeclaration.TestFindDeclaration_NestedClasses;
begin
  FindDeclarations('moduletests/fdt_nestedclasses.pas');
end;

procedure TTestFindDeclaration.TestFindDeclaration_ClassHelper;
begin
  FindDeclarations('moduletests/fdt_classhelper.pas');
end;

procedure TTestFindDeclaration.TestFindDeclaration_TypeHelper;
begin
  FindDeclarations('moduletests/fdt_typehelper.pas');
end;

procedure TTestFindDeclaration.TestFindDeclaration_ObjCClass;
begin
  FindDeclarations('moduletests/fdt_objcclass.pas');
end;

procedure TTestFindDeclaration.TestFindDeclaration_ObjCCategory;
begin
  FindDeclarations('moduletests/fdt_objccategory.pas');
end;

procedure TTestFindDeclaration.TestFindDeclaration_Generics;
begin
  FindDeclarations('moduletests/fdt_generics.pas');
end;

procedure TTestFindDeclaration.TestFindDeclaration_FileAtCursor;
var
  Code, SubUnit2Code, LFMCode: TCodeBuffer;
  Found: TFindFileAtCursorFlag;
  FoundFilename: string;
begin
  Code:=CodeToolBoss.CreateFile('test1.lpr');
  Code.Source:='uses unit2 in ''sub/../unit2.pas'';'+LineEnding;
  SubUnit2Code:=CodeToolBoss.CreateFile('unit2.pas');
  LFMCode:=CodeToolBoss.CreateFile('test1.lfm');
  try
    // --- used unit ---
    // test cursor on 'unit2'
    if not CodeToolBoss.FindFileAtCursor(Code,6,1,Found,FoundFilename) then
      Fail('CodeToolBoss.FindFileAtCursor at uses unit2');
    AssertEquals('FindFileAtCursor at uses unit2 Found',ord(ffatUsedUnit),ord(Found));
    AssertEquals('FindFileAtCursor at uses unit2 FoundFilename','unit2.pas',FoundFilename);
    // test cursor on 'in'
    if not CodeToolBoss.FindFileAtCursor(Code,12,1,Found,FoundFilename) then
      Fail('CodeToolBoss.FindFileAtCursor at uses unit2-in');
    AssertEquals('FindFileAtCursor at uses unit2-in Found',ord(ffatUsedUnit),ord(Found));
    AssertEquals('FindFileAtCursor at uses unit2-in FoundFilename','unit2.pas',FoundFilename);
    // test cursor on in-file literal
    if not CodeToolBoss.FindFileAtCursor(Code,16,1,Found,FoundFilename) then
      Fail('CodeToolBoss.FindFileAtCursor at uses unit2-in-literal');
    AssertEquals('FindFileAtCursor at uses unit2-in-lit Found',ord(ffatUsedUnit),ord(Found));
    AssertEquals('FindFileAtCursor at uses unit2-in-lit FoundFilename','unit2.pas',FoundFilename);

    // --- enabled include directive ---
    // test cursor on enabled include directive of empty file
    Code.Source:='program test1;'+LineEnding
      +'{$i unit2.pas}'+LineEnding;
    SubUnit2Code.Source:='';
    if not CodeToolBoss.FindFileAtCursor(Code,1,2,Found,FoundFilename) then
      Fail('CodeToolBoss.FindFileAtCursor at enabled include directive of empty inc');
    AssertEquals('FindFileAtCursor at enabled include directive of empty Found',ord(ffatIncludeFile),ord(Found));
    AssertEquals('FindFileAtCursor at enabled include directive of empty FoundFilename','unit2.pas',FoundFilename);

    SubUnit2Code.Source:='{$define a}';
    if not CodeToolBoss.FindFileAtCursor(Code,1,2,Found,FoundFilename) then
      Fail('CodeToolBoss.FindFileAtCursor at enabled include directive of non-empty inc');
    AssertEquals('FindFileAtCursor at enabled include directive of non-empty Found',ord(ffatIncludeFile),ord(Found));
    AssertEquals('FindFileAtCursor at enabled include directive of non-empty FoundFilename','unit2.pas',FoundFilename);

    // --- disabled include directive ---
    // test cursor on disabled include directive
    Code.Source:='program test1;'+LineEnding
      +'{$ifdef disabled}'+LineEnding
      +'{$i unit2.pas}'+LineEnding
      +'{$endif}'+LineEnding;
    SubUnit2Code.Source:='';
    if not CodeToolBoss.FindFileAtCursor(Code,1,3,Found,FoundFilename) then
      Fail('CodeToolBoss.FindFileAtCursor at disabled include directive');
    AssertEquals('FindFileAtCursor at disabled include directive Found',ord(ffatDisabledIncludeFile),ord(Found));
    AssertEquals('FindFileAtCursor at disabled include directive FoundFilename','unit2.pas',FoundFilename);

    // --- enabled resource directive ---
    Code.Source:='program test1;'+LineEnding
      +'{$R test1.lfm}'+LineEnding;
    if not CodeToolBoss.FindFileAtCursor(Code,1,2,Found,FoundFilename) then
      Fail('CodeToolBoss.FindFileAtCursor at enabled resource directive');
    AssertEquals('FindFileAtCursor at enabled resource directive Found',ord(ffatResource),ord(Found));
    AssertEquals('FindFileAtCursor at enabled resource directive FoundFilename','test1.lfm',FoundFilename);

    Code.Source:='program test1;'+LineEnding
      +'{$R *.lfm}'+LineEnding;
    if not CodeToolBoss.FindFileAtCursor(Code,1,2,Found,FoundFilename) then
      Fail('CodeToolBoss.FindFileAtCursor at enabled resource directive');
    AssertEquals('FindFileAtCursor at enabled resource directive Found',ord(ffatResource),ord(Found));
    AssertEquals('FindFileAtCursor at enabled resource directive FoundFilename','test1.lfm',FoundFilename);

    // --- disabled resource directive ---
    Code.Source:='program test1;'+LineEnding
      +'{$ifdef disabled}'+LineEnding
      +'{$R test1.lfm}'+LineEnding
      +'{$endif}'+LineEnding;
    if not CodeToolBoss.FindFileAtCursor(Code,1,3,Found,FoundFilename) then
      Fail('CodeToolBoss.FindFileAtCursor at disabled resource directive');
    AssertEquals('FindFileAtCursor at disabled resource directive Found',ord(ffatDisabledResource),ord(Found));
    AssertEquals('FindFileAtCursor at disabled resource directive FoundFilename','test1.lfm',FoundFilename);

    // --- literal ---
    Code.Source:='program test1;'+LineEnding
      +'const Cfg=''unit2.pas'';'+LineEnding;
    if not CodeToolBoss.FindFileAtCursor(Code,11,2,Found,FoundFilename) then
      Fail('CodeToolBoss.FindFileAtCursor in literal');
    AssertEquals('FindFileAtCursor in literal Found',ord(ffatLiteral),ord(Found));
    AssertEquals('FindFileAtCursor in literal FoundFilename','unit2.pas',FoundFilename);

    // --- comment ---
    Code.Source:='program test1;'+LineEnding
      +'{unit2.pas}'+LineEnding;
    if not CodeToolBoss.FindFileAtCursor(Code,3,2,Found,FoundFilename) then
      Fail('CodeToolBoss.FindFileAtCursor in comment');
    AssertEquals('FindFileAtCursor in comment Found',ord(ffatComment),ord(Found));
    AssertEquals('FindFileAtCursor in comment FoundFilename','unit2.pas',FoundFilename);

    // --- unit name search in comment ---
    Code.Source:='program test1;'+LineEnding
      +'{unit2}'+LineEnding;
    if not CodeToolBoss.FindFileAtCursor(Code,3,2,Found,FoundFilename) then
      Fail('CodeToolBoss.FindFileAtCursor in comment');
    AssertEquals('FindFileAtCursor in comment Found',ord(ffatUnit),ord(Found));
    AssertEquals('FindFileAtCursor in comment FoundFilename','unit2.pas',FoundFilename);

    // --- unit name search in code ---
    Code.Source:='program test1;'+LineEnding
      +'begin'+LineEnding
      +'  unit2.Test;'+LineEnding;
    if not CodeToolBoss.FindFileAtCursor(Code,3,3,Found,FoundFilename) then
      Fail('CodeToolBoss.FindFileAtCursor in comment');
    AssertEquals('FindFileAtCursor in comment Found',ord(ffatUnit),ord(Found));
    AssertEquals('FindFileAtCursor in comment FoundFilename','unit2.pas',FoundFilename);

  finally
    Code.IsDeleted:=true;
    SubUnit2Code.IsDeleted:=true;
    LFMCode.IsDeleted:=true;
  end;
end;

procedure TTestFindDeclaration.TestFindDeclaration_FPCTests;
begin
  TestFiles('fpctests');
end;

procedure TTestFindDeclaration.TestFindDeclaration_LazTests;
begin
  TestFiles('laztests');
end;

initialization
  AddToFindDeclarationTestSuite(TTestFindDeclaration);
end.

