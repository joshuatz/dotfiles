#!/usr/bin/env bash

large_llm_query() {
	export LC_ALL="C"
	unset IFS
	TEMP_DIR_PATH=$(mktemp -d)
	echo "Using temporary directory $TEMP_DIR_PATH"
	BANNED_FILE_PATTERNS=(
		".env"
		"scratch.py"
	)
	# In addition to text/* (e.g. text/plain, text/x-shellscript)
	EXTRA_ACCEPTED_MIME_TYPES=(
		"application/json"
		"application/ld+json"
	)
	TEMP_PROMPT_FILE="$TEMP_DIR_PATH/.prompt.txt"
	touch "$TEMP_PROMPT_FILE"
	DEBUG=0

	if [[ -z "$GOOGLE_GEMINI_API_KEY" ]]; then
		GOOGLE_GEMINI_API_KEY=$(op item get 'Google_Gemini_API_Key' --vault Private --fields 'credential')
	fi
	if [[ -z "$GOOGLE_GEMINI_API_KEY" ]]; then
		echo "ERROR: Could not find Google_Gemini_API_Key"
		return 1
	fi

	# Hardcode for now
	MODEL="gemini"

	FILENAMES_PASSED_VIA_ARG=()
	RIPGREP_ARGS=()
	GLOB=""
	QUESTION=""
	LLM_PROMPT=""
	while [[ ! $# -eq 0 ]]; do
		case "$1" in
			-rg|--ripgrep-args)
				# Turn string into args arr
				declare -a RIPGREP_ARGS=($(echo $2 | awk '{for(i=1;i<=NF;i++) print $i}'))
				declare -p RIPGREP_ARGS
				shift
				;;
			-g|--glob)
				GLOB=$2
				shift
				;;
			-q|--question)
				QUESTION=$2
				shift
				;;
			-p|--prompt)
				LLM_PROMPT=$2
				shift
				;;
			-m|--model)
				MODEL=$2
				shift
				;;
			-d|--debug)
				DEBUG=1
				;;
			*)
				if [[ -f "$1" ]]; then
					FILENAMES_PASSED_VIA_ARG+=("$1")
				else
					echo "Invalid option ${1}"
				fi
				;;
		esac
		shift
	done

	if [[ $MODEL != "gemini" ]]; then
		echo "Not yet implemented support for $MODEL"
		return 1
	fi

	if [[ ${#FILENAMES_PASSED_VIA_ARG[@]} -eq 0  ]] && [[ -z "$GLOB" ]] && [[ ${#RIPGREP_ARGS[@]} -eq 0 ]]; then
		echo "What different search terms should be used to search?"
		echo "Press enter to add another, type EOF to end query"
		AT_LEAST_ONE_SEARCH_DONE=0
		RIPGREP_ARGS+=("-l" "-i")
		while true; do
			read -r SEARCH_TERM
			if [[ -z "$SEARCH_TERM" ]] || [[ "$SEARCH_TERM" == "EOF" ]]; then
				break
			fi
			AT_LEAST_ONE_SEARCH_DONE=1
			RIPGREP_ARGS+=("-e" "$SEARCH_TERM")
		done
		if [[ $AT_LEAST_ONE_SEARCH_DONE -eq 0 ]]; then
			echo "ERROR: Must provide at least one search term"
			return 1
		fi
	fi

	if [[ ${#FILENAMES_PASSED_VIA_ARG[@]} -eq 0  ]] && [[ -z "$GLOB" ]] && [[ ${#RIPGREP_ARGS[@]} -eq 0 ]]; then
		echo "ERROR: Must provide ripgrep arguments (-rg / --ripgrep-args), glob (-g / --glob), or filenames."
		return 1
	fi

	# If neither `--prompt` nor `--question` was not passed, ask user / read from stdin
	if [[ -z "$LLM_PROMPT" ]] && [[ -z "$QUESTION" ]]; then
		echo "Enter question:"
		read -r QUESTION
		if [[ -z "$QUESTION" ]]; then
			echo "ERROR: Must provide a question (or prompt, with --prompt)"
			return 1
		fi
	fi

	# Make sure `--file` is included in args
	# If not, PREpend it as first arg
	# if [[ ! " ${RIPGREP_ARGS[*]} " =~ " --files " ]]; then
	# 	RIPGREP_ARGS=("--files" "${RIPGREP_ARGS[@]}")
	# fi

	# Prepare base prompt / prefix
	if [[ -z "$LLM_PROMPT" ]]; then
		cat > "$TEMP_PROMPT_FILE" <<- EOF
		You are an expert programmer, and someone has asked you to answer the following

		Question: $QUESTION

		You need to answer - preferably ONLY with references to the below reference material. Try to be as accurate as possible; cite files used to form your answer, and even line numbers if possible.

		Each file below is separated like so:

		---
		File: FILE_NAME
		FILE_CONTENTS
		---

		Here is the reference material / files:

		---
		EOF
	else
		echo "$LLM_PROMPT" > "$TEMP_PROMPT_FILE"
	fi

	dump_file_to_prompt() {
		FILE_PATH=$1
		if ! [[ -f $FILE_PATH ]]; then
			return 0
		fi
		# Check for binary / non-plain-text (against `ACCEPTED_FILE_MATCHES`)
		FILE_MIME_TYPE=$(file -b --mime-type $FILE_PATH)
		if [[ " ${BANNED_FILE_PATTERNS[*]} " =~ " ${FILE_PATH} " ]]; then
			echo "WARNING: Skipping $FILE_PATH; banned file pattern found"
			return 0
		fi
		if ! [[ $FILE_MIME_TYPE == "text/"*  ]] && ! [[ " ${EXTRA_ACCEPTED_MIME_TYPES[*]} " =~ " ${FILE_MIME_TYPE} " ]]; then
			echo "WARNING: Skipping $FILE_PATH; non-parseable mime-type found ($FILE_MIME_TYPE)"
			return 0
		fi
		echo "Dumping file to prompt: $FILE_PATH"
		FILE_CONTENTS_WITH_LINE_NUMBERS=$(cat -n "$FILE_PATH")
		# Remove leading indent
		# shellcheck disable=SC2001
		FILE_CONTENTS_WITH_LINE_NUMBERS=$(echo "$FILE_CONTENTS_WITH_LINE_NUMBERS" | sed 's/^[[:space:]]*//')
		cat >> "$TEMP_PROMPT_FILE" <<- EOF
		File: $FILE_PATH
		$FILE_CONTENTS_WITH_LINE_NUMBERS
		---
		EOF
	}

	# Iterate  over files
	for FILE_PATH in "${FILENAMES_PASSED_VIA_ARG[@]}"; do
		dump_file_to_prompt "$FILE_PATH"
	done
	if [[ -n $GLOB ]]; then
		if [[ $SHELL_TYPE != "ZSH" ]]; then
			echo "TODO verify glob behavior in other shells"
			return 1
		fi

		# Note: `~` for glob expansion is a zsh-ism
		# shellcheck disable=SC2296
		# shellcheck disable=SC2206
		FILE_LIST=(${~GLOB})

		for FILE_PATH in "${FILE_LIST[@]}"; do
			dump_file_to_prompt "$FILE_PATH"
		done
	else
		declare -p RIPGREP_ARGS
		for FILE_PATH in $(rg "${RIPGREP_ARGS[@]}"); do
			# TODO support partial file extraction, so to save on some tokens
			# e.g., include X number of lines around search term(s)
			dump_file_to_prompt "$FILE_PATH"
		done
	fi

	cat <<- EOF
	Prompt Stats:
		Line Count = $(wc -l < "$TEMP_PROMPT_FILE")
		Word Count = $(wc -w < "$TEMP_PROMPT_FILE")
	EOF

	# Warning: Technically, this could be done in pure bash, but there are a lot of oddities around
	# escaping, line breaks, and space expansion across shells, that makes this really error-prone
	# Leaving this partial attempt commented out for now
	# ESCAPED_PROMPT_STRING=$(cat $TEMP_PROMPT_FILE | jq -Rsa .)
	## Keep line breaks as literal line breaks / escaped
	# ESCAPED_PROMPT_STRING_FINAL=$(LC_ALL=en_US.UTF-8 echo "$ESCAPED_PROMPT_STRING" | sed 's/$/\\\\n/' | tr -d '\n')

	# Also worth noting that we are actually double-escaping here, due to the nature
	# of the heredoc and having to escape the shell first

	POST_BODY=$(TEMP_PROMPT_FILE=$TEMP_PROMPT_FILE node <<- EOF
	let TEMP_PROMPT_FILE_CONTENTS = require('fs').readFileSync(process.env.TEMP_PROMPT_FILE, 'utf8');
	// Remove any CR (e.g., from a CRLF file dumped to prompt)
	TEMP_PROMPT_FILE_CONTENTS = TEMP_PROMPT_FILE_CONTENTS.replace(/\r/g, '');
	// Double escape tabs
	TEMP_PROMPT_FILE_CONTENTS = TEMP_PROMPT_FILE_CONTENTS.replace(/\t/g, '\\\\t');
	// Double backslashes
	TEMP_PROMPT_FILE_CONTENTS = TEMP_PROMPT_FILE_CONTENTS.replace(/\\\\/g, '\\\\\\\\');
	// Double escape newlines to avoid shell expansion
	TEMP_PROMPT_FILE_CONTENTS = TEMP_PROMPT_FILE_CONTENTS.replace(/\n/g, '\\\\n');
	console.log(JSON.stringify({
		contents: [{
			parts: [{
				text: TEMP_PROMPT_FILE_CONTENTS
			}]
		}]
	}));
	EOF
	)

	echo "$POST_BODY" > "$TEMP_DIR_PATH/.prompt_req.json"

	while true; do
		printf "Are you sure you want to send off the prompt? [Yy]es / ENTER, [Cc]ancel / [Nn]o\n"
		read -r answer
		case $answer in
			[Yy]*) break ;;
			"") break ;;
			[Cc]*) return 0 ;;
			[Nn]*) return 0 ;;
		esac
	done

	# Actually make request
	# Make sure to use `-d @file` to avoid "argument list too long"
	response=$(curl "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-latest:generateContent?key=$GOOGLE_GEMINI_API_KEY" \
		-H 'Content-Type: application/json' \
		-X POST \
		-d @"$TEMP_DIR_PATH/.prompt_req.json"
	)
	echo "$response" > "$TEMP_DIR_PATH/.prompt_res.json"

	# Combine all `candidates.contents.parts[].text`
	# Double-escape line breaks again
	response=$response node <<- EOF
	let combined = '';
	const response = JSON.parse(process.env.response);
	response.candidates.forEach(can => {
		if (can.finishReason !== 'STOP') {
			console.warn('Unusual finish reason:', can.finishReason);
			return;
		}
		can.content.parts.forEach(p => {
			combined += p.text;
		})
	});
	if (combined) {
		console.log('===== Server Response =====');
		console.log(combined);
		console.log('=============================')
	}
	EOF

	# If response errored out and/or parsing failed dump response
	if [[ $? -ne 0 ]]; then
		echo "Error parsing response"
		echo "$response"
		return 1
	fi

	echo "Done!"
	if [[ $DEBUG -eq 1 ]]; then
		echo "You can inspect the full prompt and response in $TEMP_DIR_PATH"
	else
		rm -r "$TEMP_DIR_PATH"
		echo "Deleted temporary prompt files"
	fi
}

llm_toolkit() {
	local start_dir=$PWD
	local repo_dir=/Users/joshua/jtzdev/llm-toolkit
	(
		cd "$repo_dir" || exit
		activate
		cd "$start_dir" || exit
		python3 $repo_dir/backend/cli.py "$@"
	)
}

llm_toolkit_question_from_plaintext() {
	local plaintext_file=$1
	llm_toolkit question "$(cat "$plaintext_file")"
}
