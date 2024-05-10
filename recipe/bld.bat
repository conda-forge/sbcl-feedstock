@echo off
set INSTALL_ROOT=%PREFIX%

mkdir "%SRC_DIR%\_built"
cd %SRC_DIR%
msiexec /a "%MSI_FILE%" /qb TARGETDIR="%SRC_DIR%\_built"
dir
dir PFiles

copy "%SRC_DIR%\_built\PFiles\COPYING" "%RECIPE_DIR%\COPYING"
copy "%SRC_DIR%\_built\PFiles\CREDITS" "%RECIPE_DIR%\CREDITS"

if not exist "%PREFIX%\etc\conda\activate.d\" mkdir "%PREFIX%\etc\conda\activate.d\"
if not exist "%PREFIX%\etc\conda\deactivate.d\" mkdir "%PREFIX%\etc\conda\deactivate.d\"

echo @echo off > "%PREFIX%\etc\conda\activate.d\activate_sbcl.bat"
echo set SBCL_HOME=%CONDA_PREFIX%\lib\sbcl >> "%PREFIX%\etc\conda\activate.d\activate_sbcl.bat"

echo @echo off > "%PREFIX%\etc\conda\deactivate.d\deactivate_sbcl.bat"
echo set SBCL_HOME= >> "%PREFIX%\etc\conda\deactivate.d\deactivate_sbcl.bat"
