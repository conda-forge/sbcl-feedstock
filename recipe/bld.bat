@echo off

mkdir %SRC_DIR%\_bootstrap
msiexec /a %MSI_FILE% /qb TARGETDIR="%SRC_DIR%\_bootstrap"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

set "INSTALL_ROOT=%SRC_DIR%\_bootstrap\PFiles\Steel Bank Common Lisp"
copy "%INSTALL_ROOT%\sbcl.exe" "%INSTALL_ROOT%\sbcl"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Verify that the bootstrap runs the tests
copy "%INSTALL_ROOT%\sbcl" "%SRC_DIR%\src\runtime\sbcl" > nul
cd tests && bash run-tests.sh
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

set "SBCL_HOME=%INSTALL_ROOT%"
set "PATH=%SBCL_HOME%;%PATH%"

cd %SRC_DIR%\sbcl-source
  set "PATH=%BUILD_PREFIX%\Library\mingw-w64\bin;%PATH%"
  set "CC=gcc"
  set "CFLAGS=-I%BUILD_PREFIX%\Library\include %CFLAGS%"

  bash make.sh --fancy > nul 2>&1
  if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

  :: Test the build
  cd tests
    :: Remove these tests that rely upon /bin/sh or WSL
    :: del banner.test.sh checkheap.test.sh chill.test.sh clos.test.sh compiler.test.sh
    :: del elf-sans-immobile.test.sh elfcore.test.sh finalize.test.sh futex-wait.test.sh
    :: del genheaders.test.sh hide-packages.test.sh init-hooks.test.sh init.test.sh interface.test.sh
    :: del lzcore.test.sh relocation.test.sh room.test.sh run-program.test.sh save1.test.sh save10.test.sh
    :: del save2.test.sh save3.test.sh save4.test.sh save5.test.sh save6.test.sh
    :: del save7.test.sh save8.test.sh save9.test.sh script.test.sh stream.test.sh
    :: del threads.test.sh toplevel.test.sh undefined-classoid-bug.test.sh

    where sh
    where bash

    set "file_ext=*.sh *.lisp"
    set "search_string=\"/bin/sh\""
    set "replacement_string=\"%BUILD_PREFIX%/Library/usr/bin/sh.exe\""
    :: set "replacement_string=\"%BUILD_PREFIX%/Library/usr/bin/bash.exe\""

    :: Use for, findstr, and powershell to replace the string in the list of files
    for %%G in (%file_ext%) do (
      for %%F in (%%G) do (
          findstr /M /C:"%search_string%" "%%F" >nul && (
              powershell -Command "(Get-Content '%%F') -replace '%search_string%', '%replacement_string%' | Set-Content '%%F'"
          )
      )
    )

    :: bash run-tests.sh
    :: if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
  cd ..

  :: Install
  copy %SRC_DIR%\sbcl-source\COPYING %SRC_DIR%\COPYING
  copy %SRC_DIR%\sbcl-source\CREDITS %SRC_DIR%\CREDIT

  set "INSTALL_ROOT=%PREFIX%"
  set "SBCL_HOME=%INSTALL_ROOT%/lib/sbcl"
  bash install.sh
  if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
cd %SRC_DIR%

copy %SRC_DIR%\sbcl-source\COPYING %SRC_DIR%\COPYING
copy %SRC_DIR%\sbcl-source\CREDITS %SRC_DIR%\CREDITS

if not exist "%PREFIX%\etc\conda\activate.d\" mkdir "%PREFIX%\etc\conda\activate.d\"
if not exist "%PREFIX%\etc\conda\deactivate.d\" mkdir "%PREFIX%\etc\conda\deactivate.d\"

copy "%RECIPE_DIR%\scripts\activate.bat" "%PREFIX%\etc\conda\activate.d\sbcl-activate.bat" > nul
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
copy "%RECIPE_DIR%\scripts\deactivate.bat" "%PREFIX%\etc\conda\deactivate.d\sbcl-deactivate.bat" > nul
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
