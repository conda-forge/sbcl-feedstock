@echo off

mkdir %SRC_DIR%\_bootstrap
msiexec /a %MSI_FILE% /qb TARGETDIR="%SRC_DIR%\_bootstrap"

set "INSTALL_ROOT=%SRC_DIR%\_bootstrap\PFiles\Steel Bank Common Lisp"
copy "%INSTALL_ROOT%\sbcl.exe" "%INSTALL_ROOT%\sbcl"

set "SBCL_HOME=%INSTALL_ROOT%"
set "PATH=%SBCL_HOME%;%PATH%"

cd %SRC_DIR%\sbcl-source
  set "PATH=%BUILD_PREFIX%\Library\mingw-w64\bin;%PATH%"
  set "CC=gcc"
  set "CFLAGS=-I%BUILD_PREFIX%\Library\include %CFLAGS%"

  bash make.sh --fancy

  copy %SRC_DIR%\sbcl-source\COPYING %SRC_DIR%\COPYING
  copy %SRC_DIR%\sbcl-source\CREDITS %SRC_DIR%\CREDIT

  set INSTALL_ROOT=%PREFIX%
  set "SBCL_HOME=%INSTALL_ROOT%"
  bash install.sh
cd %SRC_DIR%

copy %SRC_DIR%\COPYING %PREFIX%\COPYING
copy %SRC_DIR%\CREDIT %PREFIX%\CREDIT

if not exist "%PREFIX%\etc\conda\activate.d\" mkdir "%PREFIX%\etc\conda\activate.d\"
if not exist "%PREFIX%\etc\conda\deactivate.d\" mkdir "%PREFIX%\etc\conda\deactivate.d\"

echo @echo off > "%PREFIX%\etc\conda\activate.d\activate_sbcl.bat"
echo set SBCL_HOME=%CONDA_PREFIX%\lib\sbcl >> "%PREFIX%\etc\conda\activate.d\activate_sbcl.bat"

echo @echo off > "%PREFIX%\etc\conda\deactivate.d\deactivate_sbcl.bat"
echo set SBCL_HOME= >> "%PREFIX%\etc\conda\deactivate.d\deactivate_sbcl.bat"
