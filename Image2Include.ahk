; https://autohotkey.com/board/topic/93292-image2include-include-images-in-your-scripts/
; https://gist.github.com/AHK-just-me/5559658#file-image2include-ahk
; ======================================================================================================================
; Function:       Creates AHK #Include files for images providing a function which will internally create a bitmap/icon.
; AHK version:    1.1.10.01 (U32)
; Script version: 1.0.00.02/2013-06-02/just me - added support for icons (HICON)
;                 1.0.00.01/2013-05-18/just me - fixed bug producing invalid function names
;                 1.0.00.00/2013-04-30/just me
; Credits:        Bitmap creation is based on "How to convert Image data (JPEG/PNG/GIF) to hBITMAP?" by SKAN ->
;                 http://www.autohotkey.com/board/topic/21213-how-to-convert-image-data-jpegpnggif-to-hbitmap/?p=139257
; ======================================================================================================================
; This software is provided 'as-is', without any express or implied warranty.
; In no event will the authors be held liable for any damages arising from the use of this software.
; ======================================================================================================================
#NoEnv
SetBatchLines, -1
; ======================================================================================================================
; Some strings used to generate the #Include file
; ======================================================================================================================
Header1 := "
(Join`r`n
; ##################################################################################
; # This #Include file was generated by Image2Include.ahk, you must not change it! #
; ##################################################################################
)"
; ----------------------------------------------------------------------------------------------------------------------
Header2 := "
(Join`r`n
If (NewHandle)
   hBitmap := 0
If (hBitmap)
   Return hBitmap
)"
; ----------------------------------------------------------------------------------------------------------------------
Footer1 := "
(Join`r`n
If !DllCall(""Crypt32.dll\CryptStringToBinary"", ""Ptr"", &B64, ""UInt"", 0, ""UInt"", 0x01, ""Ptr"", 0, ""UIntP"", DecLen, ""Ptr"", 0, ""Ptr"", 0)
   Return False
VarSetCapacity(Dec, DecLen, 0)
If !DllCall(""Crypt32.dll\CryptStringToBinary"", ""Ptr"", &B64, ""UInt"", 0, ""UInt"", 0x01, ""Ptr"", &Dec, ""UIntP"", DecLen, ""Ptr"", 0, ""Ptr"", 0)
   Return False
; Bitmap creation adopted from ""How to convert Image data (JPEG/PNG/GIF) to hBITMAP?"" by SKAN
; -> http://www.autohotkey.com/board/topic/21213-how-to-convert-image-data-jpegpnggif-to-hbitmap/?p=139257
hData := DllCall(""Kernel32.dll\GlobalAlloc"", ""UInt"", 2, ""UPtr"", DecLen, ""UPtr"")
pData := DllCall(""Kernel32.dll\GlobalLock"", ""Ptr"", hData, ""UPtr"")
DllCall(""Kernel32.dll\RtlMoveMemory"", ""Ptr"", pData, ""Ptr"", &Dec, ""UPtr"", DecLen)
DllCall(""Kernel32.dll\GlobalUnlock"", ""Ptr"", hData)
DllCall(""Ole32.dll\CreateStreamOnHGlobal"", ""Ptr"", hData, ""Int"", True, ""PtrP"", pStream)
hGdip := DllCall(""Kernel32.dll\LoadLibrary"", ""Str"", ""Gdiplus.dll"", ""UPtr"")
VarSetCapacity(SI, 16, 0), NumPut(1, SI, 0, ""UChar"")
DllCall(""Gdiplus.dll\GdiplusStartup"", ""PtrP"", pToken, ""Ptr"", &SI, ""Ptr"", 0)
DllCall(""Gdiplus.dll\GdipCreateBitmapFromStream"",  ""Ptr"", pStream, ""PtrP"", pBitmap)
)"
; ----------------------------------------------------------------------------------------------------------------------
Footer2 := "
(Join`r`n
DllCall(""Gdiplus.dll\GdipDisposeImage"", ""Ptr"", pBitmap)
DllCall(""Gdiplus.dll\GdiplusShutdown"", ""Ptr"", pToken)
DllCall(""Kernel32.dll\FreeLibrary"", ""Ptr"", hGdip)
DllCall(NumGet(NumGet(pStream + 0, 0, ""UPtr"") + (A_PtrSize * 2), 0, ""UPtr""), ""Ptr"", pStream)
Return hBitmap
}
)"
; ======================================================================================================================
; Read INI file
; ======================================================================================================================
IniFile := A_ScriptFullPath . ":INI"
ImgDir := OutDir := A_ScriptDir
IniRead, Value, %IniFile%, Image2Include, ImgDir, 0
If (Value) && InStr(FileExist(Value), "D")
   ImgDir := Value
IniRead, Value, %IniFile%, Image2Include, OutDir, 0
If (Value) && InStr(FileExist(Value), "D")
   OutDir := Value
ImgFile := ""
; ======================================================================================================================
; Select an image file
; ======================================================================================================================
Gui, Margin, 20, 20
Gui, Add, Text, xm cNavy, Select Image File:
Gui, Add, Edit, xm y+5 w400 vImgFile +ReadOnly
Gui, Add, Button, x+10 yp hp vBtnFile gSelectFile, ...
Gui, Add, Text, xm y+5 cNavy, Select Output Directory:
Gui, Add, Edit, xm y+5 w400 vOutDir +ReadOnly, %OutDir%
Gui, Add, Button, x+10 yp hp vBtnFolder gSelectFolder, ...
GuiControlGet, P1, Pos, BtnFolder
Gui, Add, Text, xm y+5 cNavy, Script File:
Gui, Add, Edit, xm y+5 w400 vOutFile +ReadOnly
Gui, Add, CheckBox, xm vCreateOnLoad, Create at load-time
Gui, Add, CheckBox, xm vReturnHICON, Return HICON handle
Gui, Add, Button, xm vP2 gConvert, Convert Image
GuiControlGet, P2, Pos
Gui, Add, Button, % "x" . (P1X + P1W - P2W) . " yp wp gShow", Show Script
Gui, Add, StatusBar
Gui, Show, , Convert Image to #Include File
GuiControl, Focus, BtnFile
; Prepare the GUI which will show the generated script on demand
Gui, Script: +Owner1
Gui, Script: Margin, 0, 0
Gui, Script: Font, , Courier New
Gui, Script: Add, Edit, x0 y0 w0 h0
Gui, Script: Add, Edit, % "x0 y0 w" . Round(A_ScreenWidth * 0.8) . " h" . Round(A_ScreenHeight * 0.8)
                      . " vScriptEdit +hwndHEdit +HScroll"
Gui, Script: Add, StatusBar
Return
; ----------------------------------------------------------------------------------------------------------------------
GuiClose:
ExitApp
; ----------------------------------------------------------------------------------------------------------------------
SelectFile:
   Gui, +OwnDialogs
   FileSelectFile, ImgFile, 1, %ImgDir%, Select a Picture
                 , Img (*.bmp; *.emf; *.exif; *.gif; *.ico; *.jpg; *.png; *.tif; *.wmf)
   If (ErrorLevel)
      Return
   GuiControl, , ImgFile, %ImgFile%
   SplitPath, ImgFile, , ImgDir, ImgExt, ImgName
   ImgName := RegExReplace(ImgName, "[\W]")
   ImgName .= "_" . ImgExt
   GuiControl, , OutFile, %OutDir%\Create_%ImgName%.ahk
   IniWrite, %ImgDir%, %IniFile%, Image2Include, ImgDir
Return
; ----------------------------------------------------------------------------------------------------------------------
SelectFolder:
   Gui, +OwnDialogs
   FileSelectFolder, OutDir, *%OutDir%, 1, Select a folder to store the scripts:
   If (ErrorLevel)
      Return
   GuiControlGet, ImgFile
   GuiControl, , OutDir, %OutDir%
   If (ImgFile <> "") {
      GuiControl, , OutFile, %OutDir%\Create_%ImgName%.ahk
   }
   IniWrite, %OutDir%, %IniFile%, Image2Include, OutDir
Return
; ----------------------------------------------------------------------------------------------------------------------
Convert:
   SB_SetText("")
   Gui, Submit, NoHide
   If !FileExist(ImgFile) {
      GuiControl, Focus, BtnFile
      Return
   }
   If !InStr(FileExist(OutDir), "d") {
      GuiControl, Focus, BtnFolder
      Return
   }
   ; -------------------------------------------------------------------------------------------------------------------
   ; Read the image file
   ; -------------------------------------------------------------------------------------------------------------------
   File := FileOpen(ImgFile, "r")
   BinLen := File.Length
   File.RawRead(Bin, BinLen)
   File.Close()
   ; -------------------------------------------------------------------------------------------------------------------
   ; Encode the image file
   ; -------------------------------------------------------------------------------------------------------------------
   DllCall("Crypt32.dll\CryptBinaryToString", "Ptr", &Bin, "UInt", BinLen, "UInt", 0x01, "Ptr", 0, "UIntP", B64Len)
   VarSetCapacity(B64, B64Len << !!A_IsUnicode, 0)
   DllCall("Crypt32.dll\CryptBinaryToString", "Ptr", &Bin, "UInt", BinLen, "UInt", 0x01, "Ptr", &B64, "UIntP", B64Len)
   Bin := ""
   VarSetCapacity(Bin, 0)
   VarSetCapacity(B64, -1)
   B64 := RegExReplace(B64, "\r\n")
   B64Len := StrLen(B64)
   ; -------------------------------------------------------------------------------------------------------------------
   ; Write the AHK script
   ; -------------------------------------------------------------------------------------------------------------------
   PartLength := 16000
   CharsRead  := 1
   File := FileOpen(OutFile, "w", "UTF-8")
   File.Write(Header1 . "`r`nCreate_" . ImgName . "(NewHandle := False) {`r`n")
   If (CreateOnLoad)
      File.Write("Static hBitmap := Create_" . ImgName . "()`r`n")
   Else
      File.Write("Static hBitmap := 0`r`n")
   File.Write(Header2 . "`r`n")
   File.Write("VarSetCapacity(B64, " . StrLen(B64) . " << !!A_IsUnicode)`r`n")
   Part := "B64 := """
   While (CharsRead < B64Len) {
      File.Write(Part . SubStr(B64, CharsRead, PartLength) . """`r`n")
      CharsRead += PartLength
      If (CharsRead < B64Len)
         Part := "B64 .= """
   }
   File.Write(Footer1 . "`r`n")
   If (ReturnHICON)
      File.Write("DllCall(""Gdiplus.dll\GdipCreateHICONFromBitmap"", ""Ptr"", pBitmap, ""PtrP"", hBitmap, ""UInt"", 0)`r`n")
   Else
      File.Write("DllCall(""Gdiplus.dll\GdipCreateHBITMAPFromBitmap"", ""Ptr"", pBitmap, ""PtrP"", hBitmap, ""UInt"", 0)`r`n")
   File.Write(Footer2)
   File.Close()
   SB_SetText("  File " . OutFile . " successfully created!")
Return
; ======================================================================================================================
; Show the generated script
; ======================================================================================================================
Show:
   ; -------------------------------------------------------------------------------------------------------------------
   ; Reread the AHK script and show it
   ; -------------------------------------------------------------------------------------------------------------------
   FileRead, B64, %OutFile%
   If (ErrorLevel)
      Return
   FileGetSize, Size, %OutFile%
   Gui, Script: Default
   GuiControl, , ScriptEdit, %B64%
   ControlGet, Lines, LineCount, , , ahk_id %HEDIT%
   SB_SetText("  Size: " . Size . " bytes - Lines: " . Lines)
   Gui, Show, , %OutFile%
   Return
; ----------------------------------------------------------------------------------------------------------------------
ScriptGuiClose:
   GuiControl, , ShowEdit
   Gui, Hide
Return
