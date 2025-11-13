@echo off
setlocal

:: Set your variables
set "PATH_TO_LOVE=C:\Program Files\LOVE\love.exe"
set "GAME_NAME=Ultimate Tic-Tac-Toe"
set "BAT_FILE=%~nx0"

:: Check if love.exe exists
if not exist "%PATH_TO_LOVE%" (
    echo Error: love.exe not found at "%PATH_TO_LOVE%"
    pause
    exit /b 1
)

:: Create a temporary .zip file (excluding specified files and folders) then rename to .love
echo Creating %GAME_NAME%.love file...
powershell -Command "$exclude = @('.git', '.idea', '.gitignore', '.luarc.json', '%BAT_FILE%', 'LICENCE', 'README.md', 'run.bat'); $files = Get-ChildItem -Path '.' -Exclude $exclude; Compress-Archive -Path $files -DestinationPath 'temp.zip' -Force"

:: Check if zip was successful and rename
if exist "temp.zip" (
    ren "temp.zip" "%GAME_NAME%.love"
    echo Successfully created %GAME_NAME%.love
) else (
    echo Error: Failed to create zip file
    pause
    exit /b 1
)

:: Check if .love file exists
if not exist "%GAME_NAME%.love" (
    echo Error: Failed to create %GAME_NAME%.love
    pause
    exit /b 1
)

:: Create the executable by combining love.exe and the .love file
echo Creating %GAME_NAME%.exe...
copy /b "%PATH_TO_LOVE%" + "%GAME_NAME%.love" "%GAME_NAME%.exe" >nul

:: Check if exe was created successfully
if exist "%GAME_NAME%.exe" (
    echo Success! %GAME_NAME%.exe has been created!

    :: Optional: Clean up the .love file
    del "%GAME_NAME%.love"
    echo Temporary .love file removed.
) else (
    echo Error: Failed to create %GAME_NAME%.exe
)

pause