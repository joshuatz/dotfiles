#!/usr/bin/env bash
# set -e
# set -x

SCRIPT_DIR=$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")
echo "$SCRIPT_DIR"

# For now, this should serve as a way to make sure local names don't collide with
# hub-hosted ones - using a non-existent registry - https://stackoverflow.com/a/70733299/11447682
# Another workaround would be to use a 3-char org name - @see https://github.com/docker/hub-feedback/issues/280
# Also https://stackoverflow.com/q/66597858/11447682
LOCAL_DOCKER_PREFIX="jtz-reg/jtz"
# TODO - I wonder if you could use the `docker.io/library/` auto-gen for ^ ?

# A Temurin-based image, with pre-built decompilers that run on startup
# You can use to just get a bash shell with JDK access:
#	docker run -it --rm java-playground bash
# Or, if feeling fancy, you can bind-mount JARs to decompile and it will automatically decompile them on startup
#	docker run -it --rm -v ~/jtzdev/some_file.jar:/var/some_file.jar -v ~/jtzdev/decompiled/:/var/decompile_output java-playground
build_java () {
	docker build -t "${LOCAL_DOCKER_PREFIX}/java-playground" -f "$SCRIPT_DIR/java/Dockerfile" "$SCRIPT_DIR"
}

build_tensorflowjs () {
	docker build -t "${LOCAL_DOCKER_PREFIX}/tensorflowjs" -f "$SCRIPT_DIR/tensorflowjs/Dockerfile" "$SCRIPT_DIR"
}

build_ubuntu_sandbox() {
	docker build -t "${LOCAL_DOCKER_PREFIX}/ubuntu_sandbox" -f "$SCRIPT_DIR/ubuntu_sandbox/Dockerfile" "$SCRIPT_DIR"
}

build_all () {
	build_java & build_tensorflowjs && build_ubuntu_sandbox
}

