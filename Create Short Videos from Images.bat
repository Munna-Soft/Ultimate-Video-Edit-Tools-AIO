@echo off
setlocal enabledelayedexpansion
title Create Long Videos from Shorts- by Munna MasterMind

echo.
echo =========================================================================
echo 		Create Short Videos from Images- by Munna MasterMind
echo 			https://facebook.com/The.Munna
echo =========================================================================
echo.

:: Ask for user input (between 5 to 60 seconds)
set /p duration=Enter Your Video Duration (5 to 60 seconds): 

if %duration% LSS 5 (
    echo ❌ Error: Minimum duration is 5 seconds!
    pause
    exit /b
)
if %duration% GTR 60 (
    echo ❌ Error: Maximum duration is 60 seconds!
    pause
    exit /b
)

:: Calculate fade-out start = duration - 1
set /a fadeout=%duration%-1

:: Paths
set "ffmpeg=ffmpeg.exe"
set "img_dir=images"
set "out_dir=output"
set "audio=audio.mp3"
set "bg=bg.mp3"

if not exist "%out_dir%" mkdir "%out_dir%"

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

    echo Processing: %%i with animation !anim_index!

    if exist "%bg%" (
        "%ffmpeg%" -y -loop 1 -t %duration% -i "%%i" -stream_loop -1 -i "%audio%" -stream_loop -1 -i "%bg%" ^
        -filter_complex "[0:v]scale=1080:-1:force_original_aspect_ratio=decrease,pad=1080:1920:(1080-iw)/2:(1920-ih)/2,!anim![v];[1:a][2:a]amix=inputs=2:duration=longest:dropout_transition=0[aout]" ^
        -map "[v]" -map "[aout]" -t %duration% -pix_fmt yuv420p -preset veryfast ^
        "%out_dir%\!filename!"
    ) else (
        "%ffmpeg%" -y -loop 1 -t %duration% -i "%%i" -stream_loop -1 -i "%audio%" ^
        -filter_complex "[0:v]scale=1080:-1:force_original_aspect_ratio=decrease,pad=1080:1920:(1080-iw)/2:(1920-ih)/2,!anim![v]" ^
        -map "[v]" -map 1:a -t %duration% -pix_fmt yuv420p -preset veryfast ^
        "%out_dir%\!filename!"
    )
)

echo.
echo ✅ Done! Videos created (5–60s) with looping/padded audio.
pause
