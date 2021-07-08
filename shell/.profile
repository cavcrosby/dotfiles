#
#
# shellcheck disable=2148

# adds repository dirs as env vars
export GIT_REPOS_PATH="${HOME}/git"
export HG_REPOS_PATH="${HOME}/hg"
export SVN_REPOS_PATH="${HOME}/svn"

# preferred editor as env var
export EDITOR="codium --wait"

# set a fancy prompt (non-color, unless we know we "want" color)
case "${TERM}" in
    xterm-color|*-256color) color_prompt=true ;;
esac

if [ "${color_prompt}" = true ]; then
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\n\[\033[00m\]\$ '
else
    PS1='\u@\h:\w\$ '
fi
unset color_prompt

# add bin directory variants to PATH if they are not in it
SBIN_PATH="/sbin"
local_bin_path="${HOME}/.local/bin"
if [ "$(echo "${PATH}" | grep --extended-regexp ":?${SBIN_PATH}:?" --count)" -lt 1 ]; then
    export PATH="${PATH}:${SBIN_PATH}"
fi
if [ "$(echo "${PATH}" | grep --extended-regexp ":?${local_bin_path}:?" --count)" -lt 1 ]; then
    export PATH="${PATH}:${local_bin_path}"
fi

# pyenv is used to manage different versions of python on the same system.
# pyenv uses the following to initilize the shell env for both pyenv and its
# extension virtualenv.
export PYENV_ROOT="${HOME}/.pyenv"
PYENV_ROOT_BIN_PATH="/home/reap2sow1/.pyenv/bin"
if [ -d "${PYENV_ROOT}" ] && [ -d "${PYENV_ROOT_BIN_PATH}" ]; then
    export PATH="${PYENV_ROOT_BIN_PATH}:${PATH}"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
    # To deal with PATH manipulation that could result in duplication entries for
    # pyenv (e.g. GNOME also loads this dotfile).
    space_delimited_paths="$(echo "${PATH}" | tr ':' ' ')"
    # First path from space_delimited_paths starts the refactored_path, otherwise
    # the refactored path would similar to this ':foo:bar'.
    refactored_path="$(echo "${space_delimited_paths}" | awk '{print $1}')"
    for space_delimited_path in ${space_delimited_paths}; do
        if [ "$(echo "${refactored_path}" | grep "${space_delimited_path}" --count)" -lt 1 ]; then
            refactored_path="${refactored_path}:${space_delimited_path}"
        fi
    done
    export PATH="${refactored_path}"
fi
