# special makefile variables
.DEFAULT_GOAL := help
.RECIPEPREFIX := >

# recursive variables
SHELL = /usr/bin/sh

# dotfile pkg dirs, stow will complain if I give absolute paths
bash_pkg = bash
git_pkg = git
shell_pkg = shell
msmtp_pkg = msmtp
ssh_pkg = .ssh

# pkg groupings, requires at least two pkgs to use a group
home_pkgs = \
	${bash_pkg}\
	${git_pkg}\
	${shell_pkg}\
	${msmtp_pkg}\

# targets
HELP = help
INSTALL = install
UNINSTALL = uninstall

# executables
STOW = stow
executables = \
	${STOW}

# TODO(cavcrosby): using a shorter variable name w/comment < a tad longer variable name with no comment!
# NOTES: e ==> executable, certain executables should exist before
# running. Inspired from:
# https://stackoverflow.com/questions/5618615/check-if-a-program-exists-from-a-makefile#answer-25668869
_check_executables := $(foreach e,${executables},$(if $(shell command -v ${e}),pass,$(error "No ${e} in PATH")))

.PHONY: ${HELP}
${HELP}:
	# inspired by the makefiles of the Linux kernel and Mercurial
>	@echo 'Available make targets:'
>	@echo '  install        - links all the dotfiles to their appropriate places.'
>	@echo '  uninstall      - removes links that were inserted by the install target.'

.PHONY: ${INSTALL}
${INSTALL}:
>	@for pkg in ${home_pkgs}; do \
>		echo ${STOW} --target="$${HOME}" "$${pkg}"; \
>		${STOW} --target="$${HOME}" "$${pkg}"; \
>	done
>
>	@echo ${STOW} --target="$${HOME}/.ssh" "${ssh_pkg}"
>	@${STOW} --target="$${HOME}/.ssh" "${ssh_pkg}"

# TODO(cavcrosby): while the below works, it appears to generate 'BUG' warnings, this appears to be an issue with stow. Will probably want to monitor the following ticket:
# https://github.com/aspiers/stow/issues/65
.PHONY: ${UNINSTALL}
${UNINSTALL}:
>	@for pkg in ${home_pkgs}; do \
>		echo ${STOW} --target="$${HOME}" --delete "$${pkg}"; \
>		${STOW} --target="$${HOME}" --delete "$${pkg}"; \
>	done
>
>	@echo ${STOW} --target="$${HOME}/.ssh" --delete "${ssh_pkg}"
>	@${STOW} --target="$${HOME}/.ssh" --delete "${ssh_pkg}"
