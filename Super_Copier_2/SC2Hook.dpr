{
    This file is part of SuperCopier2.

    SuperCopier2 is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    SuperCopier2 is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
}

library SC2Hook;

uses
  Windows,
  ShellApi,
  madCodeHook,
  SCHookShared in 'SCHookShared.pas';

var
	NextSHFileOperationA : function(const lpFileOp : TSHFileOpStructA):integer;stdcall;
	NextSHFileOperationW : function(const lpFileOp : TSHFileOpStructW):integer;stdcall;

{$IFDEF NEW_HOOK_ENGINE}
	NextShellExecuteExA : function(var lpExecInfo : TShellExecuteInfoA):LongBool;stdcall;
	NextShellExecuteExW : function(var lpExecInfo : TShellExecuteInfoW):LongBool;stdcall;

  App2HookData:PSCApp2HookData=nil;
  App2HookMapping:THandle=0;
{$ENDIF}

{$R *.res}

//******************************************************************************
//******************************************************************************
//                           Fonctions Helper
//******************************************************************************
//******************************************************************************

//******************************************************************************
// MultiNullStrLen: r?cup?re la taille d'une chaine termin?e par NumNull z?ros
//******************************************************************************
function MultiNullStrLen(S:Pointer;NumNull:Integer):Integer;
var PS:PChar;
    FoundNull:Integer;
begin
  Result:=0;
  FoundNull:=0;
  PS:=S;

  while FoundNull<=NumNull do
  begin
    if PS^=#0 then
      Inc(FoundNull)
    else
      FoundNull:=0;

    Inc(PS);
    Inc(Result);
  end;
end;

//******************************************************************************
// ExtractFileName: fonction standard de Delphi
//******************************************************************************
function ExtractFileName(FN:String):string;
var P:PChar;
begin
  P:=PChar(FN);
  inc(P,Length(FN));

  while (P>=PChar(FN)) and (P^<>'\') do
  begin
		if (P^>='A') and (P^<='Z') then Inc(P^,32); // uppercase -> lowercase
    dec(P);
  end;
  Result:=P+1;
end;

//******************************************************************************
//******************************************************************************
//                           Fonctions de hook
//******************************************************************************
//******************************************************************************

//******************************************************************************
// NewSHFileOperationA
//******************************************************************************
function NewSHFileOperationA(const lpFileOp : TSHFileOpStructA):integer;stdcall;
var HookData:TSCHook2AppData;
    Buffer:array of byte;
    BufferSize:Integer;
    Handled:Boolean;
begin
  with HookData,lpFileOp do
  begin
    Operation:=wFunc;
    ProcessId:=GetCurrentProcessId;
    SourceSize:=2*MultiNullStrLen(pFrom,2); // 2 #0 car ce sont des chaines a double 0 terminal
                                            // les donn?es vont ?tre stock?es sour forme unicode, donc 2 bytes/char au lieu d'1

    if wFunc in [FO_COPY,FO_MOVE] then // pTo n'est valide que si copie ou d?placement
      DestinationSize:=2*MultiNullStrLen(pTo,2)
    else
      DestinationSize:=0;

    // le buffer va contenir les 3 ?l?ments plac?s les uns derri?re les autres
    BufferSize:=SizeOf(TSCHook2AppData)+SourceSize+DestinationSize;
    SetLength(Buffer,BufferSize);

    // on ?crit dans le buffer HookData suivi de la destination suivi de la source
    // tout est converti en unicode
    Move(HookData,Buffer[0],SizeOf(TSCHook2AppData));
    MultiByteToWideChar(CP_ACP,0,pTo,DestinationSize div 2,@Buffer[SizeOf(TSCHook2AppData)],DestinationSize);
    MultiByteToWideChar(CP_ACP,0,pFrom,SourceSize div 2,@Buffer[SizeOf(TSCHook2AppData)+DestinationSize],SourceSize);

    // envoi des donn?es par IPC
    if not SendIpcMessage(IPC_NAME,Buffer,BufferSize,@Handled,SizeOf(Boolean)) then
    begin
      Handled:=False;
    end;

    // si action pas prise en charge, on renvoie le tout a windows
    if Handled then
    begin
      Result:=NO_ERROR;
    end
    else
    begin
      Result:=NextSHFileOperationA(lpFileOp);
    end;

    SetLength(Buffer,0);
  end;
end;

//******************************************************************************
// NewSHFileOperationW
//******************************************************************************
function NewSHFileOperationW(const lpFileOp : TSHFileOpStructW):integer;stdcall;
var HookData:TSCHook2AppData;
    Buffer:array of byte;
    BufferSize:Integer;
    Handled:Boolean;
begin
  with HookData,lpFileOp do
  begin
    ProcessId:=GetCurrentProcessId;
    DataType:=hdtSHFileOperation;
    Operation:=wFunc;
    SourceSize:=MultiNullStrLen(pFrom,4); // 4 #0 car ce sont des chaines unicode a double 0 terminal

    if wFunc in [FO_COPY,FO_MOVE] then // pTo n'est valide que si copie ou d?placement
      DestinationSize:=MultiNullStrLen(pTo,4)
    else
      DestinationSize:=0;

    // le buffer va contenir les 3 ?l?ments plac?s les uns derri?re les autres
    BufferSize:=SizeOf(TSCHook2AppData)+SourceSize+DestinationSize;
    SetLength(Buffer,BufferSize);

    // on ?crit dans le buffer HookData suivi de la destination suivi de la source
    Move(HookData,Buffer[0],SizeOf(TSCHook2AppData));
    Move(pTo^,Buffer[SizeOf(TSCHook2AppData)],DestinationSize);
    Move(pFrom^,Buffer[SizeOf(TSCHook2AppData)+DestinationSize],SourceSize);

    // envoi des donn?es par IPC
    if not SendIpcMessage(IPC_NAME,Buffer,BufferSize,@Handled,SizeOf(Boolean)) then
    begin
      Handled:=False;
    end;

    // si action pas prise en charge, on renvoie le tout a windows
    if Handled then
    begin
      Result:=NO_ERROR;
    end
    else
    begin
      Result:=NextSHFileOperationW(lpFileOp);
    end;

    SetLength(Buffer,0);
  end;
end;

//******************************************************************************
// NewShellExecuteExW
//******************************************************************************
{$IFDEF NEW_HOOK_ENGINE}
function NewShellExecuteExW(var lpExecInfo : TShellExecuteInfoW):LongBool;
var HookData:TSCHook2AppData;
var FN,ExplorersList:string;
begin
  with HookData,lpExecInfo do
	begin
    ProcessId:=GetCurrentProcessId;
    DataType:=hdtShellExecute;

    MessageBoxW(0,lpFile,pwidechar(widestring(string(App2HookData.HandledProcesses))),0);

		FN:=ExtractFileName(lpFile);
		if Pos(FN,ExplorersList)<>0 then // doit-on hooker le processus qui va ?tre cr???
		begin
			fMask:=fMask or SEE_MASK_NOCLOSEPROCESS; // on veut r?cup?rer un handle su processus cr??

			Result:=NextShellExecuteExW(lpExecInfo);
			if Result and (hProcess<>0) then
			begin
				//SendMessage(HandleDest,WM_HOOKEXPLORER,hProcess,GetCurrentProcessId);
				CloseHandle(hProcess);
			end;
		end
		else
		begin
			Result:=NextShellExecuteExW(lpExecInfo);
		end;
	end;
end;
{$ENDIF}

//******************************************************************************
// LibraryProc
//******************************************************************************
procedure LibraryProc(AReason:Integer);
begin
  case AReason of
    DLL_PROCESS_ATTACH:
    begin
{$IFDEF NEW_HOOK_ENGINE}
      // acc?s aux donn?es provenant de l'appli
      App2HookMapping:=OpenFileMapping(FILE_MAP_READ,True,FILE_MAPING_NAME);
      App2HookData:=MapViewOfFile(App2HookMapping,FILE_MAP_READ,0,0,0);
{$ENDIF}

      // hook des fonctions
      HookAPI('shell32.dll','SHFileOperationA',@NewSHFileOperationA,@NextSHFileOperationA);

      if GetVersion and $80000000 = 0 then // Windows NT ?
      begin
        HookAPI('shell32.dll','SHFileOperationW',@NewSHFileOperationW,@NextSHFileOperationW);
{$IFDEF NEW_HOOK_ENGINE}
        HookAPI('shell32.dll','ShellExecuteExW',@NewShellExecuteExW,@NextShellExecuteExW);
{$ENDIF}
      end;
    end;
    DLL_PROCESS_DETACH:
    begin
{$IFDEF NEW_HOOK_ENGINE}
      UnMapViewOfFile(App2HookData);
      CloseHandle(App2HookMapping);
{$ENDIF}
    end;
    DLL_THREAD_ATTACH:;
    DLL_THREAD_DETACH:;
  end;
end;

begin
  DllProc:=@LibraryProc;
  LibraryProc(DLL_PROCESS_ATTACH);
end.



