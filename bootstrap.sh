#!/usr/bin/env bash
set -e

function copyFiles() {
	cp Taskfile.global.yml ~/Taskfile.global.yml
	cp .functions ~/.functions
	cp .aliases ~/.aliases
	cp global.gitignore ~/global.gitignore

	# Todo: This needs to be merged, not overwritten, because it contains stuff like
	# email = REDACTED
	# cp .gitconfig ~/.gitconfig

	if [[ -n "$ZSH_VERSION" ]] || echo $SHELL | grep --silent -E "\/zsh$"; then
		echo "Bootstrapping for ZSH"
		cp .zshrc ~/.zshrc
		exec zsh
	elif [[ -n "$BASH_VERSION" ]] || echo $SHELL | grep --silent -E "\/bash$"; then
		echo "Bootstrapping for Bash"
		source ~/.bash_profile
	else
		echo 'unknown shell'
	fi
}

copyFiles
unset copyFiles
