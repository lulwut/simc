:: Used to automate everything for Alex so he can be lazy.
:: Requirements - Everything needs to be located in your windows path, except MSVC2015
:: 7Zip
:: WINSCP - Optional, it will just not upload the file automatically if you don't have it.
::  - "open downloads" is the command that selects the downloads alias in winscp, which for me is the simulationcraft server. Change downloads to whatever suits you.
:: MSVC 2015 - Fully updated
:: Git
:: QT 5.7.0, or whatever version we are currently using
:: Inno Setup - http://www.jrsoftware.org/isinfo.php - Used to make the installer, optional if you just want a compressed file.

@echo off
:: Building with PGO data will add 10-15 minutes to compile.
set /p ask=Build with PGO data? Only applies to 64-bit installation. (y/n)
@echo on

set simcversion=703-01
set SIMCAPPFULLVERSION=7.0.3.01
:: For bumping the minor version, just change the above line.  Make sure to also change setup32.iss and setup64.iss as well. 
set simcfiles=C:\Simulationcraft\
:: Location of source files
set qt_dir=C:\Qt\Qt5.7.0\5.7\
:: Location of QT
set redist=C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\redist\
:: This is a really standard location for VS2015, but change it if you installed it somewhere else.

cd ..
git clean -f -x -d
for /F "delims=" %%i IN ('git --git-dir=%simcfiles%\.git\ rev-parse --short HEAD') do set GITREV=-%%i

cd>bla.txt
set /p download=<bla.txt
del bla.txt

::WebEngine compilation.
set install=simc-%simcversion%-win64

for /f "skip=2 tokens=2,*" %%A in ('reg.exe query "HKLM\SOFTWARE\Microsoft\MSBuild\ToolsVersions\14.0" /v MSBuildToolsPath') do SET MSBUILDDIR=%%B

if %ask%==y "%MSBUILDDIR%msbuild.exe" %simcfiles%\simc_vs2015.sln /p:configuration=WebEngine-PGO /p:platform=x64 /nr:true
if %ask%==n "%MSBUILDDIR%msbuild.exe" %simcfiles%\simc_vs2015.sln /p:configuration=WebEngine /p:platform=x64 /nr:true

robocopy "%redist%x64\Microsoft.VC140.CRT" %install%\ msvcp140.dll vccorlib140.dll vcruntime140.dll
robocopy locale\ %install%\locale sc_de.qm sc_zh.qm sc_it.qm
robocopy winreleasescripts\ %install%\ qt.conf
robocopy . %install%\ Welcome.html Welcome.png Simulationcraft64.exe simc64.exe readme.txt Error.html COPYING
robocopy Profiles\ %install%\profiles\ *.* /S
cd %install%
%qt_dir%\msvc2015_64\bin\windeployqt.exe --no-translations simulationcraft64.exe
cd ..

cd winreleasescripts 
iscc.exe /DMyAppVersion=%simcversion% ^
		 /DSimcAppFullVersion="%SIMCAPPFULLVERSION%" "setup64.iss"
				
cd ..
call start winscp /command "open downloads" "put %download%\SimcSetup-%simcversion%-win64.exe -nopreservetime -nopermissions -transfer=binary" "exit"
7z a -r %install%%GITREV% %install% -mx9 -md=32m
call start winscp /command "open downloads" "put %download%\%install%%GITREV%.7z -nopreservetime -nopermissions -transfer=binary" "exit"