# special makefile variables
.DEFAULT_GOAL := help
.RECIPEPREFIX := >

# recursively expanded variables
SHELL = /usr/bin/sh

# shell template variables
export LOCAL_PROFILE = .profile_local
local_config_files_vars = \
	$${LOCAL_PROFILE}\
	$${_RCLONE_DRIVE_TOKEN}\
	$${_RCLONE_DRIVE_ROOT_FOLDER_ID}\
	$${MSMTP_GMAIL_PASSWORD}\
	$${GIT_SIGNING_KEY_ID}

# stow pkgs
BASH_PKG = bash
GIT_PKG = git
SHELL_PKG = shell
MSMTP_PKG = msmtp
SSH_PKG = ssh
TMUX_PKG = tmux
RCLONE_PKG = rclone

stow_pkgs = \
	${BASH_PKG}\
	${GIT_PKG}\
	${SHELL_PKG}\
	${MSMTP_PKG}\
	${SSH_PKG}\
	${TMUX_PKG}\
	${RCLONE_PKG}

# targets
HELP = help
DOTFILES = dotfiles
LOCAL_DOTFILES = local-dotfiles
INSTALL = install
UNINSTALL = uninstall
RMPLAIN_FILES = rmplain-files
CLEAN = clean

# executables
ENVSUBST = envsubst
STOW = stow
executables = \
	${STOW}

# simply expanded variables
DOTFILE_WILDCARD := .%
dotfile_shell_template_paths := $(shell find . -name .*.shtpl)
dotfile_paths := $(patsubst %.shtpl,%,${dotfile_shell_template_paths})
pkg_file_paths := $(shell find . -mindepth 2 \( -type f \) \
	-and \( ! -path './.git*' \) \
	-and \( ! -name .stow-local-ignore \) \
	-and \( ! -name .*.shtpl \) \
	-and \( -printf '%P ' \) \
)

# inspired from:
# https://stackoverflow.com/questions/5618615/check-if-a-program-exists-from-a-makefile#answer-25668869
_check_executables := $(foreach exec,${executables},$(if $(shell command -v ${exec}),pass,$(error "No ${exec} in PATH")))

.PHONY: ${HELP}
${HELP}:
	# inspired by the makefiles of the Linux kernel and Mercurial
>	@echo 'Common make targets:'
>	@echo '  ${DOTFILES}       - create dotfiles that come from a shell template (.shtpl)'
>	@echo '  ${LOCAL_DOTFILES} - create local dotfiles not tracked by version control'
>	@echo '  ${INSTALL}        - link all the dotfiles to their appropriate places'
>	@echo '  ${UNINSTALL}      - remove links that were inserted by the install target'
>	@echo '  ${CLEAN}          - remove files generated from the "dotfiles" target'

.PHONY: ${RMPLAIN_FILES}
${RMPLAIN_FILES}: private .SHELLFLAGS := -cx
${RMPLAIN_FILES}: private export PS4 :=
${RMPLAIN_FILES}:
>	@for pkg_file_path in $$(echo "${pkg_file_paths}" | sed --regexp-extended 's_^\w+/| \w+/_ _g'); do \
>		[ -L "$${HOME}/$${pkg_file_path}" ] || rm --force "$${HOME}/$${pkg_file_path}"; \
>	done

.PHONY: ${DOTFILES}
${DOTFILES}: ${dotfile_paths}

${DOTFILE_WILDCARD}: ${DOTFILE_WILDCARD}.shtpl
>	${ENVSUBST} '${local_config_files_vars}' < "$<" > "$@"

.PHONY: ${LOCAL_DOTFILES}
${LOCAL_DOTFILES}:
>	touch "$${HOME}/${LOCAL_PROFILE}"

.PHONY: ${INSTALL}
${INSTALL}: ${dotfile_paths}
>	@for pkg in ${stow_pkgs}; do \
>		echo ${STOW} --no-folding --ignore=".*.shtpl" --target="${DESTDIR}$${HOME}" "$${pkg}"; \
>		${STOW} --no-folding --ignore=".*.shtpl" --target="${DESTDIR}$${HOME}" "$${pkg}"; \
>	done

# MONITOR(cavcrosby): while the below works, it appears to generate 'BUG' warnings, this appears to be an issue with stow. Will probably want to monitor the following ticket:
# https://github.com/aspiers/stow/issues/65
.PHONY: ${UNINSTALL}
${UNINSTALL}:
>	@for pkg in ${stow_pkgs}; do \
>		echo ${STOW} --ignore=".*.shtpl" --target="${DESTDIR}$${HOME}" --delete "$${pkg}"; \
>		${STOW} --ignore=".*.shtpl" --target="${DESTDIR}$${HOME}" --delete "$${pkg}"; \
>	done

.PHONY: ${CLEAN}
${CLEAN}:
>	rm --force ${dotfile_paths}
