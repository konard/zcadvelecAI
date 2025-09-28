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

unit uzccmdinfoform;
{$INCLUDE zengineconfig.inc}

interface

uses
  uzcLog,Forms,
  uzcSynForm,
  uzcstrconsts;

var
  InfoFormVar:TSynForm=nil;

procedure createInfoFormVar;

implementation

procedure createInfoFormVar;
begin
  if not assigned(InfoFormVar) then begin
    InfoFormVar:=TSynForm.Create(application.MainForm);
    InfoFormVar.DialogPanel.HelpButton.Hide;
    InfoFormVar.DialogPanel.CancelButton.Hide;
    InfoFormVar.Caption:=(rsCAUTIONnoSyntaxCheckYet);
  end;
end;

initialization

finalization
  ProgramLog.LogOutFormatStr('Unit "%s" finalization',[{$INCLUDE %FILE%}],
    LM_Info,UnitsFinalizeLMId);
end.
