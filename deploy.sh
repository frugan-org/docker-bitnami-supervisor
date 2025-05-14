#!/bin/bash

# Bash Strict Mode:
# -e  / -o errexit    :: Exit immediately if a command exits with a non-zero status.
# -E  / -o errtrace   :: Inherit ERR trap in functions, subshells, and substitutions (older shells may require -o errtrace instead of -E).
# -u  / -o nounset    :: Treat unset variables as an error and exit immediately.
# -o pipefail         :: Exit on error in pipeline.
# -x  / -o xtrace     :: Print each command and its arguments as they are executed (useful for debugging).
# -T  / -o functrace  :: Allow function tracing (used for DEBUG and RETURN traps within functions and sourced files).
#
# Optional:
# shopt -s inherit_errexit  :: Bash >= 4.4: ensures ERR trap inheritance in all cases
#
# Common practice:
# set -eEuo pipefail  # Strict mode (recommended)
set -eEuo pipefail

#https://blog.dockbit.com/templating-your-dockerfile-like-a-boss-2a84a67d28e9

deploy() {
	str="
  s!%%TAG%%!$TAG!g;
"

	sed -r "$str" "$1"
}

TAGS=(
	bookworm
)

ITEMS=(
	"entrypoint.sh"
	"run_job.sh"
)

IFS=$'\n'

# shellcheck disable=SC2048
for TAG in ${TAGS[*]}; do
	echo "Processing tag: $TAG"

	if [ -d "$TAG" ]; then
		rm -Rf "$TAG"
	fi

	mkdir -p "$TAG"
	deploy Dockerfile.template >"$TAG"/Dockerfile

	for item in "${ITEMS[@]}"; do
		# Remove trailing slash if present (for folders)
		clean_item="${item%/}"

		if [ -e "$clean_item" ]; then
			if [ "$(dirname "$clean_item")" = "." ]; then
				dest_dir="$TAG"
			else
				# Create the destination directory while maintaining the structure
				dest_dir="$TAG/$(dirname "$clean_item")"
				mkdir -p "$dest_dir"
			fi

			if [ -d "$clean_item" ]; then
				echo "Copying directory $clean_item to $dest_dir/"
				cp -R "$clean_item" "$dest_dir"
			else
				echo "Copying file $clean_item to $dest_dir/"
				cp "$clean_item" "$dest_dir"
			fi
		else
			echo "Warning: Item $clean_item not found, skipping"
		fi
	done
done
