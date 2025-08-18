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
unit uzeentdimrotated;
{$Mode delphi}{$H+}
{$INCLUDE zengineconfig.inc}

interface
uses uzeentityfactory,uzeentdimaligned,uzeentdimension,uzestylesdim,
     uzestyleslayers,uzedrawingdef,uzbstrproc,uzctnrVectorBytes,
     uzegeometry,sysutils,uzeentity,uzbtypes,uzeconsts,uzeffdxfsupport,
     uzegeometrytypes,uzeentsubordinated;
type
PGDBObjRotatedDimension=^GDBObjRotatedDimension;
GDBObjRotatedDimension= object(GDBObjAlignedDimension)
                        function GetObjTypeName:String;virtual;
                        procedure CalcDNVectors;virtual;
                        function Clone(own:Pointer):PGDBObjEntity;virtual;
                        function P13ChangeTo(const tv:GDBVertex):GDBVertex;virtual;
                        function P14ChangeTo(const tv:GDBVertex):GDBVertex;virtual;
                        procedure transform(const t_matrix:DMatrix4D);virtual;
                        procedure TransformAt(p:PGDBObjEntity;t_matrix:PDMatrix4D);virtual;
                        procedure SaveToDXF(var outStream:TZctnrVectorBytes;var drawing:TDrawingDef;var IODXFContext:TIODXFSaveContext);virtual;
                        constructor init(own:Pointer;layeraddres:PGDBLayerProp;LW:SmallInt);
                        constructor initnul(owner:PGDBObjGenericWithSubordinated);
                        function GetObjType:TObjID;virtual;
                   end;
implementation
//uses log;
constructor GDBObjRotatedDimension.initnul;
begin
  inherited initnul(owner);
  //vp.ID := GDBRotatedDimensionID;
  vectorD:=XWCS;
  vectorN:=YWCS;
end;
constructor GDBObjRotatedDimension.init;
begin
  inherited init(own,layeraddres, lw);
  //vp.ID := GDBRotatedDimensionID;
  vectorD:=XWCS;
  vectorN:=YWCS;
end;
function GDBObjRotatedDimension.GetObjType;
begin
     result:=GDBRotatedDimensionID;
end;
procedure GDBObjRotatedDimension.SaveToDXF;
begin
  SaveToDXFObjPrefix(outStream,'DIMENSION','AcDbDimension',IODXFContext);
  dxfvertexout(outStream,10,DimData.P10InWCS);
  dxfvertexout(outStream,11,DimData.P11InOCS);
  if DimData.TextMoved then
                           dxfIntegerout(outStream,70,0+128)
                       else
                           dxfIntegerout(outStream,70,0);
  dxfStringout(outStream,3,PDimStyle^.Name);
  dxfStringout(outStream,100,'AcDbAlignedDimension');
  dxfvertexout(outStream,13,DimData.P13InWCS);
  dxfvertexout(outStream,14,DimData.P14InWCS);
  dxfDoubleout(outStream,50,vertexangle(createvertex2d(0,0),createvertex2d(vectorD.x,vectorD.y))*180/pi);
  dxfStringout(outStream,100,'AcDbRotatedDimension');
end;
procedure GDBObjRotatedDimension.transform;
var
    tm:DMatrix4D;
begin
  tm:=t_matrix;
  tm.mtr[3]:=NulVector4D2;
  vectorD:=VectorTransform3D(vectorD,tm);
  vectorN:=VectorTransform3D(vectorN,tm);
  vectorD:=normalizevertex(vectorD);
  vectorN:=normalizevertex(vectorN);
  inherited;
end;
procedure GDBObjRotatedDimension.TransformAt;
var
    tm:DMatrix4D;
begin
     tm:=t_matrix^;
     tm.mtr[3]:=NulVector4D2;
  vectorD:=VectorTransform3D(PGDBObjRotatedDimension(p)^.vectorD,tm);
  vectorN:=VectorTransform3D(PGDBObjRotatedDimension(p)^.vectorN,tm);
  vectorD:=normalizevertex(vectorD);
  vectorN:=normalizevertex(vectorN);
  inherited;
end;
function GDBObjRotatedDimension.P13ChangeTo(const tv:GDBVertex):GDBVertex;
begin
     result:=tv;
end;
function GDBObjRotatedDimension.P14ChangeTo(const tv:GDBVertex):GDBVertex;
var
    tl:Double;
begin
     result:=tv;
     tl:=GetTFromDirNormalizedPoint(DimData.P10InWCS,tv,vectorN);
     DimData.P10InWCS:=VertexDmorph(tv,vectorN,tl);
end;
{
var
    t,tl:Double;
    temp:GDBVertex;
begin
     tl:=scalardot(vertexsub(DimData.P14InWCS,DimData.P13InWCS),vectorD);
     temp:=VertexDmorph(DimData.P13InWCS,self.vectorD,tl);
     tv:=CorrectPointLine(tv,DimData.P13InWCS,temp,t);
     result:=tv;
     DimData.P10InWCS:=tv;
     self.CalcDNVectors;
     DimData.P11InOCS:=SetPointLine(t,DimData.P11InOCS,DimData.P13InWCS,temp)
end;
}
procedure GDBObjRotatedDimension.CalcDNVectors;
begin
end;
function GDBObjRotatedDimension.Clone;
var tvo: PGDBObjRotatedDimension;
begin
  Getmem(Pointer(tvo), sizeof(GDBObjRotatedDimension));
  tvo^.init(bp.ListPos.owner,vp.Layer, vp.LineWeight);
  CopyVPto(tvo^);
  CopyExtensionsTo(tvo^);
  tvo^.DimData := DimData;
  tvo^.bp.ListPos.Owner:=own;
  tvo^.PDimStyle:=PDimStyle;
  tvo^.vectorD:=vectorD;
  tvo^.vectorN:=vectorN;
  //tvo^.vp.ID := GDBRotatedDimensionID;
  result := tvo;
end;
function GDBObjRotatedDimension.GetObjTypeName;
begin
     result:=ObjN_ObjRotatedDimension;
end;
function AllocRotatedDimension:PGDBObjRotatedDimension;
begin
  Getmem(result,sizeof(GDBObjRotatedDimension));
end;
function AllocAndInitRotatedDimension(owner:PGDBObjGenericWithSubordinated):PGDBObjRotatedDimension;
begin
  result:=AllocRotatedDimension;
  result.initnul(owner);
  result.bp.ListPos.Owner:=owner;
end;
begin
  RegisterEntity(GDBRotatedDimensionID,'RotatedDimension',@AllocRotatedDimension,@AllocAndInitRotatedDimension);
end.
