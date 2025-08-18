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

unit uzeentspline;
{$Mode delphi}{$H+}
{$INCLUDE zengineconfig.inc}

interface
uses
  uzegluinterface,uzeentityfactory,uzgldrawcontext,uzgloglstatemanager,
  UGDBPoint3DArray,uzedrawingdef,uzecamera,UGDBVectorSnapArray,
  uzestyleslayers,uzeentsubordinated,uzeentcurve,
  uzeentity,uzctnrVectorBytes,uzbtypes,uzeconsts,uzglviewareadata,
  gzctnrVectorTypes,uzegeometrytypes,uzegeometry,uzeffdxfsupport,sysutils,
  uzMVReader,uzCtnrVectorpBaseEntity,uzeSplineUtils,uzbLogIntf,math;
type
  TSplineOpt=(SOClosed,SOPeriodic,SORational,SOPlanar,SOLinear);
  TSplineOpts=set of TSplineOpt;
  PGDBObjSpline=^GDBObjSpline;
  GDBObjSpline=object(GDBObjCurve)
    ControlArrayInOCS:GDBPoint3dArray;
    ControlArrayInWCS:GDBPoint3dArray;
    Knots:TKnotsVector;
    AproxPointInWCS:GDBPoint3dArray;
    Closed:Boolean;
    Degree:Integer;
    Opts:TSplineOpts;
    constructor init(own:Pointer;layeraddres:PGDBLayerProp;LW:SmallInt;c:Boolean);
    constructor initnul(owner:PGDBObjGenericWithSubordinated);
    destructor done;virtual;
    procedure LoadFromDXF(var rdr:TZMemReader;ptu:PExtensionData;var drawing:TDrawingDef;var context:TIODXFLoadContext);virtual;

    procedure FormatEntity(var drawing:TDrawingDef;var DC:TDrawContext;Stage:TEFStages=EFAllStages);virtual;
    procedure startsnap(out osp:os_record; out pdata:Pointer);virtual;
    function getsnap(var osp:os_record; var pdata:Pointer; const param:OGLWndtype; ProjectProc:GDBProjectProc;SnapMode:TGDBOSMode):Boolean;virtual;

    procedure SaveToDXF(var outStream:TZctnrVectorBytes;var drawing:TDrawingDef;var IODXFContext:TIODXFSaveContext);virtual;
    procedure SaveToDXFfollow(var outStream:TZctnrVectorBytes;var drawing:TDrawingDef;var IODXFContext:TIODXFSaveContext);virtual;
    procedure DrawGeometry(lw:Integer;var DC:TDrawContext;const inFrustumState:TInBoundingVolume);virtual;
    function Clone(own:Pointer):PGDBObjEntity;virtual;
    function GetObjTypeName:String;virtual;
    function FromDXFPostProcessBeforeAdd(ptu:PExtensionData;const drawing:TDrawingDef):PGDBObjSubordinated;virtual;
    function onmouse(var popa:TZctnrVectorPGDBaseEntity;const MF:ClipArray;InSubEntry:Boolean):Boolean;virtual;
    function onpoint(var objects:TZctnrVectorPGDBaseEntity;const point:GDBVertex):Boolean;virtual;
    procedure AddOnTrackAxis(var posr:os_record;const processaxis:taddotrac);virtual;
    procedure getoutbound(var DC:TDrawContext);virtual;

    function CreateInstance:PGDBObjSpline;static;
    function GetObjType:TObjID;virtual;
  end;

implementation

type
  PTempSplineData=^TTempSplineData;
  TTempSplineData=record
    tv0:gdbvertex;
    PAproxPointInWCS:PGDBPoint3dArray;
  end;

procedure GDBObjSpline.getoutbound;
begin
  if AproxPointInWCS.Count>0 then
    vp.BoundingBox:=AproxPointInWCS.getoutbound
  else
    vp.BoundingBox:=VertexArrayInWCS.getoutbound
end;

procedure GDBObjSpline.AddOnTrackAxis(var posr:os_record;const processaxis:taddotrac);
begin
  GDBPoint3dArrayAddOnTrackAxis(VertexArrayInWCS,posr,processaxis,closed);
end;

function GDBObjSpline.onmouse;
begin
  if AproxPointInWCS.count<2 then begin
    result:=false;
    exit;
  end;
    result:=AproxPointInWCS.onmouse(mf,closed);
end;

function GDBObjSpline.onpoint(var objects:TZctnrVectorPGDBaseEntity;const point:GDBVertex):Boolean;
begin
  if VertexArrayInWCS.onpoint(point,closed) then begin
    result:=true;
    objects.PushBackData(@self);
  end else
    result:=false;
end;

procedure GDBObjSpline.startsnap(out osp:os_record; out pdata:Pointer);
begin
  GDBObjEntity.startsnap(osp,pdata);
  Getmem(pdata,sizeof(GDBVectorSnapArray));
  PGDBVectorSnapArray(pdata).init(VertexArrayInWCS.Max);
  BuildSnapArray(VertexArrayInWCS,PGDBVectorSnapArray(pdata)^,closed);
end;

function GDBObjSpline.getsnap;
begin
  result:=GDBPoint3dArraygetsnapWOPProjPoint(VertexArrayInWCS,{snaparray}PGDBVectorSnapArray(pdata)^,osp,closed,param,ProjectProc,snapmode);
end;

procedure NurbsVertexCallBack(const v: PGDBvertex3S;const Data: Pointer);{$IFDEF Windows}stdcall{$ELSE}cdecl{$ENDIF};
var
  tv: gdbvertex;
begin
  tv.x:=v^.x+PTempSplineData(Data)^.tv0.x;
  tv.y:=v^.y+PTempSplineData(Data)^.tv0.y;
  tv.z:=v^.z+PTempSplineData(Data)^.tv0.z;
  PTempSplineData(Data)^.PAproxPointInWCS^.PushBackData(tv);
  tv.x:=0;
end;

procedure NurbsErrorCallBack(const v: GLenum);{$IFDEF Windows}stdcall{$ELSE}cdecl{$ENDIF};
begin
  zDebugLn('{E}'+GLUIntrf.ErrorString(v));
end;

procedure GDBObjSpline.FormatEntity(var drawing:TDrawingDef;var DC:TDrawContext;Stage:TEFStages=EFAllStages);
var
  ptv: pgdbvertex;
  ir:itrec;
  nurbsobj:GLUnurbsObj;
  CP:TCPVector;
  tfv:GDBvertex4D;
  tfvs:GDBvertex4S;
  //m:DMatrix4D;
  TSD:TTempSplineData;
  tv:GDBvertex;
begin
  if assigned(EntExtensions)then
    EntExtensions.RunOnBeforeEntityFormat(@self,drawing,DC);
  FormatWithoutSnapArray;
  if (not(SOLinear in Opts))and(not (ESTemp in State))and(DCODrawable in DC.Options) then begin
    CP.init(VertexArrayInWCS.count);
    ptv:=VertexArrayInWCS.beginiterate(ir);
    TSD.tv0:=ptv^;

    if ptv<>nil then
    repeat

      tfvs.x:=ptv.x-TSD.tv0.x;
      tfvs.y:=ptv.y-TSD.tv0.y;
      tfvs.z:=ptv.z-TSD.tv0.z;
      tfvs.w:=1;

      CP.PushBackData(tfvs);

      ptv:=VertexArrayInWCS.iterate(ir);
    until ptv=nil;

    AproxPointInWCS.Clear;
    TSD.PAproxPointInWCS:=@AproxPointInWCS;

    //попытка расчета масштаба при невыставленых матрицах вида, при загрузке dxf
    //по идее наверно надо матрицы выставлять, а не тут заниматься херней
    tv:=VectorTransform3D(OneVertex,{m}getmatrix^);
    tv:=VectorTransform3D(tv,DC.DrawingContext.matrixs.pmodelMatrix^);
    tv:=VectorTransform3D(tv,DC.DrawingContext.matrixs.pprojMatrix^);

    nurbsobj:=GLUIntrf.NewNurbsRenderer;

    GLUIntrf.SetupNurbsRenderer(nurbsobj,max(1,50/tv.Length),
                                DC.DrawingContext.matrixs.pmodelMatrix^,DC.DrawingContext.matrixs.pprojMatrix^,DC.DrawingContext.matrixs.pviewport^,
                                nil,nil,@NurbsVertexCallBack,@NurbsErrorCallBack,
                                @TSD);
    GLUIntrf.BeginCurve(nurbsobj);
    GLUIntrf.NurbsCurve(nurbsobj,Knots.Count,Knots.GetParrayAsPointer,{CP.Count}4,CP.GetParrayAsPointer,degree+1,GL_MAP1_VERTEX_4);
    GLUIntrf.EndCurve(nurbsobj);


    GLUIntrf.DeleteNurbsRenderer(nurbsobj);

    CP.done;
  end;
  AproxPointInWCS.Shrink;
  CalcActualVisible(dc.DrawingContext.VActuality);
  Representation.Clear;
  if (not (ESTemp in State))and(DCODrawable in DC.Options) then begin
    if SOLinear in Opts then
      Representation.DrawLineWithLT(self,getmatrix^,dc,VertexArrayInOCS.getFirst,VertexArrayInOCS.getLast,vp)
    else
      Representation.DrawPolyLineWithLT(dc,AproxPointInWCS,vp,false,false)
  end;
  calcbb(dc);
  if assigned(EntExtensions)then
    EntExtensions.RunOnAfterEntityFormat(@self,drawing,DC);
end;

function GDBObjSpline.FromDXFPostProcessBeforeAdd;
begin
  result:=nil;
end;

function GDBObjSpline.GetObjTypeName;
begin
  result:=ObjN_GDBObjSpline;
end;
constructor GDBObjSpline.init;
begin
  closed := c;
  inherited init(own,layeraddres, lw);
  ControlArrayInWCS.init(1000);
  ControlArrayInOCS.init(1000);
  Knots.init(1000{,sizeof(Single)});
  AproxPointInWCS.init(1000);
  Opts:=[];
  //vp.ID := GDBSplineID;
end;
constructor GDBObjSpline.initnul;
begin
  inherited initnul(owner);
  ControlArrayInWCS.init(1000);
  ControlArrayInOCS.init(1000);
  Knots.init(1000{,sizeof(Single)});
  AproxPointInWCS.init(1000);
  Opts:=[];
  //vp.ID := GDBSplineID;
end;
function GDBObjSpline.GetObjType;
begin
  result:=GDBSplineID;
end;
destructor GDBObjSpline.done;
begin
  ControlArrayInWCS.done;
  ControlArrayInOCS.done;
  Knots.done;
  AproxPointInWCS.done;
  inherited;
end;
procedure GDBObjSpline.DrawGeometry;
begin
  //vertexarrayInWCS.DrawGeometryWClosed(closed);
  self.Representation.DrawGeometry(DC,VP.BoundingBox,inFrustumState);
  {if closed then oglsm.myglbegin(GL_line_loop)
             else oglsm.myglbegin(GL_line_strip);
  vertexarrayInWCS.iterategl(@myglVertex3dv);
  oglsm.myglend;}
  //inherited;
  drawbb(dc);
end;
function GDBObjSpline.Clone;
var
  tpo: PGDBObjSpline;
begin
  Getmem(Pointer(tpo), sizeof(GDBObjSpline));
  tpo^.init(own,vp.Layer, vp.LineWeight,closed);
  CopyVPto(tpo^);
  CopyExtensionsTo(tpo^);
  //tpo^.vertexarray.init(1000);
  vertexarrayinocs.copyto(tpo^.vertexarrayinocs);
  Knots.copyto(tpo^.Knots);
  tpo^.degree:=degree;
  {p:=vertexarrayinocs.PArray;
  for i:=0 to vertexarrayinocs.Count-1 do
  begin
      tpo^.vertexarrayinocs.add(p);
      inc(p)
  end;}
  //tpo^.snaparray:=nil;
  //tpo^.format;
  result := tpo;
end;

//SplineOpt=(SOClosed,SOPeriodic,SORational,SOPlanar,SOLinear);
function DXFFlag2SplineOpts(AFlag:Integer):TSplineOpts;
begin
  if (AFlag and 1)<>0 then
    result:=[SOClosed]
  else
    result:=[];
  if (AFlag and 2)<>0 then
    result:=result+[SOPeriodic];
  if (AFlag and 4)<>0 then
    result:=result+[SORational];
  if (AFlag and 8)<>0 then
    result:=result+[SOPlanar];
  if (AFlag and 16)<>0 then
    result:=result+[SOLinear];
end;

function SplineOpts2DXFFlag(AOpts:TSplineOpts):Integer;
begin
  if SOClosed in AOpts then
    result:=1
  else
    result:=0;
  if SOPeriodic in AOpts then
    result:=result+2;
  if SORational in AOpts then
    result:=result+4;
  if SOPlanar in AOpts then
    result:=result+8;
  if SOLinear in AOpts then
    result:=result+16;
end;

procedure GDBObjSpline.SaveToDXF;
var
  ir:itrec;
  fl:PSingle;
  ptv:pgdbvertex;
begin
  SaveToDXFObjPrefix(outStream,'SPLINE','AcDbSpline',IODXFContext);
  dxfIntegerout(outStream,70,SplineOpts2DXFFlag(Opts));
  {if closed then
    dxfIntegerout(outStream,70,9)
  else
    dxfIntegerout(outStream,70,8);}
  dxfIntegerout(outStream,71,degree);
  dxfIntegerout(outStream,72,Knots.Count);
  dxfIntegerout(outStream,73,VertexArrayInOCS.Count);

  dxfDoubleout(outStream,42,0.0000000001);
  dxfDoubleout(outStream,43,0.0000000001);

  fl:=Knots.beginiterate(ir);
  if fl<>nil then
  repeat
    dxfDoubleout(outStream,40,fl^);
    fl:=Knots.iterate(ir);
  until fl=nil;

  ptv:=VertexArrayInOCS.beginiterate(ir);
  if ptv<>nil then
  repeat
    dxfvertexout(outStream,10,ptv^);
    ptv:=VertexArrayInOCS.iterate(ir);
  until ptv=nil;
end;

procedure GDBObjSpline.SaveToDXFfollow(var outStream:TZctnrVectorBytes;var drawing:TDrawingDef;var IODXFContext:TIODXFSaveContext);
begin
end;

procedure GDBObjSpline.LoadFromDXF;
var
  DXFGroupCode:Integer;
  tmpFlag:Integer;
  tmpVertex:GDBvertex;
  tmpKnot:Single;
begin
  Closed:=false;
  tmpVertex:=NulVertex;
  tmpKnot:=0;
  tmpFlag:=0;

  DXFGroupCode:=rdr.ParseInteger;
  while DXFGroupCode <> 0 do begin
    if not LoadFromDXFObjShared(rdr,DXFGroupCode,ptu,drawing,context) then
       if dxfLoadGroupCodeVertex(rdr,10,DXFGroupCode,tmpVertex) then begin
         if DXFGroupCode=30 then
           addvertex(tmpVertex);
       end else if dxfLoadGroupCodeFloat(rdr,40,DXFGroupCode,tmpKnot) then
         Knots.PushBackData(tmpKnot)
       else if dxfLoadGroupCodeInteger(rdr,70,DXFGroupCode,tmpFlag) then begin
         Opts:=DXFFlag2SplineOpts(tmpFlag);
         Closed:=SOClosed in Opts;
         //if (tmpFlag and 1) = 1 then Closed := true;
       end else if dxfLoadGroupCodeInteger(rdr,71,DXFGroupCode,Degree) then begin
         Degree:=Degree;
       end else
         rdr.SkipString;
    DXFGroupCode:=rdr.ParseInteger;
  end;

  vertexarrayinocs.Shrink;
  Knots.Shrink;
end;
function AllocSpline:PGDBObjSpline;
begin
  Getmem(result,sizeof(GDBObjSpline));
end;
function AllocAndInitSpline(owner:PGDBObjGenericWithSubordinated):PGDBObjSpline;
begin
  result:=AllocSpline;
  result.initnul(owner);
  result.bp.ListPos.Owner:=owner;
end;
function GDBObjSpline.CreateInstance:PGDBObjSpline;
begin
  result:=AllocAndInitSpline(nil);
end;
begin
  RegisterDXFEntity(GDBSplineID,'SPLINE','Spline',@AllocSpline,@AllocAndInitSpline);
end.
