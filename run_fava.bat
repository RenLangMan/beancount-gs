@echo off

rem This file is UTF-8 encoded, so we need to update the current code page while executing it
rem 记录旧的代码页值到_OLD_CODEPAGE变量中
for /f "tokens=2 delims=:." %%a in ('"%SystemRoot%\System32\chcp.com"') do (
    set _OLD_CODEPAGE=%%a
)
rem 如果定义了_OLD_CODEPAGE这个变量，就将代码改为65001==UTF-8编码
if defined _OLD_CODEPAGE (
    "%SystemRoot%\System32\chcp.com" 65001 > nul
)

rem 设置虚拟环境根目录
set VIRTUAL_ENV=H:\beancount-gs\.env

@REM prompt:设置提示符
@REM https://blog.csdn.net/weixin_30819163/article/details/95188359
@REM 如果没有定义命令行提示符，则设置默认的命令行提示符prompt为:当前目录名和>号
if not defined PROMPT set PROMPT=$P$G

@REM 如果有定义旧的虚拟环境命令行提示符_OLD_VIRTUAL_PROMPT，则定义默认的命令行提示符prompt为:旧的虚拟环境命令行_OLD_VIRTUAL_PROMPT
if defined _OLD_VIRTUAL_PROMPT set PROMPT=%_OLD_VIRTUAL_PROMPT%
@REM 如果有定义旧的虚拟环境PythonHome _OLD_VIRTUAL_PYTHONHOME，则定义PYTHONHOME为:旧的虚拟环境PythonHome：_OLD_VIRTUAL_PYTHONHOME
if defined _OLD_VIRTUAL_PYTHONHOME set PYTHONHOME=%_OLD_VIRTUAL_PYTHONHOME%

set _OLD_VIRTUAL_PROMPT=%PROMPT%
set PROMPT=(.env) %PROMPT%

if defined PYTHONHOME set _OLD_VIRTUAL_PYTHONHOME=%PYTHONHOME%
set PYTHONHOME=

if defined _OLD_VIRTUAL_PATH set PATH=%_OLD_VIRTUAL_PATH%
if not defined _OLD_VIRTUAL_PATH set _OLD_VIRTUAL_PATH=%PATH%

@REM 设置新的环境变量PATH 与 新的提示符
set PATH=%VIRTUAL_ENV%\Scripts;%PATH%
set VIRTUAL_ENV_PROMPT=(.env) 


fava .\data\beancount\33d074dafab8f7f71e681869f17bc103e2821b23\index.bean

:END
if defined _OLD_CODEPAGE (
    "%SystemRoot%\System32\chcp.com" %_OLD_CODEPAGE% > nul
    set _OLD_CODEPAGE=
)

