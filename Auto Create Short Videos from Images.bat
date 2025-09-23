@echo off
setlocal enabledelayedexpansion
title Auto Create Short Videos from Images- by Munna MasterMind

echo.
echo ========================================================================================
echo               Select Music for Short Video Creation- by Munna MasterMind
echo                        https://facebook.com/The.Munna
echo ========================================================================================
echo.

:: ---- Paths ----
set "ffmpeg=ffmpeg.exe"
set "img_dir=Images"
set "music_dir=Music"
set "out_dir=Output"
set "temp_dir=Temp"

if not exist "%music_dir%" mkdir "%music_dir%"
if not exist "%img_dir%" mkdir "%img_dir%"
if not exist "%out_dir%" mkdir "%out_dir%"
if not exist "%temp_dir%" mkdir "%temp_dir%"

:: ---- List available audio ----
set j=0
echo Available Music:
for %%F in ("%music_dir%\*.mp3" "%music_dir%\*.wav" "%music_dir%\*.m4a" "%music_dir%\*.aac") do (
    set /a j+=1
    set "AUD!j!=%%~fF"
    echo   !j!. %%~nxF
)

if %j%==0 (
    echo ❌ No audio files found in %music_dir%!
    pause
    exit /b
)
echo ------------------------------------------

:ASKAUD
<nul set /p "=Select Your Audio [1-%j%]: "
set /p "AUDCHOICE="
set "AUDIO=!AUD%AUDCHOICE%!"
if not defined AUDIO (
    echo ❌ Invalid selection! retrying in 2s...
    timeout /t 2 /nobreak >nul
    goto ASKAUD
)

:: Optional background music
set "bg=%music_dir%\bg.mp3"
if exist "%bg%" (
    echo ℹ️ Background music found: bg.mp3 (will be mixed)
) else (
    set "bg="
)

echo.
echo 🎵 You Selected: %AUDIO%
echo 🖼️ Images will be taken from: %img_dir%
echo.
echo ------------------------------------------

:: ---- Ask for duration ----
:ASKDUR
<nul set /p "=Enter Your Video Duration (5 to 60 seconds): "
set /p "duration="
if not defined duration goto ASKDUR
if %duration% LSS 5 (
    echo ❌ Error: Minimum duration is 5 seconds!
    timeout /t 2 >nul
    goto ASKDUR
)
if %duration% GTR 60 (
    echo ❌ Error: Maximum duration is 60 seconds!
    timeout /t 2 >nul
    goto ASKDUR
)

:: Calculate fade-out start = duration - 1
set /a fadeout=%duration%-1

:: ---- Process each image ----
set count=0
for %%i in (%img_dir%\*.jpg %img_dir%\*.jpeg %img_dir%\*.png) do (
    set /a count+=1
    set "filename=video!count!.mp4"

    set /a anim_index=!count! %% 5

    if !anim_index! EQU 0 set "anim=zoompan=z='min(zoom+0.002,1.3)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=%duration%*25:s=1080x1920"
    if !anim_index! EQU 1 set "anim=zoompan=z='if(gte(zoom,1.3),zoom-0.002,1.3)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=%duration%*25:s=1080x1920"
    if !anim_index! EQU 2 set "anim=zoompan=z='1.2':x='on*3':y='0':d=%duration%*25:s=1080x1920"
    if !anim_index! EQU 3 set "anim=zoompan=z='1.2':x='iw-on*3':y='0':d=%duration%*25:s=1080x1920"
    if !anim_index! EQU 4 set "anim=zoompan=z='1.2':x='0':y='on*3':d=%duration%*25:s=1080x1920"
    if !anim_index! EQU 5 set "anim=zoompan=z='1.2':x='0':y='ih-on*3':d=%duration%*25:s=1080x1920"
    if !anim_index! EQU 6 set "anim=zoompan=z='1.25':x='on*2':y='on*2':d=%duration%*25:s=1080x1920"
    if !anim_index! EQU 7 set "anim=zoompan=z='1.25':x='iw-on*2':y='ih-on*2':d=%duration%*25:s=1080x1920"
    if !anim_index! EQU 8 set "anim=rotate=0.003*on:ow=1080:oh=1920,zoompan=z='1.2':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=%duration%*25:s=1080x1920"
    if !anim_index! EQU 9 set "anim=rotate=-0.003*on:ow=1080:oh=1920,zoompan=z='1.2':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=%duration%*25:s=1080x1920"

    echo Processing: %%~nxi with animation !anim_index!

    if defined bg (
        "%ffmpeg%" -y -loop 1 -t %duration% -i "%%i" -stream_loop -1 -i "%AUDIO%" -stream_loop -1 -i "%bg%" ^
        -filter_complex "[0:v]scale=1080:-1:force_original_aspect_ratio=decrease,pad=1080:1920:(1080-iw)/2:(1920-ih)/2,!anim![v];[1:a][2:a]amix=inputs=2:duration=longest:dropout_transition=0[aout]" ^
        -map "[v]" -map "[aout]" -t %duration% -pix_fmt yuv420p -preset veryfast ^
        "%out_dir%\!filename!"
    ) else (
        "%ffmpeg%" -y -loop 1 -t %duration% -i "%%i" -stream_loop -1 -i "%AUDIO%" ^
        -filter_complex "[0:v]scale=1080:-1:force_original_aspect_ratio=decrease,pad=1080:1920:(1080-iw)/2:(1920-ih)/2,!anim![v]" ^
        -map "[v]" -map 1:a -t %duration% -pix_fmt yuv420p -preset veryfast ^
        "%out_dir%\!filename!"
    )
)

echo.
echo ✅ Done! Videos created with selected music (and optional bg.mp3).
pause
