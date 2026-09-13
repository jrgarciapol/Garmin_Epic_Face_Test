@echo off
rem Lanza el reloj en una ventana. Requiere Python 3.10+ y las dependencias:
rem     pip install -r requirements.txt
cd /d "%~dp0"
python -m reloj --ventana %*
if errorlevel 1 pause
