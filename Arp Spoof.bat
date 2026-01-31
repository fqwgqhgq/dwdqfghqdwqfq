@echo off
title N.I.C SPOOF ^| v1.1
setlocal EnableDelayedExpansion
mode con:cols=66 lines=25

:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo( && echo   [33m# Administrator privileges are required. && echo([0m
    runas /user:Administrator "%~0" %*
    exit /b
)

:: Variable(s)
set "reg_path=HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"

:SELECTION_MENU
:: Enumerate available NICs - (You can use "name" or "NetConnectionId")
set "count=0"
cls && echo( && echo   [35m[i] Input NIC # to modify.[0m && echo(
for /f "skip=2 tokens=2 delims=," %%A in ('wmic nic get NetConnectionId /format:csv') do (
    for /f "delims=" %%B in ("%%~A") do (
        set /a "count+=1"
        set "nic[!count!]=%%B"
        echo   [36m!count![0m - %%B
    )
)
:: Receive user selection
echo( && echo>nul|clip
set /p "nic_selection=.  [35m# [0m"
set /a "nic_selection=nic_selection"
if !nic_selection! GTR 0 (
    if !nic_selection! LEQ !count! (
        for /f "delims=" %%A in ("!nic_selection!") do set "NetworkAdapter=!nic[%%A]!"
        goto :SPOOF_MAC
    )
)
cls && echo( && echo   [31m[!] "!nic_selection!" is a invalid option.[0m && >nul timeout /t 2 && goto :SELECTION_MENU
exit /b

:SPOOF_MAC
cls && echo( && call :MAC_RECIEVE && call :GEN_MAC && call :NIC_INDEX
echo   [36m^> Selected NIC :[0m !NetworkAdapter! && echo(
echo   [36m^> Previous MAC :[0m !MAC! && echo(
echo   [36m^> Modified MAC :[0m !mac_address_print!
>nul 2>&1 (
    netsh interface set interface "!NetworkAdapter!" admin=disable
    reg add "!reg_path!\!Index!" /v "NetworkAddress" /t REG_SZ /d "!mac_address!" /f
    netsh interface set interface "!NetworkAdapter!" admin=enable
)
echo( && echo   [35m[i] MAC address successfully spoofed.[0m
echo( && echo   [35m# Press any key to continue...[0m && >nul pause && goto :ACTION_MENU
exit /b

:: Generating Random MAC Address
:: The second character of the first octet of the MAC Address needs to contain A, E, 2, or 6 to properly function for certain wireless NIC's. Example: xA:xx:xx:xx:xx
:GEN_MAC
set #hex_chars=0123456789ABCDEF`AE26
set mac_address=
for /l %%A in (1,1,11) do (
    set /a "random_index=!random! %% 16"
    for %%B in (!random_index!) do (
        set mac_address=!mac_address!!#hex_chars:~%%B,1!
    )
)
set /a "random_index=!random! %% 4 + 17"
set mac_address=!mac_address:~0,1!!#hex_chars:~%random_index%,1!!mac_address:~1!

:: Add colons after every two characters for printing
set mac_address_print=!mac_address:~0,2!:!mac_address:~2,2!:!mac_address:~4,2!:!mac_address:~6,2!:!mac_address:~8,2!:!mac_address:~10,2!
exit /b

:: Retrieving Current MAC Address
:MAC_RECIEVE
call :NIC_INDEX

:: An unaltered MAC address will not be present in the registry. As a result, we retrieve it via WMIC.
for /f "tokens=2 delims==" %%A in ('wmic nic where "Index='!Index!'" get MacAddress /format:value ^| find "MACAddress"') do (
    set "MAC=%%A"
)

exit /b

:: Retrieving current caption & converting into a Index - (You can use "name" or "NetConnectionId")
:NIC_INDEX
for /f "tokens=2 delims=[]" %%A in ('wmic nic where "NetConnectionId='!NetworkAdapter!'" get Caption /format:value ^| find "Caption"') do (
    set "Index=%%A"
    set "Index=!Index:~-4!"
)
exit /b 0