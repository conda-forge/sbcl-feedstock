@if defined _SBCL_HOME_BACKUP (
    @set "SBCL_HOME=%_SBCL_HOME_BACKUP%"
    @set "_SBCL_HOME_BACKUP="
) else (
    @set "SBCL_HOME="
)
