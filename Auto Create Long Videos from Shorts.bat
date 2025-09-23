@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Auto Create Long Videos from Shorts- by Munna MasterMind

:: ---- FOLDERS ----
set "ROOT=%~dp0"
set "VIDDIR=%ROOT%Videos"
set "AUDDIR=%ROOT%Music"
set "OUT=%ROOT%Output"
set "TEMP=%ROOT%Temp"

if not exist "%VIDDIR%" md "%VIDDIR%"
if not exist "%AUDDIR%" md "%AUDDIR%"
if not exist "%OUT%" md "%OUT%"
if not exist "%TEMP%" md "%TEMP%"

:: ---- FIND FFMPEG/FFPROBE ----
set "FFM=ffmpeg.exe"
set "FFP=ffprobe.exe"
if not exist "%FFM%" set "FFM=ffmpeg"
if not exist "%FFP%" set "FFP=ffprobe"
%FFM% -version >nul 2>&1 || (echo ❌ ffmpeg.exe not found! Put ffmpeg.exe next to this BAT. & pause & exit /b)

:: ---- LIST AVAILABLE VIDEOS ----
set i=0
echo.
echo ========================================================================================
echo           Select Your Video + Audio for Long Video Creation- by Munna MasterMind
echo                            https://facebook.com/The.Munna
echo ========================================================================================
echo.
echo Available Videos:
for %%F in ("%VIDDIR%\*.mp4" "%VIDDIR%\*.mov" "%VIDDIR%\*.mkv" "%VIDDIR%\*.webm" "%VIDDIR%\*.avi") do (
    set /a i+=1
    set "VID!i!=%%~fF"
    echo   !i!. %%~nxF
)
if %i%==0 echo ❌ No video files found in %VIDDIR%! & pause & exit /b
echo ------------------------------------------
set /p "VIDCHOICE=Select Your Video [1-%i%]: "
set "VIDEO=!VID%VIDCHOICE%!"
if not defined VIDEO echo ❌ Invalid selection & pause & exit /b

echo.
echo.

:: ---- LIST AVAILABLE AUDIO ----
set j=0
echo Available Music:
echo   1. None (No Music)
set "AUD1="

for %%F in ("%AUDDIR%\*.mp3" "%AUDDIR%\*.wav" "%AUDDIR%\*.m4a" "%AUDDIR%\*.aac") do (
    set /a j+=1
    set /a idx=j+1
    set "AUD!idx!=%%~fF"
    echo   !idx!. %%~nxF
)

set /a TOTAL=j+1
echo ------------------------------------------
set /p "AUDCHOICE=Select Your Audio [1-%TOTAL%]: "
set "AUDIO=!AUD%AUDCHOICE%!"

if not defined AUDIO (
    if "%AUDCHOICE%"=="1" (
        set "AUDIO="
    ) else (
        echo ❌ Invalid selection
        pause
        exit /b
    )
)

echo.
echo.
if "%AUDCHOICE%"=="1" (
    echo ➜ You Selected: None (No music will be added)
) else (
    echo ➜ You Selected: !AUDIO!
)
echo.
pause

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

:: ---- ASK DURATION (flexible: minutes or HH:MM) ----
:ASKD
cls
echo.
echo ========================================================================================
echo          Input Duration for Long Video Creation- by Munna MasterMind
echo                        https://facebook.com/The.Munna
echo ========================================================================================
echo Video: %VIDEO% (!ORIG_WIDTH!x!ORIG_HEIGHT!)
if "%AUDCHOICE%"=="1" (
    echo Audio: None (No Music)
) else (
    echo Audio: %AUDIO%
)
echo Video In Audio: !HAS_VIDEO_AUDIO! (1=Yes, 0=No)
echo ------------------------------------------
echo Examples Duration:
echo    5       = 5 minutes
echo    10      = 10 minutes
echo    1:30    = 1 hour 30 minutes
echo    2:45    = 2 hours 45 minutes
echo    10:15   = 10 hours 15 minutes
echo    24:00   = 24 hours 0 minutes
echo ------------------------------------------
set "USERDUR="
set /p "USERDUR=Enter Video Duration - max 24 Hours (HH:MM or minutes): "

if "%USERDUR%"=="" goto BADINPUT

:: remove spaces
set "USERDUR=%USERDUR: =%"

:: parse either H:MM or minutes-only
echo %USERDUR% | findstr ":" >nul 2>&1
if errorlevel 1 (
    set "HOURS=0"
    set "MINS=%USERDUR%"
) else (
    for /f "tokens=1,2 delims=:" %%A in ("%USERDUR%") do (
        set "HOURS=%%A"
        set "MINS=%%B"
    )
)

:: default to 0 if empty
if not defined HOURS set "HOURS=0"
if not defined MINS set "MINS=0"

:: Validate numeric and compute total minutes safely
set "BAD=0"
set /a TOTMIN=HOURS*60+MINS 2>nul || set "BAD=1"
if "%BAD%"=="1" goto BADINPUT

:: Reject invalid minutes part (0-59)
set /a MINPART=MINS 2>nul
if %MINPART% LSS 0 goto BADINPUT
if %MINPART% GEQ 60 goto BADINPUT

:: Ensure total minutes in (0 .. 1440]
if %TOTMIN% LEQ 0 goto BADINPUT
if %TOTMIN% GTR 1440 goto BADINPUT

:: Build HH:MM:SS (zero-padded)
set /a HH = TOTMIN / 60
set /a MM = TOTMIN %% 60
if %HH% LSS 10 (set "HH=0%HH%")
if %MM% LSS 10 (set "MM=0%MM%")
set "DUR=%HH%:%MM%:00"

echo ➜ Selected Duration: %DUR%
goto ASKR

:BADINPUT
echo.
echo ❌ Invalid input! Please type correctly (examples: 5, 10, 1:30, 10:15, 24:00).
timeout /t 2 /nobreak >nul
goto ASKD

:: ---- ASK RESOLUTION ----
:ASKR
cls
echo.
echo ========================================================================================
echo          Select Resolution for Long Video Creation- by Munna MasterMind
echo                https://facebook.com/The.Munna
echo ========================================================================================
echo Video: %VIDEO% (!ORIG_WIDTH!x!ORIG_HEIGHT!)
if "%AUDCHOICE%"=="1" (
    echo Audio: None
) else (
    echo Audio: %AUDIO%
)
echo Video In Audio: !HAS_VIDEO_AUDIO! (1=Yes, 0=No)
echo ------------------------------------------
echo Duration: %DUR% [Selected]
echo ----------------------------
echo Select resolution:
echo     1. Original Resolution (!ORIG_WIDTH!x!ORIG_HEIGHT!)
echo     2. 720p (1280x720)
echo     3. 1080p (1920x1080)
echo     4. 2K (2560x1440)
echo     5. 4K (3840x2160)
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
    echo Invalid choice & goto ASKR
)

echo ➜ Building %DUR% %RESNAME% video...

:: ---- STEP A: MAKE SHORT MERGED CLIP ----
set "MIX=%TEMP%\mix_short_%RESNAME%.mp4"
echo 🔊 Merging video + audio and encoding to %RESNAME%...

if "%AUDCHOICE%"=="1" (
  echo (No external music selected)
  if "!HAS_VIDEO_AUDIO!"=="1" (
    "%FFM%" -y -hide_banner -loglevel error -stats -i "%VIDEO%" ^
      -filter_complex "[0:v]%SCALE_FILTER%format=yuv420p[v]" ^
      -map "[v]" -map 0:a -c:v libx264 -preset ultrafast -crf 23 -c:a aac -b:a 192k -shortest "%MIX%"
  ) else (
    "%FFM%" -y -hide_banner -loglevel error -stats -i "%VIDEO%" ^
      -filter_complex "[0:v]%SCALE_FILTER%format=yuv420p[v]" ^
      -map "[v]" -c:v libx264 -preset ultrafast -crf 23 -shortest "%MIX%"
  )
) else (
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
)

if not exist "%MIX%" (echo ❌ Merge failed & pause & exit /b 1)

:: ---- STEP B: DIRECT LONG ENCODE (fast copy) ----
set "DURSAFE=%DUR::=-%"
set "FINAL=%OUT%\Create-Video_%RESNAME%_%DURSAFE%.mp4"
echo 🕒 Creating long video (%DUR%) from %RESNAME% source (fast copy)...
"%FFM%" -y -hide_banner -loglevel error -stats ^
  -stream_loop -1 -i "%MIX%" -t %DUR% -c copy "%FINAL%"
if errorlevel 1 (echo ❌ Long encode failed & pause & exit /b 1)

:: ---- CLEANUP ----
del /q "%TEMP%\has_audio.txt" >nul 2>&1
del /q "%TEMP%\resolution.txt" >nul 2>&1
del /q "%MIX%" >nul 2>&1

echo ✅ Done! %RESNAME% video saved: %FINAL%
echo File size:
for %%F in ("%FINAL%") do echo   %%~zF bytes
pause
