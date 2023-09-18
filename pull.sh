#!/usr/bin/env bash
set -e

echo "Starting dotfiles pull / copying into dotfiles"

# Tabby
if [[ -f "$HOME/Library/Application Support/tabby/config.yaml" ]]; then
	cp "$HOME/Library/Application Support/tabby/config.yaml" ./tabby.config.yml
	# Remove `recentProfiles` YML entry, that doesn't need to be synced and contains folder names
	TABBY_CONFIG="$(cat ./tabby.config.yml)" node << "EOF" > tabby.config.yml
const TABBY_CONFIG = process.env.TABBY_CONFIG
cleaned = TABBY_CONFIG.replace(/recentProfiles:.*^clickableLinks:/gms, 'clickableLinks:');
if (cleaned.includes('cwd')) {
	console.error('Still found CWD after cleaning!');
	process.exit(1);
}
console.log(cleaned)
EOF
	echo "✅ Pulled: Tabby"
else
	echo "⏩ Skipped: Tabby"
fi

# VS Code
if (which code > /dev/null); then
	# Export extensions
	code --list-extensions > vscode/extensions.txt

	# Export config files
	CODE_USER_DIR=/Users/$USER/Library/Application\ Support/Code/User
	cp "$CODE_USER_DIR/settings.json" vscode/settings.json
	cp -R "$CODE_USER_DIR/snippets" vscode
	echo "✅ Pulled VS Code"
else
	echo "⏩ Skipped: VS Code"
fi
