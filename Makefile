# special makefile variables
.DEFAULT_GOAL := help
.RECIPEPREFIX := >

# recursively expanded variables
SHELL = /usr/bin/sh

# shell template variables
COMMON_CONFIGS_FILE = .conf
export LOCAL_PROFILE = .profile_local
local_config_files_vars = \
	$${LOCAL_PROFILE}\
	$${_RCLONE_DRIVE_TOKEN}\
	$${_RCLONE_DRIVE_ROOT_FOLDER_ID}\
	$${MSMTP_GMAIL_PASSWORD}\
	$${GIT_SIGNING_KEY_ID}\
	$${ENCODED_DOCKER_HUB_AUTH_STR}

# stow pkgs
BASH_PKG = bash
GIT_PKG = git
SHELL_PKG = shell
MSMTP_PKG = msmtp
SSH_PKG = ssh
TMUX_PKG = tmux
RCLONE_PKG = rclone
DOCKER_PKG = docker

stow_pkgs = \
	${BASH_PKG}\
	${GIT_PKG}\
	${SHELL_PKG}\
	${MSMTP_PKG}\
	${SSH_PKG}\
	${TMUX_PKG}\
	${RCLONE_PKG}\
	${DOCKER_PKG}

define _COMMON_CONFIGS_FILE =
cat << '_EOF_'
#
#
# Config file to centralize common dotfile vars.

export _RCLONE_DRIVE_TOKEN=''
export _RCLONE_DRIVE_ROOT_FOLDER_ID=""
export MSMTP_GMAIL_PASSWORD=""
export GIT_SIGNING_KEY_ID=""
export DOCKER_HUB_API_TOKEN=""

ENCODED_DOCKER_HUB_AUTH_STR="$$(echo -n "cavcrosby:$${DOCKER_HUB_API_TOKEN}" | base64)"
export ENCODED_DOCKER_HUB_AUTH_STR
_EOF_
endef
export _COMMON_CONFIGS_FILE

# targets
HELP = help
PKG_FILES = pkg-files
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
raw_pkg_file_paths := $(shell find . -mindepth 2 \( -type f \) \
	-and \( ! -path './.git*' \) \
	-and \( ! -name .stow-local-ignore \) \
	-and \( -printf '%P ' \) \
)
pkg_file_paths := $(shell echo "$(patsubst %.shtpl,%,${raw_pkg_file_paths})" | tr ' ' '\n' | sort --unique)

# inspired from:
# https://stackoverflow.com/questions/5618615/check-if-a-program-exists-from-a-makefile#answer-25668869
_check_executables := $(foreach exec,${executables},$(if $(shell command -v ${exec}),pass,$(error "No ${exec} in PATH")))

.PHONY: ${HELP}
${HELP}:
	# inspired by the makefiles of the Linux kernel and Mercurial
>	@echo 'Common make targets:'
>	@echo '  ${COMMON_CONFIGS_FILE}          - the configuration file to be used by the'
>	@echo '                   package files that come from a shell template'
>	@echo '  ${PKG_FILES}      - create package files that come from a shell template (.shtpl)'
>	@echo '  ${LOCAL_DOTFILES} - create local dotfiles not tracked by version control'
>	@echo '  ${INSTALL}        - link all the package files to their appropriate places'
>	@echo '  ${UNINSTALL}      - remove links that were inserted by the install target'
>	@echo '  ${CLEAN}          - remove files generated from the "pkg-files" target'

${COMMON_CONFIGS_FILE}:
>	eval "$${_COMMON_CONFIGS_FILE}" > "./${COMMON_CONFIGS_FILE}"	

.PHONY: ${RMPLAIN_FILES}
${RMPLAIN_FILES}: private .SHELLFLAGS := -cx
${RMPLAIN_FILES}: private export PS4 :=
${RMPLAIN_FILES}:
>	@for pkg_file_path in $$(echo "${pkg_file_paths}" | sed --regexp-extended 's_^\w+/| \w+/_ _g'); do \
>		if [ -e "$${HOME}/$${pkg_file_path}" ] && ! [ -L "$${HOME}/$${pkg_file_path}" ]; then \
>			rm --force "$${HOME}/$${pkg_file_path}"; \
>		fi; \
>	done

.PHONY: ${PKG_FILES}
${PKG_FILES}: ${pkg_file_paths}

%:: %.shtpl
>	${ENVSUBST} '${local_config_files_vars}' < "$<" > "$@"

.PHONY: ${LOCAL_DOTFILES}
${LOCAL_DOTFILES}:
>	touch "$${HOME}/${LOCAL_PROFILE}"

.PHONY: ${INSTALL}
${INSTALL}: ${pkg_file_paths}
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
>	rm --force $(patsubst %.shtpl,%,$(filter %.shtpl,${raw_pkg_file_paths}))
