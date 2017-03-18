@echo off
rem loader.cmd
rem load driver, configure network, download tools and install windows
echo "Starting auto installer script, press CTRL+C to interrupt"

set HALTONBSOD=
set BSODKEY="HKLM\System\ControlSet001\Control\CrashControl"
set DRIVERLOC="%systemdrive%\drivers\*.inf"
set REGTOOL=%systemdrive%\windows\system32\reg.exe
set DRVLOADTOOL=%systemdrive%\windows\system32\drvload.exe
set WPEUTILTOOL=%systemdrive%\windows\system32\wpeutil.exe
set WPEINITTOOL=%systemdrive%\windows\system32\wpeutil.exe
set NETSHTOOL=%systemdrive%\windows\system32\netsh.exe
set WGETTOOL=%systemdrive%\windows\system32\wget.exe
rem Might want to add a oobe answer file at some point

echo "Setting should halt on BSOD to " %HALTONBSOD%
if %HALTONBSOD%=="yes" (
    %REGTOOL% add %BSODKEY% /v AutoReboot /t REG_DWORD /d 0 /f 
)

echo "Installing critical drivers for setup"
for /f "delims=" %%d in ('dir /s /b %DRIVERLOC%') do (
    %DRVLOADTOOL% %%d
    if %errorlevel% neq 0 goto driverLoadError
)


echo "Searching for network adapter"
wmic path win32_networkadaper where PhysicalAdapter=True call disable
for /f "skip=1" %%i in ('"wmic path win32_networkadapter where Physical=True get Index"') do (
    for /f "delims=" %%j in ("%%i") do (
        echo "Checking network adapter %%j"
        echo "Enableing adapter..."
        wmic path win32_networkadapter where Index=%%j call enable
        set /a octatc=%random%*169/32768+1
        set /a octatd=%random%*169/32768+1
        echo "Setting adapter ip address to 169.254.%octatc%.%octatd%/16"
        wmic nicconfig where Index=1 class EnableStatic ("169.254.%octatc%.%octatd%"),("255.255.0.0")
    )
)



:driverLoadError
echo "One of he drivers failed to load and the setup process"
echo "cannot continue. Please fix the error and reboot the "
echo "system using 'wpeutil reboot'"
exit /B 1

:EOF