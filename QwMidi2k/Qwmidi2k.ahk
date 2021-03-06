/*
QwMidi2k v0.05 - by JimF, Midi effects by genmce

GNU - GPL 2.0 license statment
----------------------------------------------
QwMIDI2k by JimF, Midi effects by genmce.
The program lets you play a midi instrument or mulitple midi instruments 
from the computer keyboard. Notes can be output to different midi ports.
There is also a basic percussion facility and metronome.
Copyright (C) 2010  JimF

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
-----------------------------------------------


Escape = toggle on/off, changes icon

Ability to send multiple notes (coroutines)
Noteon is sent on keydown and noteoff on keyup
Change settings via tray icon
Store everything in an ini file
Trap keyboard repeats
GM Instrument selection
Percussion set
Enable Octave changing on the fly
FX
*/
;MAKE SURE WE'RE IN THE SAME DIRECTORY AS THE SCRIPT
vers := "0.05"
SetWorkingDir %A_ScriptDir%
#SingleInstance ignore
#NoEnv
#persistent
#HotkeyInterval 1
#maxthreads 1000
#HotkeyInterval 1
#MaxThreadsPerHotkey 1
;#MaxThreadsBuffer On
SendMode Event
SetKeyDelay -1
SetBatchLines -1
;Process, priority, , High

;DEFAULTS - used if the ini file is missing
;TIMERS and GLOBAL VARS
;KEYBOARDS
MidiDev3 := 0, MidiDev2 := 0, MidiDev1 := 0, SavOct2 := 4, SavOct1 := 3
SavInst2 := 7, SavInst1 := 7, SavChan2 := 2, SavChan1 := 1
SuspendState = 0

;EFFECTS
Velocity := 80, ShiftVelocity := 100, Trans = 0 ; no transpose
PB := 8192, PBdelta := 606 ;initial value and delta
ModVal := 0, Moddelta = 10, CCmod = 1 ;Mod wheel coarse
pb1 :=1, pb2 :=1, Mod1 := 1, Mod2 :=1, Sus1 :=1, Sus2 :=1 ;all fx on
F_PBend := "Off", F_Mod := "Lo", PBAuto := 0
octs1 := 1, octs2 :=1, Oct2 := SavOct2 *12, Oct1 := SavOct1 *12
lasnote := 0, har1 := 0, Chd := "Off", Sust := "Off"

GetKeyState, buttons, JoyButtons ;test for Joystick

;PERCUSSION VARS
PEnd := 10, PLeft := 7, Pright := 4, PUp := 17, PDown := 2

;GET VARS FROM INI FILE IF AVAILABLE
Gosub, ReadIni

;DEFAULT VELOCITY
Vel := Velocity

;Generic keyboard type
If %0% > 0
{
KBD = %1%
Gosub, Writeini
MsgBox %KBD% keyboard
}

If (KBD = "us")
bslash := 40, leshft := 7 
If (KBD = "eu")
bslash := 7, leshft := 5

;CREATE DROP DOWN MENU 
 Menu, tray, NoStandard
 Menu, tray, icon, active.ico
 Menu, Tray, Add, Help, Helpinfo 
 Menu, tray, add, Settings, MidiSet
 Menu, Tray, Add, Reload, ReloadProgram
 Menu, Tray, Add, Exit QwMidi2k, ExitProgram

;GUI TO DISPLAY EFFECTS KEY STATES
 Gui, 3:+NoActivate -Caption +Border
 Gui, 3:Add, Text, w900 vKbda
 Gui, 3:Show, Y30 H30
  
;INITIALISE MIDI
OpenCloseMidiAPI()
h_midiout2 := midiOutOpen(MidiDev2)
MidiStatus := 191 + SavChan2
midiOutShortMsg(h_midiout2, MidiStatus, SavInst2, 0) 
If (MidiDev1 = MidiDev2)
h_midiout1 := h_midiout2
else
h_midiout1 := midiOutOpen(MidiDev1)
MidiStatus := 191 + SavChan1
midiOutShortMsg(h_midiout1, MidiStatus, SavInst1, 0) 

If (MidiDev3 = MidiDev2)
h_midiout3 := h_midiout2
else
If (MidiDev3 = MidiDev1)
h_midiout3 := h_midiout1
else
h_midiout3 := midiOutOpen(MidiDev3)

Gosub, Dispanel
 
;Set Timer for FX
SetTimer, FX_Run, 50 

;NOTE STATE ARRAY-IGNORE KEYBOARD REPEATS & MANAGE NOTEOFF
Loop, 40
{
    Noteno1_%A_Index% =0
    Noteno2_%A_Index% =0
    Perceno%A_Index% =U
}
;END OF INITIALISATION
return

;INI READ ROUTINE
ReadIni:
IfExist, QwMidi2k.ini
{
IniRead, KBD, Qwmidi.ini, Settings, KBD , %KBD%
IniRead, MidiDev3, QwMidi2k.ini, Settings, MidiDev3, %MidiDev3%
IniRead, MidiDev2, QwMidi2k.ini, Settings, MidiDev2, %MidiDev2%
IniRead, MidiDev1, QwMidi2k.ini, Settings, MidiDev1, %MidiDev1%
IniRead, SavOct2, QwMidi2k.ini, Settings, SavOct2, %SavOct2%
IniRead, SavOct1, QwMidi2k.ini, Settings, SavOct1, %SavOct1%
IniRead, SavInst2, QwMidi2k.ini, Settings, SavInst2, %SavInst2%
IniRead, SavInst1, QwMidi2k.ini, Settings, SavInst1, %SavInst1%
IniRead, SavChan2, QwMidi2k.ini, Settings, SavChan2, %SavChan2%
IniRead, SavChan1, QwMidi2k.ini, Settings, SavChan1, %SavChan1%
IniRead, PEnd, QwMidi2k.ini, Settings, PEnd, %PEnd%
IniRead, PLeft, QwMidi2k.ini, Settings, PLeft, %PLeft%
IniRead, PRight, QwMidi2k.ini, Settings, PRight, %PRight%
IniRead, PUp, QwMidi2k.ini, Settings, PUp, %PUp%
IniRead, PDown, QwMidi2k.ini, Settings, PDown, %PDown%
IniRead, Beats, QwMidi2k.ini, Settings, Beats, %Beats%
}
else
Gosub WriteIni  ;WRITE AN INI FILE IF ITS MISSING
Return

;CALLED TO UPDATE INI WHENEVER SAVED PARAMETERS CHANGE
WriteIni:
IfNotExist, QwMidi2k.ini
 FileAppend,, QwMidi2k.ini
   IniWrite, %KBD%, Qwmidi.ini, Settings, KBD
   IniWrite, %MidiDev3%, QwMidi2k.ini, Settings, MidiDev3
   IniWrite, %MidiDev2%, QwMidi2k.ini, Settings, MidiDev2
   IniWrite, %MidiDev1%, QwMidi2k.ini, Settings, MidiDev1
   IniWrite, %SavOct2%, QwMidi2k.ini, Settings, SavOct2
   IniWrite, %SavOct1%, QwMidi2k.ini, Settings, SavOct1
   IniWrite, %SavInst2%, QwMidi2k.ini, Settings, SavInst2
   IniWrite, %SavInst1%, QwMidi2k.ini, Settings, SavInst1
   IniWrite, %SavChan2%, QwMidi2k.ini, Settings, SavChan2
   IniWrite, %SavChan1%, QwMidi2k.ini, Settings, SavChan1
   IniWrite, %PEnd%, QwMidi2k.ini, Settings, PEnd
   IniWrite, %PLeft%, QwMidi2k.ini, Settings, PLeft
   IniWrite, %PRight%, QwMidi2k.ini, Settings, PRight
   IniWrite, %PUp%, QwMidi2k.ini, Settings, PUp
   IniWrite, %PDown%, QwMidi2k.ini, Settings, PDown
   IniWrite, %Beats%, QwMidi2k.ini, Settings, Beats
Return

ReloadProgram:
   Gosub, writeini
   Reload
return

ExitProgram:

 midiOutClose(h_midiout2)
 If (h_midiout1 <> h_midiout2)
 midiOutClose(h_midiout1)
 If (h_midiout3 <> h_midiout2) and (h_midiout3 <> h_midiout1)
 midiOutClose(h_midiout3)
 
 OpenCloseMidiAPI()
 Gosub, WriteIni
 sleep 100
 ExitApp
return

;DISPLAY A GUI WITH A JPEG HELP FILE	
Helpinfo:
Menu, tray, Disable, Help	;STOP USER FROM CALLING THE SAME GUI TWICE
Gui, 2:Add, Picture,, QwMidi2k_%KBD%.jpg
Gui, 2:Show, , QwMidi2k v%vers% Help
return

;CLEANUP THE GUI AND RETRIEVE RESOURCES
2GuiClose:
Menu, tray, Enable, Help
Gui 2: Destroy
return

;THIS SETS UP THE MIDI DEVICE GUI 
MidiSet:
Menu, tray, Disable, Settings	;STOP THIS GUI BEING CALLED AGAIN

;SETTINGS FOR MIDI FOR BOTH KEYBOARDS
Gui, Add, Text, y10 x10, Upper Keyboard
Gui, Add, Text, y30 x10, Midi Port
Gui, Add, Text, x200 y10, Lower Keyboard
Gui, Add, Text, y30 x200, Midi Port

NumPorts := MidiOutsEnumerate() ; fills global array MidiOutPortName
Gui, Add, DropDownList, altsubmit x10 y50 w160 h140 vMidiport2 gSetChange
Gui, Add, DropDownList, altsubmit x200 y50 w160 h140 vMidiport1 gSetChange
Gui, Add, DropDownList, altsubmit x660 w150 y50 h140 vMidiport3 gSetChange
Loop % NumPorts {
Port := A_Index -1
Device:=MidiOutPortName%Port%     
GuiControl,, Midiport2, %Port% > %Device%
GuiControl,, Midiport1, %Port% > %Device%
GuiControl,, Midiport3, %Port% > %Device%
}
Tmp := MidiDev2 + 1
GuiControl, Choose, Midiport2, %Tmp%
Tmp := MidiDev1 + 1
GuiControl, Choose, Midiport1, %Tmp%
Tmp := MidiDev3 + 1
GuiControl, Choose, Midiport3, %Tmp%
Gui, Add, Text, x10 y82, Channel
Gui, Add, Text, x200 y82, Channel
Gui, Add, Edit, w40 x130 y80 
Gui, Add, UpDown, gSetChange vUDChan2 Range1-16, 1
Gui, Add, Edit, w40 x320 y80 
Gui, Add, UpDown, gSetChange vUDChan1 Range1-16, 1
GuiControl, , UDChan2, %SavChan2%
GuiControl, , UDChan1, %SavChan1%
Gui, Add, Text, x10 y112 gSetChange, Default (Saved) Octave
Gui, Add, Text, x200 y112 gSetChange,  Default (Saved) Octave
Gui, Add, Edit, w40 x130 y110 
Gui, Add, UpDown, gSetChange vUDOct2 Range1-6, 4
Gui, Add, Edit, w40 x320 y110 
Gui, Add, UpDown, gSetChange vUDOct1 Range1-6, 4
GuiControl, , UDOct2, %SavOct2%
GuiControl, , UDOct1, %SavOct1%
Gui, Add, Text, x10 y150, Instrument
Gui, Add, Edit, ReadOnly vInst2 x150 y150 w20
Gui, Add, Text, x200 y150, Instrument
Gui, Add, Edit, ReadOnly vInst1 x340 y150 w20
Gui, Add, DropDownList, x10 y170 w160 h220 altsubmit vSelInst2 gSetChange
Gui, Add, DropDownList, x200 y170 w160 h220 altsubmit vSelInst1 gSetChange

;GM NAMES FROM AN INI FILE
while A_INDEX < 128
{ 
 iniread, iniline, QwInstr.ini, Instruments, %A_INDEX%
 GuiControl,, SelInst2, %A_INDEX%>%iniline%
 GuiControl,, SelInst1, %A_INDEX%>%iniline%
} 
;SET THE LAST INSTRUMENT SAVED AS DEFAULT
GuiControl, Choose, SelInst2, %SavInst2%
GuiControl, Choose, SelInst1, %SavInst1%
GuiControl,, Inst2, %SavInst2%
GuiControl,, Inst1, %SavInst1%

Gui, Add, Text, y200 x10, Effects
Gui, Add, Checkbox, x10 y230  vPB2 gSetChange Checked, Pitch Bend
Gui, Add, Text, y200 x200, Effects
Gui, Add, Checkbox, x200 y230 vPB1 gSetChange Checked, Pitch Bend
Gui, Add, Checkbox, x10 y260  vMod2 gSetChange Checked, Mod Wheel
Gui, Add, Checkbox, x200 y260  vMod1 gSetChange Checked, Mod Wheel
Gui, Add, Checkbox, x10 y290  vSus2 gSetChange Checked, Sustain
Gui, Add, Checkbox, x200 y290  vSus1 gSetChange Checked, Sustain

;SET UP EFFECTS
Gui, Add, Text, x390 y10, Effects Settings
Gui, Add, Text, x390 y30, Velocity
Gui, Add, Edit, x510 w60 y81 
Gui, Add, UpDown, gSetChange vUDStVel Range0-127, 127
Gui, Add, Text, x390 y82, Set Velocity
Gui, Add, Text, x390 y112, Set Shift Vel
Gui, Add, Edit, w60 x510 y111
Gui, Add, UpDown, gSetChange vUDShVel Range0-127, 100
GuiControl, , gSetChange UDStVel, %Velocity%
GuiControl, , gSetChange UDShVel, %ShiftVelocity%

;SET UP TRANSPOSE GUI
Gui, Add, Text, x390 y150, Transpose
Gui, Add, Text, x390 y172 gSetChange, SemiTones
Gui, Add, Edit, w60 x510 y171 
Gui, Add, UpDown, gSetChange vUDTranspose Range-12-12, 0
GuiControl, , UDTranspose, %Trans%

;PITCH BEND AND MOD
Gui, Add, Text, x390 y210, Pitch Wheel %A_TAB% %A_TAB% Auto
Gui, Add, CheckBox, x556 y210 vPba gSetChange Checked%PBAuto%
Gui, Add, Text, x390 y232, Set Delta
Gui, Add, Edit, w60 x510 y230 
Gui, Add, UpDown, gSetChange vUDPBend Range50-900, 606
GuiControl, , UDPBend, %PBDelta%
Gui, Add, Text, x390 y270, Mod Wheel
Gui, Add, Text, x474 y270, Coarse
Gui, Add, Radio, x510 y270  vCmod gSetChange Checked, % "  Fine" 
Gui, Add, Radio, x556 y270  gSetChange
Gui, Add, Text, x390 y292 gSetChange, Set Delta
Gui, Add, Edit, w60 x510 y290 
Gui, Add, UpDown, gSetChange vUDMod Range50-900, 606
GuiControl, , UDMod, %ModDelta%5

;SET UP PERCUSSION GUI
Gui, Add, Text, y10 x660, Percussion Keys
Gui, Add, Text, y30 x660, Midi Port
Gui, Add, Text, x610 y84, Left
Gui, Add, DropDownList, altsubmit x660 w150 y80 vPLeft gSetChange
Gui, Add, Text, x610 y114, Right
Gui, Add, DropDownList, altsubmit x660 w150 y110 vPRight gSetChange
Gui, Add, Text, x610 y144, Up
Gui, Add, DropDownList, altsubmit x660 w150 y140 vListUp gSetChange
Gui, Add, Text, x610 y174, Down
Gui, Add, DropDownList, altsubmit x660 w150 y170 vListDown gSetChange
Gui, Add, Text, x610 y204, End `n + `nMetronome
Gui, Add, DropDownList, altsubmit x660 w150 y200 vListEnd gSetChange
;READ GM PERCUSSION NAMES INTO LISTBOX FROM INI FILE
while A_INDEX < 46
{ 
 iniread, iniline, QwInstr.ini, Percussion, %A_INDEX%
 GuiControl,, PLeft, %iniline%
 GuiControl,, PRight, %iniline%
 GuiControl,, ListUp, %iniline%
 GuiControl,, ListDown, %iniline%
 GuiControl,, ListEnd, %iniline%
}  
;SELECT LAST SAVED PERCUSSION INSTRUMENTS
GuiControl, Choose, PLeft, %PLeft%
GuiControl, Choose, PRight, %PRight%
GuiControl, Choose, ListUp, %PUp%
GuiControl, Choose, ListDown, %PDown%
GuiControl, Choose, ListEnd, %PEnd%

;SET UP METRONOME GUI
Gui, Add, Text, x610 y230, Metronome
Gui, Add, Edit, x610 y261 w44  
Gui, Add, UpDown, vMet Range40-160,60
Gui, Add, Button, x660 w70 y260 gDoneMet, On/Set
Gui, Add, Button, x740 w70 y260 gMetoff, Off
GuiControl,, Met, %Beats%

;BUTTON TO EXIT THE SETTINGS GUI - DUPLICATES CLOSING THE WINDOW
Gui, Add, Button,Y+20 x740 gDoneSel, Exit Midi Settings
Gui, Show,, QwMidi2k Settings
return

;CALLED WHEN METRONOME VALUE IS CHANGED
DoneMet:
Gui, Submit, NoHide
Beats := Met
Metroon(Beats)
Gui, Flash
return

;STOPS TIMERS - METRONOME
Metoff:
AlTimeroff()
Gui, Flash
Return

;GENERIC ROUTINE CALLED WHENEVER SETTINGS GUI IS CHANGED TO UPDATE VARIABLES
;ALSO UPDATES MIDI VALUES
SetChange:
Gui, Submit, NoHide
Gui, Flash
If %Midiport2%
MidiDev2:= Midiport2 -1
If %Midiport1%
MidiDev1:= Midiport1 -1
If %Midiport3%
MidiDev3:= Midiport3 -1

Velocity := UDStVel, ShiftVelocity := UDShVel
;TrayTip,, %SelInst2% , 20, 17

If %SelInst2%
SavInst2:= SelInst2
If %SelInst1%
SavInst1:= SelInst1

SavChan2 := UDChan2, SavChan1 := UDChan1
If (SavChan2 = SavChan1) AND (h_midiout1 = h_midiout2) {
MsgBox, , Warning, To use seperate instruments on the same `nmidi synth please use seperate channels, 4
SavInst1 := SavInst2
}
If (SavChan1 = 10) OR (SavChan2 = 10)
MsgBox, , Warning, Channel 10 is used for percussion, 4

SavOct2 := UDOct2, SavOct1 := UDOct1, Moddelta := UDMod
Oct1 := SavOct1*12, Oct2 := SavOct2*12, PBAuto := Pba


If (CMod = 1)
CCmod := 1
else
CCmod := 33

If %Transpose%
Trans = %Transpose% 

CleanUp:
 midiOutClose(h_midiout2)
 If (h_midiout1 <> h_midiout2)
 midiOutClose(h_midiout1)
 If (h_midiout3 <> h_midiout2) and (h_midiout3 <> h_midiout1)
 midiOutClose(h_midiout3)
 
 OpenCloseMidiAPI()
 h_midiout2 := midiOutOpen(MidiDev2)
 If (MidiDev1 = MidiDev2)
 h_midiout1 := h_midiout2
 else
 h_midiout1 := midiOutOpen(MidiDev1)
 
 If (MidiDev3 = MidiDev1)
 h_midiout3 := h_midiout1
 else
 If (MidiDev3 = MidiDev2)
 h_midiout3 := h_midiout2
 else
 h_midiout3 := midiOutOpen(MidiDev3)
 
;SendPC
 MidiStatus := 191 + SavChan1
 midiOutShortMsg(h_midiout1, MidiStatus, SavInst1, 0) 
 MidiStatus := 191 + SavChan2
 midiOutShortMsg(h_midiout2, MidiStatus, SavInst2, 0) 
 
Gosub, WriteIni
 
;TrayTip,, %SavInst2% , 20, 17
Gui, Show,, QwMidi2k Settings
GuiControl,, Midiport2, %MidiDev2%
GuiControl,, Midiport1, %MidiDev1% 
GuiControl,, Midiport3, %MidiDev3%
GuiControl, Choose, SelInst2, %SavInst2%
GuiControl, Choose, SelInst1, %SavInst1%
GuiControl,, Inst2, %SavInst2%
GuiControl,, Inst1, %SavInst1%
GuiControl,, UDChan2, %SavChan2%
GuiControl,, UDChan1, %SavChan1%
GuiControl,, UDOct2, %SavOct2%
GuiControl,, UDOct1, %SavOct1%
return

;EXIT SETTINGS GUI BY EXIT BUTTON OR CLOSE WINDOW
DoneSel:
GuiClose:
Gui Destroy
Menu, tray, Enable, Settings
return  

Dispanel:
Tmp := "Lower Keyboard :: Octave [" (Floor(Oct1/12)) "] :: Chord [" Chd "]	Upper Keyboard :: Octave [" (Floor(Oct2/12)) "]" 
GuiControl,3: , kbda , Pitch Bend [%F_PBend% %PBAuto%] :: Mod Wheel [%F_Mod%] :: Sustain [%Sust%] :: Transpose [%Trans%] %A_TAB% %Tmp%
Return

;GLOBAL SUSPEND FUNCTION TO RESTORE WINDOWS KEYBOARD
SuspendScript()
{
 Global SuspendState
 If (A_IsSuspended == 0) 
{
 menu, tray,icon, inactive.ico,,1
 suspend on
 SuspendState = 1
 Gosub, writeini
 exit ;necessary 
}
 suspendstate == 1
 menu, tray,icon, active.ico,,1
 suspend off
 SuspendState = 0
 Gosub, writeini
}	

;ESCAPE RESTORES KEYBOARD CONTROL 
SC001::
 suspend permit
 SuspendScript()
return

;DIAGNOSTIC ON MENU KEY #KeyHistory 0 to disable history
SC15D::

ListHotkeys
Keyhistory
return

LoKbdOn(Note) {
global har1, har2, har3, lasnote
if (lasnote = Note)
return
if (lasnote > 0)
{
SendNoteOff(lasnote, 1)
SendNoteOff(lasnote+har1, 1)
SendNoteOff(lasnote+har2, 1)
SendNoteOff(lasnote+har3, 1)
}
SendNoteOn(Note, 1)
If (har1 > 0)
{
SendNoteOn(Note+har1, 1)
SendNoteOn(Note+har3, 1)
SendNoteOn(Note+har3, 1)
lasnote := Note
}
}

HiKbdOn(Note) {
SendNoteOn(Note, 2)
}

;MAIN PIANO KEYBOARD FOR PLAY
SendNoteOn(Note, KBD) {
global h_midiout1, h_midiout2, Vel, Trans, Pnote
, SavInst1, SavInst2, Oct1, Oct2, SavChan1, SavChan2
If (Note < 1)
Return
 ;THE NOTE USED INCLUDES ANY TRANSPOSE VALUE AND OCTAVE
   Pnote := Note + Trans + Oct%KBD%
   ;ONLY PLAY A NOTE IF ITS BEEN RELEASED
   if Noteno%KBD%_%Note% = 0
   {
   ;PLAY IT SAM !
   MidiStatus := 143 + SavChan%KBD%
   midiOutShortMsg(h_midiout%KBD%, MidiStatus, Pnote, vel) 
   Noteno%KBD%_%Note% := Pnote
   }
} 

LoKbdOff(Note) {
global har1, har2, har3, lasnote
if (har1 = 0)
SendNoteOff(Note, 1)
if (lasnote != Note)
return
if (har1 > 0)
{
SendNoteOff(Note, 1)
SendNoteOff(Note+har1, 1)
SendNoteOff(Note+har2, 1)
SendNoteOff(Note+har3, 1)
lasnote := 0
}
}

HiKbdOff(Note) {
SendNoteOff(Note, 2)
}

;SEND PIANO NOTE OFF - TRIGGERED FROM KEY UP
SendNoteOff(Note, KBD) {
  global h_midiout1, h_midiout2, Pnote, SavCHan1, SavChan2
  ;ONLY IF THE NOTE IS BEING PLAYED
  If (Note < 1)
  Return
  If Noteno%KBD%_%Note% > 0
  {
  Pnote := Noteno%KBD%_%Note%
  MidiStatus := 127 + SavChan%KBD%
  midiOutShortMsg(h_midiout%KBD%, MidiStatus, Pnote, 0) 
  Noteno%KBD%_%Note% := 0 
  }
} 

;PLAY PERCUSSION KEYBOARD NOTE
PerKeyOn(Per)
{
global h_midiout3, Note
;OFFSET TO PERCUSSION VALUES
Note := Per + 34 
   ;ONLY PLAY IF NOTE NOT ALEADY ACTIVE
   if Perceno%Per% = U
   {
   MidiStatus := 143 + 10
   midiOutShortMsg(h_midiout3,MidiStatus, Note, 127) 
   Perceno%Per% = D
   keywait %newkey%
   }
}
return

;STOP PERCUSSION KEYBOARD NOTE
PerKeyOff(Per)
{  global h_midiout3, Octave, Note
Note := Per + 34
  If Perceno%Per% = D
  {
  MidiStatus := 127 + 10
  midiOutShortMsg(h_midiout3, MidiStatus, Note, 0) 
  Perceno%Per% = U
  }
}
return

;SWITCH METRONOME TIMER ON 
Metroon(Beats) {
MetDel := 60000/Beats
;MsgBox %MetDel%
SetTimer, Metro, %MetDel%
;SetTimer, Metro, On
}

;USE SPACE BAR TO STOP ALL TIMERS (EX EFFECTS)
Altimeroff() {
SetTimer, Metro, Off
}

;METRONOME TIMER ROUTINE- CALLED FOR EVERY BEAT
Metro:
PerKeyOn(PEnd)
sleep 10
PerKeyOff(PEnd)
return

;OCTAVE UP AND DOWN
*SC152::	;Ins
  Oct2 := SavOct2*12, Oct1 := SavOct1*12
  Gosub Dispanel
Return

^SC149::	;PgUp
  if Oct2 < 84
  Oct2 += 12
  Gosub Dispanel
Return

^SC151::	;PgDn
  if Oct2 > 12
  Oct2 -= 12
  Gosub Dispanel
Return

SC149::		;PgUP
  if Oct1 < 84
  Oct1 += 12
  Gosub Dispanel
Return

SC151::		;PgDn
  if Oct1 > 12
  Oct1 -= 12
  Gosub Dispanel
Return

;EFFECTS TIMER ROUTINE - RUNS CONSTANTLY
FX_Run: 

If (Buttons >0 AND Joyuse =1)
{
GetKeyState, JoyX, JoyX
GetKeyState, JoyY, JoyY 

if JoyX > 70
    F_Mod = Hi
else if JoyX < 30
    F_Mod = Lo
	
if JoyY > 70
	F_PBend = Up
else if JoyY < 30
	F_PBend = Dn 
else 
	F_PBend = Off
}
	
If (F_PBend = "Up")
{
Gosub, Dispanel
PB := PB+PBdelta 
If (PB > 16383)
{
PB:=16383
If PBAuto = 1
{
PB := 8192, F_PBend := "Off"
Gosub, Dispanel
}
}
If pb1 =1
midiOutShortMsg(h_midiout1, (SavChan1+223), (PB&0x7F), (PB>>7))
If pb2 =1
midiOutShortMsg(h_midiout2, (SavChan2+223), (PB&0x7F), (PB>>7))
}

If (F_PBend = "Dn") 
{
Gosub, Dispanel
PB := PB-PBdelta 
IF (PB < 0) 
{
PB:= 0
If PBAuto = 1
{
PB := 8192, F_PBend := "Off"
Gosub, Dispanel
}
}
If pb1 =1
midiOutShortMsg(h_midiout1, (SavChan1+223), (PB&0x7F), (PB>>7))
If pb2 =1
midiOutShortMsg(h_midiout2, (SavChan2+223), (PB&0x7F), (PB>>7))
}

If PBAuto = 0
If (PB <> 8192 and F_PBend = "Off") 
{
Gosub, Dispanel
PB := 8192 ; sets pitch bend to center    
If pb1 =1
midiOutShortMsg(h_midiout1, (Savchan1+ 223), (PB&0x7F), (PB>>7))
If pb2 =1
midiOutShortMsg(h_midiout2, (Savchan2+ 223), (PB&0x7F), (PB>>7))
}

If (F_Mod = "Hi" and Modval < 127)
{
Gosub, Dispanel
ModVal := ModVal + Moddelta
If ModVal > 127   ; check for max value reached
ModVal:= 127
If Mod1 =1
midiOutShortMsg(h_midiout1, SavChan1 + 175, CCmod, ModVal) 
;midiport, cc = 176, CCmod is var above, ModVal in vars above 
If Mod2 =1
midiOutShortMsg(h_midiout2, SavChan2 + 175, CCmod, ModVal)
}

If (F_Mod = "Lo" and Modval > 0)
{
Gosub, Dispanel
ModVal := ModVal- Moddelta 
If ModVal < 0      ; check min value reached. 
ModVal:=0
If Mod1 =1
midiOutShortMsg(h_midiout1, SavChan1 + 175, CCmod, ModVal)
If Mod2 =1
midiOutShortMsg(h_midiout2, SavChan2 + 175, CCmod, ModVal)  
}
Return

;KEYBOARD HOTKEYS
;USING THE * TO MAKE KEYS UNCONDITIONAL SO I CAN EXTEND
;THE MUSIC KEYBOARD RANGE tO SHIFT & LOCK KEYS

;Panic Button - all notes off
*SC045::	;Break
midiOutShortMsg(h_midiout1, (Savchan1+175), 123, 0)
midiOutShortMsg(h_midiout2, (Savchan2+175), 123, 0)
Return

;DRUM KIT
*SC14F::PerkeyOn(PEnd)	 ;End
*SC14F Up::PerkeyOff(PEnd)
*SC14B::PerkeyOn(PLeft)	 ;Left
*SC14B Up::PerKeyOff(PLeft)
*SC14D::PerkeyOn(PRight) ;Right
*SC14D Up::PerkeyOff(PRight)
*SC148::PerkeyOn(PUp)	 ;Up
*SC148 Up::PerkeyOff(PUp)
*SC150::PerkeyOn(PDown)	 ;Down
*SC150 Up::PerkeyOff(PDown)
*SC039::Altimeroff()	 ;Space
*SC138::Metroon(Beats)	 ;RAlt

;Chord Hotkeys
*SC03B:: ;F1
Chd = Maj
Gosub, ChClean
har1 := 4, har2 := 7, har3 := 0
Return
*SC03C:: ;F2
Chd = Min
Gosub, ChClean
har1 := 3, har2 := 7, har3 := 12
Return
*SC03D:: ;F3
Chd = Ma7
Gosub, ChClean
har1 := 4, har2 := 7, har3 := 10
return
*SC03E:: ;F4
Chd = Mi7
Gosub, Chclean
har1 := 3, har2 := 7, har3 := 10
Return
*SC03F:: ;F5
Chd = 5th
Gosub, ChClean
har1 := 7, har2 := 0, har3 := 0
Return
*SC040:: ;F6
Chd = Oct
Gosub, ChClean
har1 := 12, har2 := 0, har3 := 0
Return
*SC041:: ;F7
Chd = Pwr
Gosub, ChClean
har1 := 5, har2 := 10, har3 := -12
Return
*SC042:: ;F8
Chd = Off
Gosub, ChClean
har1 := 0
Return

Chclean:
SendNoteOff(lasnote+har1, 1)
SendNoteOff(lasnote+har2, 1)
SendNoteOff(lasnote+har3, 1)
Gosub, Dispanel
Return

;EFFECTS HOTKEYS
*SC15B:: vel := ShiftVelocity ;SET VOLUME HIGH OR LOW
*SC15B UP:: vel := Velocity 

Joy6::
*SC038::  ;LAlt Sustain
Sust = On
If Sus1 =1
midiOutShortMsg(h_midiout1, (SavChan1+175), 64, 127)	
If Sus2 =1
midiOutShortMsg(h_midiout2, (SavChan2+175), 64, 127)
Gosub, Dispanel
Return
*SC038 UP::
Joy5::
Sust = Off
If Sus1 =1
midiOutShortMsg(h_midiout1, (SavChan1+175), 64, 0)
If Sus2 =1
midiOutShortMsg(h_midiout2, (SavChan2+175), 64, 0)
Gosub, Dispanel
Return

*SC044::F_Mod = Hi	; F10 Mod wheel up 
*SC043::F_Mod = Lo	; F9 Mod wheel down 
*SC058::
F_PBend = Up		; F12 Pitch bend Up
Joyuse = 0
Return
*SC057::F_PBend = Dn
Joyuse = 0
Return			  ;F11 Pitch bend down
*SC058 UP::		  ;F12,F11 Pitch Bend Off
*SC057 UP::
If PBAuto = 0
F_PBend = Off
Return

;KEYBOARD BOTTOM ROW
*SC02A::LoKbdOn(leshft)	;f (UK) g (US) LShift
*SC02A UP::LoKbdOff(leshft)
*SC03A::LoKbdOn(6)		;f# Capslock
*SC03A UP::LoKbdOff(6)
*SC056:: LoKbdOn(bslash)	;g (UK) top e (US)
*SC056 UP::LoKbdOff(bslash)
*SC01E::LoKbdOn(8)		;g# (A)
*SC01E UP::LoKbdOff(8)
*SC02C::LoKbdOn(9)		;a (Z)
*SC02C UP::LoKbdOff(9)
*SC01F::LoKbdOn(10)		;a# (S)
*SC01F UP::LoKbdOff(10)
*SC02D::LoKbdOn(11)		;b (X)
*SC02D UP::LoKbdOff(11)
*SC02E::LoKbdOn(12)		;c (C)
*SC02E UP::LoKbdOff(12)
*SC021::LoKbdOn(13)		;c# (F)
*SC021 UP::LoKbdOff(13)
*SC02F::LoKbdOn(14)		;d (V)
*SC02F UP::LoKbdOff(14)
*SC022::LoKbdOn(15)		;d#
*SC022 UP::LoKbdOff(15)
*SC030::LoKbdOn(16)		;e (B)
*SC030 UP::LoKbdOff(16)
*SC031::LoKbdOn(17)		;f (N)
*SC031 UP::LoKbdOff(17)
*SC024::LoKbdOn(18)		;f# (J)
*SC024 UP::LoKbdOff(18)
*SC032::LoKbdOn(19)		;g (M)
*SC032 UP::LoKbdOff(19)
*SC025::LoKbdOn(20)		;g# (K)
*SC025 UP::LoKbdOff(20)
*SC033::LoKbdOn(21)		;a (,)
*SC033 UP::LoKbdOff(21)
*SC026::LoKbdOn(22)		;a# (L)
*SC026 UP::LoKbdOff(22)
*SC034::LoKbdOn(23)		;b (.)
*SC034 UP::LoKbdOff(23)
*SC035::LoKbdOn(24)		;c (/)
*SC035 UP::LoKbdOff(24)
*SC028::LoKbdOn(25)		;c# (')
*SC028 UP::LoKbdOff(25)
SC136::LoKbdOn(26)		;d (RShift)
SC136 UP::LoKbdOff(26)

;KEYBOARD TOP ROW
*SC00F::HiKbdOn(17)	;f (TAB)
*SC00F UP::HiKbdOff(17)
*SC002::HiKbdOn(18)	;f# (1)
*SC002 UP::HiKbdOff(18)
*SC010::HiKbdOn(19)	;g (Q)
*SC010 UP::HiKbdOff(19)
*SC003::HiKbdOn(20)	;g# (2)
*SC003 UP::HiKbdOff(20)
*SC011::HiKbdOn(21)	;a (W)
*SC011 UP::HiKbdOff(21)
*SC004::HiKbdOn(22)	;a# (3)
*SC004 UP::HiKbdOff(22)
*SC012::HiKbdOn(23)	;b (E)
*SC012 UP::HiKbdOff(23)
*SC013::HiKbdOn(24)	;c (R)
*SC013 UP::HiKbdOff(24)
*SC006::HiKbdOn(25)	;c# (5)
*SC006 UP::HiKbdOff(25)
*SC014::HiKbdOn(26)	;d (T)
*SC014 UP::HiKbdOff(26)
*SC007::HiKbdOn(27)	;d# (6)
*SC007 UP::HiKbdOff(27)
*SC015::HiKbdOn(28)	;e (Y)
*SC015 UP::HiKbdOff(28)
*SC016::HiKbdOn(29)	;f (U)
*SC016 UP::HiKbdOff(29)
*SC009::HiKbdOn(30)	;f# (8)
*SC009 UP::HiKbdOff(30)
*SC017::HiKbdOn(31)	;g (I)
*SC017 UP::HiKbdOff(31)
*SC00A::HiKbdOn(32)	;g# (9)
*SC00A UP::HiKbdOff(32)
*SC018::HiKbdOn(33)	;a (O)
*SC018 UP::HiKbdOff(33)
*SC00B::HiKbdOn(34)	;a# (0)
*SC00B UP::HiKbdOff(34)
*SC019::HiKbdOn(35)	;b (P)
*SC019 UP::HiKbdOff(35) 
*SC01A::HiKbdOn(36)	;c ([)
*SC01A UP::HiKbdOff(36)
*SC00D::HiKbdOn(37)	;c# (=)
*SC00D UP::HiKbdOff(37)
*SC01B::HiKbdOn(38)	;d (])
*SC01B UP::HiKbdOff(38)

;KEYBOARD NULLED KEYS
*SC020::return
*SC023::return
*SC027::return
*SC005::return
*SC008::return
*SC00C::return
return

;THATS THE END OF MY STUFF (JimF) THE REST IS WHAT LASZLO AND PAXOPHOBE WERE USING ALREADY
;AHK FUNCTIONS FOR MIDI OUTPUT - calling winmm.dll
;http://msdn.microsoft.com/library/default.asp?url=/library/en-us/multimed/htm/_win32_multimedia_functions.asp
;Derived from Midi.ahk dated 29 August 2008 - streaming support removed

OpenCloseMidiAPI() {  ; at the beginning to load, at the end to unload winmm.dll
  Static hModule
   If hModule
   DllCall("FreeLibrary", UInt,hModule), hModule := ""
    If (0 = hModule := DllCall("LoadLibrary",Str,"winmm.dll")) {
    MsgBox Cannot load libray winmm.dll
    Exit
}
}

;FUNCTIONS FOR SENDING SHORT MESSAGES

midiOutOpen(uDeviceID = 0) { ; Open midi port for sending individual midi messages --> handle
strh_midiout = 0000

result := DllCall("winmm.dll\midiOutOpen", UInt,&strh_midiout, UInt,uDeviceID, UInt,0, UInt,0, UInt,0, UInt)
   If (result or ErrorLevel) {
      MsgBox There was an error opening the midi port. %uDeviceID% `nError code %result%`nErrorLevel = %ErrorLevel%
      Return -1
}
   Return UInt@(&strh_midiout)
}


midiOutShortMsg(h_midiout, MidiStatus, Param1, Param2) {
  ;h_midiout: handle to midi output device returned by midiOutOpen
  ;EventType, Channel combined -> MidiStatus byte: http://www.harmony-central.com/MIDI/Doc/table1.html
  ;Param3 should be 0 for PChange, ChanAT, or Wheel
  ;Wheel events: entire Wheel value in Param2 - the calling function splits it into two bytes
  result := DllCall("winmm.dll\midiOutShortMsg", UInt,h_midiout, UInt, MidiStatus|(Param1<<8)|(Param2<<16), UInt)
  If (result or ErrorLevel)  {
    MsgBox There was an error sending the midi shortmessage event: `Handle-%h_midiout% Status-%MidiStatus% P1-%Param1% P2-%Param2% `(%result%`, %ErrorLevel%)
    Return -1
}
}

midiOutClose(h_midiout) {  ; Close MidiOutput
Loop 9 {
  result := DllCall("winmm.dll\midiOutClose", UInt,h_midiout)
   If !(result or ErrorLevel)
   Return
   Sleep 250
}
  MsgBox Error in closing the midi output port. %h_midiout% There may still be midi events being processed.
  Return -1
}

;UTILITY FUNCTIONS
MidiOutGetNumDevs() { ; Get number of midi output devices on system, first device has an ID of 0
  Return DllCall("winmm.dll\midiOutGetNumDevs")
}

MidiOutNameGet(uDeviceID = 0) { ; Get name of a midiOut device for a given ID

;MIDIOUTCAPS struct
;    WORD      wMid;
;    WORD      wPid;
;    MMVERSION vDriverVersion;
;    CHAR      szPname[MAXPNAMELEN];
;    WORD      wTechnology;
;    WORD      wVoices;
;    WORD      wNotes;
;    WORD      wChannelMask;
;    DWORD     dwSupport;

VarSetCapacity(MidiOutCaps, 50, 0)  ; allows for szPname to be 32 bytes
OffsettoPortName := 8, PortNameSize := 32
result := DllCall("winmm.dll\midiOutGetDevCapsA", UInt,uDeviceID, UInt,&MidiOutCaps, UInt,50, UInt)

If (result OR ErrorLevel) {
  MsgBox Error %result% (ErrorLevel = %ErrorLevel%) in retrieving the name of midi output %uDeviceID%
  Return -1
}

VarSetCapacity(PortName, PortNameSize)
DllCall("RtlMoveMemory", Str,PortName, Uint,&MidiOutCaps+OffsettoPortName, Uint,PortNameSize)
Return PortName
}

MidiOutsEnumerate() { ; Returns number of midi output devices, creates global array MidiOutPortName with their names
  Local NumPorts, PortID
  MidiOutPortName =
  NumPorts := MidiOutGetNumDevs()

  Loop %NumPorts% {
  PortID := A_Index -1
  MidiOutPortName%PortID% := MidiOutNameGet(PortID)
}
  Return NumPorts
}

UInt@(ptr) {
   Return *ptr | *(ptr+1) << 8 | *(ptr+2) << 16 | *(ptr+3) << 24
}

PokeInt(p_value, p_address) { ; Windows 2000 and later
DllCall("ntdll\RtlFillMemoryUlong", UInt,p_address, UInt,4, UInt,p_value)
}