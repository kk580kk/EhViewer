@echo off
REM HarmonyOS 构建包装脚本 (Windows)
cd /d "%~dp0"
where hvigorw >nul 2>&1 && (hvigorw %*) && exit /b
where hvigor >nul 2>&1 && (hvigor %*) && exit /b
node "%~dp0scripts\run-hvigor.js" %*
