@if defined SBCL_HOME (
     @set "_SBCL_HOME_BACKUP=%SBCL_HOME%"
)
@set "SBCL_HOME=%CONDA_PREFIX%\lib\sbcl"
