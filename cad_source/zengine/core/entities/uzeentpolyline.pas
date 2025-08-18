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

unit uzeentpolyline;
{$Mode delphi}{$H+}
{$INCLUDE zengineconfig.inc}

interface
uses uzeentityfactory,uzgldrawcontext,uzedrawingdef,uzecamera,UGDBVectorSnapArray,
     uzestyleslayers,uzeentsubordinated,uzeentcurve,
     uzeentity,uzctnrVectorBytes,uzbtypes,uzeconsts,uzglviewareadata,
     uzegeometrytypes,uzegeometry,uzeffdxfsupport,sysutils,
     uzMVReader,uzCtnrVectorpBaseEntity;
type
PGDBObjPolyline=^GDBObjPolyline;
GDBObjPolyline= object(GDBObjCurve)
                 Closed:Boolean;
                 constructor init(own:Pointer;layeraddres:PGDBLayerProp;LW:SmallInt;c:Boolean);
                 constructor initnul(owner:PGDBObjGenericWithSubordinated);
                 procedure LoadFromDXF(var rdr:TZMemReader;ptu:PExtensionData;var drawing:TDrawingDef;var context:TIODXFLoadContext);virtual;

                 procedure FormatEntity(var drawing:TDrawingDef;var DC:TDrawContext;Stage:TEFStages=EFAllStages);virtual;
                 procedure startsnap(out osp:os_record; out pdata:Pointer);virtual;
                 function getsnap(var osp:os_record; var pdata:Pointer; const param:OGLWndtype; ProjectProc:GDBProjectProc;SnapMode:TGDBOSMode):Boolean;virtual;

                 procedure SaveToDXF(var outStream:TZctnrVectorBytes;var drawing:TDrawingDef;var IODXFContext:TIODXFSaveContext);virtual;
                 procedure DrawGeometry(lw:Integer;var DC:TDrawContext;const inFrustumState:TInBoundingVolume);virtual;
                 function Clone(own:Pointer):PGDBObjEntity;virtual;
                 function GetObjTypeName:String;virtual;
                 function onmouse(var popa:TZctnrVectorPGDBaseEntity;const MF:ClipArray;InSubEntry:Boolean):Boolean;virtual;
                 function onpoint(var objects:TZctnrVectorPGDBaseEntity;const point:GDBVertex):Boolean;virtual;
                 procedure AddOnTrackAxis(var posr:os_record;const processaxis:taddotrac);virtual;
                 function GetLength:Double;virtual;

                 class function CreateInstance:PGDBObjPolyline;static;
                 function GetObjType:TObjID;virtual;
                 function CalcTrueInFrustum(const frustum:ClipArray):TInBoundingVolume;virtual;
           end;

implementation
function GDBObjPolyline.CalcTrueInFrustum;
begin
  result:=VertexArrayInWCS.CalcTrueInFrustum(frustum,closed);
end;
function GDBObjPolyline.GetLength:Double;
var
   ptpv0,ptpv1:PGDBVertex;
begin
  result:=inherited;
  if closed then
  begin
       ptpv0:=VertexArrayInWCS.GetParrayAsPointer;
       ptpv1:=VertexArrayInWCS.getDataMutable(VertexArrayInWCS.Count-1);
       result:=result+uzegeometry.Vertexlength(ptpv0^,ptpv1^);
  end;
end;
procedure GDBObjPolyline.AddOnTrackAxis(var posr:os_record;const processaxis:taddotrac);
begin
  GDBPoint3dArrayAddOnTrackAxis(VertexArrayInWCS,posr,processaxis,closed);
end;
function GDBObjPolyline.onmouse;
begin
  if VertexArrayInWCS.count<2 then
                                  begin
                                       result:=false;
                                       exit;
                                  end;
   result:=VertexArrayInWCS.onmouse(mf,closed);
end;
function GDBObjPolyline.onpoint(var objects:TZctnrVectorPGDBaseEntity;const point:GDBVertex):Boolean;
begin
     if VertexArrayInWCS.onpoint(point,closed) then
                                                begin
                                                     result:=true;
                                                     objects.PushBackData(@self);
                                                end
                                            else
                                                result:=false;
end;
procedure GDBObjPolyline.startsnap(out osp:os_record; out pdata:Pointer);
begin
     GDBObjEntity.startsnap(osp,pdata);
     Getmem(pdata,sizeof(GDBVectorSnapArray));
     PGDBVectorSnapArray(pdata).init(VertexArrayInWCS.Max);
     BuildSnapArray(VertexArrayInWCS,PGDBVectorSnapArray(pdata)^,closed);
end;
function GDBObjPolyline.getsnap;
begin
     result:=GDBPoint3dArraygetsnapWOPProjPoint(VertexArrayInWCS,{snaparray}PGDBVectorSnapArray(pdata)^,osp,closed,param,ProjectProc,snapmode);
end;
procedure GDBObjPolyline.FormatEntity(var drawing:TDrawingDef;var DC:TDrawContext;Stage:TEFStages=EFAllStages);
begin
  if assigned(EntExtensions)then
    EntExtensions.RunOnBeforeEntityFormat(@self,drawing,DC);
  FormatWithoutSnapArray;
  calcbb(dc);
  //-------------BuildSnapArray(VertexArrayInWCS,snaparray,Closed);
  CalcActualVisible(dc.DrawingContext.VActuality);
  Representation.Clear;
  if (not (ESTemp in State))and(DCODrawable in DC.Options) then
    if VertexArrayInWCS.Count>1 then
      Representation.DrawPolyLineWithLT(dc,VertexArrayInWCS,vp,closed,false);


  if assigned(EntExtensions)then
    EntExtensions.RunOnAfterEntityFormat(@self,drawing,DC);
end;

function GDBObjPolyline.GetObjTypeName;
begin
     result:=ObjN_GDBObjPolyLine;
end;
constructor GDBObjPolyline.init;
begin
  //vp.ID := GDBPolylineID;
  closed := c;
  inherited init(own,layeraddres, lw);
end;
constructor GDBObjPolyline.initnul;
begin
  inherited initnul(owner);
  //vp.ID := GDBPolylineID;
end;
function GDBObjPolyline.GetObjType;
begin
     result:=GDBPolylineID;
end;
procedure GDBObjPolyline.DrawGeometry;
begin
     //vertexarrayInWCS.DrawGeometryWClosed(closed);
     self.Representation.DrawGeometry(DC,VP.BoundingBox,inFrustumState);
{  if closed then oglsm.myglbegin(GL_line_loop)
            else oglsm.myglbegin(GL_line_strip);
  vertexarrayInWCS.iterategl(@myglVertex3dv);
  oglsm.myglend;}
  //inherited;
end;
function GDBObjPolyline.Clone;
var
  tpo: PGDBObjPolyLine;
begin
  Getmem(Pointer(tpo), sizeof(GDBObjPolyline));
  tpo^.init({bp.ListPos.owner}own,vp.Layer, vp.LineWeight,closed);
  CopyVPto(tpo^);
  CopyExtensionsTo(tpo^);
  //tpo^.vertexarray.init(1000);
  tpo^.vertexarrayinocs.SetSize(vertexarrayinocs.Count);
  vertexarrayinocs.copyto(tpo^.vertexarrayinocs);
  tpo^.bp.ListPos.owner:=own;

  result := tpo;
end;
procedure GDBObjPolyline.SaveToDXF;
//var
//    ptv:pgdbvertex;
//    ir:itrec;
begin
  SaveToDXFObjPrefix(outStream,'POLYLINE','AcDb3dPolyline',IODXFContext);
  dxfIntegerout(outStream,66,1);
  dxfvertexout(outStream,10,uzegeometry.NulVertex);
  if closed then
                dxfIntegerout(outStream,70,9)
            else
                dxfIntegerout(outStream,70,8);
end;
procedure GDBObjPolyline.LoadFromDXF;
var s{, layername}: String;
  byt{, code}: Integer;
  //p: gdbvertex;
  hlGDBWord: Integer;
  vertexgo: Boolean;
  tv:gdbvertex;
begin
  closed := false;
  vertexgo := false;
  hlGDBWord:=0;
  tv:=NulVertex;

  //initnul(@gdb.ObjRoot);
  byt:=rdr.ParseInteger;
  while true do
  begin
    s:='';
    if not LoadFromDXFObjShared(rdr,byt,ptu,drawing,context) then
       if dxfLoadGroupCodeVertex(rdr,10,byt,tv) then
                                         begin
                                              if byt=30 then
                                                            if vertexgo then
                                                                            FastAddVertex(tv);
                                         end
  else if dxfLoadGroupCodeInteger(rdr,70,byt,hlGDBWord) then
                                                   begin
                                                        if (hlGDBWord and 1) = 1 then closed := true;
                                                   end
   else if dxfLoadGroupCodeString(rdr,0,byt,s)then
                                             begin
                                                  if s='VERTEX' then vertexgo := true;
                                                  if s='SEQEND' then system.Break;
                                             end
                                      else s:= rdr.ParseString;
    byt:=rdr.ParseInteger;
  end;

  vertexarrayinocs.SetSize(curveVertexArrayInWCS.Count);
  curveVertexArrayInWCS.copyto(vertexarrayinocs);
  curveVertexArrayInWCS.Clear;
end;
{procedure GDBObjPolyline.LoadFromDXF;
var s, layername: String;
  byt, code: Integer;
  p: gdbvertex;
  hlGDBWord: LongWord;
  vertexgo: Boolean;
begin
  closed := false;
  vertexgo := false;
  s := f.readString;
  val(s, byt, code);
  while true do
  begin
    case byt of
      0:
        begin
          s := f.readString;
          if s = 'SEQEND' then
            system.break;
          if s = 'VERTEX' then vertexgo := true;
        end;
      8:
        begin
          layername := f.readString;
          vp.Layer := gdb.LayerTable.getLayeraddres(layername);
        end;
      10:
        begin
          s := f.readString;
          val(s, p.x, code);
        end;
      20:
        begin
          s := f.readString;
          val(s, p.y, code);
        end;
      30:
        begin
          s := f.readString;
          val(s, p.z, code);
          if vertexgo then addvertex(p);
        end;
      70:
        begin
          s := f.readString;
          val(s, hlGDBWord, code);
          hlGDBWord := strtoint(s);
          if (hlGDBWord and 1) = 1 then closed := true;
        end;
      370:
        begin
          s := f.readString;
          vp.lineweight := strtoint(s);
        end;
    else
      s := f.readString;
    end;
    s := f.readString;
    val(s, byt, code);
  end;
  vertexarrayinocs.Shrink;
end;}
function AllocPolyline:PGDBObjPolyline;
begin
  Getmem(pointer(result),sizeof(GDBObjPolyline));
end;
function AllocAndInitPolyline(owner:PGDBObjGenericWithSubordinated):PGDBObjPolyline;
begin
  result:=AllocPolyline;
  result.initnul(owner);
  result.bp.ListPos.Owner:=owner;
end;
class function GDBObjPolyline.CreateInstance:PGDBObjPolyline;
begin
  result:=AllocAndInitPolyline(nil);
end;
begin
  RegisterDXFEntity(GDBPolylineID,'POLYLINE','3DPolyLine',@AllocPolyline,@AllocAndInitPolyline);
end.
