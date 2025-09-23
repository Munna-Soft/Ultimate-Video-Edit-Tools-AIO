@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Auto Join Multiple Videos- by Munna MasterMind

:: ---- FOLDERS ----
set "ROOT=%~dp0"
set "INPUT_FOLDER=%ROOT%Videos"
set "OUTPUT_FOLDER=%ROOT%Output"
set "TEMP=%ROOT%Temp"

:: Create folders if they don't exist
if not exist "%INPUT_FOLDER%" (
    md "%INPUT_FOLDER%"
    echo ℹ Created Videos folder. Please put your videos there and run again.
    pause
    exit /b
)
if not exist "%TEMP%" md "%TEMP%"
if not exist "%OUTPUT_FOLDER%" md "%OUTPUT_FOLDER%"

:: ---- FIND FFMPEG ----
set "FFMPEG=ffmpeg.exe"
if not exist "%FFMPEG%" set "FFMPEG=ffmpeg"

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

:: ---- COUNT VIDEOS ----
set "COUNT=0"
for %%F in ("%INPUT_FOLDER%\*.mp4" "%INPUT_FOLDER%\*.mov" "%INPUT_FOLDER%\*.mkv" "%INPUT_FOLDER%\*.avi" "%INPUT_FOLDER%\*.webm") do (
    set /a COUNT+=1
)

echo ✅ Found !COUNT! video files

:: ---- ASK RESOLUTION ----
:ASKR
cls
echo.
echo ========================================================================================
echo                Select Resolution for Video Creation- by Munna MasterMind
echo 			            https://facebook.com/The.Munna
echo ========================================================================================
echo.
echo Found !COUNT! video files in Videos Folder
echo -------------------------------------------
echo Select output resolution:
echo 	1. Original Resolution (No scaling)
echo 	2. 720p (1280x720)
echo 	3. 1080p (1920x1080) [Default]
echo 	4. 2K (2560x1440)
echo 	5. 4K (3840x2160)
echo -------------------------------------------
set /p "RESCHOICE=Enter Your Choice [1-5]: "
if "%RESCHOICE%"=="" set "RESCHOICE=3"

if "%RESCHOICE%"=="1" (
    set "SCALE_FILTER="
    set "RESNAME=original"
) else if "%RESCHOICE%"=="2" (
    set "SCALE_FILTER=scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2"
    set "RESNAME=720p"
) else if "%RESCHOICE%"=="3" (
    set "SCALE_FILTER=scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2"
    set "RESNAME=1080p"
) else if "%RESCHOICE%"=="4" (
    set "SCALE_FILTER=scale=2560:1440:force_original_aspect_ratio=decrease,pad=2560:1440:(ow-iw)/2:(oh-ih)/2"
    set "RESNAME=2K"
) else if "%RESCHOICE%"=="5" (
    set "SCALE_FILTER=scale=3840:2160:force_original_aspect_ratio=decrease,pad=3840:2160:(ow-iw)/2:(oh-ih)/2"
    set "RESNAME=4K"
) else (
    echo Invalid choice & timeout /t 2 >nul & goto ASKR
)

:: ---- SET OUTPUT FILENAME ----
set "OUTPUT_FILE=%OUTPUT_FOLDER%\Merged_!RESNAME!_!COUNT!videos.mp4"

:: ---- CREATE TEMPORARY FILES ----
set "TEMP_LIST=%ROOT%video_list.txt"
set "TEMP_VIDEO=%ROOT%temp_resized.mp4"

del "%TEMP_LIST%" 2>nul
del "%TEMP_VIDEO%" 2>nul

:: ---- CREATE FILE LIST FOR FFMPEG ----
echo 📝 Creating video list...
for %%F in ("%INPUT_FOLDER%\*.mp4" "%INPUT_FOLDER%\*.mov" "%INPUT_FOLDER%\*.mkv" "%INPUT_FOLDER%\*.avi" "%INPUT_FOLDER%\*.webm") do (
    echo file '%%F' >> "%TEMP_LIST%"
)

:: ---- MERGE VIDEOS WITH SELECTED RESOLUTION ----
echo 🎬 Merging !COUNT! videos to !RESNAME! resolution...
echo ⏳ This may take a while...

if "!SCALE_FILTER!"=="" (
    echo Using original resolution (no scaling)
    %FFMPEG% -y -f concat -safe 0 -i "%TEMP_LIST%" -c copy "%OUTPUT_FILE%"
) else (
    echo Scaling to !RESNAME! resolution
    %FFMPEG% -y -f concat -safe 0 -i "%TEMP_LIST%" -vf "!SCALE_FILTER!" -c:a copy -c:v libx264 -preset fast -crf 23 "%OUTPUT_FILE%"
)

if errorlevel 1 (
    echo ❌ Merge failed!
    del "%TEMP_LIST%" 2>nul
    del "%TEMP_VIDEO%" 2>nul
    pause
    exit /b
)

:: ---- CLEANUP AND FINISH ----
del "%TEMP_LIST%" 2>nul
del "%TEMP_VIDEO%" 2>nul

echo.
echo ✅ Successfully Merged !COUNT! videos to !RESNAME! resolution!
echo 📁 Output: !OUTPUT_FILE!
echo.
echo 🎉 Process completed!
pause
