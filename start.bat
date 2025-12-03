@echo off

echo Starting up local server
start "" /B python server.py

timeout /t 2 /nobreak >nul

echo Starting BizHawk.exe
start "" "..\..\EmuHawk.exe" --socket_ip=127.0.0.1 --socket_port=5000

echo Starting training script
start "" /B python train.py

echo training script not added yet

pause>nul