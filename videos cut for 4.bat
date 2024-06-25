@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion  

REM 检查是否已安装 ffmpeg
where ffmpeg >nul 2>nul
if errorlevel 1 (
    echo 未找到 ffmpeg，请确保已安装并已将其添加到系统路径中。
    pause
    exit /b
)

REM 列出当前目录下的所有视频文件
set /a count=1
for %%f in (*.mp4 *.avi *.mov *.mkv *.wmv *.flv *.mpeg *.mpg) do (
    echo !count!. %%f
    set "file[!count!]=%%f"
    set /a count+=1
)

REM 检查是否存在视频文件
if %count% equ 1 (
    echo 未找到任何视频文件。
    pause
    exit /b
)

set "num_i=1"

:all_main
    set "filename=!file[%num_i%]!"

    for /f "tokens=2 delims=, " %%a in ('ffmpeg -i "!filename!" 2^>^&1 ^| find "Duration:"') do (
        set str=%%a
    )
    echo 文件名：!filename! 
    echo 文件时长：!str!    

    for /f "tokens=1-3 delims=:. " %%a in ("!str!") do (  
        set "hours=%%a"  
        set "minutes=%%b"  
        set "seconds=%%c"  
    )  
  
    echo Hour: !hours!  
    echo Minute: !minutes!  
    echo Second: !seconds!  
  
    set /a "totalSeconds=hours*3600+minutes*60+seconds"  
    set /a "segmentSeconds=totalSeconds/4"  

    set "end_time_sourse=!hours!:!minutes!:!seconds!"
  
    set "endTime1="  
    set "endTime2="  
    set "endTime3="  
    set "endTime4=%end_time_sourse%"  
  
    set "num_k=1"
    :CalculateEndTime  
    set /a "currentSeconds+=segmentSeconds"  
    set /a "hours=currentSeconds/3600"  
    set /a "remainingSeconds=currentSeconds%%3600"  
    set /a "minutes=remainingSeconds/60"  
    set /a "seconds=remainingSeconds%%60"  
    if !hours! lss 10 set "hours=0!hours!"  
    if !minutes! lss 10 set "minutes=0!minutes!"  
    if !seconds! lss 10 set "seconds=0!seconds!"  
  
    if "!num_k!"=="1" (  
        set "endTime1=!hours!:!minutes!:!seconds!"  
    ) else if "!num_k!"=="2" (  
        set "endTime2=!hours!:!minutes!:!seconds!"  
    ) else if "!num_k!"=="3" (  
        set "endTime3=!hours!:!minutes!:!seconds!"  
    ) else if "!num_k!"=="4" (  
        goto :End  
    )  
  
    set /a "currentSeconds+=1"  REM 修正由于整数除法导致的误差  
    set /a num_k+=1 
    goto :CalculateEndTime  
  
    :End  
    set /a "currentSeconds=0" 
    echo End Time 1: !endTime1!
    echo End Time 2: !endTime2!  
    echo End Time 3: !endTime3!  
    echo End Time 4: !endTime4!  

    REM 如果用户没有输入导出视频格式，则默认为MP4
    if "%export_format%"=="" set "export_format=mp4"

    set "num_j=1"
    :cut
        echo !num_j!

        REM 保留原视频名称
        set "export_name=!filename:~0,-4!"

        REM 保留原视频名称，后缀加1234
        set "export_name=!export_name!_!num_j!"

        REM 将输入的时间部分格式化为两位数
        if "!num_j!"=="1" (  
            set "start_time=00:00:00"  
            set "end_time=!endTime1!"  
        ) else if "!num_j!"=="2" (  
            set "start_time=!endTime1!"  
            set "end_time=!endTime2!"  
        ) else if "!num_j!"=="3" (  
            set "start_time=!endTime2!"  
            set "end_time=!endTime3!"  
        ) else if "!num_j!"=="4" (  
            set "start_time=!endTime3!"  
            set "end_time=!endTime4!"  
        )  
        
        echo !filename! !start_time! !end_time!

        ffmpeg -i "!filename!" -ss !start_time! -to !end_time! -c:v copy -c:a copy "%export_name%.%export_format%"

        echo 视频已成功切割并保存为 "%export_name%.%export_format%"。

        REM 检查是否存在 !filename:~0,-4! 文件夹，如果不存在则创建
        if not exist "!filename:~0,-4!" (
            mkdir "!filename:~0,-4!"
            echo 创建了  !filename:~0,-4!  文件夹。
        )

        REM 将剪切好的视频移动到  !filename:~0,-4! 文件夹
        move /y "%export_name%.%export_format%" "!filename:~0,-4!\"

        echo 视频已成功移动到 "!filename:~0,-4!" 文件夹中。

        REM 更改视频名称
        ren "!filename:~0,-4!\%export_name%.%export_format%" "%export_name%.%export_format%"

        echo 视频名称已成功更改为 "%export_name%.%export_format%"。

        set /a num_j+=1 
        if !num_j! lss 5 (
            goto :cut
        )

set /a num_i+=1 
if !num_i! lss !count! (
    goto :all_main
)

endlocal  
pause
