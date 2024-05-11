@echo off
mkdir "%SRC_DIR%\_bootstrap"
msiexec /a "%SRC_DIR%\%MSI_FILE%" /qb TARGETDIR="%SRC_DIR%\_bootstrap"

set "INSTALL_ROOT=%SRC_DIR%\_built\PFiles\Steel Bank Common Lisp"
set "SBCL_HOME=%INSTALL_ROOT%"
setx /M PATH "%SBCL_HOME%:%PATH%"

dir %SBCL_HIME%"
where sbcl

cd %SRC_DIR%\sbcl-source
  bash make.sh --fancy

  copy %SRC_DIR%\sbcl-source\COPYING %SRC_DIR%\COPYING
  copy %SRC_DIR%\sbcl-source\CREDITS %SRC_DIR%\CREDIT

  set INSTALL_ROOT=%PREFIX%
  bash install.sh
cd ..

if not exist "%PREFIX%\etc\conda\activate.d\" mkdir "%PREFIX%\etc\conda\activate.d\"
if not exist "%PREFIX%\etc\conda\deactivate.d\" mkdir "%PREFIX%\etc\conda\deactivate.d\"

echo @echo off > "%PREFIX%\etc\conda\activate.d\activate_sbcl.bat"
echo set SBCL_HOME=%CONDA_PREFIX%\lib\sbcl >> "%PREFIX%\etc\conda\activate.d\activate_sbcl.bat"

echo @echo off > "%PREFIX%\etc\conda\deactivate.d\deactivate_sbcl.bat"
echo set SBCL_HOME= >> "%PREFIX%\etc\conda\deactivate.d\deactivate_sbcl.bat"
