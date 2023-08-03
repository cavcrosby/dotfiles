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
if (tput setaf && tput setab) > /dev/null 2>&1; then
    ANSI_COLOR_SUPPORT=1 # true
else
    ANSI_COLOR_SUPPORT=0 # false
fi

alias ll="ls -alF"
alias la="ls -A"
alias l="ls -CF"
if ! [ -x "$(command -v kubectl)" ] && [ -x "$(command -v minikube)" ]; then
    alias kubectl="minikube kubectl --"
fi
alias docker='env --chdir "${HOME}/.docker" docker'

make() {
    command make --include-dir "${HOME}/.local/include/cavcrosby-makefiles" "$@"
}

chktooling() {
    if (( ANSI_COLOR_SUPPORT )); then
        local -r OK='\033[00;32mok\033[m'
        local -r ERROR='\033[00;31merror\033[m'
    else
        local -r OK="ok"
        local -r ERROR="error"
    fi

    local log_file_path
    if [ "$(command -v aws)" ]; then
        log_file_path="$(mktemp --tmpdir "aws-cli.log.$(date "+%b_%d_%H_%M_%S_%N")XXX")"
        if aws sts get-caller-identity > "${log_file_path}" 2>&1; then
            echo -e "checking aws-cli credentials... ${OK}"
        else
            echo -e "checking aws-cli credentials... ${ERROR} see ${log_file_path}" >&2
        fi
    fi

    if [ "$(command -v docker)" ]; then
        log_file_path="$(mktemp --tmpdir "docker.log.$(date "+%b_%d_%H_%M_%S_%N")XXX")"
        if docker login > "${log_file_path}" 2>&1; then
            echo -e "checking docker hub credentials... ${OK}"
        else
            echo -e "checking docker hub credentials... ${ERROR} see ${log_file_path}" >&2
        fi
    fi

    if [ "$(command -v msmtp)" ]; then
        if echo "hello there cavcrosby" \
            | msmtp \
                --account "gmail" \
                "cavcrosby@gmail.com" \
                > "/dev/null" \
                2>&1; \
        then
            echo -e "checking gmail smtp credentials... ${OK}"
        else
            echo -e "checking gmail smtp credentials... ${ERROR} see ${HOME}/.msmtp.log" >&2
        fi
    fi

    if [ "$(command -v rclone)" ]; then
        log_file_path="$(mktemp --tmpdir "rclone.log.$(date "+%b_%d_%H_%M_%S_%N")XXX")"
        if rclone ls --max-depth 1 "crosbyco3:/" > "${log_file_path}" 2>&1; then
            echo -e "checking drive token blob for crosbyco3... ${OK}"
        else
            echo -e "checking drive token blob for crosbyco3... ${ERROR} see ${log_file_path}" >&2
        fi
    fi
}

# Intended for the lesspipe provided on debian-like systems, see debian's
# lesspipe(1).
[ -x "/usr/bin/lesspipe" ] && eval "$(lesspipe)"

if (( ANSI_COLOR_SUPPORT )); then
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[1;34m\]\W\[\033[00m\]$ '
else
    PS1='\u@\h:\w\$ '
fi

if (( ANSI_COLOR_SUPPORT )) || (tput setf && tput setb) > /dev/null 2>&1; then
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
