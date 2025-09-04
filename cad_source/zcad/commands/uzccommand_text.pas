{
*****************************************************************************
*                                                                           *
*  This file is part of the ZCAD                                            *
*                                                                           *
*  See the file COPYING.txt, included in this distribution,                 *
*  for details about the copyright.                                         *
*                                                                           *
*  This program is distributed in the hope that it will be useful,          *
*  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
*                                                                           *
*****************************************************************************
}
{
@author(Andrey Zubarev <zamtmn@yandex.ru>) 
}
{$MODE OBJFPC}{$H+}
unit uzccommand_text;
{$INCLUDE zengineconfig.inc}

interface
uses
  SysUtils,
  gzctnrVectorTypes,
  uzgldrawcontext,
  
  uzbtypes,
  uzcdrawings,
  uzeutils,uzcutils,
  URecordDescriptor,typedescriptors,uzeentityfactory,uzegeometry,Varman,
  uzccommandsabstract,uzccmdfloatinsert,uzeentabstracttext,uzeenttext,uzeentmtext,
  uzcinterface,uzcstrconsts,uzccommandsmanager,
  uzeentity,uzcLog,uzctnrvectorstrings,uzestylestexts,uzeconsts,uzcsysvars,uzctextenteditor,
  varmandef,
  uzeExtdrAbstractDrawingExtender,uzedrawingabstract,uzedrawingsimple,uzbPaths,
  UBaseTypeDescriptor,UPointerDescriptor;
type
  TIMode=(
          TIM_Text,
          TIM_MText
         );
  TTOMode=(
          TO_Text,
          TO_MText,
          TO_NotDefined
         );
{EXPORT+}
  {REGISTEROBJECTTYPE TextInsert_com}
  TextInsert_com= object(FloatInsert_com)
                       pt:PGDBObjText;
                       TOverrider:TTOMode;
                       TXTOverrider:TDXFEntsInternalStringType;
                       SaveOperands:TCommandOperands;
                       //procedure Build(Operands:pansichar); virtual;
                       procedure CommandStart(const Context:TZCADCommandContext;Operands:TCommandOperands); virtual;
                       procedure CommandEnd(const Context:TZCADCommandContext); virtual;
                       procedure Command(Operands:TCommandOperands); virtual;
                       procedure BuildPrimitives; virtual;
                       procedure Format;virtual;
                       procedure FormatAfterFielfmod(PField,PTypeDescriptor:Pointer);virtual;
                       function DoEnd(Context:TZCADCommandContext;pdata:Pointer):Boolean;virtual;

                       function getNeedEntityType:TIMode;
                       function getNeedText:TDXFEntsInternalStringType;
  end;
{EXPORT-}
PTTextInsertParams=^TTextInsertParams;
TTextInsertParams=record
                   mode:TIMode;(*'Entity'*)
                   Style:TEnumData;(*'Style'*)
                   justify:TTextJustify;(*'Justify'*)
                   h:Double;(*'Height'*)
                   WidthFactor:Double;(*'Width factor'*)
                   Oblique:Double;(*'Oblique'*)
                   Width:Double;(*'Width'*)
                   LineSpace:Double;(*'Line space factor'*)
                   text:TDXFEntsInternalStringType;(*'Text'*)
                   runtexteditor:Boolean;(*'Run text editor'*)
             end;

implementation
type
  TDrwExtdrCmdText=class(TAbstractDrawingExtender)
    txtStyle:string;
    constructor Create(pEntity:TAbstractDrawing);override;
  end;
var
  TextInsertParams:TTextInsertParams;
  TextInsert:TextInsert_com;

constructor TDrwExtdrCmdText.Create(pEntity:TAbstractDrawing);
begin
  txtStyle:='';
end;

function getTXTStyle:PGDBTextStyle;
begin
  if TextInsertParams.Style.Selected<TextInsertParams.Style.Enums.Count-1 then begin
    result:=drawings.GetCurrentDWG^.TextStyleTable.FindStyle(pString(TextInsertParams.Style.Enums.getDataMutable(TextInsertParams.Style.Selected))^,false);
  end else begin
    result:=drawings.GetCurrentDWG^.CurrentTextStyle;
  end;
end;

function TextInsert_com.getNeedText:TDXFEntsInternalStringType;
begin
  if TXTOverrider='' then
    Exit(TextInsertParams.text)
  else
    Exit(TXTOverrider);
end;

function TextInsert_com.getNeedEntityType:TIMode;
begin
  case TOverrider of
    TO_Text:
      result:=TIM_Text;
    TO_MText:
      result:=TIM_MText;
    TO_NotDefined:
      result:=TextInsertParams.mode;
  end;
end;

procedure TextInsert_com.BuildPrimitives;
var
  ppt:PRecordDescriptor;
begin
     if drawings.GetCurrentDWG^.TextStyleTable.GetRealCount>0 then
     begin
     drawings.GetCurrentDWG^.ConstructObjRoot.ObjArray.free;
     pointer(ppt):=PGDBPointerDescriptor(TextInsert.commanddata.PTD)^.TypeOf;
     case TOverrider of
       TO_MText,TO_Text:
         ppt^.SetAttrib('mode',[fldaHidden],[]);
       TO_NotDefined:
         ppt^.SetAttrib('mode',[],[fldaHidden]);
     end;
     if TXTOverrider<>''then begin
       ppt^.SetAttrib('text',[fldaHidden],[]);
       ppt^.SetAttrib('runtexteditor',[fldaHidden],[]);
     end else begin
       ppt^.SetAttrib('text',[],[fldaHidden]);
       ppt^.SetAttrib('runtexteditor',[],[fldaHidden]);
     end;
     case getNeedEntityType of
           TIM_Text:
           begin
             ppt^.SetAttrib('Oblique',[],[fldaReadOnly]);
             ppt^.SetAttrib('WidthFactor',[],[fldaReadOnly]);

             ppt^.SetAttrib('Width',[fldaReadOnly],[]);
             ppt^.SetAttrib('LineSpace',[fldaReadOnly],[]);

                pt := Pointer(AllocEnt(GDBTextID));
                pt^.init(@drawings.GetCurrentDWG^.ConstructObjRoot,drawings.GetCurrentDWG^.GetCurrentLayer,sysvar.dwg.DWG_CLinew^,'',nulvertex,2.5,0,1,0,jstl);
                zcSetEntPropFromCurrentDrawingProp(pt);
           end;
           TIM_MText:
           begin
                ppt^.SetAttrib('Oblique',[fldaReadOnly],[]);
                ppt^.SetAttrib('WidthFactor',[fldaReadOnly],[]);

                ppt^.SetAttrib('Width',[],[fldaReadOnly]);
                ppt^.SetAttrib('LineSpace',[],[fldaReadOnly]);

                pt := Pointer(AllocEnt(GDBMTextID));
                pgdbobjmtext(pt)^.init(@drawings.GetCurrentDWG^.ConstructObjRoot,drawings.GetCurrentDWG^.GetCurrentLayer,sysvar.dwg.DWG_CLinew^,
                                  '',nulvertex,2.5,0,1,0,jstl,10,1);
                zcSetEntPropFromCurrentDrawingProp(pt);
           end;

     end;
     pt^.TXTStyle:=getTXTStyle;
     drawings.GetCurrentDWG^.ConstructObjRoot.ObjArray.AddPEntity(pt^);
     end;
end;
procedure TextInsert_com.CommandStart(const Context:TZCADCommandContext;Operands:TCommandOperands);
begin
  SaveOperands:=Operands;
  inherited;
  if drawings.GetCurrentDWG^.TextStyleTable.GetRealCount<1 then begin
    zcUI.TextMessage(rscmInDwgTxtStyleNotDeffined,TMWOShowError);
    commandmanager.executecommandend;
  end;
end;
procedure TextInsert_com.CommandEnd(const Context:TZCADCommandContext);
begin
  inherited;
end;

function GetStyleNames(var AStyleNamesVector:TZctnrVectorStrings;AFindName:String;AAddedLastName:string):Integer;
var
  pb:PGDBTextStyle;
  ir:itrec;
  i:Integer;
begin
  result:=-1;
  i:=0;
  AFindName:=uppercase(AFindName);
  pb:=drawings.GetCurrentDWG^.TextStyleTable.beginiterate(ir);
  if pb<>nil then
    repeat
      if uppercase(pb^.name)=AFindName then
        result:=i;
      AStyleNamesVector.PushBackData(pb^.name);
      pb:=drawings.GetCurrentDWG^.TextStyleTable.iterate(ir);
      inc(i);
    until pb=nil;
  if AAddedLastName<>''then
    AStyleNamesVector.PushBackData(AAddedLastName);
end;

function FindCmdTextDrawingExtender(var dwg:TSimpleDrawing;CreateIfnotFound:boolean=true):TDrwExtdrCmdText;
begin
  result:=dwg.DrawingExtensions.specialize GetExtension<TDrwExtdrCmdText>;
  if (CreateIfnotFound)and(result=nil) then begin
    result:=TDrwExtdrCmdText.Create(dwg);
    dwg.DrawingExtensions.AddExtension(result);
  end;
end;

procedure TextInsert_com.Command(Operands:TCommandOperands);
var
  te:TDrwExtdrCmdText;
  txtStyleName:string;
  i:integer;
  op1,op2:string;
begin
  TOverrider:=TO_NotDefined;
  TXTOverrider:='';
  if Operands<>'' then begin
    op2:=Operands;
    GetPartOfPath(op1,op2,',');
    op1:=UpperCase(op1);
    case op1 of
       'TEXT','T':TOverrider:=TO_Text;
       'MTEXT','M':TOverrider:=TO_MText;
       else
         zcUI.TextMessage(sysutils.format(rsErrorOperandN,[1]),TMWOShowError);
    end;
      TXTOverrider:=op2;
  end;
  if drawings.GetCurrentDWG^.TextStyleTable.GetRealCount>0 then begin
    te:=FindCmdTextDrawingExtender(drawings.CurrentDWG^,false);
    if Assigned(te) then
      txtStyleName:=te.txtStyle
    else
      txtStyleName:='';
    TextInsertParams.Style.Enums.free;
    i:=GetStyleNames(TextInsertParams.Style.Enums,txtStyleName,'%%TEXTSTYLE');
    if i<0 then
      TextInsertParams.Style.Selected:=TextInsertParams.Style.Enums.Count-1
    else
      TextInsertParams.Style.Selected:=i;
    zcUI.Do_GUIaction(nil,zcMsgUIActionRedraw);
    BuildPrimitives;
    drawings.GetCurrentDWG^.wa.SetMouseMode((MGet3DPoint) or (MMoveCamera) or (MRotateCamera));
    format;
  end;
end;
function TextInsert_com.DoEnd(Context:TZCADCommandContext;pdata:Pointer):Boolean;
begin
  result:=false;
  dec(self.mouseclic);
  zcRedrawCurrentDrawing;
  if (TextInsertParams.runtexteditor)and(TXTOverrider='') then
    RunTextEditor(pdata,drawings.GetCurrentDWG^);
  //redrawoglwnd;
  build(context,SaveOperands);
end;
procedure TextInsert_com.FormatAfterFielfmod(PField,PTypeDescriptor:Pointer);
begin
  inherited;
  Self.Format;
end;

procedure TextInsert_com.Format;
var
  DC:TDrawContext;
  te:TDrwExtdrCmdText;
begin
  if ((pt^.GetObjType=GDBTextID)and(getNeedEntityType=TIM_MText))
  or ((pt^.GetObjType=GDBMTextID)and(getNeedEntityType=TIM_Text)) then
    BuildPrimitives;
    pt^.vp.Layer:=drawings.GetCurrentDWG^.GetCurrentLayer;
    pt^.vp.LineWeight:=sysvar.dwg.DWG_CLinew^;
    if TextInsertParams.Style.Selected<TextInsertParams.Style.Enums.Count-1 then begin
      pt^.TXTStyle:=drawings.GetCurrentDWG^.TextStyleTable.FindStyle(pString(TextInsertParams.Style.Enums.getDataMutable(TextInsertParams.Style.Selected))^,false);
      te:=FindCmdTextDrawingExtender(drawings.CurrentDWG^,true);
      if assigned(te)then
        te.txtStyle:=pt^.TXTStyle^.GetName;
    end else begin
      te:=FindCmdTextDrawingExtender(drawings.CurrentDWG^,false);
      if assigned(te)then
        pt^.TXTStyle:=drawings.GetCurrentDWG^.CurrentTextStyle;
    end;

     pt^.textprop.size:=TextInsertParams.h;
     pt^.Content:='';
     pt^.Template:=getNeedText;

     case getNeedEntityType of
     TIM_Text:
              begin
                   pt^.textprop.oblique:=TextInsertParams.Oblique;
                   pt^.textprop.wfactor:=TextInsertParams.WidthFactor;
                   byte(pt^.textprop.justify):=byte(TextInsertParams.justify);
              end;
     TIM_MText:
              begin
                   pgdbobjmtext(pt)^.width:=TextInsertParams.Width;
                   pgdbobjmtext(pt)^.linespace:=TextInsertParams.LineSpace;

                   if TextInsertParams.LineSpace<0 then
                                               pgdbobjmtext(pt)^.linespacef:=(-TextInsertParams.LineSpace*3/5)/TextInsertParams.h
                                           else
                                               pgdbobjmtext(pt)^.linespacef:=TextInsertParams.LineSpace;

                   //linespace := textprop.size * linespacef * 5 / 3;

                   byte(pt^.textprop.justify):=byte(TextInsertParams.justify);
              end;

     end;
     dc:=drawings.GetCurrentDWG^.CreateDrawingRC;
     pt^.FormatEntity(drawings.GetCurrentDWG^,dc);
end;

initialization
  programlog.LogOutFormatStr('Unit "%s" initialization',[{$INCLUDE %FILE%}],LM_Info,UnitsInitializeLMId);
  if SysUnit<>nil then begin
    SysUnit^.RegisterType(TypeInfo(PTTextInsertParams));//регистрируем тип данных в зкадном RTTI
    SysUnit^.SetTypeDesk(TypeInfo(TTextInsertParams),['mode','Style','justify','h','WidthFactor','Oblique','Width','LineSpace','text','runtexteditor']);//Даем програмные имена параметрам, по идее это должно быть в ртти, но ненашел
    SysUnit^.SetTypeDesk(TypeInfo(TIMode),['TIM_Text','TIM_MText']);//Даем человечьи имена параметрам
  end;
  TextInsert.init('Text',0,0);
  TextInsertParams.Style.Enums.init(10);
  TextInsertParams.Style.Selected:=0;
  TextInsertParams.h:=2.5;
  TextInsertParams.Oblique:=0;
  TextInsertParams.WidthFactor:=1;
  TextInsertParams.justify:=jstl;
  TextInsertParams.text:='text';
  TextInsertParams.runtexteditor:=false;
  TextInsertParams.Width:=100;
  TextInsertParams.LineSpace:=1;
  TextInsert.SetCommandParam(@TextInsertParams,'PTTextInsertParams');
finalization
  ProgramLog.LogOutFormatStr('Unit "%s" finalization',[{$INCLUDE %FILE%}],LM_Info,UnitsFinalizeLMId);
  TextInsertParams.Style.Enums.done;
end.
