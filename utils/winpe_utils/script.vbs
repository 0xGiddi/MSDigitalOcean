' JSON Decoding class. Removed uneeded Encode function
' From http://demon.tw By Demon
Class clsJSON
    Private Whitespace, NumberRegex, StringChunk
    Private b, f, r, n, t
    Private Sub Class_Initialize
        Whitespace = " " & vbTab & vbCr & vbLf
        b = ChrW(8)
        f = vbFormFeed
        r = vbCr
        n = vbLf
        t = vbTab

        Set NumberRegex = New RegExp
        NumberRegex.Pattern = "(-?(?:0|[1-9]\d*))(\.\d+)?([eE][-+]?\d+)?"
        NumberRegex.Global = False
        NumberRegex.MultiLine = True
        NumberRegex.IgnoreCase = True

        Set StringChunk = New RegExp
        StringChunk.Pattern = "([\s\S]*?)([""\\\x00-\x1f])"
        StringChunk.Global = False
        StringChunk.MultiLine = True
        StringChunk.IgnoreCase = True
    End Sub  
    Public Function Decode(ByRef str)
        Dim idx
        idx = SkipWhitespace(str, 1)

        If Mid(str, idx, 1) = "{" Then
            Set Decode = ScanOnce(str, 1)
        Else
            Decode = ScanOnce(str, 1)
        End If
    End Function  
    Private Function ScanOnce(ByRef str, ByRef idx)
        Dim c, ms
        idx = SkipWhitespace(str, idx)
        c = Mid(str, idx, 1)
        If c = "{" Then
            idx = idx + 1
            Set ScanOnce = ParseObject(str, idx)
            Exit Function
        ElseIf c = "[" Then
            idx = idx + 1
            ScanOnce = ParseArray(str, idx)
            Exit Function
        ElseIf c = """" Then
            idx = idx + 1
            ScanOnce = ParseString(str, idx)
            Exit Function
        ElseIf c = "n" And StrComp("null", Mid(str, idx, 4)) = 0 Then
            idx = idx + 4
            ScanOnce = Null
            Exit Function
        ElseIf c = "t" And StrComp("true", Mid(str, idx, 4)) = 0 Then
            idx = idx + 4
            ScanOnce = True
            Exit Function
        ElseIf c = "f" And StrComp("false", Mid(str, idx, 5)) = 0 Then
            idx = idx + 5
            ScanOnce = False
            Exit Function
        End If        
        Set ms = NumberRegex.Execute(Mid(str, idx))
        If ms.Count = 1 Then
            idx = idx + ms(0).Length
            ScanOnce = CDbl(ms(0))
            Exit Function
        End If    
        Err.Raise 8732,,"No JSON object could be ScanOnced"
    End Function
    Private Function ParseObject(ByRef str, ByRef idx)
        Dim c, key, value
        Set ParseObject = CreateObject("Scripting.Dictionary")
        idx = SkipWhitespace(str, idx)
        c = Mid(str, idx, 1)   
        If c = "}" Then
            Exit Function
        ElseIf c <> """" Then
            Err.Raise 8732,,"Expecting property name"
        End If
        idx = idx + 1     
        Do
            key = ParseString(str, idx)
            idx = SkipWhitespace(str, idx)
            If Mid(str, idx, 1) <> ":" Then
                Err.Raise 8732,,"Expecting : delimiter"
            End If
            idx = SkipWhitespace(str, idx + 1)
            If Mid(str, idx, 1) = "{" Then
                Set value = ScanOnce(str, idx)
            Else
                value = ScanOnce(str, idx)
            End If
            ParseObject.Add key, value
            idx = SkipWhitespace(str, idx)
            c = Mid(str, idx, 1)
            If c = "}" Then
                Exit Do
            ElseIf c <> "," Then
                Err.Raise 8732,,"Expecting , delimiter"
            End If
            idx = SkipWhitespace(str, idx + 1)
            c = Mid(str, idx, 1)
            If c <> """" Then
                Err.Raise 8732,,"Expecting property name"
            End If
            idx = idx + 1
        Loop
        idx = idx + 1
    End Function
    Private Function ParseArray(ByRef str, ByRef idx)
        Dim c, values, value
        Set values = CreateObject("Scripting.Dictionary")
        idx = SkipWhitespace(str, idx)
        c = Mid(str, idx, 1)
        If c = "]" Then
            ParseArray = values.Items
            Exit Function
        End If
        Do
            idx = SkipWhitespace(str, idx)
            If Mid(str, idx, 1) = "{" Then
                Set value = ScanOnce(str, idx)
            Else
                value = ScanOnce(str, idx)
            End If
            values.Add values.Count, value
            idx = SkipWhitespace(str, idx)
            c = Mid(str, idx, 1)
            If c = "]" Then
                Exit Do
            ElseIf c <> "," Then
                Err.Raise 8732,,"Expecting , delimiter"
            End If
            idx = idx + 1
        Loop
        idx = idx + 1
        ParseArray = values.Items
    End Function 
    Private Function ParseString(ByRef str, ByRef idx)
        Dim chunks, content, terminator, ms, esc, char
        Set chunks = CreateObject("Scripting.Dictionary")
        Do
            Set ms = StringChunk.Execute(Mid(str, idx))
            If ms.Count = 0 Then
                Err.Raise 8732,,"Unterminated string starting"
            End If
            content = ms(0).Submatches(0)
            terminator = ms(0).Submatches(1)
            If Len(content) > 0 Then
                chunks.Add chunks.Count, content
            End If
            idx = idx + ms(0).Length
            If terminator = """" Then
                Exit Do
            ElseIf terminator <> "\" Then
                Err.Raise 8732,,"Invalid control character"
            End If
            esc = Mid(str, idx, 1)
            If esc <> "u" Then
                Select Case esc
                    Case """" char = """"
                    Case "\"  char = "\"
                    Case "/"  char = "/"
                    Case "b"  char = b
                    Case "f"  char = f
                    Case "n"  char = n
                    Case "r"  char = r
                    Case "t"  char = t
                    Case Else Err.Raise 8732,,"Invalid escape"
                End Select
                idx = idx + 1
            Else
                char = ChrW("&H" & Mid(str, idx + 1, 4))
                idx = idx + 5
            End If
            chunks.Add chunks.Count, char
        Loop
        ParseString = Join(chunks.Items, "")
    End Function
    Private Function SkipWhitespace(ByRef str, ByVal idx)
        Do While idx <= Len(str) And _
            InStr(Whitespace, Mid(str, idx, 1)) > 0
            idx = idx + 1
        Loop
        SkipWhitespace = idx
    End Function
End Class


Class clsDiskpartWrapper 
    Private objDPHandle, objShell

    Private Sub Class_Initialize
        Set objShell = WScript.CreateObject("WScript.Shell")
        Set objDPHandle = objShell.Exec("diskpart.exe")
    End Sub

    Public Function RunAndExpect(strCmd, strResultSubs)
        Dim strTemp

        WScript.Echo "Sending command to diskpar: " & strCmd
        objDPHandle.StdIn.Write strCmd  & VbCrLf

        WScript.Echo "First loop output: "
        Do While True
            strTemp = objDPHandle.StdOut.ReadLine & VbCrLf
            WScript.Echo strTemp
            If InStr(strTemp, "DISKPART>") <> 0 Then 
                Exit Do
            End If
        Loop      

        WScript.Echo "Sending empty command"
        objDPHandle.StdIn.Write VbCrLf

        WScript.Echo "Second loop output: "
        Do While True
            strTemp = objDPHandle.StdOut.ReadLine
            WScript.Echo strTemp

            If InStr(strTemp, "DISKPART>") <> 0 Then 
                Exit Do
            End If 

            RunAndExpect = False
            WScript.Echo "Expected '" & strResultSubs  & "' to be in output"
            If InStr(strResultSubs, strTemp) Then
                WScript.Echo "Expected result was found"
                RunAndExpect = True
            Else
                WScript.Echo "Expected result was NOT found"
            End If
        Loop
    End Function

End Class

' Set the network interface wih the given MAC to he given parameters
Function SetDropletRealNetConfig(strIPAddr, strNetmask, strGateway, strAdapterMAC)
    On Error Resume Next
    Dim objWMIService, objWMIResult, errEnableAddr, intTestAdapter, blnAdapterFound

    Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2") 
    Set objWMIResult = objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled=True")
    blnAdapterFound = False

    For Each adapter In objWMIResult
        intTestAdapter= StrComp(strAdapterMAC, adapter.MACAddress, vbTextCompare)
        If  intTestAdapter = 0 Then
            blnAdapterFound = True
            WScript.Echo "Found the public interface at index: " & adapter.Index & " (" & adapter.MACAddress & ")"
            errEnableAddr = adapter.EnableStatic(Array(strIPAddr), Array(strNetmask))
            
            If errEnableAddr <> 0 Then
                WScript.Echo "Error setting adapter address with code: " & errEnableAddr 

            Else
                WScript.Echo "Nework adapter address set"
                errEnableAddr = Empty
            End If 

            errEnableAddr = adapter.SetGateways(Array(strGateway), Array(1))
            If errEnableAddr <> 0 Then
                WScript.Echo "Error setting adapter gateway with code: " & errEnableAddr 
            Else
                WScript.Echo "Nework adapter gateway set"
                errEnableAddr = Empty
            End If 
        End If
    Next
    
    SetDropletRealNetConfig = True
    If Not blnAdapterFound Then
        SetDropletRealNetConfig = False
        WScript.Echo "Failed to find netwrok adapater with matching mac addr"
    End If
    WScript.Echo "SetDropletRealNetConfig exit"
End Function


' Gets the droplet information from the metadata service
' and returns the parsed JSON data to VBS types.
Function GetDropletMetadata
    On Error Resume Next
    Const strMDUrl = "http://169.254.0.1/metadata/v1.json"
    Dim objWinHttp, objJSON

    Set objWinHttp = CreateObject("WinHttp.WinHttpRequest.5.1")
    
    objWinHttp.Open "GET", strMDUrl, False
    objWinHttp.Send
    If Err.Number = 0 Then 
        If objWinHttp.Status = 200 Then
            Set objJSON = new clsJSON
            Set GetDropletMetadata = objJSON.Decode(objWinHttp.ResponseText)
            If Err.Number <> 0 Then
                WScript.Echo "Error while parsing JSON data: " & Err.Number
                GetDropletMetadata = Nothing
            End If
            Exit Function
        Else
            WScript.Echo "WinHttp recived an unexpected " & objWinHttp.Status & " " & objWinHttp.StatusText
        End If
    End If
    WScript.Echo "Got to end of GetDropletMetadata, must have been erros"
    GetDropletMetadata = Nothing
End Function


' Blocks until the network adapters are ready and have
' an IP address (this is usally an APIPA address)
Sub BlockUntilNetworkReady
    On Error Resume Next
    Dim objWMIService, objWMIResult, intTemp

    Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2") 

    Do While True
        Set objWMIResult = objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled=True")
        ' XXX - The following statement is only used to force Err on bad query.
        intTemp = objWMIResult.Count
        If Err.Number <> 0 Then
            WScript.Echo "ERROR on WMI query: " & Err.Description
        ElseIf objWMIResult.Count > 0 Then
            WScript.Echo "Got network adapters with IP " & objWMIResult.Count
            Exit Do
        End If
        WScript.Echo "No adapters found. Waiting..."
        WScript.Sleep 5000
    Loop
    WScript.Echo "BlockUntilNetworkReady done"
End Sub

Sub RebuildStorageForWindows
    Dim objDiskpart, blnErrorCheck

    Set objDiskpart = New clsDiskpartWrapper
    
    blnErrorCheck = objDiskpart.RunAndExpect("select disk 0", "Disk 0 is now the selected disk")
    If Not blnErrorCheck Then WScript.Echo "ERROR!!! Diskpar command failed"
    blnErrorCheck = objDiskpart.RunAndExpect("clean", "DiskPart succeeded in cleaning the disk")
    If Not blnErrorCheck Then WScript.Echo "ERROR!!! Diskpar command failed"
    blnErrorCheck = objDiskpart.RunAndExpect("create partition primary size=300", "DiskPart succeeded in creating the specified partition")
    If Not blnErrorCheck Then WScript.Echo "ERROR!!! Diskpar command failed"
    blnErrorCheck = objDiskpart.RunAndExpect("format quick fs=ntfs label=""System""", "DiskPart successfully formatted the volume")
    If Not blnErrorCheck Then WScript.Echo "ERROR!!! Diskpar command failed"
    blnErrorCheck = objDiskpart.RunAndExpect("assign letter=""S""", "DiskPart successfully assigned the drive letter or mount point")
    If Not blnErrorCheck Then WScript.Echo "ERROR!!! Diskpar command failed"

    blnErrorCheck = objDiskpart.RunAndExpect("active", "DiskPart marked the current partition as active")
    If Not blnErrorCheck Then WScript.Echo "ERROR!!! Diskpar command failed"
    blnErrorCheck = objDiskpart.RunAndExpect("create partition primary", "DiskPart succeeded in creating the specified partition")
    If Not blnErrorCheck Then WScript.Echo "ERROR!!! Diskpar command failed"
    blnErrorCheck = objDiskpart.RunAndExpect("format quick fs=ntfs label=""Windows""", "DiskPart successfully formatted the volume")
    If Not blnErrorCheck Then WScript.Echo "ERROR!!! Diskpar command failed"
    blnErrorCheck = objDiskpart.RunAndExpect("assign letter=""W""", "DiskPart successfully assigned the drive letter or mount point")
    If Not blnErrorCheck Then WScript.Echo "ERROR!!! Diskpar command failed"
End Sub


Sub FetchDownloaderExec
	
End Sub

' Main script subroutine. 
Sub Main 
    Dim objDropletConfig, blnErrorCheck

    Call BlockUntilNetworkReady
    Set objDropletConfig = GetDropletMetadata()
    If Not IsObject(objDropletConfig) Then
        WScript.Echo "Did not find any droplet metadata " 
        Exit Sub
    End If

    blnErrorCheck = SetDropletRealNetConfig( objDropletConfig("interfaces")("public")("0")("ipv4")("ip_address"), _
        objDropletConfig("interfaces")("public")("0")("ipv4")("netmask"), _
        objDropletConfig("interfaces")("public")("0")("ipv4")("gateway"), _
        objDropletConfig("interfaces")("public")("0")("mac"))
    
    If Not blnErrorCheck Then
        WScript.Echo "Failed to set adapter real address"
    End If

    Call RebuildStorageForWindows

End Sub

Call Main
