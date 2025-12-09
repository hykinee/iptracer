@echo off
chcp 65001 > nul
title IP Tracer
cls

echo ===================================
echo        IP TRACER - FIXED
echo ===================================
echo.

:: Получаем файл с IP
if "%~1"=="" (
    echo Drag and drop TXT file with IP addresses:
    echo.
    set /p input_file=
) else (
    set "input_file=%~1"
)

set "input_file=%input_file:"=%"

if not exist "%input_file%" (
    echo ERROR: File not found!
    echo %input_file%
    pause
    exit
)

echo.
echo Processing: %input_file%
echo.

:: Создаем выходной файл
set "output_file=result.txt"
if exist "%output_file%" del "%output_file%"

:: Включаем отложенное расширение переменных
setlocal enabledelayedexpansion

set counter=0
for /f "usebackq delims=" %%a in ("%input_file%") do (
    set /a counter+=1
    set "current_ip=%%a"
    
    echo [!counter!] Testing: !current_ip!
    
    :: Проверяем, что адрес не пустой
    if not "!current_ip!"=="" (
        :: Запускаем tracert с таймаутом и максимальным количеством прыжков 30
        echo Running: tracert -d -w 1000 -h 30 !current_ip!
        tracert -d -w 1000 -h 30 !current_ip! > tracert_output.tmp 2>&1
        
        :: Проверяем, создался ли файл с выводом
        if exist tracert_output.tmp (
            :: Показываем первые 3 строки вывода для диагностики
            echo First 3 lines of tracert output:
            for /f "tokens=1* delims=:" %%i in ('findstr /n "^" tracert_output.tmp ^| findstr "^[1-3]:"') do echo   %%j
            
            :: Способ 1: Считаем строки, начинающиеся с цифры
            set hop_count=0
            for /f %%b in ('findstr /r "^[ ]*[0-9]" tracert_output.tmp ^| find /c /v ""') do set hop_count=%%b
            
            :: Способ 2: Если первый способ не сработал, считаем строки содержащие "ms"
            if "!hop_count!"=="0" (
                for /f %%c in ('findstr /c:" ms " tracert_output.tmp ^| find /c /v ""') do set hop_count=%%c
            )
            
            :: Записываем результат
            echo !current_ip!	!hop_count! >> "%output_file%"
            echo Result: !hop_count! hops
        ) else (
            echo ERROR: tracert output file not created!
            echo !current_ip!	ERROR >> "%output_file%"
        )
        
        :: Удаляем временный файл
        if exist tracert_output.tmp del tracert_output.tmp
    ) else (
        echo Skipping empty line
    )
    
    echo.
    timeout /t 1 >nul
)

echo ===================================
echo          COMPLETED
echo ===================================
echo.
echo Total processed: %counter% IP addresses
echo Results saved to: %output_file%
echo.
echo Results:
echo ========
type "%output_file%"
echo ========
echo.

pause