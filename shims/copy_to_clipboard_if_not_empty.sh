#!/usr/bin/env bash
set -e

if ! (which copy_to_clipboard_if_not_empty > /dev/null); then
	# shellcheck disable=SC1090
	source ~/.functions
fi

# Pass stdin
copy_to_clipboard_if_not_empty "$(cat)"
