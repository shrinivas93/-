@echo off
set seconds=%2
set /a delay=%seconds%+1

:loop
Rscript %1
ipconfig /flushdns > nul
ping localhost -n %delay% > nul
goto loop