#!/usr/bin/env bash
set -e

SCRIPT_DIR=$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")

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

inject_dynamic_values_into_profile() {
	local profile_path="$1"
	cat >> "$profile_path" <<- EOF
	# Dynamic variables, injected by manage.sh (jtz dotfiles)
	DOTFILES_DIR="$SCRIPT_DIR"
	EOF
}

bootstrap() {
	if [[ -n "$ZSH_VERSION" ]] || echo $SHELL | grep --silent -E "\/zsh$"; then
		echo "Bootstrapping for ZSH"
		cp "$SCRIPT_DIR/.zshrc" ~/.zshrc
		inject_dynamic_values_into_profile ~/.zshrc
		exec zsh
	elif [[ -n "$BASH_VERSION" ]] || echo $SHELL | grep --silent -E "\/bash$"; then
		echo "Bootstrapping for Bash"
		cp "$SCRIPT_DIR/.bash_profile" ~/.bash_profile
		inject_dynamic_values_into_profile ~/.bash_profile
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
		code --list-extensions | sort | cat > "$SCRIPT_DIR/vscode/extensions.txt"

		# Export config files
		cp "$CODE_USER_DIR/settings.json" "$SCRIPT_DIR/vscode/settings.json"
		cp "$CODE_USER_DIR/tasks.json" "$SCRIPT_DIR/vscode/tasks.json"
		cp -R "$CODE_USER_DIR/snippets" "$SCRIPT_DIR/vscode/"

		# Separate keyboard settings by OS
		os_keybinding_file="vscode/keybindings.$OS_NAME.json"
		cp "$CODE_USER_DIR/keybindings.json" "$SCRIPT_DIR/$os_keybinding_file"
		echo "✅ Pulled VS Code"
	else
		echo "⏩ Skipped: VS Code"
	fi

	# OBS - Mac
	obs_settings_dir="$HOME/Library/Application Support/obs-studio/basic"
	if (stat "$obs_settings_dir" > /dev/null); then
		obs_backup_dir="$SCRIPT_DIR/obs/$COMPUTER_NAME"
		mkdir -p "$obs_backup_dir"
		cp -R "$obs_settings_dir" "$obs_backup_dir"
		echo "✅ Pulled OBS"
	else
		echo "⏩ Skipped: OBS"
	fi
}

push() {
	# Make sure env files are scaffolded
	for env_file in "$SCRIPT_DIR"/.env.*.example; do
		non_tracked_env_file_name=$(basename "$env_file" | sed -e 's/\.example$//')
		if [[ ! -f "$SCRIPT_DIR/$non_tracked_env_file_name" ]]; then
			echo "Creating $non_tracked_env_file_name - please fill out"
			cp "$env_file" "$SCRIPT_DIR/$non_tracked_env_file_name"
		fi
		cp "$SCRIPT_DIR/$non_tracked_env_file_name" ~
	done

	# Single files
	cp "$SCRIPT_DIR/Taskfile.global.yml" ~
	cp "$SCRIPT_DIR/.functions" ~
	cp "$SCRIPT_DIR/.aliases" ~
	cp "$SCRIPT_DIR/global.gitignore" ~
	cp "$SCRIPT_DIR/.tmux.conf" ~
	cp "$SCRIPT_DIR/.wezterm.lua" ~
	cp "$SCRIPT_DIR/.asdfrc" ~

	# Dirs
	# TODO, make this more streamlined (symlinks? dynamic resolution?)
	cp -r "$SCRIPT_DIR/scripts" ~/
	cp -r "$SCRIPT_DIR/utils" ~/

	# Todo: This needs to be merged, not overwritten, because it contains stuff like
	# email = REDACTED
	# cp .gitconfig ~/.gitconfig

	# VS Code
	if (which code > /dev/null); then
		# Install extensions
		# `code --install-extension` will skip already installed, but the check is slow, so compare first
		local VSCODE_TEMP_DIR=$(mktemp -d)
		code --list-extensions | sort > "$VSCODE_TEMP_DIR/installed_extensions.txt"
		sort > "$VSCODE_TEMP_DIR/dotfiles_extensions.txt" < vscode/extensions.txt
		uninstalled_extensions=$(comm -23 "$VSCODE_TEMP_DIR/dotfiles_extensions.txt" "$VSCODE_TEMP_DIR/installed_extensions.txt")
		if [[ -n "$uninstalled_extensions" ]]; then
			echo "There are $(echo "$uninstalled_extensions" | wc -l) uninstalled extensions to install"
			echo "$uninstalled_extensions" | tr '\n' '\0' | xargs -0 -L 1 code --install-extension
		fi

		# Sync config files
		cp "$SCRIPT_DIR/vscode/settings.json" "$CODE_USER_DIR/settings.json"
		cp "$SCRIPT_DIR/vscode/tasks.json" "$CODE_USER_DIR/tasks.json"
		cp -R "$SCRIPT_DIR/vscode/snippets" "$CODE_USER_DIR/"
		OS_KEYBINDINGS_FILE="$SCRIPT_DIR/vscode/keybindings.$OS_NAME.json"
		if [[ -f "$OS_KEYBINDINGS_FILE" ]]; then
			cp "$OS_KEYBINDINGS_FILE" "$CODE_USER_DIR/keybindings.json"
		fi
		echo "✅ Pushed VS Code"
	else
		echo "⏩ Skipped: VS Code"
	fi

	# For files that require sudo, let's diff first to avoid password prompt if we don't have to use it
	LIBINPUT_QUIRKS_FILE="$SCRIPT_DIR/libinput-local-overrides.quirks"
	if [[ "$OS_NAME" == "linux" ]]; then
		if ! [[ -f "$LIBINPUT_QUIRKS_FILE" ]] || ! (diff /etc/libinput/local-overrides.quirks "$LIBINPUT_QUIRKS_FILE" > /dev/null); then
			sudo cp "$LIBINPUT_QUIRKS_FILE" /etc/libinput/local-overrides.quirks
		fi
	fi

	# task / go-task - bootstrap shell completions
	if (which task > /dev/null); then
		if ! (task --completion zsh 2>/dev/null > /dev/null); then
			echo "Warning: Could not generate completions for task. Is your version up-to-date?"
		else
			local UPDATE_TASK_COMPLETIONS=0
			# Noop / non-sudo by default
			local SUDO_PREFIX=exec
			local CURRENT_TASK_COMPLETIONS=/usr/local/share/zsh/site-functions/_task
			local TEMP_UPDATED_TASK_COMPLETIONS=$(mktemp)
			task --completion zsh 2>/dev/null > "$TEMP_UPDATED_TASK_COMPLETIONS"

			# Check if sudo is needed
			if [[ -f "$CURRENT_TASK_COMPLETIONS" ]] && ! (stat "$CURRENT_TASK_COMPLETIONS" > /dev/null); then
				SUDO_PREFIX="sudo"
			fi


			if ! [[ -f "$CURRENT_TASK_COMPLETIONS" ]] || ! ($SUDO_PREFIX diff "$CURRENT_TASK_COMPLETIONS" "$TEMP_UPDATED_TASK_COMPLETIONS" > /dev/null); then
				while true; do
					printf "Looks like Task has updated its shell completions for ZSH."
					printf "  Update completions? [Yy]es, [Nn]o / [Cc]ancel\n"
					read -r answer
					case $answer in
						[Yy]*) UPDATE_TASK_COMPLETIONS=1 && break ;;
						[Nn]*) break ;;
						[Cc]*) break ;;
					esac
				done
			fi

			if [[ $UPDATE_TASK_COMPLETIONS -eq 1 ]]; then
				$SUDO_PREFIX cp "$TEMP_UPDATED_TASK_COMPLETIONS" "$CURRENT_TASK_COMPLETIONS"
				$SUDO_PREFIX chmod 644 "$CURRENT_TASK_COMPLETIONS"
			fi
		fi
	fi

	bootstrap
}

# If no option pre-selected, prompt for choice
COMMAND="$1"
if [[ -z "$COMMAND" ]]; then
	echo "No command specified"
	select opt in "pull" "push" "bootstrap"; do
		COMMAND=$opt
		break
	done
fi

case $COMMAND in
	"pull")
		pull
		;;
	"push")
		push
		;;
	"bootstrap")
		bootstrap
		;;
	*)
		echo "Invalid option"
		;;
esac
