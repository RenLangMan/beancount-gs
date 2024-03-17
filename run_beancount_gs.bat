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
@REM ［适用场合］当你厌烦了c:\大于的提示符或者您想使您的提示符与众不同时，您可以试一试，非常有趣的DOS命令，可以随时显示时间与日期。
@REM ［用法］prompt $p$g 以当前目录名和大于号为提示符，这是最常用的提示符
@REM prompt $t 表示时间　　　　　　prompt $d 表示日期
@REM prompt $$ 表示$ 　　　　　　　prompt $q 表示=
@REM prompt $v 表示当前版本　　　　prompt $l 表示<
@REM prompt $b 表示| 　　　　　　　prompt $h 表示退位符
@REM prompt $e 表示Esc代表的字符 　prompt $_ 表示回车换行 
@REM https://blog.csdn.net/weixin_30819163/article/details/95188359

@REM 如果没有定义命令行提示符，则设置默认的命令行提示符prompt为:当前目录名和大于号
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

set PATH=%VIRTUAL_ENV%\Scripts;%PATH%
set VIRTUAL_ENV_PROMPT=(.env) 


H:\beancount-gs\beancount-gs.exe

:END
if defined _OLD_CODEPAGE (
    "%SystemRoot%\System32\chcp.com" %_OLD_CODEPAGE% > nul
    set _OLD_CODEPAGE=
)

