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

program zcad;

{$IFNDEF LINUX}
  {$APPTYPE GUI}
{$ENDIF}

//файл с объявлениями директив компилятора - должен быть подключен во все файлы проекта
{$INCLUDE zengineconfig.inc}

//zcad/zcadelectrotech compile mode
//если он отсутствует см. https://github.com/zamtmn/zcad/blob/master/cad_source/docs/userguide/locale/ru/for_developers/building_from_sources.adoc
//if missing see https://github.com/zamtmn/zcad/blob/master/BUILD_FROM_SOURCES.md
{$INCLUDE buildmode.inc}

uses
  {$IFDEF REPORTMMEMORYLEAKS}heaptrc,{$ENDIF}
  //first, setup crash report file path (uzcregexceptionsfile) and instll exceptions handler for console and gui
  uzcregexceptionsfile,uzbexceptionscl,uzbexceptionsgui,
  //second, install data providers for crash report
  uzcregexceptions,

  Interfaces,forms, classes,LCLVersion,
  uzclog,uzcreglog,

  uzcSysInfo,uzcfsplash,
  uzcsysvars,

  uzcsysparams,uzcPathMacros,
  uzbpaths,uzbCommandLineParser,uzcCommandLineParser,

  uzcregMemProfiler,

  varman,
  //
  //if need create variables before system.pas loading, place unit bellow
  //
  uzcregzscript,//this need before other registers
  uzcoiregister,
  uzcreggeneralwiewarea,
  uzcregfontmanager,
  uzcregpaths,
  uzcregenginefeatures,
  uzcreginterface,
  uzcregnavigatorentities,
  {$IFDEF ELECTROTECH}
  uzcregnavigatordevices,
  {$ENDIF}
  //
  //next line load system.pas
  //
  uzcregsystempas,//loading rtl/system.pas
  {$INCLUDE allgeneratedfiles.inc}//correct defs in system.pas
  uzcregother,//setup SysVar

 {$IFDEF WINDOWS}
  uMetaDarkStyle,uDarkStyleSchemes,uDarkStyleSchemesAdditional,
  uDarkStyleSchemesLoader,
 {$ENDIF}

  UUnitManager,
  uzefontmanager,
  uzeFontFileFormatSHX,
  uzeFontFileFormatTTFBackendFTTest,uzeffttf,
  uzeffLibreDWG,uzeffLibreDWG2Ents,


  uzcdrawings,


  {DXF entities}
  uzeent3dface,uzeentsolid,
  uzeentcircle,uzeentarc,uzeentellipse,
  uzeentblockinsert,uzeentdevice,
  uzeentdimaligned,uzeentdimdiametric,uzeentdimension,
  uzeentdimensiongeneric,uzeentdimradial,uzeentdimrotated,
  uzeenthatch,
  uzeentline,
  uzeentlwpolyline,
  uzeenttext,uzeentmtext,
  uzeentpoint,
  uzeentpolyline,
  uzeentspline,
  uzeenttable,

  {$IFDEF ELECTROTECH}
  {ZCAD entities}
  uzcentcable,
  uzcentelleader,
  uzcentnet,
  {$ENDIF}



  //varman,
  //UGDBDescriptor,
  uzccommandsmanager,
  uzcdevicebase,
  URecordDescriptor,
  //gdbase,
  //splashwnd,
  {$IFDEF ELECTROTECH}
  uzcfprojecttree,
  {$ENDIF}
  //ugdbabstractdrawing,
  sysutils,



  //commandline,

  uzccommand_selectframe,
  uzccommand_ondrawinged,
  uzccommand_stretch,
  uzccommand_selsim,
  {$IFDEF ELECTROTECH}
  uzccomdb,
  {$ENDIF}
  uzccomdraw,
  uzccommand_copy,
  uzccommand_move,
  uzccommand_mirror,
  uzccommand_3dpoly,
  uzccommand_print,
  uzccommand_blockpreviewexport,
  uzccommand_blocksinbasepreviewexport,
  uzccommand_layoff,
  uzccommand_insertlayersfrombase,
  uzccommand_LayerOn,uzccommand_LayerOff,
  uzccommand_loadmenus,
  uzccommand_loadpalettes,
  uzccommand_loadtoolbars,
  uzccommand_loadactions,
  uzccommand_DWGNew,
  uzccommand_DWGNext,uzccommand_DWGPrev,
  uzccommand_DWGClose,
  uzccommand_load,uzcCommand_LoadLibrary,
  uzccommand_mergeblocks,
  uzccommand_merge,
  uzccommand_saveas,
  uzccommand_qsave,
  uzccommand_cancel,
  uzccommand_zoom,
  uzccommand_zoomwindow,
  uzccommand_pan,
  uzccommand_view,
  uzccommand_camreset,
  uzccommand_undo,uzccommand_redo,
  uzccommand_selectall,uzccommand_deselectall,
  uzccommand_regen,
  uzccommand_updatepo,
  uzccommand_treestat,
  uzccommand_copyclip,uzccommand_CopyBase,uzccommand_PasteClip,
  uzccommand_multiselect2objinsp,
  uzccommand_selobjchangelayertocurrent,uzccommand_selobjchangelwtocurrent,
  uzccommand_selobjchangecolortocurrent,uzccommand_selobjchangeltypetocurrent,
  uzccommand_selobjchangetstyletocurrent,uzccommand_selobjchangedimstyletocurrent,
  uzccommand_polydiv,
  uzccommand_selectobjectbyaddres,
  uzccommand_selectonmouseobjects,
  uzccommand_VarsEdSel,uzccommand_VarsED,uzccommand_VarsEdBD,uzccommand_VarsEdUnit,
  uzccommand_unitsman,
  uzccommand_rebuildtree,
  uzccommand_changeprojtype,
  uzccommand_storefrustum,
  uzccommand_snapproperties,
  uzccommand_polytest,

  uzccommand_loadlayout,uzccommand_savelayout,
  uzccommand_quit,
  uzccommand_units,uzccommand_layer,uzccommand_textstyles,uzccommand_dimstyles,
  uzccommand_linetypes,uzccommand_colors,

  uzccommand_clearfilehistory,

  uzccommand_show,uzccommand_showtoolbar,

  uzccommand_setobjinsp,
  uzccommand_dbgmemsummary,uzccommand_dbgMemProfiler,
  uzccommand_executefile,
  uzccommand_dbgClipboard,
  uzccommand_dbgCmdList,uzccommand_dbgBlocksList,
  uzccommand_entslist,
  uzccommand_saveoptions,
  uzccommand_showpage,
  uzccommand_options,
  uzccommand_about,uzccommand_help,
  uzccommand_get3dpoint,uzccommand_get3dpoint_drawrect,uzccommand_getrect,
  uzccommand_dist,

  uzccommand_line,uzccommand_circle,uzccommand_arc,

  uzccommand_line2,uzccommand_circle2,//old commands

  uzccommand_scale,uzccommand_rotate,uzccommand_rotateents,uzccommand_erase,
  uzccommand_inverseselected,uzccommand_cutclip,

  uzccommand_polyed,

  uzccommand_polygon,uzccommand_rectangle,
  uzccommand_matchprop,
  uzccommand_dimlinear,uzccommand_dimaligned,uzccommand_dimdiameter,
  uzccommand_dimradius,

  uzccommand_exampleinsertdevice,uzccommand_examplecreatelayer,
  uzccommand_ExampleVarManipulation,
  uzccommand_exampleconstructtomodalspace,

  uzccommand_VarsLink,

  uzccommand_text,
  uzccommand_exporttexttocsv,
  uzccommand_dataexport,uzccommand_dataimport,
  uzccommand_extdrentslist,uzccommand_extdralllist,uzccommand_extdrAdd,uzccommand_extdrRemove,
  uzccommand_DevDefSync,
  uzccommand_VariablesAdd,uzccommand_VarValueCopy,

  uzccommand_dbgRaiseException,uzccommand_dbgGetAV,uzccommand_dbgGetOutOfMem,uzccommand_dbgGetStackOverflow,
  uzccommand_dbgPlaceAllBlocks,uzcCommand_dbgSelectEnts,
  uzccommand_Insert,uzccommand_BlockReplace,

  uzccommand_NumDevices,

  uzccommand_tstCmdLinePrompt,
  uzccommand_explDbCheck,

  uzccommand_cfgAddSupportPath,uzccommand_cfgSetRendererBackEnd,
  uzccommand_DockingOptions,
  uzcCommand_MoveEntsByMouse,
  uzcCommand_LPCSRun,
  uzcCommand_Find,
  uzcCommand_SpellCheck,
  uzcCommand_Duplicate,

  uzcCommand_PlaceDelegate,

  uzcenitiesvariablesextender,uzcExtdrLayerControl,uzcExtdrSmartTextEnt,
  uzcExtdrIncludingVolume,uzcExtdrSCHConnection,uzcExtdrSCHConnector,
  uzcExtdrReport,
  uzcfhistorywindow,

  {$IFNDEF DARWIN}
  {$IFDEF ELECTROTECH}
  //**for velec func**//
  uzccommand_drawsuperline,uzccommand_l2sl,
  uzvslagcab, //автопрокладка кабелей по именным суперлиниям
  uzvagslcom, //создания именных суперлиний в комнате между извещателями
  uzvstripmtext, //очистка мтекста, сделано плохо, в будущем надо переделывать мтекст и механизм.
  uzvcabmountmethod,
  uzvelscheme, //создание электрической схемы
  uzvaddconnection, //добавить подключение к устройству
  uzvremoveconnection, //удаление подключения к устройству
  uzvmanemcom, //управления и обработка полученой электрической модели
  uzvmanemschemalevelone, //создание одноуровневой схемы
  uzvmanemdialogcom,//запуск генератора схемы через диалоговое окно
  {$IFDEF WINDOWS}//uzvmodeltoxlsx,
  uzvmodeltoxlsxfps, uzvdevtoxlsx, uzvxlsxtocad,uzvelectricalexcelcom,{$ENDIF}  //запуск экспорта информации из veb модели в xlsx на OLE

  //uzvelectricalexcelcom,
  //**//
  {$ENDIF}
  uzcregconnectmanager,
  {$ENDIF}

  //uzccomexample2,
  uzventsuperline,
  //uzccomobjectinspector,
  //uzccomexperimental,

  {$IFDEF ELECTROTECH}
  uzcregelectrotechfeatures,
  uzccomelectrical,
  uzccomops,
  //uzccommaps,
  uzceCommand_SCHConnection,
  {$ENDIF}
  uzcmainwindow,
  uzcuidialogs,
  uzcstrconsts,
  uzeiopalette,
  uzctextpreprocessorimpl,
  uzcregisterenitiesfeatures,
  uzcregisterenitiesextenders,
  uzcoiregistermultiproperties,
  uzclibraryblocksregister,
  {$IF not((DEFINED(WINDOWS))and(DEFINED(LCLQT5)))}uzglviewareaogl,uzglviewareaoglmodern,{$ENDIF}
  uzglviewareagdi,uzglviewareacanvas,
  {$IFDEF WINDOWS}{uzglviewareadx,}{$ENDIF}

  uzctbexttoolbars, uzctbextmenus, uzctbextpalettes,

  uzcinterface,
  uzccommand_dbgappexplorer,
  uzelongprocesssupport;

//resourcestring
// rsStartAutorun='Execute *components\autorun.cmd';

var
  lpsh:TLPSHandle;
  i:integer;
  scrfile:string;

{$R *.res}

begin
  programlog.logoutstr('<<<<<<<<<<<<<<<End units initialization',0,LM_Debug);
     if ZCSysParams.notsaved.otherinstancerun then
                                      exit;
  lpsh:=LPS.StartLongProcess('Start program',@lpsh,0);
{$IFDEF REPORTMMEMORYLEAKS}printleakedblock:=true;{$ENDIF}
{$IFDEF REPORTMMEMORYLEAKS}
       SetHeapTraceOutput(ConcatPaths([GetTempPath,'memory-heaptrace.txt']));
       keepreleased:=true;
{$ENDIF}
  //Application_Initialize перемещен в инициализацию uzcfsplash чтоб показать сплэш пораньше
  //Application.Initialize;

  //инициализация drawings
  FontManager.EnumerateFontFiles;
  uzcdrawings.startup('$(DistribPath)/rtl/dwg/DrawingVars.pas','');
  uzcdevicebase.startup;
  {$IF lcl_fullversion>2001200}
  {$ELSE}
    Application.MainFormOnTaskBar:=true;
  {$ENDIF}
  //создание окна программы
  {$IF DEFINED(MSWINDOWS)}
  LoadLResources;
  if SysVar.INTF.INTF_ColorScheme<>nil then
    ApplyMetaDarkStyle(GetScheme(SysVar.INTF.INTF_ColorScheme^));
  {$ENDIF}
  Application.CreateForm(TZCADMainWindow,ZCADMainWindow);
  ZCADMainWindow.show;
  {if sysvar.SYS.SYS_IsHistoryLineCreated<>nil then
                                                  sysvar.SYS.SYS_IsHistoryLineCreated^:=true;}
  ZCMsgCallBackInterface.TextMessage(format(rsZCADStarted,[programname,sysvar.SYS.SYS_Version^]),TMWOHistoryOut);
  application.ProcessMessages;

  ZCADMainWindow.SwithToProcessBar;

  FromDirsIterator(sysvar.PATH.Preload_Paths^,'*.cmd','autorun.cmd',RunCmdFile,nil);
  if CommandLineParser.HasOption(RunScript)then
    for i:=0 to CommandLineParser.OptionOperandsCount(RunScript)-1 do begin
      scrfile:=CommandLineParser.OptionOperand(RunScript,i);
      commandmanager.executefile(scrfile,drawings.GetCurrentDWG,nil);
    end;

  if ZCSysParams.notsaved.preloadedfile<>'' then begin
    commandmanager.executecommand('Load('+ZCSysParams.notsaved.preloadedfile+')',drawings.GetCurrentDWG,drawings.GetCurrentOGLWParam);
    ZCSysParams.notsaved.preloadedfile:='';
  end;

  ZCADMainWindow.SwithToHintText;
  //убираем сплэш
  ZCMsgCallBackInterface.Do_SetNormalFocus;
  removesplash;

  TZGuiExceptionsHandler.EnableLCLCaptureExceptions;
  LPS.EndLongProcess(lpsh);
  Application.run;

  sysvar.SYS.SYS_RunTime:=nil;

  //createsplash(false);
  //SplashForm.TXTOut('ugdbdescriptor.finalize;',false);uzcdrawings.finalize;

  programlog.logoutstr('END.',0,LM_Necessarily);
  programlog.logoutstr('<<<<<<<<<<<<<<<Start units finalization',0,LM_Debug);
end.



