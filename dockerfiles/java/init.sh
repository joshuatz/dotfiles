#!/usr/bin/env bash
set -e

DECOMPILE_BIND_MOUNT="/var/jars_to_decompile"
# Note: Must end in `.jar` for fernflower, or else it just skips it silently
DECOMPILE_BIND_MOUNT_SINGLE="/var/jar_to_decompile.jar"
DEFAULT_DECOMPILE_OUT_DIR="/var/decompile_output"

auto_decompile() {
	local OUT_DIR="$DEFAULT_DECOMPILE_OUT_DIR"
	echo "==== Running auto_decompile ===="


	cat <<- EOF
	|--- In Dir: $DECOMPILE_BIND_MOUNT
	|--- In File: $DECOMPILE_BIND_MOUNT_SINGLE
	|--- Out Dir: $OUT_DIR
	EOF

	if ! [[ -d "$DECOMPILE_BIND_MOUNT" ]] && ! [[ -f "$DECOMPILE_BIND_MOUNT_SINGLE" ]]; then
		echo "Nothing to decompile!"
		return
	fi

	local JAR_LIST=()
	if [[ -d "$DECOMPILE_BIND_MOUNT" ]]; then
		JAR_LIST=("$DECOMPILE_BIND_MOUNT"/*.jar)
	fi
	if [[ -f "$DECOMPILE_BIND_MOUNT_SINGLE" ]]; then
		JAR_LIST+=("$DECOMPILE_BIND_MOUNT_SINGLE")
	fi

	for jar in "${JAR_LIST[@]}"; do
		jar_name=$(basename "$jar")
		echo "Decompiling $jar_name..."

		echo "↳ w/fernflower ..."
		local fernflower_out="$OUT_DIR/$jar_name/fernflower/"
		mkdir -p "$fernflower_out"
		java -jar ./fernflower.jar "$jar" "$fernflower_out" || true
		echo "   ↳ ✅ Fernflower done"

		printf '\n\n' && sleep 4 && printf '\n\n'

		echo "↳ w/vineflower ..."
		local vineflower_out="$OUT_DIR/$jar_name/vineflower/"
		mkdir -p "$vineflower_out"
		java -jar ./vineflower.jar "$jar" "$vineflower_out" || true
		echo "   ↳ ✅ Vineflower done"
	done

	echo "=== /auto_decompile ==="
}

auto_decompile
