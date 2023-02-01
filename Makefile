# special makefile variables
.DEFAULT_GOAL := help
.RECIPEPREFIX := >

# recursively expanded variables
SHELL = /usr/bin/sh
TRUTHY_VALUES = \
    true\
    1

# shell template variables
export LOCAL_GITCONFIG = .gitconfig_local
export LOCAL_PROFILE = .profile_local
local_config_files_vars = \
	$${LOCAL_GITCONFIG}\
	$${LOCAL_PROFILE}

# dotfile pkg dirs, stow will complain if I give absolute paths
BASH_PKG = bash
GIT_PKG = git
SHELL_PKG = shell
MSMTP_PKG = msmtp
SSH_PKG = ssh
TERMINATOR_PKG = terminator
PAPIRUS_ICONS_PKG = papirus-icons
# MONITOR(cavcrosby): currently there is a "jenkins" file type supported by
# vscode that uses the jenkins file icon. However, this file icon does not
# extend to folders. This may change in the future, which then I could discard
# the file icon that I have saved to use for "jenkins" directories. The icon
# names are in the format required by vscode to be useable (folder_type_*).
VSCODIUM_PKG = vscodium

stow_pkgs = \
	${BASH_PKG}\
	${GIT_PKG}\
	${SHELL_PKG}\
	${MSMTP_PKG}\
	${SSH_PKG}\
	${TERMINATOR_PKG}\
	${VSCODIUM_PKG}\
	${PAPIRUS_ICONS_PKG}

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
SHELL_TEMPLATE_EXT := .shtpl
shell_template_wildcard := %${SHELL_TEMPLATE_EXT}
DOTFILE_WILDCARD := .%
dotfile_shell_templates := $(shell find . -name .*${SHELL_TEMPLATE_EXT})
# Determines the dotfile name(s) to be generated from the template(s).
# Short hand notation for string substitution: $(text:pattern=replacement).
dotfile_paths := $(dotfile_shell_templates:${SHELL_TEMPLATE_EXT}=)

# Find expression that looks for files of interest to stow based on the following
# criteria: the file is in a stow package, the file is of type file, the file is
# not in the .git subdir, the file is not any special dotfile that stow uses, and
# the file is not a shell template.
#
# The paths return should be of the form, <app>/<app files/dirs>, with the ending
# child/leaf being a file (e.g. ssh/.ssh/config).
stowfiles := $(shell echo \
	$(shell find . -mindepth 2 \( -type f \) \
		-and \( ! -path './.git*' \) \
		-and \( ! -name .stow-local-ignore \) \
		-and \( ! -name .*${SHELL_TEMPLATE_EXT} \) \
		-and \( -printf '%P ' \) \
	) \
)

# inspired from:
# https://stackoverflow.com/questions/5618615/check-if-a-program-exists-from-a-makefile#answer-25668869
_check_executables := $(foreach exec,${executables},$(if $(shell command -v ${exec}),pass,$(error "No ${exec} in PATH")))

.PHONY: ${HELP}
${HELP}:
	# inspired by the makefiles of the Linux kernel and Mercurial
>	@echo 'Common make targets:'
>	@echo '  ${DOTFILES}       - create dotfiles that are shell templates (.shtpl)'
>	@echo '  ${LOCAL_DOTFILES} - create local dotfiles not tracked by version control'
>	@echo '  ${INSTALL}        - link all the dotfiles to their appropriate places'
>	@echo '  ${UNINSTALL}      - remove links that were inserted by the install target'
>	@echo '  ${CLEAN}          - remove files generated from the "dotfiles" target'

.PHONY: ${RMPLAIN_FILES}
${RMPLAIN_FILES}:
	# This isn't very pretty to look at, considering a temporary shell variable must
	# be set to use any shell parameter expansion (e.g. ${parameter:-word},
	# ${parameter#word}).
	#
	# The alternative was to attempt to use a shell for loop, however, my IDE picks
	# the ${p#w} parameter expansion to be a comment starting with the hashtag. Hence,
	# that solution would also have some ugly backslashing going on, so this is ok
	# for now.
>	@rm --force $(foreach stowfile,${stowfiles},$\
					$(shell stwfile=${stowfile}; tstwfile=$${stwfile#*/}; if ! [ -L "${HOME}/$${tstwfile}" ]; then echo "${HOME}/$${tstwfile}"; fi))

.PHONY: ${DOTFILES}
${DOTFILES}: ${dotfile_paths}

.PHONY: ${LOCAL_DOTFILES}
${LOCAL_DOTFILES}:
>	touch "$${HOME}/${LOCAL_PROFILE}"
>	touch "$${HOME}/${LOCAL_GITCONFIG}"

.PHONY: ${INSTALL}
${INSTALL}: ${dotfile_paths} ${RMPLAIN_FILES}
>	@for pkg in ${stow_pkgs}; do \
>		echo ${STOW} --target="${DESTDIR}$${HOME}" "$${pkg}"; \
>		${STOW} --no-folding --ignore=".*${SHELL_TEMPLATE_EXT}" --target="${DESTDIR}$${HOME}" "$${pkg}"; \
>	done

# MONITOR(cavcrosby): while the below works, it appears to generate 'BUG' warnings, this appears to be an issue with stow. Will probably want to monitor the following ticket:
# https://github.com/aspiers/stow/issues/65
.PHONY: ${UNINSTALL}
${UNINSTALL}:
>	@for pkg in ${stow_pkgs}; do \
>		echo ${STOW} --target="${DESTDIR}$${HOME}" --delete "$${pkg}"; \
>		${STOW} --ignore=".*${SHELL_TEMPLATE_EXT}" --target="${DESTDIR}$${HOME}" --delete "$${pkg}"; \
>	done

# custom implicit rules for the above targets
${DOTFILE_WILDCARD}: ${DOTFILE_WILDCARD}${SHELL_TEMPLATE_EXT}
>	${ENVSUBST} '${local_config_files_vars}' < "$<" > "$@"

.PHONY: ${CLEAN}
${CLEAN}:
>	rm --force ${dotfile_paths}
