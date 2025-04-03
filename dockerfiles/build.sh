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

build_image() {
	local subdir_name="$1"
	docker build -t "${LOCAL_DOCKER_PREFIX}/$subdir_name" -f "$SCRIPT_DIR/$subdir_name/Dockerfile" "$SCRIPT_DIR"
}

build_all() {
	for subdir in "$SCRIPT_DIR"/*; do
		if [[ -d $subdir && -f $subdir/Dockerfile ]]; then
			local subdir_name=$(basename "$subdir")
			echo "Building image for $subdir_name"
			build_image "$subdir_name"
		fi
	done
}
