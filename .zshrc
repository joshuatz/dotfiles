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

# Autocomplete - ORDER MATTERS
unsetopt complete_aliases
autoload -Uz compinit
compinit

# Load main customization files
[[ -f ~/.functions ]] && source ~/.functions
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
fi

# Wezterm
WEZTERM_PATH_MAC=/Applications/WezTerm.app/Contents/MacOS/
if [[ -d $WEZTERM_PATH_MAC ]]; then
	PATH="$PATH:$WEZTERM_PATH_MAC"
fi

# Make sure brew comes last, so its shims can override any path stuff filled in
# previous steps
if type brew &>/dev/null; then
	FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH

	# Docker autocompletion
	DOCKER_COMPLETION_DIR=/Applications/Docker.app/Contents/Resources/etc
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

	# monkey business with PG via homebrew - especially useful / necessary for psycopg2
	if [[ "$computer_name" == "Joshua’s MacBook Pro" ]]; then
		PG_CONFIG_PATH="$(greadlink -f $(brew --prefix postgresql@12))/bin"
		export PATH="$PATH:$PG_CONFIG_PATH"
	fi
fi

# =========================
# Dynamic variables, injected by manage.sh (jtz dotfiles)
DOTFILES_DIR="/Users/joshua/jtzdev/dotfiles"
