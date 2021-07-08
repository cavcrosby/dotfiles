#
#
# shellcheck disable=1090,1091,2148

[ -r "${HOME}/.profile" ] && . "${HOME}/.profile"

[ -r "${HOME}/.profile_local" ] && . "${HOME}/.profile_local"

# This is just used to keep .profile/.profile_local from being loaded twice
# by '.bashrc'.
export PROFILES_LOADED=true

[ -r "${HOME}/.bashrc" ] && . "${HOME}/.bashrc"

# Used for now, the issue is PROFILES_LOADED lingers in the env when .bashrc is
# read each time from a new non-login bash session.
unset PROFILES_LOADED
