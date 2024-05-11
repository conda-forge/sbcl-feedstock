@echo off
set INSTALL_ROOT=%PREFIX%

mkdir "%SRC_DIR%\_built"
msiexec /a "%SRC_DIR%\%MSI_FILE%" /qb TARGETDIR="%SRC_DIR%\_built"

dir "%SRC_DIR%\_built\PFiles\Steel Bank Common Lisp"

copy "%SRC_DIR%\_built\PFiles\Steel Bank Common Lisp\sbcl.exe" "%PREFIX%\bin"
copy "%SRC_DIR%\_built\PFiles\Steel Bank Common Lisp\sbcl.core" "%PREFIX%\bin"

if not exist "%PREFIX%\etc\conda\activate.d\" mkdir "%PREFIX%\etc\conda\activate.d\"
if not exist "%PREFIX%\etc\conda\deactivate.d\" mkdir "%PREFIX%\etc\conda\deactivate.d\"

echo @echo off > "%PREFIX%\etc\conda\activate.d\activate_sbcl.bat"
echo set SBCL_HOME=%CONDA_PREFIX%\lib\sbcl >> "%PREFIX%\etc\conda\activate.d\activate_sbcl.bat"

echo @echo off > "%PREFIX%\etc\conda\deactivate.d\deactivate_sbcl.bat"
echo set SBCL_HOME= >> "%PREFIX%\etc\conda\deactivate.d\deactivate_sbcl.bat"
