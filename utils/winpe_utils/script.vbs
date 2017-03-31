Sub WaitForNetworkConfig
	On Error Resume Next
	Dim objWMIService, colNetAdapters, iJunk
	
	Set objWMIService = GetObject("winmgmts:{impersonationLevel=Impersonate}!\\.\roo\cimv2")
	
	Do While True
		Set colNetAdapters = objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled=True")
		' If the query failes this will not set Err.Number right away,
		' This is a hack in order to force Err.Number if the query failed
		iJunk = colNetAdapters.Count
		
		If Err.Number <> 0 Then
			' Really need to write a 'printf' function ... this is ridiculous 
			WScript.Echo "WMI Query error :: (" & Err.Number & ", '" & Err.Description & "')" 
		ElseIf colNetAdapters.Count > 0 Then
			WScript.Echo "Got (" & colNetAdapters.Count & ") Adapters"
			Exit Do
		End If
		WScript.Echo "No Adapters ready, Keep calm and carry on"
		WScript.Sleep 10000
	Loop
	WScript.Echo "WaitForNetworkConfig return"
End Sub


Sub Main
	' Wait for APIPA IP (No DCHP present)
	Call WaitForNetworkConfig
	
End Sub

Call Main
