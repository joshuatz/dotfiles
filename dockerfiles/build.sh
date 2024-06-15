#!/usr/bin/env bash
set -e

SCRIPT_DIR=$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")

# A Temurin-based image, with pre-built decompilers that run on startup
# You can use to just get a bash shell with JDK access:
#	docker run -it --rm java-playground bash
# Or, if feeling fancy, you can bind-mount JARs to decompile and it will automatically decompile them on startup
#	docker run -it --rm -v ~/jtzdev/some_file.jar:/var/some_file.jar -v ~/jtzdev/decompiled/:/var/decompile_output java-playground
build_java () {
	docker build -t java-playground -f "$SCRIPT_DIR/java/Dockerfile" "$SCRIPT_DIR"
}

build_java
