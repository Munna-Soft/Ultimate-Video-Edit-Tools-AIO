@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Create Long Videos from Shorts- by Munna MasterMind

:: ---- FOLDERS ----
set "ROOT=%~dp0"
set "OUT=%ROOT%output"
set "TEMP=%ROOT%temp"
if not exist "%OUT%" md "%OUT%"
if not exist "%TEMP%" md "%TEMP%"

:: ---- FIND FFMPEG/FFPROBE ----
set "FFM=ffmpeg.exe"
set "FFP=ffprobe.exe"
if not exist "%FFM%" set "FFM=ffmpeg"
if not exist "%FFP%" set "FFP=ffprobe"

:: ---- QUICK CHECK ----
%FFM% -version >nul 2>&1 || (echo ❌ ffmpeg.exe not found! Put ffmpeg.exe next to this BAT. & pause & exit /b)

:: ---- AUTO DISCOVER INPUTS (first match in folder) ----
set "VIDEO="
for %%F in ("%ROOT%*.mp4" "%ROOT%*.mov" "%ROOT%*.mkv" "%ROOT%*.webm" "%ROOT%*.avi") do if not defined VIDEO set "VIDEO=%%~fF"
set "AUDIO="
for %%F in ("%ROOT%*.mp3" "%ROOT%*.wav" "%ROOT%*.m4a" "%ROOT%*.aac") do if not defined AUDIO set "AUDIO=%%~fF"

if not defined VIDEO echo ❌ Put your short video (e.g. video.mp4) here & pause & exit /b
if not defined AUDIO echo ❌ Put your audio/music (e.g. audio.mp3) here & pause & exit /b

:: ---- GET ORIGINAL VIDEO RESOLUTION ----
echo Getting original video resolution...
"%FFP%" -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "%VIDEO%" > "%TEMP%\resolution.txt" 2>nul
set /p "ORIGINAL_RES=" < "%TEMP%\resolution.txt" 2>nul
for /f "tokens=1,2 delims=x" %%A in ("!ORIGINAL_RES!") do (
    set "ORIG_WIDTH=%%A"
    set "ORIG_HEIGHT=%%B"
)
echo Original resolution: !ORIG_WIDTH!x!ORIG_HEIGHT!

:: ---- CHECK IF VIDEO HAS AUDIO ----
echo Checking if video has audio stream...
"%FFP%" -v error -select_streams a -show_entries stream=index -of csv=p=0 "%VIDEO%" > "%TEMP%\has_audio.txt" 2>nul
set /p "HAS_AUDIO=" < "%TEMP%\has_audio.txt" 2>nul
if "!HAS_AUDIO!"=="" (
    set "HAS_VIDEO_AUDIO=0"
    echo Video has NO audio stream
) else (
    set "HAS_VIDEO_AUDIO=1"
    echo Video has audio stream
)

:: ---- ASK HOURS (1...24) ----
:ASKH
cls
echo.
echo ========================================================================================
echo 		Create Long Videos from Shorts- by Munna MasterMind
echo 			   https://facebook.com/The.Munna
echo ========================================================================================
echo Video: %VIDEO% (!ORIG_WIDTH!x!ORIG_HEIGHT!)
echo Audio: %AUDIO%
echo Video In Audio: !HAS_VIDEO_AUDIO! (1=Yes, 0=No)
echo ------------------------------------------
echo How Many Hours Do You Need? [1...24] (default 12)
set /p "HOURS=Enter Your Choice [1-24]: "
if "%HOURS%"=="" set "HOURS=12"
set "OK="
for %%# in (1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24) do if "%HOURS%"=="%%#" set "OK=1"
if not defined OK (echo Invalid choice & timeout /t 2 >nul & goto ASKH)

:: ---- ASK RESOLUTION ----
:ASKR
cls
echo.
echo ========================================================================================
echo 		Create Long Videos from Shorts- by Munna MasterMind
echo 			   https://facebook.com/The.Munna
echo ========================================================================================
echo Video: %VIDEO% (!ORIG_WIDTH!x!ORIG_HEIGHT!)
echo Audio: %AUDIO%
echo Video In Audio: !HAS_VIDEO_AUDIO! (1=Yes, 0=No)
echo ------------------------------------------
echo Duration: %HOURS% Hours [Selected]
echo ----------------------------
echo Select resolution:
echo 1. Original Resolution (!ORIG_WIDTH!x!ORIG_HEIGHT!)
echo 2. 720p (1280x720)
echo 3. 1080p (1920x1080)
echo 4. 2K (2560x1440)
echo 5. 4K (3840x2160)
echo ------------------------------------------
set /p "RESCHOICE=Enter Your Choice [1-5]: "
if "%RESCHOICE%"=="" set "RESCHOICE=1"

if "%RESCHOICE%"=="1" (
    set "WIDTH=!ORIG_WIDTH!"
    set "HEIGHT=!ORIG_HEIGHT!"
    set "RESNAME=Original"
    set "SCALE_FILTER="
) else if "%RESCHOICE%"=="2" (
    set "WIDTH=1280"
    set "HEIGHT=720"
    set "RESNAME=720p"
    set "SCALE_FILTER=scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,"
) else if "%RESCHOICE%"=="3" (
    set "WIDTH=1920"
    set "HEIGHT=1080"
    set "RESNAME=1080p"
    set "SCALE_FILTER=scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,"
) else if "%RESCHOICE%"=="4" (
    set "WIDTH=2560"
    set "HEIGHT=1440"
    set "RESNAME=2K"
    set "SCALE_FILTER=scale=2560:1440:force_original_aspect_ratio=decrease,pad=2560:1440:(ow-iw)/2:(oh-ih)/2,"
) else if "%RESCHOICE%"=="5" (
    set "WIDTH=3840"
    set "HEIGHT=2160"
    set "RESNAME=4K"
    set "SCALE_FILTER=scale=3840:2160:force_original_aspect_ratio=decrease,pad=3840:2160:(ow-iw)/2:(oh-ih)/2,"
) else (
    echo Invalid choice & timeout /t 2 >nul & goto ASKR
)

echo ➜ Building %HOURS% hour(s) %RESNAME% video...
set "DUR=%HOURS%:00:00"

:: ---- STEP A: MAKE SHORT MERGED CLIP ----
set "MIX=%temp%\mix_short_%RESNAME%.mp4"
echo 🔊 Merging video+audio and encoding to %RESNAME%...

if "!HAS_VIDEO_AUDIO!"=="1" (
  echo (video has audio → amix with music)
  "%FFM%" -y -hide_banner -loglevel error -stats -i "%VIDEO%" -i "%AUDIO%" ^
    -filter_complex "[0:a][1:a]amix=inputs=2:duration=shortest[a];[0:v]%SCALE_FILTER%format=yuv420p[v]" ^
    -map "[v]" -map "[a]" -c:v libx264 -preset ultrafast -crf 23 -c:a aac -b:a 192k -shortest "%MIX%"
) else (
  echo (video has NO audio → use only music)
  "%FFM%" -y -hide_banner -loglevel error -stats -i "%VIDEO%" -i "%AUDIO%" ^
    -filter_complex "[0:v]%SCALE_FILTER%format=yuv420p[v]" ^
    -map "[v]" -map 1:a -c:v libx264 -preset ultrafast -crf 23 -c:a aac -b:a 192k -shortest "%MIX%"
)

if not exist "%MIX%" (echo ❌ Merge failed & pause & exit /b 1)

:: ---- STEP B: DIRECT LONG ENCODE (fast copy) ----
set "FINAL=%OUT%\Create-Video_%RESNAME%_%HOURS%h.mp4"
echo 🕒 Creating %HOURS% hour video from %RESNAME% source (fast copy)...
"%FFM%" -y -hide_banner -loglevel error -stats ^
  -stream_loop -1 -i "%MIX%" -t %DUR% -c copy "%FINAL%"
if errorlevel 1 (echo ❌ Long encode failed & pause & exit /b 1)

:: ---- CLEANUP ----
del /q "%TEMP%\has_audio.txt" >nul 2>&1
del /q "%TEMP%\resolution.txt" >nul 2>&1
del /q "%MIX%" >nul 2>&1

echo ✅ Done! %RESNAME% Create video saved: %FINAL%
echo File size: 
for %%F in ("%FINAL%") do echo   %%~zF bytes
pause