#
#
# ~/.bashrc: executed by bash(1) for non-login shells.
# shellcheck disable=2148

# If not running interactively, don't do anything. Should be added to
# .bash_profile if I wanted to discard it from here. For reference:
# https://stackoverflow.com/questions/40747576/need-help-understanding-a-strange-bashrc-expression
case "$-" in
    *i*) ;;
      *) return ;;
esac

# Don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options.
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTABSOLUTESIZE=2000
HISTSIZE="${HISTABSOLUTESIZE}"
HISTFILESIZE="${HISTABSOLUTESIZE}"

# Check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS. Will leave for now,
# but bash(1) seems to indicate this is enabled by default.
shopt -s checkwinsize

# Make less more friendly for non-text input files on Debian GNU/Linux systems,
# see lesspipe(1).
[ -x "/usr/bin/lesspipe" ] && eval "$(SHELL=/bin/sh lesspipe)"

# set a fancy prompt (non-color, unless we know we "want" color)
case "${TERM}" in
    xterm-color|*-256color) color_prompt=true ;;
esac

if [ "${color_prompt}" = true ]; then
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]|\[\033[1;34m\]\W\[\033[00m\]$ '
else
    PS1='\u@\h:\w\$ '
fi
unset color_prompt

# enable color support of ls and add handy aliases
if [ -x /usr/bin/dircolors ]; then
    # I want the last expression to run in the event if either of the first two
    # expressions failed to run 'as intended'.
    # shellcheck disable=2015
    [ -r ~/.dircolors ] && eval "$(dircolors --bourne-shell ~/.dircolors)" || eval "$(dircolors --bourne-shell)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# add other handy aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Enable programmable bash completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        # shellcheck disable=1091
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        # shellcheck disable=1091
        . /etc/bash_completion
    fi
fi

if [ -d "${PYENV_ROOT}" ]; then
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi

# Used by various Debian maintenance tools, for reference:
# https://www.debian.org/doc/manuals/maint-guide/first.en.html#dh-make
DEBEMAIL="conner@cavcrosby.tech"
DEBFULLNAME="Conner Crosby"
export DEBEMAIL DEBFULLNAME

# Sets an additional directory for make to search in for makefiles I include in
# other project makefiles.
make() {
    command make --include-dir "${HOME}/.local/include/cavcrosby-makefiles" "$@"
}
