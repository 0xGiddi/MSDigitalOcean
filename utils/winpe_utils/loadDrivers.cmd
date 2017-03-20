drvload x:\drivers\netkvm.inf || goto die
drvload x:\drivers\viostor.inf || goto die

exit /b

:die
echo Failed to load drivers, please fix and reboot.
pause
