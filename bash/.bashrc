#
# shellcheck disable=SC2148 # not an executable
# ~/.bashrc: executed by bash(1) for non-login shells.

if ! printf '%s\n' "$-" | grep --quiet "i"; then
    return
fi

# shellcheck source=../shell/.rc
[ -r "${HOME}/.rc" ] && . "${HOME}/.rc"

shopt -s histappend checkwinsize

HISTABSOLUTESIZE=2000
HISTSIZE="${HISTABSOLUTESIZE}"
HISTFILESIZE="${HISTABSOLUTESIZE}"
HISTCONTROL="ignoredups:ignorespace"
if (tput setaf && tput setab) > "/dev/null" 2>&1; then
    ANSI_COLOR_SUPPORT=1 # true
    enter_bold_mode="$(tput bold)"
    color_red="$(tput setaf 1)"
    color_green="$(tput setaf 2)"
    color_blue="$(tput setaf 4)"
    exit_attr_mode="$(tput sgr0)"
else
    ANSI_COLOR_SUPPORT=0 # false
fi

alias ll="ls -alF"
alias la="ls -A"
alias l="ls -CF"
if ! [ -x "$(command -v kubectl)" ] && [ -x "$(command -v minikube)" ]; then
    alias kubectl="minikube kubectl --"
fi

_printf_ok() {
    if (( ANSI_COLOR_SUPPORT )); then
        printf '%s %bok%b\n' "$1" "${color_green}" "${exit_attr_mode}"
    else
        printf '%s ok\n' "$1"
    fi
}

_printf_error() {
    if (( ANSI_COLOR_SUPPORT )); then
        printf '%s %berror%b %s\n' "$1" "${color_red}" "${exit_attr_mode}" "$2" >&2
    else
        printf '%s error %s\n' "$1" "$2" >&2
    fi
}

chktooling() {
    local log_file_path
    if [ "$(command -v aws)" ]; then
        log_file_path="$(mktemp --tmpdir "aws-cli.log.$(date '+%Y-%m-%dT%H:%M:%S')-XXX")"
        if aws sts get-caller-identity > "${log_file_path}" 2>&1; then
            _printf_ok "checking aws-cli credentials..."
        else
            _printf_error "checking aws-cli credentials..." "see ${log_file_path}"
        fi
    fi

    if [ "$(command -v docker)" ]; then
        log_file_path="$(mktemp --tmpdir "docker.log.$(date '+%Y-%m-%dT%H:%M:%S')-XXX")"
        if env --chdir "${HOME}/.docker" docker login > "${log_file_path}" 2>&1; then
            _printf_ok "checking docker hub credentials..."
        else
            _printf_error "checking docker hub credentials..." "see ${log_file_path}"
        fi
    fi

    if [ "$(command -v msmtp)" ]; then
        if printf '%s\n' "hello there cavcrosby" \
            | msmtp \
                --account "gmail" \
                "cavcrosby@gmail.com" \
                > "/dev/null" \
                2>&1; \
        then
            _printf_ok "checking gmail smtp credentials..."
        else
            _printf_error "checking gmail smtp credentials..." "see ${HOME}/.msmtp.log"
        fi
    fi

    if [ "$(command -v rclone)" ]; then
        log_file_path="$(mktemp --tmpdir "rclone.log.$(date '+%Y-%m-%dT%H:%M:%S')-XXX")"
        if rclone ls --max-depth 1 "crosbyco3:/" > "${log_file_path}" 2>&1; then
            _printf_ok "checking drive token blob for crosbyco3..."
        else
            _printf_error "checking drive token blob for crosbyco3..." "see ${log_file_path}"
        fi
    fi
}

genpass() {
    local passlen="$1"
    tr \
        --complement \
        --delete \
        '[:alnum:]!@#$%^&*' \
        < "/dev/urandom" \
        | head --bytes "${passlen}" \
        | sed 's/$/\n/'
}

ssh_keygen() {
    ssh-keygen \
        -t "ed25519" \
        -C "${LOGNAME}@${HOSTNAME} $(date)" \
        -f "${HOME}/.ssh/id_ed25519" \
        -N ""
}

# Intended for the lesspipe provided on debian-like systems, see debian's
# lesspipe(1).
[ -x "/usr/bin/lesspipe" ] && eval "$(lesspipe)"

if (( ANSI_COLOR_SUPPORT )); then
    PS1='\[${enter_bold_mode}${color_green}\]\u@\h\[${exit_attr_mode}\]:\[${enter_bold_mode}${color_blue}\]\W\[${exit_attr_mode}\]\$ '
else
    PS1='\u@\h:\w\$ '
fi

if (( ANSI_COLOR_SUPPORT )) || (tput setf && tput setb) > "/dev/null" 2>&1; then
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
    PATH="${PYENV_ROOT}/bin:${PATH}"
    eval "$(pyenv init - bash)"

    if [ -d "${PYENV_ROOT}/plugins/pyenv-virtualenv" ]; then
        eval "$(pyenv virtualenv-init -)"
    fi
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

export PATH
