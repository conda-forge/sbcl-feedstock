@echo off
￼
mkdir %SRC_DIR%\_bootstrap
msiexec /a %MSI_FILE% /qb TARGETDIR="%SRC_DIR%\_bootstrap"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

set "INSTALL_ROOT=%SRC_DIR%\_bootstrap\PFiles\Steel Bank Common Lisp"
copy "%INSTALL_ROOT%\sbcl.exe" "%INSTALL_ROOT%\sbcl"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

set "SBCL_HOME=%INSTALL_ROOT%"
set "PATH=%SBCL_HOME%;%PATH%"

cd %SRC_DIR%\sbcl-source
  set "PATH=%BUILD_PREFIX%\Library\mingw-w64\bin;%PATH%"
  set "CC=gcc"
  set "CFLAGS=-I%BUILD_PREFIX%\Library\include %CFLAGS%"

  bash make.sh --fancy
  if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

  copy %SRC_DIR%\sbcl-source\COPYING %SRC_DIR%\COPYING
  copy %SRC_DIR%\sbcl-source\CREDITS %SRC_DIR%\CREDIT

  set "INSTALL_ROOT=%PREFIX%"
  set "SBCL_HOME=%INSTALL_ROOT%\lib\sbcl"
  bash install.sh
  if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
cd %SRC_DIR%
