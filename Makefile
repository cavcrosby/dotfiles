# special makefile variables
.DEFAULT_GOAL := help
.RECIPEPREFIX := >

# recursively expanded variables
SHELL = /usr/bin/sh

# shell template variables
COMMON_CONFIGS_FILE = .conf
export LOCAL_RC = .rc.local
export LOCAL_GITCONFIG = .gitconfig.local
local_config_files_vars = \
	$${LOCAL_RC}\
	$${LOCAL_GITCONFIG}\
	$${_RCLONE_DRIVE_TOKEN}\
	$${_RCLONE_DRIVE_ROOT_FOLDER_ID}\
	$${_AWS_ACCESS_KEY_ID}\
	$${AWS_ACCESS_KEY_ID_MAIN_OPENTOFU}\
	$${_AWS_SECRET_ACCESS_KEY}\
	$${AWS_SECRET_ACCESS_KEY_MAIN_OPENTOFU}\
	$${MSMTP_GMAIL_PASSWORD}\
	$${ENCODED_DOCKER_HUB_AUTH_STR}\
	$${GITHUB_ACCESS_TOKEN}

# stow pkgs
BASH_PKG = bash
GIT_PKG = git
SHELL_PKG = shell
MSMTP_PKG = msmtp
SSH_PKG = ssh
TMUX_PKG = tmux
RCLONE_PKG = rclone
DOCKER_PKG = docker
AWS_PKG = aws
LOCAL = local

STOW_PKGS = \
	${BASH_PKG}\
	${GIT_PKG}\
	${SHELL_PKG}\
	${MSMTP_PKG}\
	${SSH_PKG}\
	${TMUX_PKG}\
	${RCLONE_PKG}\
	${DOCKER_PKG}\
	${AWS_PKG}\
	${LOCAL}

define _COMMON_CONFIGS_FILE =
cat << '_EOF_'
#
#
# Config file to centralize common dotfile vars.

export _RCLONE_DRIVE_TOKEN=''
export _RCLONE_DRIVE_ROOT_FOLDER_ID=""
export _AWS_ACCESS_KEY_ID=""
export AWS_ACCESS_KEY_ID_MAIN_OPENTOFU=""
export _AWS_SECRET_ACCESS_KEY=""
export AWS_SECRET_ACCESS_KEY_MAIN_OPENTOFU=""
export MSMTP_GMAIL_PASSWORD=""
export DOCKER_HUB_API_TOKEN=""
export GITHUB_ACCESS_TOKEN=""

ENCODED_DOCKER_HUB_AUTH_STR="$$(printf '%s' "cavcrosby:$${DOCKER_HUB_API_TOKEN}" | base64)"
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
CHMOD_FILES = chmod-files
CLEAN = clean

# executables
ENVSUBST = envsubst
STOW = stow
executables = \
	${STOW}

# simply expanded variables
raw_pkg_file_paths := $(shell find \
	. \
	-mindepth 2 \
	\( -type f \) \
	-and \( ! -path './.git*' \) \
	-and \( ! -name .stow-local-ignore \) \
	-and \( -printf '%P ' \) \
)
pkg_file_paths := $(shell printf '%s\n' "$(patsubst %.shtpl,%,${raw_pkg_file_paths})" | tr ' ' '\n' | sort --unique)

# inspired from:
# https://stackoverflow.com/questions/5618615/check-if-a-program-exists-from-a-makefile#answer-25668869
_check_executables := $(foreach exec,${executables},$(if $(shell command -v ${exec}),pass,$(error "No ${exec} in PATH")))

.PHONY: ${HELP}
${HELP}:
	# inspired by the makefiles of the Linux kernel and Mercurial
>	@printf '%s\n' 'Common make targets:'
>	@printf '%s\n' '  ${COMMON_CONFIGS_FILE}          - the configuration file to be used by the'
>	@printf '%s\n' '                   package files that come from a shell template'
>	@printf '%s\n' '  ${PKG_FILES}      - create package files that come from a shell template (.shtpl)'
>	@printf '%s\n' '  ${LOCAL_DOTFILES} - create local dotfiles not tracked by version control'
>	@printf '%s\n' '  ${INSTALL}        - link all the package files to their appropriate places'
>	@printf '%s\n' '  ${UNINSTALL}      - remove links that were inserted by the install target'
>	@printf '%s\n' '  ${CLEAN}          - remove files generated from the '\''pkg-files'\'' target'
>	@printf '%s\n' 'Common make configurations (e.g. make [config]=1 [targets]):'
>	@printf '%s\n' '  STOW_PKGS      - chooses the Stow packages to install'

${COMMON_CONFIGS_FILE}:
>	eval "$${_COMMON_CONFIGS_FILE}" > "./${COMMON_CONFIGS_FILE}"

.PHONY: ${RMPLAIN_FILES}
${RMPLAIN_FILES}: private .SHELLFLAGS := -cx
${RMPLAIN_FILES}: private export PS4 :=
${RMPLAIN_FILES}:
>	@for pkg_file_path in $$(printf '%s\n' "${pkg_file_paths}" | sed --regexp-extended 's_^\w+/| \w+/_ _g'); do \
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
>	touch "${LOCAL}/${LOCAL_RC}"
>	touch "${LOCAL}/${LOCAL_GITCONFIG}"

.PHONY: ${INSTALL}
${INSTALL}: ${pkg_file_paths}
>	@for pkg in ${STOW_PKGS}; do \
>		printf '%s\n' "${STOW} --no-folding --ignore=\".*.shtpl\" --target=\"${DESTDIR}$${HOME}\" \"$${pkg}\""; \
>		${STOW} --no-folding --ignore=".*.shtpl" --target="${DESTDIR}$${HOME}" "$${pkg}"; \
>	done

# MONITOR(cavcrosby): while the below works, it appears to generate 'BUG' warnings, this appears to be an issue with stow. Will probably want to monitor the following ticket:
# https://github.com/aspiers/stow/issues/65
.PHONY: ${UNINSTALL}
${UNINSTALL}:
>	@for pkg in ${STOW_PKGS}; do \
>		printf '%s\n' "${STOW} --ignore=\".*.shtpl\" --target=\"${DESTDIR}$${HOME}\" --delete \"$${pkg}\""; \
>		${STOW} --ignore=".*.shtpl" --target="${DESTDIR}$${HOME}" --delete "$${pkg}"; \
>	done

.PHONY: ${CHMOD_FILES}
${CHMOD_FILES}: ${COMMON_CONFIGS_FILE}
>	chmod 600 "./${COMMON_CONFIGS_FILE}"
>	chmod 600 "./aws/.aws/credentials"
>	chmod 600 "./docker/.docker/config.json"
>	chmod 600 "./git/.git-credentials"
>	chmod 644 "./git/.gitconfig"
>	chmod 600 "./msmtp/.netrc"
>	chmod 600 "./rclone/.rclone.conf"
>	chmod 644 "./shell/.rc"
>	chmod 600 "./ssh/.ssh/authorized_keys"
>	chmod 644 "./ssh/.ssh/config"

.PHONY: ${CLEAN}
${CLEAN}:
>	rm --force $(patsubst %.shtpl,%,$(filter %.shtpl,${raw_pkg_file_paths}))
