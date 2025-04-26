# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export OH_MY_ZSH_ACTIVE=true

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="agnoster"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Disable auto-setting terminal title.
# WARNING: If this is not set to true, oh-my-zsh will override the window
# title, and you cannot override yourself (e.g., trying to set via ANSI
# sequences will _NOT_ work)
DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# Caution: this setting can cause issues with multiline prompts (zsh 5.7.1 and newer seem to work)
# See https://github.com/ohmyzsh/ohmyzsh/issues/5765
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# ==== Customizations =====

export EDITOR="code"
export USER_BIN_OVERRIDES_DIR="${HOME}/.local/bin"
if ! [[ -d $USER_BIN_OVERRIDES_DIR ]]; then
	mkdir -p $USER_BIN_OVERRIDES_DIR
fi
export DOTFILES_DIR="${HOME}/dotfiles"

# Autocomplete - ORDER MATTERS
unsetopt complete_aliases
autoload -Uz compinit
compinit

[[ -f ~/.functions ]] && source ~/.functions

# Set aliases for g* (GNU) versions of programs, on systems where not necessary
if [[ $IS_MAC -ne 1 ]]; then
	alias ghead="head"
	alias greadlink="readlink"
fi

# Load main customization files
[[ -f "$DOTFILES_DIR/ascii_art/loader.sh" ]] && source "$DOTFILES_DIR/ascii_art/loader.sh"
[[ -f ~/.aliases ]] && source ~/.aliases
[[ -f ~/.env.public ]] && source ~/.env.public

computer_name=$(get_computer_name)

# GPG signing
export GPG_TTY=$(tty)

# Poetry
POETRY_BIN_DIR="$HOME/Library/Application Support/pypoetry/venv/bin"
if [[ -d $POETRY_BIN_DIR ]]; then
	export PATH="$POETRY_BIN_DIR:$PATH"
fi

# asdf
# Note that this is coming before brew, so that asdf plugins will be preferred
# over global brew installs (e.g., if accidentally installed some bin through
# both tools)
has_asdf=0
if [[ -f /usr/local/opt/asdf/libexec/asdf.sh ]]; then
	# Homebrew
	source /usr/local/opt/asdf/libexec/asdf.sh
	has_asdf=1
elif [[ -f ~/.asdf/asdf.sh ]]; then
	# Manual install (e.g. git cloned)
	source ~/.asdf/asdf.sh
	has_asdf=1
fi

# asdf mods
if [[ $has_asdf -eq 1 ]]; then
	# Main shimming
	PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

	# golang
	export ASDF_GOLANG_MOD_VERSION_ENABLED=true
	asdf_golang_path=$(asdf where golang 2>&1 > /dev/null)
	if [[ $? -eq 0 ]] && [[ -n "$asdf_golang_path" ]]; then
		# https://github.com/asdf-community/asdf-golang/issues/28
		export GOPATH="${asdf_golang_path}/packages"
		export GOROOT="${asdf_golang_path}/go"
		# You shouldn't usually have to explicitly set these, but some VS Code
		# tooling breaks without (you might also have to edit `settings.json`
		# and set env vars there)
		export GOMODCACHE="${GOPATH}/pkg/mod"
		export GOCACHE="${GOPATH}/pkg/mod"
		export PATH="${PATH}:$(go env GOPATH)/bin"
	fi

	# OH COME ON NOW!!!
	# (ノ ゜Д゜)ノ ︵ ┻━┻
	export ASDF_FORCE_PREPEND=
	PATH="/usr/local/bin:$PATH"
fi

# Make sure shims / overrides come first, which handle some edge-cases.
# For example, for Apple development, some tools (e.g. CocoaPods) will
# have high-priority system paths that have to be intelligently
# overwritten
export PATH="$DOTFILES_DIR/shims:$PATH"


# Wezterm
WEZTERM_PATH_MAC=/Applications/WezTerm.app/Contents/MacOS/
if [[ -d $WEZTERM_PATH_MAC ]]; then
	PATH="$PATH:$WEZTERM_PATH_MAC"
fi

# Android dev - see https://developer.android.com/tools/variables
EXPECTED_ANDROID_HOME="$HOME/Library/Android/sdk"
if [[ -d "$EXPECTED_ANDROID_HOME" ]]; then
	export ANDROID_HOME="$EXPECTED_ANDROID_HOME"
	export PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools"
fi

# Shell completions for task (go-task)
TASK_COMPLETIONS_PATH=/usr/local/share/zsh/site-functions/_task
if (which task > /dev/null) && [[ -f "$TASK_COMPLETIONS_PATH" ]]; then
	source "$TASK_COMPLETIONS_PATH"
fi

# Make sure brew comes last, so its shims can override any path stuff filled in
# previous steps
if [[ -d /home/linuxbrew/.linuxbrew/ ]]; then
	export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew";
	export HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar";
	export HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew";

	export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin${PATH+:$PATH}";
	[ -z "${MANPATH-}" ] || export MANPATH=":${MANPATH#:}";
	export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:${INFOPATH:-}";
fi
if type brew &>/dev/null; then
	FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
fi


# Docker autocompletion, mac
DOCKER_COMPLETION_DIR=/Applications/Docker.app/Contents/Resources/etc
if [[ -d $DOCKER_COMPLETION_DIR ]]; then
	DOCKER_COMPLETION_PATHS=(
		"$DOCKER_COMPLETION_DIR/docker.zsh-completion"
		"$DOCKER_COMPLETION_DIR/docker-compose.zsh-completion"
	)
	for _path in $DOCKER_COMPLETION_PATHS; do
		if [[ -f $_path ]]; then
			# Compute autocomplete filename
			# E.g. `docker-compose.zsh-completion` -> `_docker-compose`
			# ZSH_FILENAME="_${$(basename $_path)%.*}"
			# ln -s "$_path" "/usr/local/share/zsh/site-functions/$ZSH_FILENAME"
			FPATH="$FPATH:$_path"
		fi
	done
fi

# monkey business with PG via homebrew - especially useful / necessary for psycopg2
if [[ "$computer_name" == "Joshua’s MacBook Pro" ]]; then
	PG_CONFIG_PATH="$(greadlink -f $(brew --prefix postgresql@12))/bin"
	export PATH="$PATH:$PG_CONFIG_PATH"
fi

# Finally, any thing in `~/.local/bin`, *recursively* should take priority
if [[ -d "$USER_BIN_OVERRIDES_DIR" ]]; then
	export PATH="$USER_BIN_OVERRIDES_DIR:$PATH"
	RECURSIVE_PATH_ADDITIONS=0
	# Recursively add all subdirs to path, but bail out if a large number are detected
	# (e.g. if a user has a lot of random stuff in there)
	for dir in $(find "$USER_BIN_OVERRIDES_DIR" -type d); do
		if [[ $RECURSIVE_PATH_ADDITIONS -gt 100 ]]; then
			echo "A large amount of subdirectories were found in $USER_BIN_OVERRIDES_DIR; please investigate"
			break
		fi
		if [[ $dir != "$USER_BIN_OVERRIDES_DIR" ]]; then
			PATH="$dir:$PATH"
			RECURSIVE_PATH_ADDITIONS=$((RECURSIVE_PATH_ADDITIONS + 1))
		fi
	done
fi

# === Dynamic Injection Section ===

