#!/usr/bin/env bash
set -e

COMPUTER_NAME=""
if (which scutil > /dev/null); then
	COMPUTER_NAME=$(scutil --get ComputerName)
else
	COMPUTER_NAME=$(uname -n | sed -e 's/\.local$//')
fi

USER_CONFIG_DIR=$HOME/.config

OS_NAME="linux"
IS_MAC=0
if [[ "$OSTYPE" == "darwin"* ]]; then
	USER_CONFIG_DIR=$HOME/Library/Application\ Support
	OS_NAME="mac"
	IS_MAC=1
fi

CODE_USER_DIR=$USER_CONFIG_DIR/Code/User
TABBY_CONFIG_FILE=$USER_CONFIG_DIR/tabby/config.yaml

bootstrap() {
	if [[ -n "$ZSH_VERSION" ]] || echo $SHELL | grep --silent -E "\/zsh$"; then
		echo "Bootstrapping for ZSH"
		cp .zshrc ~/.zshrc
		exec zsh
	elif [[ -n "$BASH_VERSION" ]] || echo $SHELL | grep --silent -E "\/bash$"; then
		echo "Bootstrapping for Bash"
		cp .bash_profile ~/.bash_profile
		source ~/.bash_profile
	else
		echo 'unknown shell'
		return 1
	fi
}

pull() {
	echo "Starting dotfiles pull / copying into dotfiles"

	# Tabby
	if [[ -f "$TABBY_CONFIG_FILE" ]]; then
		cp "$TABBY_CONFIG_FILE" ./tabby.config.yml.tmp
		# Remove `recentProfiles` YML entry, that doesn't need to be synced and contains folder names
		TABBY_CONFIG="$(cat ./tabby.config.yml.tmp)" node <<-"EOF" > tabby.config.yml
		const TABBY_CONFIG = process.env.TABBY_CONFIG
		cleaned = TABBY_CONFIG.replace(/recentProfiles:.*^clickableLinks:/gms, 'clickableLinks:');
		if (cleaned.includes('cwd')) {
			console.error('Still found CWD after cleaning!');
			process.exit(1);
		}
		console.log(cleaned)
		EOF
		rm ./tabby.config.yml.tmp
		echo "✅ Pulled: Tabby"
	else
		echo "⏩ Skipped: Tabby"
	fi

	# VS Code
	if (which code > /dev/null); then
		# Export extensions
		code --list-extensions > vscode/extensions.txt

		# Export config files
		cp "$CODE_USER_DIR/settings.json" vscode/settings.json
		cp "$CODE_USER_DIR/tasks.json" vscode/tasks.json
		cp -R "$CODE_USER_DIR/snippets" vscode/

		# Separate keyboard settings by OS
		os_keybinding_file="vscode/keybindings.$OS_NAME.json"
		if [[ -f "$os_keybinding_file" ]]; then
			cp "$CODE_USER_DIR/keybindings.json" "$os_keybinding_file"
		fi
		echo "✅ Pulled VS Code"
	else
		echo "⏩ Skipped: VS Code"
	fi

	# OBS - Mac
	obs_settings_dir="$HOME/Library/Application Support/obs-studio/basic"
	if (stat "$obs_settings_dir" > /dev/null); then
		obs_backup_dir="./obs/$COMPUTER_NAME"
		mkdir -p "$obs_backup_dir"
		cp -R "$obs_settings_dir" "$obs_backup_dir"
		echo "✅ Pulled OBS"
	else
		echo "⏩ Skipped: OBS"
	fi
}

push() {
	cp Taskfile.global.yml ~/Taskfile.global.yml
	cp .functions ~/.functions
	cp .aliases ~/.aliases
	cp global.gitignore ~/global.gitignore

	# Todo: This needs to be merged, not overwritten, because it contains stuff like
	# email = REDACTED
	# cp .gitconfig ~/.gitconfig

	# VS Code
	if (which code > /dev/null); then
		# Install extensions
		# `code --install-extension` will skip already installed, but the check is slow, so compare first
		TEMP_PATH=$(mktemp)
		code --list-extensions > "$TEMP_PATH"
		uninstalled_extensions=$(comm -23 vscode/extensions.txt "$TEMP_PATH")
		if [[ -n "$uninstalled_extensions" ]]; then
			echo "There are $(echo "$uninstalled_extensions" | wc -l) uninstalled extensions to install"
			echo "$uninstalled_extensions" | tr '\n' '\0' | xargs -0 -L 1 code --install-extension
		fi
		rm "$TEMP_PATH"

		# Sync config files
		cp vscode/settings.json "$CODE_USER_DIR/settings.json"
		cp vscode/tasks.json "$CODE_USER_DIR/tasks.json"
		cp -R vscode/snippets "$CODE_USER_DIR/"
		OS_KEYBINDINGS_FILE="vscode/keybindings.$OS_NAME.json"
		if [[ -f "$OS_KEYBINDINGS_FILE" ]]; then
			cp "$OS_KEYBINDINGS_FILE" "$CODE_USER_DIR/keybindings.json"
		fi
		echo "✅ Pushed VS Code"
	else
		echo "⏩ Skipped: VS Code"
	fi

	# For files that require sudo, let's diff first to avoid password prompt if we don't have to use it
	LIBINPUT_QUIRKS_FILE=./libinput-local-overrides.quirks
	if [[ "$OS_NAME" == "linux" ]]; then
		if ! [[ -f "$LIBINPUT_QUIRKS_FILE" ]] || ! (diff /etc/libinput/local-overrides.quirks "$LIBINPUT_QUIRKS_FILE" > /dev/null); then
			sudo cp "$LIBINPUT_QUIRKS_FILE" /etc/libinput/local-overrides.quirks
		fi
	fi

	bootstrap
}
