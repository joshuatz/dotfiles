#!/usr/bin/env bash
set -e

: "${AUTO_RUN_BIND_MOUNT:="/var/to_compile"}"
: "${AUTO_RUN_OUT_DIR:="/var/output"}"

auto_compile() {
    if ! [[ -d $AUTO_RUN_BIND_MOUNT ]]; then
        echo "Directory $AUTO_RUN_BIND_MOUNT (AUTO_RUN_BIND_MOUNT) is not a valid directory"
        return 1
    fi
    if ! [[ -d $AUTO_RUN_OUT_DIR ]]; then
        echo "Directory $AUTO_RUN_OUT_DIR (AUTO_RUN_OUT_DIR) is not a valid directory"
        return 1
    fi

    echo "===== STARTING AUTO-COMPILER ====="

    echo "Copying source files to temp directory"
    local temp_dir=$(mktemp -d)
    # Copy the source directory
    # shellcheck disable=SC2086
    cp -r $AUTO_RUN_BIND_MOUNT/** $temp_dir

    temp_dir=$temp_dir AUTO_RUN_BIND_MOUNT=$AUTO_RUN_BIND_MOUNT $SHELL

    echo "==== CALLING PYODIDE BUILD ===="
    if ! (pyodide build --outdir "$AUTO_RUN_OUT_DIR" "$@" "$temp_dir"); then
        # Drop into a shell if fails
        echo "==== PYODIDE BUILD FAILED ===="
        temp_dir=$temp_dir AUTO_RUN_BIND_MOUNT=$AUTO_RUN_BIND_MOUNT $SHELL
    fi
}

source "$BUILDER_DIR/venv-host/bin/activate"
source "$BUILDER_EMSDK_DIR/emsdk_env.sh"
auto_compile "$@"
