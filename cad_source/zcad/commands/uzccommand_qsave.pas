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

unit uzccommand_qsave;
{$INCLUDE zengineconfig.inc}

interface

uses
  LazUTF8,uzcLog,
  uzcdialogsfiles,
  SysUtils,
  uzbpaths,
  uzeffmanager,
  uzccommand_DWGNew,
  uzccommandsimpl,uzccommandsabstract,
  uzcsysvars,uzcSysParams,uzcFileStructure,
  uzcstrconsts,
  uzcdrawings,
  uzcinterface,
  uzccommand_saveas,
  uzccommand_rebuildtree;

implementation

function QSave_com(const Context:TZCADCommandContext;
  operands:TCommandOperands):TCommandResult;
var
  s,s1:ansistring;
  itAutoSave:boolean;
  TempSavedParam:TZCSavedParams;
begin
  itAutoSave:=False;
  if operands='QS' then begin
    s1:=ExpandPath(sysvar.SAVE.SAVE_Auto_FileName^);
    s:=format(rsAutoSave,[s1]);
    zcUI.TextMessage(s,TMWOHistoryOut);
    itAutoSave:=True;
  end else begin
    if extractfilepath(drawings.GetCurrentDWG.GetFileName)='' then begin
      SaveAs_com(Context,EmptyCommandOperands);
      exit;
    end;
    s1:=drawings.GetCurrentDWG.GetFileName;
  end;

  if itAutoSave then begin
    LoadParams(FindFileInCfgsPaths(CFSconfigsDir,CFSconfigxmlFile),TempSavedParam);
    TempSavedParam.LastAutoSaveFile:=s1;
    ZCSysParams.saved.LastAutoSaveFile:=s1;
    SaveParams(GetWritableFilePath(CFSconfigsDir,CFSconfigxmlFile),TempSavedParam);
  end;
  Result:=SaveDXFDPAS(s1,not itAutoSave);
  if (not itAutoSave)and(Result=cmd_ok) then
    drawings.GetCurrentDWG.ChangeStampt(False);
  SysVar.SAVE.SAVE_Auto_Current_Interval^:=SysVar.SAVE.SAVE_Auto_Interval^;
  RebuildTree_com(Context,'');
end;

initialization
  programlog.LogOutFormatStr('Unit "%s" initialization',[{$INCLUDE %FILE%}],
    LM_Info,UnitsInitializeLMId);
  CreateZCADCommand(@QSave_com,'QSave',CADWG or CADWGChanged,0).CEndActionAttr:=
    [CEDWGNChanged];

finalization
  ProgramLog.LogOutFormatStr('Unit "%s" finalization',[{$INCLUDE %FILE%}],
    LM_Info,UnitsFinalizeLMId);
end.
