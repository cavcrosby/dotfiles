#
# shellcheck disable=SC2148 # not an executable
# ~/.bash_profile: executed by bash(1) for login shells.

# shellcheck source=../shell/.profile
[ -r "${HOME}/.profile" ] && . "${HOME}/.profile"

# shellcheck source=../bash/.bashrc
[ -r "${HOME}/.bashrc" ] && . "${HOME}/.bashrc"
