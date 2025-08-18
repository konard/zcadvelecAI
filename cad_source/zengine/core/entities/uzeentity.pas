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

unit uzeentity;
{$Mode delphi}{$H+}
{$INCLUDE zengineconfig.inc}
interface
uses
  uzepalette,uzeobjectextender,uzgldrawerabstract,uzgldrawcontext,uzedrawingdef,
  uzecamera,uzeentitiesprop,uzestyleslinetypes,
  uzegeometrytypes,UGDBControlPointArray,uzeentsubordinated,uzbtypes,uzeconsts,
  uzglviewareadata,uzegeometry,uzeffdxfsupport,sysutils,uzctnrVectorBytes,
  uzestyleslayers,uzeenrepresentation,uzbLogIntf,
  uzMVReader,uzCtnrVectorpBaseEntity;
type
taddotrac=procedure (var posr:os_record;const axis:GDBVertex) of object;
TEFStage=(EFCalcEntityCS,EFDraw);
TEFStages=set of TEFStage;
const
EFAllStages=[EFCalcEntityCS,EFDraw];
type
PGDBObjEntity=^GDBObjEntity;
TSelect2Stage=procedure(PEntity,PGripsCreator:PGDBObjEntity;var SelectedObjCount:Integer)of object;
TDeSelect2Stage=procedure(PV:PGDBObjEntity;var SelectedObjCount:Integer)of object;
TEntityState=(ESCalcWithoutOwner,ESTemp,ESConstructProxy);
TEntityStates=set of TEntityState;
PTExtAttrib=^TExtAttrib;
TExtAttrib=record
                 OwnerHandle:QWord;
                 MainFunctionHandle:QWord;
                 dwgHandle:QWord;
                 Handle:QWord;
                 Upgrade:TEntUpgradeInfo;
                 ExtAttrib2:Boolean;
           end;
  GDBObjEntity= object(GDBObjSubordinated)
    {-}protected{//}
      //fInfrustum:TActuality;
    {-}public{//}
                    vp:GDBObjVisualProp;
                    Selected:Boolean;
                    Visible:TActuality;
                    PExtAttrib:PTExtAttrib;
                    Representation:TZEntityRepresentation;
                    State:TEntityStates;
    {-}protected{//}
      function GetInfrustumFromTree:TActuality;virtual;
    {-}public{//}
                    destructor done;virtual;
                    constructor init(own:Pointer;layeraddres:PGDBLayerProp;LW:SmallInt);
                    constructor initnul(owner:PGDBObjGenericWithSubordinated);
                    procedure SaveToDXFObjPrefix(var  outStream:TZctnrVectorBytes;entname,dbname:String;var IODXFContext:TIODXFSaveContext;notprocessHandle:boolean=false);
                    function LoadFromDXFObjShared(var rdr:TZMemReader;DXFCode:Integer;ptu:PExtensionData;var drawing:TDrawingDef;var context:TIODXFLoadContext):Boolean;
                    function ProcessFromDXFObjXData(const _Name,_Value:String;ptu:PExtensionData;const drawing:TDrawingDef):Boolean;virtual;
                    function FromDXFPostProcessBeforeAdd(ptu:PExtensionData;const drawing:TDrawingDef):PGDBObjSubordinated;virtual;
                    procedure FromDXFPostProcessAfterAdd;virtual;
                    procedure postload(var context:TIODXFLoadContext);virtual;

                    procedure createfield;virtual;
                    function AddExtAttrib:PTExtAttrib;
                    function CopyExtAttrib:PTExtAttrib;
                    procedure LoadFromDXF(var rdr:TZMemReader;ptu:PExtensionData;var drawing:TDrawingDef;var context:TIODXFLoadContext);virtual;abstract;
                    procedure SaveToDXF(var outStream:TZctnrVectorBytes;var drawing:TDrawingDef;var IODXFContext:TIODXFSaveContext);virtual;
                    procedure DXFOut(var outStream:TZctnrVectorBytes;var drawing:TDrawingDef;var IODXFContext:TIODXFSaveContext);virtual;
                    procedure SaveToDXFfollow(var outStream:TZctnrVectorBytes;var drawing:TDrawingDef;var IODXFContext:TIODXFSaveContext);virtual;
                    procedure SaveToDXFPostProcess(var handle:TZctnrVectorBytes;var IODXFContext:TIODXFSaveContext);
                    procedure SaveToDXFObjXData(var outStream:TZctnrVectorBytes;var IODXFContext:TIODXFSaveContext);virtual;
                    function IsStagedFormatEntity:boolean;virtual;
                    procedure FormatEntity(var drawing:TDrawingDef;var DC:TDrawContext;Stage:TEFStages=EFAllStages);virtual;
                    procedure FormatFeatures(var drawing:TDrawingDef);virtual;
                    procedure FormatFast(var drawing:TDrawingDef;var DC:TDrawContext);virtual;
                    procedure FormatAfterEdit(var drawing:TDrawingDef;var DC:TDrawContext;Stage:TEFStages=EFAllStages);virtual;
                    procedure FormatAfterFielfmod(PField,PTypeDescriptor:Pointer);virtual;

                    procedure DrawWithAttrib(var DC:TDrawContext;const inFrustumState:TInBoundingVolume);virtual;
                    procedure DrawWithOutAttrib(var DC:TDrawContext;const inFrustumState:TInBoundingVolume);virtual;

                    procedure DrawGeometry(lw:Integer;var DC:TDrawContext;const inFrustumState:TInBoundingVolume);virtual;

                    function CalculateLineWeight(const DC:TDrawContext):Integer;//inline;
                    //function InRect:TInRect;virtual;
                    function Clone(own:Pointer):PGDBObjEntity;virtual;
                    procedure SetFromClone(_clone:PGDBObjEntity);virtual;
                    function CalcOwner(own:Pointer):Pointer;virtual;
                    procedure rtsave(refp:Pointer);virtual;
                    procedure TransformAt(p:PGDBObjEntity;t_matrix:PDMatrix4D);virtual;abstract;
                    procedure getoutbound(var DC:TDrawContext);virtual;
                    procedure getonlyoutbound(var DC:TDrawContext);virtual;
                    function getonlyvisibleoutbound(var DC:TDrawContext):TBoundingBox;virtual;
                    procedure correctbb(var DC:TDrawContext);virtual;
                    function GetLTCorrectH(GlobalLTScale:Double):Double;virtual;
                    function GetLTCorrectL(GlobalLTScale:Double):Double;virtual;
                    procedure calcbb(var DC:TDrawContext);virtual;
                    procedure DrawBB(var DC:TDrawContext);
                    function calcvisible(const frustum:ClipArray;const Actuality:TVisActuality;var Counters:TCameraCounters;ProjectProc:GDBProjectProc;const zoom,currentdegradationfactor:Double):Boolean;virtual;

                    function onmouse(var popa:TZctnrVectorPGDBaseEntity;const MF:ClipArray;InSubEntry:Boolean):Boolean;virtual;
                    function onpoint(var objects:TZctnrVectorPGDBaseEntity;const point:GDBVertex):Boolean;virtual;

                    function isonmouse(var popa:TZctnrVectorPGDBaseEntity;const mousefrustum:ClipArray;InSubEntry:Boolean):Boolean;virtual;
                    procedure startsnap(out osp:os_record; out pdata:Pointer);virtual;
                    function getsnap(var osp:os_record; var pdata:Pointer; const param:OGLWndtype; ProjectProc:GDBProjectProc;SnapMode:TGDBOSMode):Boolean;virtual;
                    procedure endsnap(out osp:os_record; var pdata:Pointer);virtual;
                    function getintersect(var osp:os_record;pobj:PGDBObjEntity; const param:OGLWndtype; ProjectProc:GDBProjectProc;SnapMode:TGDBOSMode):Boolean;virtual;
                    procedure higlight(var DC:TDrawContext);virtual;
                    procedure addcontrolpoints(tdesc:Pointer);virtual;abstract;
                    function select(var SelectedObjCount:Integer;s2s:TSelect2Stage):Boolean;virtual;
                    //procedure Selector(SelObjArray:Pointer;var SelectedObjCount:Integer);virtual;
                    //procedure DeSelector(SelObjArray:Pointer;var SelectedObjCount:Integer);virtual;
                    procedure DeSelect(var SelectedObjCount:Integer;ds2s:TDeSelect2Stage);virtual;
                    function SelectQuik:Boolean;virtual;
                    procedure remapcontrolpoints(pp:PGDBControlPointArray;pcount:TActuality;ScrollMode:Boolean;var camera:GDBObjCamera; ProjectProc:GDBProjectProc;var DC:TDrawContext);virtual;
                    //procedure rtmodify(md:Pointer;dist,wc:gdbvertex;save:Boolean);virtual;
                    procedure rtmodifyonepoint(const rtmod:TRTModifyData);virtual;abstract;
                    procedure transform(const t_matrix:DMatrix4D);virtual;
                    procedure remaponecontrolpoint(pdesc:PControlPointDesc;ProjectProc:GDBProjectProc);virtual;abstract;
                    function beforertmodify:Pointer;virtual;
                    procedure afterrtmodify(p:Pointer);virtual;
                    function IsRTNeedModify(const Point:PControlPointDesc; p:Pointer):Boolean;virtual;
                    procedure clearrtmodify(p:Pointer);virtual;
                    function getowner:PGDBObjSubordinated;virtual;
                    function GetMainOwner:PGDBObjSubordinated;virtual;
                    function getmatrix:PDMatrix4D;virtual;
                    function getownermatrix:PDMatrix4D;virtual;
                    function ObjToString(const prefix,sufix:String):String;virtual;
                    function ReturnLastOnMouse(InSubEntry:Boolean):PGDBObjEntity;virtual;
                    procedure YouDeleted(var drawing:TDrawingDef);virtual;
                    procedure YouChanged(var drawing:TDrawingDef);virtual;
                    function GetObjTypeName:String;virtual;
                    function GetObjType:TObjID;virtual;
                    procedure correctobjects(powner:PGDBObjEntity;pinownerarray:Integer);virtual;
                    function GetLineWeight:SmallInt;inline;
                    function IsSelected:Boolean;virtual;
                    function IsActualy:Boolean;virtual;
                    function IsHaveLCS:Boolean;virtual;
                    function IsHaveGRIPS:Boolean;virtual;
                    function GetLayer:PGDBLayerProp;virtual;
                    function GetCenterPoint:GDBVertex;virtual;
                    procedure SetInFrustum(infrustumactualy:TActuality;var Counters:TCameraCounters);virtual;
                    procedure SetInFrustumFromTree(const frustum:ClipArray;const Actuality:TVisActuality;var Counters:TCameraCounters; ProjectProc:GDBProjectProc;const zoom,currentdegradationfactor:Double);virtual;
                    function CalcActualVisible(const Actuality:TVisActuality):Boolean;virtual;
                    procedure SetNotInFrustum(infrustumactualy:TActuality;var Counters:TCameraCounters);virtual;
                    function CalcInFrustum(const frustum:ClipArray;const Actuality:TVisActuality;var Counters:TCameraCounters;ProjectProc:GDBProjectProc;const zoom,currentdegradationfactor:Double):Boolean;virtual;
                    function CalcTrueInFrustum(const frustum:ClipArray):TInBoundingVolume;virtual;
                    function IsIntersect_Line(lbegin,lend:gdbvertex):Intercept3DProp;virtual;
                    procedure BuildGeometry(var drawing:TDrawingDef);virtual;
                    procedure AddOnTrackAxis(var posr:os_record; const processaxis:taddotrac);virtual;

                    function CalcObjMatrixWithoutOwner:DMatrix4D;virtual;

                    procedure EraseMi(pobj:pGDBObjEntity;pobjinarray:Integer;var drawing:TDrawingDef);virtual;
                    function GetTangentInPoint(const point:GDBVertex):GDBVertex;virtual;
                    procedure CalcObjMatrix(pdrawing:PTDrawingDef=nil);virtual;
                    procedure ReCalcFromObjMatrix;virtual;
                    procedure correctsublayers(var la:GDBLayerArray);virtual;
                    procedure CopyVPto(var toObj:GDBObjEntity);virtual;
                    function CanSimplyDrawInWCS(const DC:TDrawContext;const ParamSize,TargetSize:Double):Boolean;inline;
                    function SqrCanSimplyDrawInWCS(const DC:TDrawContext;const ParamSize,TargetSize:Double):Boolean;//inline;
                    procedure FormatAfterDXFLoad(var drawing:TDrawingDef;var DC:TDrawContext);virtual;
                    procedure IterateCounter(PCounted:Pointer;var Counter:Integer;proc:TProcCounter);virtual;
                    class function GetDXFIOFeatures:TDXFEntIODataManager;static;
                    function GetNameInBlockTable:String;virtual;
                    procedure addtoconnect2(pobj:pgdbobjEntity;var ConnectedArray:TZctnrVectorPGDBaseEntity);
                    function CheckState(AStates:TEntityStates):Boolean;
                    function GetObjName:String;virtual;
                    {-}property infrustum:TActuality read GetInfrustumFromTree{ write fInfrustum};{//}
  end;
var onlygetsnapcount:Integer;
    GDBObjEntityDXFFeatures:TDXFEntIODataManager;
implementation
uses usimplegenerics,uzeentityfactory,uzeentitiestree;
function GDBObjEntity.GetInfrustumFromTree:TActuality;
begin
  if bp.TreePos.Owner=nil then BEGIN
    if bp.ListPos.Owner=nil then
      result:=0
    else
      Result:=pgdbobjEntity(bp.ListPos.Owner).infrustum;
  end
  else
    result:=PTEntTreeNode(bp.TreePos.Owner)^.NodeData.infrustum;
end;

function GDBObjEntity.GetObjName:String;
begin
  result:='entity'
end;

function GDBObjEntity.CheckState(AStates:TEntityStates):Boolean;
begin
  result:=(AStates*State)<>[];
  if not result then
    if bp.ListPos.Owner<>nil then
      if IsIt(typeof(bp.ListPos.Owner^),typeof(GDBObjEntity)) then
        result:=PGDBObjEntity(bp.ListPos.Owner)^.CheckState(AStates);
end;

procedure GDBObjEntity.addtoconnect2(pobj:pgdbobjEntity;var ConnectedArray:TZctnrVectorPGDBaseEntity);
begin
  ConnectedArray.PushBackIfNotPresent(pobj);
end;
procedure GDBObjEntity.IterateCounter(PCounted:Pointer;var Counter:Integer;proc:TProcCounter);
begin
    proc(@self,PCounted,Counter);
end;
function GDBObjEntity.GetNameInBlockTable:String;
begin
    result:='';
end;
procedure GDBObjEntity.FormatAfterDXFLoad;
begin
     //format;
     CalcObjMatrix;
     CalcGeometry;
     calcbb(dc);
end;

function GDBObjEntity.CanSimplyDrawInWCS(const DC:TDrawContext;const ParamSize,TargetSize:Double):Boolean;
var
   templod:Double;
begin
     if dc.maxdetail then
                         exit(true);
  templod:=(ParamSize)/(dc.DrawingContext.zoom);
  if templod>TargetSize then
                            exit(true)
                        else
                            exit(false);
end;

function GDBObjEntity.SqrCanSimplyDrawInWCS(const DC:TDrawContext;const ParamSize,TargetSize:Double):Boolean;
var
   templod:Double;
begin
     if dc.maxdetail then
                         exit(true);
  templod:=(ParamSize)/(dc.DrawingContext.zoom*dc.DrawingContext.zoom);
  if templod>TargetSize then
                            exit(true)
                        else
                            exit(false);
end;


procedure GDBObjEntity.CopyVPto(var toObj:GDBObjEntity);
begin
  toObj.OSnapModeControl:=OSnapModeControl;
  toObj.vp.LineType:=vp.LineType;
  toObj.vp.LineTypeScale:=vp.LineTypeScale;
  toObj.vp.color:=vp.color;
  toObj.vp.Layer:=vp.Layer;
  toObj.vp.LineWeight:=vp.LineWeight;
end;

procedure GDBObjEntity.correctsublayers(var la:GDBLayerArray);
begin

end;

function GDBObjEntity.IsHaveGRIPS:Boolean;
begin
     result:=true;
end;
procedure GDBObjEntity.ReCalcFromObjMatrix;
begin

end;
procedure GDBObjEntity.CalcObjMatrix;
begin

end;
procedure GDBObjEntity.EraseMi(pobj:pGDBObjEntity;pobjinarray:Integer;var drawing:TDrawingDef);
begin

end;

function GDBObjEntity.GetTangentInPoint(const point:GDBVertex):GDBVertex;
begin
     result:=nulvertex;
end;

function GDBObjEntity.IsHaveLCS:Boolean;
begin
     result:=false;
end;

function GDBObjEntity.CalcObjMatrixWithoutOwner:DMatrix4D;
begin
     result:=onematrix;
end;

procedure GDBObjEntity.SetInFrustumFromTree;
begin
end;
function GDBObjEntity.CalcActualVisible(const Actuality:TVisActuality):Boolean;
var
  oldValue:TActuality;
begin
  oldValue:=visible;
  if (self.vp.Layer._on) then
    visible:=Actuality.visibleactualy
  else
    visible:=0;
  result:=oldValue<>Visible;
end;

procedure GDBObjEntity.AddOnTrackAxis(var posr:os_record;const processaxis:taddotrac);
begin

end;
procedure GDBObjEntity.BuildGeometry;
begin

end;
function GDBObjEntity.IsIntersect_Line(lbegin,lend:gdbvertex):Intercept3DProp;
begin
     result.isintercept:=false;
end;
procedure GDBObjEntity.createfield;
begin
     inherited;
     Selected := false;
     self.Visible:=0;
     vp.lineweight:=-1;
     vp.LineType:={''}nil;
     vp.LineTypeScale:=1;

     {if gdb.GetCurrentDWG<>nil then
                                   vp.layer:=gdb.GetCurrentDWG.LayerTable.GetSystemLayer
                               else
                                   vp.layer:=nil;}
     vp.layer:=@DefaultErrorLayer;
     self.PExtAttrib:=nil;
     vp.LastCameraPos:=-1;
     vp.color:=ClByLayer;
     State:=[];
end;
function GDBObjEntity.CalcOwner(own:Pointer):Pointer;
begin
     if own=nil then
                    result:=bp.ListPos.owner
                else
                    result:=own;
end;
procedure GDBObjEntity.DrawBB;
begin
  if DC.SystmGeometryDraw{and(GDB.GetCurrentDWG.OGLwindow1.param.subrender=0)} then
  begin
  //oglsm.glcolor3ubv(palette[sysvar.SYS.SYS_SystmGeometryColor^].RGB);
  dc.drawer.SetColor(palette[dc.SystmGeometryColor].RGB);
  dc.drawer.DrawAABB3DInModelSpace(vp.BoundingBox,dc.DrawingContext.matrixs);
  end;
end;
function GDBObjEntity.GetCenterPoint;
begin
     result:=nulvertex;
end;
procedure GDBObjEntity.FromDXFPostProcessAfterAdd;
begin
end;
procedure  GDBObjEntity.postload(var context:TIODXFLoadContext);
begin
  if assigned(EntExtensions) then
    EntExtensions.RunPostload(context);
end;
function GDBObjEntity.FromDXFPostProcessBeforeAdd;
var
    EntUpgradeKey:TEntUpgradeKey;
    EntUpgradeData:TEntUpgradeData;
begin
     result:=nil;
     if self.PExtAttrib<>nil then
     if self.PExtAttrib^.Upgrade>0 then
     begin
       EntUpgradeKey.EntityID:={vp.ID}GetObjType;
       EntUpgradeKey.UprradeInfo:=self.PExtAttrib^.Upgrade;
       if EntUpgradeKey2EntUpgradeData.MyGetValue(EntUpgradeKey,EntUpgradeData) then
       if assigned(EntUpgradeData.EntityUpgradeFunc) then
         result:=EntUpgradeData.EntityUpgradeFunc(ptu,@self,drawing);
     end;
end;
function GDBObjEntity.AddExtAttrib;
begin
     if PExtAttrib=nil then
                           begin
                                Getmem(Pointer(PExtAttrib),sizeof(TExtAttrib));
                                fillchar(PExtAttrib^,sizeof(TExtAttrib),0);
                                PExtAttrib^.ExtAttrib2:=false;
                           end;
     result:=PExtAttrib;
end;
function GDBObjEntity.CopyExtAttrib;
begin
     if PExtAttrib<>nil then
                           begin
                                Getmem(Pointer(Result),sizeof(TExtAttrib));
                                fillchar(result^,sizeof(TExtAttrib),0);
                                result^:=PExtAttrib^;
                           end
                        else
                            result:=nil;
end;
function GDBObjEntity.GetLineWeight;
begin
     result:=vp.LineWeight;
end;
function GDBObjEntity.GetLayer;
begin
     result:=vp.Layer;
end;

function GDBObjEntity.IsSelected;
begin
     //result:=selected;
     if selected then
                     result:=selected
                 else
                     begin
                          if bp.ListPos.owner<>nil then
                                            result:=bp.ListPos.owner.IsSelected
                                           else
                                               result:=false;
                     end;
end;
procedure GDBObjEntity.correctobjects;
begin
     bp.ListPos.Owner:=powner;
     bp.ListPos.SelfIndex:=pinownerarray;
end;
function GDBObjEntity.GetObjTypeName;
begin
     result:=ObjN_NotRecognized;
end;
function GDBObjEntity.GetObjType;
begin
     result:={vp.ID}0;
end;
procedure GDBObjEntity.YouDeleted;
begin
     PGDBObjEntity(bp.ListPos.owner)^.EraseMi(@self,bp.ListPos.SelfIndex,drawing);
end;
procedure GDBObjEntity.YouChanged;
begin
     PGDBObjGenericWithSubordinated(bp.ListPos.owner)^.ImEdited(@self,bp.ListPos.SelfIndex,drawing);
end;
function GDBObjEntity.ReturnLastOnMouse;
begin
     result:=@self;
end;
function GDBObjEntity.ObjToString(const prefix,sufix:String):String;
begin
     result:=prefix+'#'+inttohex(PtrInt(@self),10)+sufix;
end;
function GDBObjEntity.GetMainOwner:PGDBObjSubordinated;
begin
     if bp.ListPos.Owner<>nil then
                                  result:=PGDBObjEntity(bp.ListPos.Owner)^.getmainowner
                              else
                                  result:=nil;
end;
function GDBObjEntity.getowner;
begin
     result:=PGDBObjEntity(bp.ListPos.Owner)^.getowner;
end;
function GDBObjEntity.getmatrix;
begin
     result:=PGDBObjEntity(bp.ListPos.Owner)^.GetMatrix;
end;
function GDBObjEntity.getownermatrix;
begin
     result:=PGDBObjEntity(bp.ListPos.Owner)^.GetMatrix;
end;
procedure GDBObjEntity.DrawGeometry;
begin
     drawbb(dc);
end;
function GDBObjEntity.CalculateLineWeight;
var lw: Integer;
    minlw: Integer;
begin
  if not dc.drawmode then
                       begin
                            lw := 1;
                            exit;
                       end;

  if dc.LWDisplayScale>14 then
                           minlw:=2
                       else
                           minlw:=1;

  if vp.lineweight < 0 then
  begin
    case vp.lineweight of
      -3: lw := dc.DefaultLW;
      -2: lw := dc.OwnerLineWeight;
      -1: lw := vp.layer^.lineweight;
    end
  end
  else lw := vp.lineweight;

  case lw of
      -3: lw := dc.DefaultLW;
      -2: lw := dc.OwnerLineWeight;
      -1: lw := vp.layer^.lineweight;
  end;

  if lw <= 0 then lw := minlw;
  if lw > 65-2*dc.LWDisplayScale then begin
    lw := (lw div (35-dc.LWDisplayScale))+1;
    if lw>dc.MaxWidth then lw:=dc.MaxWidth;
    result := lw;
  end
  else
  begin
    result := minlw;
  end;
  dc.drawer.setlinewidth(result);
end;
constructor GDBObjEntity.init;
begin
  createfield;
  //vp.ID := 0;
  vp.Layer := layeraddres;
  vp.LineWeight := LW;
  vp.LineType:={''}nil;
  vp.LineTypeScale:=1;
  bp.ListPos.owner:=own;
  Representation.init();
  GetDXFIOFeatures.RunConstructorFeature(@self);
  GetDXFIOFeatures.AddExtendersToEntity(@self);
end;
constructor GDBObjEntity.initnul;
begin
     createfield;
     if owner<>nil then
                       bp.ListPos.owner:=owner;
     Representation.init();
     GetDXFIOFeatures.RunConstructorFeature(@self);
     GetDXFIOFeatures.AddExtendersToEntity(@self);
end;
procedure GDBObjEntity.DrawWithOutAttrib;
var lw: Integer;
//  sel: Boolean;
begin
  lw := CalculateLineWeight(dc);
  if visible=dc.DrawingContext.VActuality.visibleactualy then
    DrawGeometry(lw,dc,infrustumstate);
  if lw > 1 then
  begin
    dc.drawer.setlinewidth(1);
    {oglsm.myglDisable(GL_LINE_SMOOTH);
    oglsm.mygllinewidth(1);
    oglsm.myglpointsize(1);
    oglsm.myglDisable(gl_point_smooth);}
  end;
end;
procedure GDBObjEntity.DrawWithAttrib;
var lw: Integer;
  sel,_selected: Boolean;
procedure SetEntColor(color:integer;var DC:TDrawContext);
begin
  if color<>7 then
                  dc.drawer.SetColor(palette[color].RGB)
              else
                  dc.drawer.SetColor(palette[DC.DrawingContext.ForeGroundColorIndex].RGB);
end;

begin
  //if visible<>dc.visibleactualy then
  //                               exit;
  //Draw(lw,dc);
  //exit;
  sel := false;
  if not dc.drawmode then
                         lw := 1
                     else
                         lw := CalculateLineWeight(dc);

  if selected or dc.selected then
                                                                    begin
                                                                         _selected:=dc.selected;
                                                                         dc.selected:=true;
                                                                         //oglsm.myglStencilFunc(GL_ALWAYS,0,1);
                                                                         dc.drawer.SetSelectedStencilMode;
                                                                         dc.drawer.SetPenStyle(TPS_Selected);
                                                                         sel := true;
                                                                    end;
  if (dc.subrender = 0)
      then
          begin
               case vp.color of
                               ClByLayer:
                                         SetEntColor(vp.layer^.color,dc);
                               ClByBlock:
                                         SetEntColor(dc.ownercolor,dc);
                               else
                                   SetEntColor(vp.color,dc);

               end;
          end
      else
          if (vp.layer<>dc.DrawingContext.SysLayer) then
                                         begin
                                              case vp.color of
                                                              ClByLayer:
                                                                        SetEntColor(vp.layer^.color,dc);
                                                              ClByBlock:
                                                                        SetEntColor(dc.ownercolor,dc);
                                                              else
                                                                  SetEntColor(vp.color,dc);

                                              end;
                                         end
                                                else
                                                    begin
                                                              case vp.color of
                                                                              ClByLayer:
                                                                                        SetEntColor(bp.ListPos.owner.getlayer^.color,dc);
                                                                              ClByBlock:
                                                                                        SetEntColor(dc.ownercolor,dc);
                                                                              else
                                                                                  SetEntColor(vp.color,dc);

                                                              end;
                                                    end;
    if visible=dc.DrawingContext.VActuality.visibleactualy then
         DrawGeometry(lw,dc,infrustumstate);

  //if selected or ((bp.ListPos.owner <> nil) and (bp.ListPos.owner^.isselected)) then
  (*if {selected or dc.selected}sel then
                                                                    begin
                                                                    end
                                                                else
                                                                    begin
                                                                         //oglsm.mytotalglend;
                                                                         oglsm.myglStencilFunc(GL_EQUAL,0,1);
                                                                         //oglsm.myglStencilOp(GL_KEEP,GL_KEEP,GL_KEEP);
                                                                    end;*)

  if lw > 1 then
  begin
    dc.drawer.setlinewidth(1);
    {oglsm.myglDisable(GL_LINE_SMOOTH);
    oglsm.mygllinewidth(1);
    oglsm.myglpointsize(1);
    oglsm.myglDisable(gl_point_smooth);}
  end;
  if sel then
             begin
                  //oglsm.mytotalglend;
                  dc.drawer.SetPenStyle(TPS_Solid);
                  dc.selected:=_selected;
             end;
end;
{procedure GDBObjEntity.RenderFeedbackIFNeed;
begin
  if vp.LastCameraPos<>pcount then
    Renderfeedback(pcount,camera,ProjectProc,dc);
end;}
{procedure GDBObjEntity.Renderfeedback;
begin
  vp.LastCameraPos:=pcount;
end;}

{procedure GDBObjEntity.format;
begin
end;}
procedure GDBObjEntity.FormatFast;
begin
     FormatEntity(drawing,dc);
end;
function GDBObjEntity.IsStagedFormatEntity:boolean;
begin
  result:=false;
end;
procedure GDBObjEntity.FormatEntity(var drawing:TDrawingDef;var DC:TDrawContext;Stage:TEFStages=EFAllStages);
begin
end;
procedure GDBObjEntity.FormatFeatures(var drawing:TDrawingDef);
begin
     inherited;
     GetDXFIOFeatures.RunFormatProcs(drawing,@self);
end;

procedure GDBObjEntity.FormatAfterEdit;
begin
     formatentity(drawing,dc,Stage);
     //AddObjectToObjArray
end;
procedure GDBObjEntity.FormatAfterFielfmod;
begin

end;
procedure GDBObjEntity.higlight;
begin
end;
procedure GDBObjEntity.SetInFrustum;
begin
     //result:=infrustum;
     //infrustum:=infrustumactualy;
     inc(Counters.totalobj);
     inc(Counters.infrustum);
end;
procedure GDBObjEntity.SetNotInFrustum;
begin
     //result:=infrustum;
     //infrustum:=false;
     inc(Counters.totalobj);
end;
procedure GDBObjEntity.DXFOut;
begin
     SaveToDXF(outStream,drawing,IODXFContext);
     SaveToDXFPostProcess(outStream,IODXFContext);
     SaveToDXFFollow(outStream,drawing,IODXFContext);
end;
procedure GDBObjEntity.SaveToDXF;
begin
end;
procedure GDBObjEntity.SaveToDXFfollow;
begin
  if assigned(EntExtensions) then
    EntExtensions.RunSaveToDXFfollow(@self,outStream,drawing,IODXFContext);
  inherited;
end;
procedure GDBObjEntity.SaveToDXFObjXData(var outStream:TZctnrVectorBytes;var IODXFContext:TIODXFSaveContext);
begin
     GetDXFIOFeatures.RunSaveFeatures(outStream,@self,IODXFContext);
     if assigned(EntExtensions) then
       EntExtensions.RunSaveToDxf(outStream,@self,IODXFContext);
     inherited;
end;

procedure GDBObjEntity.SaveToDXFPostProcess;
begin
  dxfStringout(handle,1001,ZCADAppNameInDXF);
  dxfStringout(handle,1002,'{');
  self.SaveToDXFObjXData(handle,IODXFContext);
  dxfStringout(handle,1002,'}');
end;
function GDBObjEntity.CalcInFrustum;
begin
     result:=true;
end;
function GDBObjEntity.CalcTrueInFrustum;
begin
     result:=IREmpty;
end;
{function GDBObjEntity.CalcVisibleByTree;
begin

end;}

function GDBObjEntity.calcvisible;
//var i:Integer;
//    tv,tv1:gdbvertex4d;
//    m:DMatrix4D;
begin
      visible:=Actuality.visibleactualy;
      result:=true;
      //inc(gdb.GetCurrentDWG.pcamera^.totalobj);
      if CalcInFrustum(frustum,Actuality,Counters,ProjectProc,zoom,currentdegradationfactor) then
                           begin
                                setinfrustum(Actuality.infrustumactualy,Counters);
                           end
                       else
                           begin
                                setnotinfrustum(Actuality.infrustumactualy,Counters);
                                visible:=0;
                                result:=false;
                           end;
      if self.vp.Layer<>nil then
      if not(self.vp.Layer._on) then
                           begin
                                visible:=0;
                                result:=false;
                           end;

      {if visible then begin
                           m:=gdb.pcamera^.modelmatrix;
                           //matrixtranspose(m);
                           inc(gdb.pcamera^.infrustum);
                           pgdbvertex(@tv)^:=CoordInWCS.lbegin;
                           tv.w:=1;
                           tv1:=VectorTransform(tv,m);
                           CalcZ(tv1.z);
                           //if lbegin.z>=0 then CalcZ(lbegin.z);
                           //if lend.z>=0 then CalcZ(lend.z);
                      end;}
end;
function GDBObjEntity.GetLTCorrectH(GlobalLTScale:Double):Double;
var
   LT:PGDBLtypeProp;
begin
      LT:=getLTfromVP(vp);
      if LT<>nil then
      begin
           result:=GlobalLTScale*vp.LineTypeScale*LT.h
      end
         else
         result:=0;

end;
function GDBObjEntity.GetLTCorrectL(GlobalLTScale:Double):Double;
var
   LT:PGDBLtypeProp;
begin
      LT:=getLTfromVP(vp);
      if LT<>nil then
      begin
           result:=GlobalLTScale*vp.LineTypeScale*LT.strokesarray.LengthFact
      end
         else
         result:=0;

end;
procedure GDBObjEntity.correctbb;
var cv:gdbvertex;
    d:double;
begin
     {cv:=VertexSub(vp.BoundingBox.RTF,vp.BoundingBox.LBN);
     cv:=VertexMulOnSc(cv,onedivbasedist);
     if cv.x<minoffsetstart then
                                cv.x:=minoffsetstart;
     if cv.y<minoffsetstart then
                                cv.y:=minoffsetstart;
     if cv.z<minoffsetstart then
                                cv.z:=minoffsetstart;}

      {if self.vp.LineType<>nil then
      begin
           if SysVar.dwg.DWG_LTScale<>nil then
                                              d:=SysVar.dwg.DWG_LTScale^*vp.LineTypeScale*self.vp.LineType.len
                                          else
                                              d:=vp.LineTypeScale*self.vp.LineType.len;
      end
         else
             d:=0;}
     d:=GetLTCorrectL(dc.DrawingContext.globalltscale);
     cv:=VertexSUB(vp.BoundingBox.RTF,vp.BoundingBox.LBN);
     if (d>0)and(d*d<cv.x*cv.x+cv.y*cv.y+cv.z*cv.z) then
     begin
     d:=GetLTCorrectH(dc.DrawingContext.globalltscale);
     cv:=createvertex(d,d,d);
     vp.BoundingBox.LBN:=VertexSUB(vp.BoundingBox.LBN,cv);
     vp.BoundingBox.RTF:=VertexAdd(vp.BoundingBox.RTF,cv);
     end;
end;
procedure GDBObjEntity.calcbb;
begin
     getoutbound(dc);
     correctbb(dc);
end;
procedure GDBObjEntity.getoutbound;
begin
end;
procedure GDBObjEntity.getonlyoutbound;
begin
     getoutbound(dc);
end;
function GDBObjEntity.getonlyvisibleoutbound(var DC:TDrawContext):TBoundingBox;
begin
  getonlyoutbound(dc);
  result:=vp.BoundingBox;
end;
function GDBObjEntity.IsActualy:Boolean;
begin
     if vp.Layer^._on then
                               result:=true
                           else
                               result:=false;
end;

function GDBObjEntity.isonmouse;
begin
     if IsActualy then
                          result:=onmouse(popa,mousefrustum,InSubEntry)
                      else
                          result:=false;
end;
function GDBObjEntity.onpoint(var objects:TZctnrVectorPGDBaseEntity;const point:GDBVertex):Boolean;
begin
     result:=false;
end;
function GDBObjEntity.onmouse;
begin
     result:=false;
end;
{function GDBObjEntity.InRect:TInRect;
begin
     result:=IREmpty;
end;}
procedure GDBObjEntity.SetFromClone(_clone:PGDBObjEntity);
begin
end;
function GDBObjEntity.Clone;
//var tvo: PGDBObjEntity;
begin
  //Getmem(Pointer(tvo), sizeof(GDBObjEntity));
  //tvo^.init(bp.owner,vp.Layer, vp.LineWeight);
  result := nil;
end;

destructor GDBObjEntity.done;
begin
     inherited;
     if PExtAttrib<>nil then
                            Freemem(pointer(PExtAttrib));
     vp.LineType:={''}nil;
     Representation.done;
     GetDXFIOFeatures.RunDestructorFeature(@self);
end;

procedure GDBObjEntity.rtsave;
begin
end;
procedure GDBObjEntity.startsnap;
begin
     onlygetsnapcount:=0;
     osp.PGDBObject:=@self;
     pdata:=nil;
end;
procedure GDBObjEntity.endsnap(out osp:os_record; var pdata:Pointer);
begin
end;
function GDBObjEntity.getsnap;
begin
     result:=false;
end;
function GDBObjEntity.getintersect;
begin
     result:=false;
end;
function GDBObjEntity.SelectQuik;
begin
     if (vp.Layer._lock)or(not vp.Layer._on) then
                           begin
                                result:=false;
                           end
                       else
                           begin
                                result:=true;
                                selected:=true;
                           end;
end;
(*procedure GDBObjEntity.Selector;
var tdesc:pselectedobjdesc;
begin
     tdesc:=PGDBSelectedObjArray(SelObjArray)^.addobject(@self);
     if tdesc<>nil then
     if IsHaveGRIPS then
     begin
     Getmem(Pointer(tdesc^.pcontrolpoint),sizeof(GDBControlPointArray));
     addcontrolpoints(tdesc);
     end;
     bp.ListPos.Owner.ImSelected(@self,bp.ListPos.SelfIndex);
     inc(Selectedobjcount);
end;*)
function GDBObjEntity.select;
begin
     result:=false;
     if selected=false then
     begin
       result:=SelectQuik;
       if result then
         if assigned(s2s)then
           s2s(@self,@self,SelectedObjCount);
     end;
end;
{procedure GDBObjEntity.DeSelector;
var tdesc:pselectedobjdesc;
    ir:itrec;
begin
          tdesc:=PGDBSelectedObjArray(SelObjArray)^.beginiterate(ir);
          if tdesc<>nil then
          repeat
                if tdesc^.objaddr=@self then
                                            begin
                                                 PGDBSelectedObjArray(SelObjArray)^.freeelement(tdesc);
                                                 PGDBSelectedObjArray(SelObjArray)^.deleteelementbyp(tdesc);
                                            end;

                tdesc:=PGDBSelectedObjArray(SelObjArray)^.iterate(ir);
          until tdesc=nil;
          dec(Selectedobjcount);
end;}
procedure GDBObjEntity.DeSelect;
{var tdesc:pselectedobjdesc;
    ir:itrec;}
begin
     if selected then
     begin
       if assigned(ds2s)then
         ds2s(@self,SelectedObjCount);
       Selected:=false;
     end;
end;
procedure GDBObjEntity.remapcontrolpoints;
var pdesc:pcontrolpointdesc;
    i:Integer;
begin
          if pp.count<>0 then
          begin
               pdesc:=pp^.getparrayaspointer;
               for i:=0 to pp.count-1 do
               begin
                    remaponecontrolpoint(pdesc,ProjectProc);
                    inc(pdesc);
               end;
          end;
end;
function GDBObjEntity.beforertmodify;
begin
     result:=nil;
end;

procedure GDBObjEntity.clearrtmodify(p:Pointer);
begin

end;

procedure GDBObjEntity.afterrtmodify;
begin
     if p<>nil then Freemem(p);
end;
function GDBObjEntity.IsRTNeedModify(const Point:PControlPointDesc; p:Pointer):Boolean;
begin
     result:=true;
end;

procedure GDBObjEntity.transform;
begin
end;
procedure GDBObjEntity.SaveToDXFObjPrefix;
var
  tmpHandle:TDWGHandle;
begin
  dxfStringout(outStream,0,entname);
  //TODO: MyGetOrCreateValue можно желать не для всех примитивов, а только для главных функций
  //TODO: это чуток ускорит сохранение с ним 0.35сек, без 0.34~0.33 в тесте
  if notprocessHandle then begin
    tmpHandle:=IODXFContext.handle;
    inc(IODXFContext.handle);
  end else
    begin
      if IODXFContext.currentEntAddrOverrider=nil then
        IODXFContext.p2h.MyGetOrCreateValue(@self,IODXFContext.handle,tmpHandle)
      else begin
        IODXFContext.p2h.MyGetOrCreateValue(IODXFContext.currentEntAddrOverrider,IODXFContext.handle,tmpHandle);
        IODXFContext.currentEntAddrOverrider:=nil;
        inc(IODXFContext.handle);
      end;
    end;
//  if $3d=tmpHandle then
//    tmpHandle:=tmpHandle;

  dxfStringout(outStream,5,inttohex(tmpHandle{IODXFContext.handle}, 0));
  dxfStringout(outStream,100,dxfName_AcDbEntity);
  dxfStringout(outStream,8,dxfEnCodeString(vp.layer^.name,IODXFContext.header));
  if vp.color<>ClByLayer then
                             dxfStringout(outStream,62,inttostr(vp.color));
  if vp.lineweight<>-1 then dxfIntegerout(outStream,370,vp.lineweight);
  if dbname<>'' then
                    dxfStringout(outStream,100,dbname);
  if vp.LineType<>{''}nil then dxfStringout(outStream,6,dxfEnCodeString(vp.LineType^.Name,IODXFContext.header));
  if vp.LineTypeScale<>1 then dxfDoubleout(outStream,48,vp.LineTypeScale);
end;

function GDBObjEntity.LoadFromDXFObjShared;
var
  APP_NAME:ShortString;
  XGroup:Integer;
  XValue:String;
  Name,Value:String;
  i:integer;
begin
  result:=false;
  case DXFCode of
    5:begin
      if AddExtAttrib^.dwgHandle=0 then begin
        PExtAttrib^.dwgHandle:=rdr.ParseHexQWord;
      end else begin
        //при загрузке полилинии у вертексов есть хэндл
        rdr.SkipString;
      end;
      result:=true;
    end;
    6:begin
      vp.LineType:=drawing.GetLTypeTable.getAddres(dxfDeCodeString(rdr.ParseShortString,Context.header));
      result:=true
    end;
    8:begin
      if vp.layer=@DefaultErrorLayer then begin
        vp.Layer :=drawing.getlayertable.getAddres(dxfDeCodeString(rdr.ParseShortString,Context.header));
        if vp.Layer=nil then
          vp.Layer:=vp.Layer;
      end else
        APP_NAME:=rdr.ParseString;
        result:=true
    end;
    48:begin
      vp.LineTypeScale:=rdr.ParseDouble;
      result:=true
    end;
    62:begin
      vp.color:=rdr.ParseInteger;
      result:=true
    end;
    370:begin
      vp.lineweight:=rdr.ParseInteger;
      result:=true
    end;
    1001:begin
      APP_NAME:=rdr.ParseShortString;
      result:=true;
      if (Length(APP_NAME) = Length(ZCADAppNameInDXF)) and
         (StrLComp(@APP_NAME[1], @ZCADAppNameInDXF[1], Length(APP_NAME))=0) then begin
        repeat
          XGroup:=rdr.ParseInteger;
          XValue:=rdr.ParseString;
          if XGroup=1000 then begin
            i:=pos('=',Xvalue);
            if i>1 then Name:=copy(Xvalue,1,i-1) else name:='empty';
            Value:=copy(Xvalue,i+1,length(xvalue)-i);
            ProcessFromDXFObjXData(Name,Value,ptu,drawing);
          end;
        until (XGroup=1002)and(XValue='}')
      end;
    end;
  end;
end;
class function GDBObjEntity.GetDXFIOFeatures:TDXFEntIODataManager;
begin
  result:=GDBObjEntityDXFFeatures;
end;
function GDBObjEntity.ProcessFromDXFObjXData(const _Name,_Value:String;ptu:PExtensionData;const drawing:TDrawingDef):Boolean;
var
   features:TDXFEntIODataManager;
   FeatureLoadProc:TDXFEntLoadFeature;
begin
     result:=false;
     features:=GetDXFIOFeatures;
     if assigned(features) then
     begin
          FeatureLoadProc:=features.GetLoadFeature(_Name);
          if assigned(FeatureLoadProc)then
          begin
               result:=FeatureLoadProc(_Name,_Value,ptu,drawing,@self);
          end;
     end;
     {if not(result) then
     result:=inherited ProcessFromDXFObjXData(_Name,_Value,ptu,drawing);}
end;

initialization
  GDBObjEntityDXFFeatures:=TDXFEntIODataManager.Create;
finalization
  ZDebugLN('{I}[UnitsFinalization] Unit "'+{$INCLUDE %FILE%}+'" finalization');
  GDBObjEntityDXFFeatures.Destroy;
end.
