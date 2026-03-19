@echo off
echo ===================================================
echo  FinSight ML Server - One-Click Startup
echo ===================================================
echo.

:: Step 1: Kill any old server on port 8001
echo [1/3] Cleaning up old server (if any)...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8001 2^>nul') do (
    taskkill /F /PID %%a >nul 2>&1
)
timeout /t 1 >nul

:: Step 2: Start the ML FastAPI server in a new window
echo [2/3] Starting ML server on port 8001...
start "ML Server" cmd /c "cd /d %~dp0 && python api/server.py"
timeout /t 5 >nul

:: Step 3: Setup adb reverse (tunnels device ports to host)
echo [3/3] Setting up adb reverse (device tunnels)...
set ADB=C:\Users\lenovo\AppData\Local\Android\Sdk\platform-tools\adb.exe
for /f "tokens=1" %%i in ('"%ADB%" devices ^| findstr "\<device\>"') do (
    echo     Setting up tunnel for device: %%i
    "%ADB%" -s %%i reverse tcp:8001 tcp:8001
)
echo.

echo ===================================================
echo  ML Server is UP! Open http://localhost:8001/docs
echo  App URL: http://127.0.0.1:8001
echo ===================================================
echo.
pause
