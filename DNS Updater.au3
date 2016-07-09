#include <AutoItConstants.au3>
#include <EditConstants.au3>
#include <Constants.au3>
#include <GUIConstantsEx.au3>
#include <TrayConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <MsgBoxConstants.au3>
#include <ComboConstants.au3>
#include <StringConstants.au3>

Local Const $REG_BASE = "HKEY_CURRENT_USER\SOFTWARE\DNSUpdater"
Local Const $GRID = 12
Local Const $WIDTH = 360
Local Const $HEIGHT = $GRID * 11

#RequireAdmin

If Not IsAdmin () Then
   MsgBox (BitOR ($MB_OK, $MB_ICONERROR), "Error: Administrator Rights Required", _
	  "This program requires Administrator privileges to run.")
   Exit
EndIf

Opt ("GUIOnEventMode", 1)
Opt ("GUICloseOnEsc", 0)
Opt ("TrayMenuMode", 3)
Opt ("TrayOnEventMode", 1)
Opt ("TrayAutoPause", 0)

;Function for getting HWND from PID
Func _GetHwndFromPID($PID)
   Local $winlist = WinList()
   For $i = 1 To $winlist[0][0]
	  If $winlist[$i][0] <> "" And _
		 WinGetProcess($winlist[$i][1]) = $PID Then Return $winlist[$i][1]
   Next
   Return 0
EndFunc

Local $pid = RegRead ($REG_BASE, "PID")
If $pid <> "" Then
   Local $hWnd = _GetHwndFromPID ($pid)
   If $hWnd <> 0 Then
	  WinSetState ($hWnd, "", @SW_SHOW)
	  WinActivate ($hWnd)
	  Exit
   EndIf
EndIf
RegWrite ($REG_BASE, "PID", "REG_SZ", @AutoItPID)

TraySetOnEvent ($TRAY_EVENT_PRIMARYDOUBLE, "EventTrayPriDouble")
TraySetToolTip ("DNS Updater")
TraySetClick (8)

Global $trayExit = TrayCreateItem ("Exit")
TrayItemSetOnEvent ($trayExit, "EventQuit")

Local $ifLines = RunCmd ("netsh interface ipv4 show interfaces")
Local $ifNames = ""
Local $lastSelected = RegRead ($REG_BASE, "LastSelected")
Local $ifDefault = ""
Local $lastName
For $line In $ifLines
   Local $res = StringRegExp ($line, " connected +(.+)$", $STR_REGEXPARRAYMATCH)
   If @error Then ContinueLoop
   If $res[0] == $lastSelected Then $ifDefault = $lastSelected
   $lastName = $res[0]
   $ifNames &= "|" & $res[0]
Next
If $ifDefault == "" Then $ifDefault = $lastName

Global $window = GUICreate ("DNS Updater", $WIDTH, $HEIGHT, -1, -1, _
   BitOR ($WS_CAPTION, $WS_POPUP, $WS_SYSMENU))
GUISetOnEvent ($GUI_EVENT_CLOSE, "EventToTray")

GUICtrlCreateLabel ("Interface:", $GRID, $GRID * 1.25 )

Global $ifCombo = GUICtrlCreateCombo ("", $GRID * 5.5, $GRID, $WIDTH - ($GRID * 6.5), $GUI_DOCKHEIGHT, _
   BitOR ($GUI_SS_DEFAULT_COMBO, $CBS_DROPDOWNLIST))
GuiCtrlSetData ($ifCombo, $ifNames, $ifDefault)
GUICtrlSetOnEvent ($ifCombo, "EventIfCombo")

Global $currentLabel = GUICtrlCreateLabel ("", $GRID, $GRID * 4, $WIDTH - ($GRID * 2), $GRID * 1.5)

Global $dhcpRadio = GUICtrlCreateRadio ("DHCP DNS", $GRID, $GRID * 6)
GUICtrlSetOnEvent ($dhcpRadio, "EventDHCPRadio")

Global $staticRadio = GUICtrlCreateRadio ("Static DNS:", $GRID, $GRID * 8)
GUICtrlSetOnEvent ($staticRadio, "EventStaticRadio")

Global $staticInput = GUICtrlCreateInput ("", $GRID * 8, $GRID * 8, $GRID * 8)
GUICtrlSetOnEvent ($staticInput, "EventStaticInput")
GUIRegisterMsg ($WM_COMMAND, "EventCommand")

Global $staticApplyButton = GUICtrlCreateButton (" Change ", $GRID * 17, $GRID * 7.75)
GUICtrlSetOnEvent ($staticApplyButton, "EventStaticApplyButton")

GetInterfaceState ($ifDefault)

GUISetState (@SW_SHOWNORMAL, $window)

While Sleep (10000)
WEnd

Func GetInterfaceState ($ifName)
   Local $isDHCP = False
   Local $ip
   Local $staticLines = RunCmd ('netsh interface ipv4 show dnsserver name="' & $ifName & '"')

   For $line In $staticLines
	  If StringRegExp ($line, "DHCP") Then $isDHCP = True

	  Local $res = StringRegExp ($line, "DNS[^:]*: +(.+)", $STR_REGEXPARRAYMATCH)
	  If @error Then ContinueLoop
	  $ip = $res[0]
   Next

   GUICtrlSetData ($currentLabel, "Current: " & $ip & (($isDHCP)? " (DHCP)" : " (Static)"))

   Local $ipStatic = RegRead ($REG_BASE & "\Static", $ifName)
   GUICtrlSetData ($staticInput, $ipStatic)
   ValidateStaticInput ()

   If $isDHCP Then
	  GUICtrlSetState ($dhcpRadio, $GUI_CHECKED)
	  GUICtrlSetState ($staticRadio, $GUI_UNCHECKED)
	  GUICtrlSetState ($staticInput, $GUI_DISABLE)
	  GUICtrlSetCursor ($staticInput, -1) ; Arrow
	  GUICtrlSetState ($staticApplyButton, $GUI_DISABLE)
   Else
	  GUICtrlSetState ($dhcpRadio, $GUI_UNCHECKED)
	  GUICtrlSetState ($staticRadio, $GUI_CHECKED)
	  GUICtrlSetState ($staticInput, $GUI_ENABLE)
	  GUICtrlSetCursor ($staticInput, 5) ; IBeam
   EndIf
EndFunc

Func ValidateIP ($ip)
   Local $res = StringRegExp ($ip, '^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$', _
	  $STR_REGEXPARRAYMATCH)
   If @error Then Return False

   If $res[0] > 0 And $res[0] < 255 And _
	  $res[1] >= 0 And $res[1] <= 255 And _
	  $res[2] >= 0 And $res[2] <= 255 And _
	  $res[3] > 0 And $res[3] < 255 Then
	  Return True
   EndIf

   Return False
EndFunc

Func ValidateStaticInput ()
   Local $ip = GUICtrlRead ($staticInput)
   If ValidateIP ($ip) Then
	  GUICtrlSetBkColor ($staticInput, 0xFFFFFF)
	  GUICtrlSetColor ($staticInput, 0x000000)
	  GUICtrlSetState ($staticApplyButton, $GUI_ENABLE)
	  Return True
   EndIf

   GUICtrlSetBkColor ($staticInput, 0xFFA0A0)
   GUICtrlSetColor ($staticInput, 0xFFFFFF)
   GUICtrlSetState ($staticApplyButton, $GUI_DISABLE)
   Return False
EndFunc

Func RunCmd ($cmd)
   GUISetCursor (15, 1) ; Hourglass
   Local $pid = Run ($cmd, "", @SW_HIDE, $STDOUT_CHILD)
   ProcessWaitClose ($pid)
   GUISetCursor (-1, 1) ; Arrow
   Local $out = StdoutRead ($pid)
   return StringSplit (StringTrimRight (StringStripCR ($out), StringLen (@CRLF)), @CRLF)
EndFunc

Func ApplyStaticIP ()
   Local $ifName = GUICtrlRead ($ifCombo)
   If $ifName == "" Then Return

   Local $ip = GUICtrlRead ($staticInput)
   If Not ValidateIP ($ip) Then Return

   RunCmd ("netsh interface ipv4 add dnsserver " & $ifName & _
	  " address=" & $ip & " index=1 validate=no")

   GetInterfaceState ($ifName)
EndFunc

Func Quit ()
   RegDelete ($REG_BASE, "PID")
   GUIDelete ($window)
   Exit
EndFunc

Func EventQuit ()
   Quit ()
EndFunc

Func EventIfCombo ()
   Local $ifName = GUICtrlRead ($ifCombo)
   If $ifName == "" Then Return

   RegWrite ($REG_BASE, "LastSelected", "REG_SZ", $ifName)

   GetInterfaceState ($ifName)

   Local $ip = RegRead ($REG_BASE & "\Static", $ifName)
   If $ip == "" Then Return

   GUICtrlSetData ($staticInput, $ip)
   ValidateStaticInput ()
EndFunc

Func EventDHCPRadio ()
   GUICtrlSetState ($staticInput, $GUI_DISABLE)
   GUICtrlSetCursor ($staticInput, -1) ; Arrow
   GUICtrlSetState ($staticApplyButton, $GUI_DISABLE)

   Local $ifName = GUICtrlRead ($ifCombo)
   If $ifName == "" Then Return

   RunCmd ("netsh interface ipv4 set dnsserver " & $ifName & " source=dhcp")

   GetInterfaceState ($ifName)
EndFunc

Func EventStaticRadio ()
   GUICtrlSetState ($staticInput, $GUI_ENABLE)
   GUICtrlSetCursor ($staticInput, 5) ; IBeam
   ValidateStaticInput ()
   ApplyStaticIP ()
EndFunc

Func EventCommand ($hWndGUI, $MsgID, $WParam, $LParam)
   Local $nNotifyCode = BitShift($WParam, 16)
   Local $nID = BitAND($WParam, 0xFFFF)
   Local $hCtrl = $LParam

   If $nID = $staticInput And $nNotifyCode = 0x300 Then ValidateStaticInput ()
   Return $GUI_RUNDEFMSG
EndFunc

Func EventStaticInput ()
   ValidateStaticInput ()
EndFunc

Func EventStaticApplyButton ()
   Local $ip = GUICtrlRead ($staticInput)
   If Not ValidateIP ($ip) Then Return

   Local $ifName = GUICtrlRead ($ifCombo)
   If $ifName == "" Then Return

   RegWrite ($REG_BASE & "\Static", $ifName, "REG_SZ", $ip)
   ApplyStaticIP ()
EndFunc

Func EventTrayPriDouble ()
   GUISetState (@SW_SHOW, $window)
EndFunc

Func EventToTray ()
   GUISetState (@SW_HIDE, $window)
EndFunc
