#
# shellcheck disable=SC2148 # not an executable
# ~/.bashrc: executed by bash(1) for non-login shells.

if ! echo "$-" | grep --quiet "i"; then
    return
fi

shopt -s histappend checkwinsize

HISTABSOLUTESIZE=2000
HISTSIZE="${HISTABSOLUTESIZE}"
HISTFILESIZE="${HISTABSOLUTESIZE}"
HISTCONTROL="ignoredups:ignorespace"

alias ll="ls -alF"
alias la="ls -A"
alias l="ls -CF"
if ! [ -x "$(command -v kubectl)" ] && [ -x "$(command -v minikube)" ]; then
    alias kubectl="minikube kubectl --"
fi

make() {
    command make --include-dir "${HOME}/.local/include/cavcrosby-makefiles" "$@"
}

# Intended for the lesspipe provided on debian-like systems, see debian's
# lesspipe(1).
[ -x "/usr/bin/lesspipe" ] && eval "$(lesspipe)"

if (tput setaf && tput setab) > /dev/null 2>&1; then
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[1;34m\]\W\[\033[00m\]$ '
else
    PS1='\u@\h:\w\$ '
fi

if (tput setaf && tput setab) > /dev/null 2>&1 || (tput setf && tput setb) > /dev/null 2>&1; then
    alias ls="ls --color=auto"
    alias grep="grep --color=auto"
    alias fgrep="fgrep --color=auto"
    alias egrep="egrep --color=auto"
fi

if [ -x "/usr/bin/dircolors" ]; then
    if [ -r "${HOME}/.dircolors" ]; then
        eval "$(dircolors --bourne-shell "${HOME}/.dircolors")"
    else
        eval "$(dircolors --bourne-shell)"
    fi
fi

if ! shopt -oq posix; then
    if [ -f "/usr/share/bash-completion/bash_completion" ]; then
        # File existence is system dependent and not guaranteed for sourcing
        # (SC1091).
        # shellcheck source=/dev/null
        . "/usr/share/bash-completion/bash_completion"
    elif [ -f "/etc/bash_completion" ]; then
        # File existence is system dependent and not guaranteed for sourcing
        # (SC1091).
        # shellcheck source=/dev/null
        . "/etc/bash_completion"
    fi
fi

if [ -d "${PYENV_ROOT}" ]; then
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi

# dynamic path means file existence is not guaranteed for sourcing (SC1091)
# shellcheck source=/dev/null
[ -s "${NVM_DIR}/nvm.sh" ] && . "${NVM_DIR}/nvm.sh"

# dynamic path means file existence is not guaranteed for sourcing (SC1091)
# shellcheck source=/dev/null
[ -s "${NVM_DIR}/bash_completion" ] && . "${NVM_DIR}/bash_completion"

if [ -d "${HOME}/.rbenv" ]; then
    eval "$("${HOME}"/.rbenv/bin/rbenv init - bash)"
fi
