# shellcheck disable=1090,2148
# Load .profile
[ -r "${HOME}/.profile" ] && source "${HOME}/.profile"

# NOTE: currently this is just used to keep .profile from 
# being loaded assuming .bashrc also loads .profile
export FROM_BASH_PROFILE="true"

# load .bashrc
[ -r "${HOME}/.bashrc" ] && source "${HOME}/.bashrc"

# NOTE2: work around for now, the issue is FROM_BASH_PROFILE
# lingers in the env when .bashrc is called each time for a new terminal session
unset FROM_BASH_PROFILE
