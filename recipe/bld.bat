@echo off

mkdir %SRC_DIR%\_bootstrap
msiexec /a %MSI_FILE% /qb TARGETDIR="%SRC_DIR%\_bootstrap"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

set "INSTALL_ROOT=%SRC_DIR%\_bootstrap\PFiles\Steel Bank Common Lisp"
copy "%INSTALL_ROOT%\sbcl.exe" "%INSTALL_ROOT%\sbcl" > nul
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

set "SBCL_HOME=%INSTALL_ROOT%"
set "PATH=%SBCL_HOME%;%PATH%"

cd %SRC_DIR%\sbcl-source
  set "PATH=%BUILD_PREFIX%\Library\mingw-w64\bin;%PATH%"
  set "CC=gcc"
  set "CFLAGS=-I%BUILD_PREFIX%\Library\include %CFLAGS%"

  bash make.sh --fancy > nul
  if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

  set "INSTALL_ROOT=%PREFIX%"
  set "SBCL_HOME=%INSTALL_ROOT%/lib/sbcl"
  bash install.sh > nul
  if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
cd %SRC_DIR%

copy %SRC_DIR%\sbcl-source\COPYING %SRC_DIR%\COPYING > nul
copy %SRC_DIR%\sbcl-source\CREDITS %SRC_DIR%\CREDITS > nul

if not exist "%PREFIX%\etc\conda\activate.d\" mkdir "%PREFIX%\etc\conda\activate.d\"
if not exist "%PREFIX%\etc\conda\deactivate.d\" mkdir "%PREFIX%\etc\conda\deactivate.d\"

copy "%RECIPE_DIR%\scripts\activate.bat" "%PREFIX%\etc\conda\activate.d\sbcl-activate.bat" > nul
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
copy "%RECIPE_DIR%\scripts\deactivate.bat" "%PREFIX%\etc\conda\deactivate.d\sbcl-deactivate.bat" > nul
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
