@echo off

:: Use existing conda sbcl as bootstrap
call mamba install -y sbcl

:: Build and install SBCL (builds in _conda-build dir and installs in PREFIX)
mkdir %SRC_DIR%\_conda-build
cd %SRC_DIR%\_conda-build
  xcopy /E %SRC_DIR%\sbcl-source\* . > nul

  set "PATH=%BUILD_PREFIX%\Library\ucrt64\bin;%PATH%"
  set "CC=gcc"
  set "CFLAGS=-I%BUILD_PREFIX%\Library\ucrt64\include %CFLAGS%"

  set "_build_prefix=%BUILD_PREFIX:\=/%"
  bash -c "find %_build_prefix% -name gcc.exe"

  bash make.sh --fancy > nul
  if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

  set "INSTALL_ROOT=%PREFIX%"
  set "SBCL_HOME=%INSTALL_ROOT%/lib/sbcl"
  bash install.sh > nul
  if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

  :: Install dynamic library
  make -C src/runtime libsbcl.dll
  if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
  copy src\runtime\libsbcl.dll %PREFIX%\bin\libsbcl.dll > nul
  copy src\runtime\libsbcl.lib %PREFIX%\lib\libsbcl.lib > nul

cd %SRC_DIR%

:: Copy the license files for conda-recipe compliance
copy %SRC_DIR%\sbcl-source\COPYING %SRC_DIR%\COPYING > nul
copy %SRC_DIR%\sbcl-source\CREDITS %SRC_DIR%\CREDITS > nul

:: Setting conda host environment variables
if not exist "%PREFIX%\etc\conda\activate.d\" mkdir "%PREFIX%\etc\conda\activate.d\"
if not exist "%PREFIX%\etc\conda\deactivate.d\" mkdir "%PREFIX%\etc\conda\deactivate.d\"

copy "%RECIPE_DIR%\scripts\activate.bat" "%PREFIX%\etc\conda\activate.d\sbcl-activate.bat" > nul
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
copy "%RECIPE_DIR%\scripts\deactivate.bat" "%PREFIX%\etc\conda\deactivate.d\sbcl-deactivate.bat" > nul
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
