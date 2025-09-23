@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Long Video Sequence Cutter- by Munna MasterMind

:: ---- FOLDERS ----
set "ROOT=%~dp0"
set "INPUT_FOLDER=%ROOT%Videos"
set "OUTPUT_FOLDER=%ROOT%Output"
set "TEMP=%ROOT%temp"

:: Create folders if they don't exist
if not exist "%INPUT_FOLDER%" (
    md "%INPUT_FOLDER%"
    echo ℹ Created Videos folder. Please put your videos there and run again.
    pause
    exit /b
)
if not exist "%OUTPUT_FOLDER%" md "%OUTPUT_FOLDER%"
if not exist "%TEMP%" md "%TEMP%"

:: ---- FIND FFMPEG/FFPROBE ----
set "FFMPEG=ffmpeg.exe"
set "FFPROBE=ffprobe.exe"
if not exist "%FFMPEG%" set "FFMPEG=ffmpeg"
if not exist "%FFPROBE%" set "FFPROBE=ffprobe"

:: ---- CHECK FFMPEG ----
%FFMPEG% -version >nul 2>&1 || (
    echo ❌ ffmpeg not found! Please install ffmpeg or put ffmpeg.exe in this folder.
    pause
    exit /b
)

:: ---- FIND VIDEO FILES ----
echo 🔍 Searching for video files in %INPUT_FOLDER%...
dir /b /a-d "%INPUT_FOLDER%\*.mp4" "%INPUT_FOLDER%\*.mov" "%INPUT_FOLDER%\*.mkv" "%INPUT_FOLDER%\*.avi" "%INPUT_FOLDER%\*.webm" >nul 2>&1

if errorlevel 1 (
    echo ❌ No video files found in Videos folder!
    echo Supported formats: MP4, MOV, MKV, AVI, WEBM
    pause
    exit /b
)

:: ---- LIST VIDEO FILES WITH RESOLUTION AND DURATION ----
echo 📋 Available video files:
set "INDEX=0"
for %%F in ("%INPUT_FOLDER%\*.mp4" "%INPUT_FOLDER%\*.mov" "%INPUT_FOLDER%\*.mkv" "%INPUT_FOLDER%\*.avi" "%INPUT_FOLDER%\*.webm") do (
    set /a INDEX+=1
    set "VIDEO_!INDEX!=%%~nxF"
    set "VIDEO_PATH_!INDEX!=%%F"
    
    :: Get video resolution using ffprobe
    set "RESOLUTION=Unknown"
    "%FFPROBE%" -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "%%F" > "%TEMP%\res_!INDEX!.txt" 2>nul
    set /p "RESOLUTION=" < "%TEMP%\res_!INDEX!.txt" 2>nul
    if "!RESOLUTION!"=="" set "RESOLUTION=Unknown"
    set "RESOLUTION_!INDEX!=!RESOLUTION!"
    
    :: Get video duration using ffprobe
set "DURATION=Unknown"
set "DURATION_MINUTES=0"

    :: ffprobe to (decimal)
"%FFPROBE%" -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "%%F" > "%TEMP%\dur_!INDEX!.txt" 2>nul
set /p "TOTAL_SECONDS=" < "%TEMP%\dur_!INDEX!.txt" 2>nul

    :: If value access
if not "!TOTAL_SECONDS!"=="" (
    :: Convert Decimal to Integer
    for /f "tokens=1 delims=." %%A in ("!TOTAL_SECONDS!") do set /a "TOTAL_SEC_INT=%%A"

    set /a "HOURS=TOTAL_SEC_INT/3600"
    set /a "MINUTES=(TOTAL_SEC_INT - HOURS*3600)/60"
    set /a "SECONDS=TOTAL_SEC_INT %% 60"

    :: 2 Digit Format (01:05:09)
    if !HOURS! lss 10 set "HOURS=0!HOURS!"
    if !MINUTES! lss 10 set "MINUTES=0!MINUTES!"
    if !SECONDS! lss 10 set "SECONDS=0!SECONDS!"

    set "DURATION=!HOURS!:!MINUTES!:!SECONDS!"
    set /a "TOTAL_MINUTES=(TOTAL_SEC_INT+59)/60"   :: nearest minute up
    set "DURATION_MINUTES=!TOTAL_MINUTES! minutes"
)

set "DURATION_!INDEX!=!DURATION!"
set "DURATION_MINUTES_!INDEX!=!DURATION_MINUTES!"

echo !INDEX!. %%~nxF [!RESOLUTION!] [!DURATION!]

)
echo ===========================================
echo.

:: ---- COUNT AND DISPLAY SUMMARY ----
echo ✅ Found !INDEX! video files
echo.

:: ---- SELECT VIDEO FILE ----
:SELECT_VIDEO
cls
echo.
echo ========================================================================================
echo   	            Select Video for Sequence Cutter- by Munna MasterMind
echo 	 	                    https://facebook.com/The.Munna
echo ========================================================================================
echo 📋 Available video files:
echo.
for /l %%I in (1,1,!INDEX!) do (
    echo 	%%I. !VIDEO_%%I! [!RESOLUTION_%%I!]
)
echo ----------------------------------
echo.
set /p "VIDEO_CHOICE=Select video file (1-!INDEX!): "
if "!VIDEO_CHOICE!"=="" (
    echo Invalid selection! Please try again.
    timeout /t 2 >nul
    goto SELECT_VIDEO
)

set /a VIDEO_CHOICE_NUM=!VIDEO_CHOICE! 2>nul
if !VIDEO_CHOICE_NUM! lss 1 (
    echo Invalid selection! Please try again.
    timeout /t 2 >nul
    goto SELECT_VIDEO
)
if !VIDEO_CHOICE_NUM! gtr !INDEX! (
    echo Invalid selection! Please try again.
    timeout /t 2 >nul
    goto SELECT_VIDEO
)

set "SELECTED_VIDEO=!VIDEO_%VIDEO_CHOICE_NUM%!"
set "INPUT_FILE=!VIDEO_PATH_%VIDEO_CHOICE_NUM%!"
set "SELECTED_RESOLUTION=!RESOLUTION_%VIDEO_CHOICE_NUM%!"
set "SELECTED_DURATION=!DURATION_%VIDEO_CHOICE_NUM%!"
set "SELECTED_DURATION_MINUTES=!DURATION_MINUTES_%VIDEO_CHOICE_NUM%!"

:: ---- DISPLAY VIDEO DETAILS ----
echo ------------------------------
echo 📊 Video Details:
echo.
echo File: !SELECTED_VIDEO!
echo Resolution: !SELECTED_RESOLUTION!
echo Duration: !SELECTED_DURATION! (!SELECTED_DURATION_MINUTES!)
echo ------------------------------
echo.

:: ---- INPUT CUT DETAILS ----
:INPUT_START
set /p "START_TIME=Enter start time (HH:MM:SS or MM:SS or seconds): "
if "!START_TIME!"=="" (
    echo Invalid input! Please try again.
    timeout /t 2 >nul
    goto INPUT_START
)

:INPUT_END
set /p "END_TIME=Enter end time (HH:MM:SS or MM:SS or seconds): "
if "!END_TIME!"=="" (
    echo Invalid input! Please try again.
    timeout /t 2 >nul
    goto INPUT_END
)

:: ---- INPUT OUTPUT FILENAME ----
set "BASE_NAME=!SELECTED_VIDEO:~0,-4!"
set /p "OUTPUT_NAME=Enter output filename (without extension) [!BASE_NAME!_cut]: "
if "!OUTPUT_NAME!"=="" set "OUTPUT_NAME=!BASE_NAME!_cut"

set "OUTPUT_FILE=%OUTPUT_FOLDER%\!OUTPUT_NAME!.mp4"

:: ---- CONFIRM CUT OPERATION ----
echo.
echo ===========================================
echo 📋 Cut Details:
echo.
echo Input file: !SELECTED_VIDEO!
echo Resolution: !SELECTED_RESOLUTION!
echo Duration: !SELECTED_DURATION!
echo Start time: !START_TIME!
echo End time: !END_TIME!
echo Output file: !OUTPUT_NAME!.mp4
echo ===========================================
echo.

:CONFIRM_CUT
set /p "CONFIRM=Proceed with cutting? (Y/N): "
if /i "!CONFIRM!"=="Y" goto CUT_VIDEO
if /i "!CONFIRM!"=="N" (
    echo Operation cancelled.
    pause
    exit /b
)
echo Invalid choice! Please enter Y or N.
timeout /t 2 >nul
goto CONFIRM_CUT

:: ---- CUT THE VIDEO ----
:CUT_VIDEO
echo 🎬 Cutting video from !START_TIME! to !END_TIME!...
echo ⏳ This may take a while...

%FFMPEG% -y -i "!INPUT_FILE!" -ss !START_TIME! -to !END_TIME! -c copy "%OUTPUT_FILE%"

if errorlevel 1 (
    echo ❌ Cut failed! Trying alternative method...
    %FFMPEG% -y -ss !START_TIME! -i "!INPUT_FILE!" -to !END_TIME! -c copy "%OUTPUT_FILE%"
)

if errorlevel 1 (
    echo ❌ Both cutting methods failed!
    echo Try re-encoding with: %FFMPEG% -y -ss !START_TIME! -i "!INPUT_FILE!" -to !END_TIME! -c:v libx264 -c:a aac "%OUTPUT_FILE%"
    pause
    exit /b
)

:: ---- CLEANUP TEMP FILES ----
del /q "%TEMP%\res_*.txt" >nul 2>&1
del /q "%TEMP%\dur_*.txt" >nul 2>&1

:: ---- FINISH ----
echo.
echo ✅ Successfully cut video!
echo 📁 Output: !OUTPUT_FILE!
echo.
echo 🎉 Process completed!
pause
