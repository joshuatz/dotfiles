#!/usr/bin/env bash
set -e

DECOMPILE_BIND_MOUNT="/var/jars_to_decompile"
# Note: Must end in `.jar` for fernflower, or else it just skips it silently
DECOMPILE_BIND_MOUNT_SINGLE_JAR="/var/to_decompile.jar"
DECOMPILE_BIND_MOUNT_SINGLE_APK="/var/to_decompile.apk"
OUT_DIR="/var/decompile_output"

auto_decompile_jars() {
	echo "==== Running auto_decompile_jars ===="

	cat <<- EOF
	|--- In Dir: $DECOMPILE_BIND_MOUNT
	|--- In File (JAR): $DECOMPILE_BIND_MOUNT_SINGLE_JAR
	|--- Out Dir: $OUT_DIR
	EOF

	local JAR_LIST=()
	if [[ -d "$DECOMPILE_BIND_MOUNT" ]]; then
		JAR_LIST=("$DECOMPILE_BIND_MOUNT"/*.jar)
	fi
	if [[ -f "$DECOMPILE_BIND_MOUNT_SINGLE_JAR" ]]; then
		JAR_LIST+=("$DECOMPILE_BIND_MOUNT_SINGLE_JAR")
	fi

	if [[ ${#JAR_LIST[@]} -eq 0 ]]; then
		echo "Nothing to decompile!"
		return
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

	echo "==== DONE /auto_decompile_jars ===="
}

auto_decompile_apks() {
	echo "==== Running auto_decompile_apks ===="

	cat <<- EOF
	| jadx version: $(jadx --version)
	|--- In Dir: $DECOMPILE_BIND_MOUNT
	|--- In File (JAR): $DECOMPILE_BIND_MOUNT_SINGLE_JAR
	|--- Out Dir: $OUT_DIR
	EOF

	local APK_LIST=()
	if [[ -d "$DECOMPILE_BIND_MOUNT" ]]; then
		APK_LIST=("$DECOMPILE_BIND_MOUNT"/*.apk)
	fi
	if [[ -f "$DECOMPILE_BIND_MOUNT_SINGLE_APK" ]]; then
		APK_LIST+=("$DECOMPILE_BIND_MOUNT_SINGLE_APK")
	fi

	if [[ ${#APK_LIST[@]} -eq 0 ]]; then
		echo "Nothing to decompile!"
		return
	fi

	for apk in "${APK_LIST[@]}"; do
		# Use jadx
		apk_name=$(basename "$apk")
		echo "Decompiling $apk_name..."
		local jadx_out="$OUT_DIR/$apk_name/jadx/"
		mkdir -p "$jadx_out"
		jadx "$apk" --output-dir "$jadx_out" || true
	done

	echo "==== DONE /auto_decompile_apks ===="
}

auto_decompile() {
	echo "==== Running auto_decompile (main) ===="
	auto_decompile_jars || true
	auto_decompile_apks || true
	echo "=== /auto_decompile ==="
}

auto_decompile
