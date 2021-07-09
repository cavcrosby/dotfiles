# special makefile variables
.DEFAULT_GOAL := help
.RECIPEPREFIX := >

# recursive variables
SHELL = /usr/bin/sh

# shell template variables
export LOCAL_GITCONFIG = .gitconfig_local
export LOCAL_PROFILE = .profile_local
local_config_files_vars = \
	$${LOCAL_GITCONFIG}\
	$${LOCAL_PROFILE}

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
DOTFILES = dotfiles
LOCAL_DOTFILES = local-dotfiles
INSTALL = install
UNINSTALL = uninstall
CLEAN = clean

# executables
ENVSUBST = envsubst
STOW = stow
executables = \
	${STOW}

# simply expanded variables
SHELL_TEMPLATE_EXT := .shtpl
shell_template_wildcard := %${SHELL_TEMPLATE_EXT}
DOTFILE_WILDCARD := .%
dotfile_shell_templates := $(shell find ${CURDIR} -name .*${SHELL_TEMPLATE_EXT})

# TODO(cavcrosby): using a shorter variable name w/comment < a tad longer variable name with no comment!
# NOTES: e ==> executable, certain executables should exist before
# running. Inspired from:
# https://stackoverflow.com/questions/5618615/check-if-a-program-exists-from-a-makefile#answer-25668869
_check_executables := $(foreach e,${executables},$(if $(shell command -v ${e}),pass,$(error "No ${e} in PATH")))

# Determines the dotfile name(s) to be generated from the template(s).
# Short hand notation for string substitution: $(text:pattern=replacement).
dotfils := $(dotfile_shell_templates:${SHELL_TEMPLATE_EXT}=)

.PHONY: ${HELP}
${HELP}:
	# inspired by the makefiles of the Linux kernel and Mercurial
>	@echo 'Available make targets:'
>	@echo '  ${DOTFILES}       - evaluate dotfiles that are shell templates (shtpls).'
>	@echo '  ${LOCAL_DOTFILES} - creates local dotfiles not tracked by version control.'
>	@echo '  ${INSTALL}        - links all the dotfiles to their appropriate places.'
>	@echo '  ${UNINSTALL}      - removes links that were inserted by the install target.'
>	@echo '  ${CLEAN}          - removes files generated from the ${DOTFILES} target.'

.PHONY: ${DOTFILES}
${DOTFILES}: ${dotfils}

.PHONY: ${LOCAL_DOTFILES}
${LOCAL_DOTFILES}:
>	touch $${HOME}/${LOCAL_PROFILE}
>	touch $${HOME}/${LOCAL_GITCONFIG}

.PHONY: ${INSTALL}
${INSTALL}: ${dotfils}
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

# custom implicit rules for the above targets
${DOTFILE_WILDCARD}: ${DOTFILE_WILDCARD}${SHELL_TEMPLATE_EXT}
>	${ENVSUBST} '${local_config_files_vars}' < "$<" > "$@"

.PHONY: ${CLEAN}
${CLEAN}:
>	rm --force ${dotfils}
