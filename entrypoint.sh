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

CONFIG_DIR="/etc/supervisor/conf.d"
JOBS_DIR="/etc/supervisor/jobs.d"
mkdir -p $CONFIG_DIR

# Function to validate job names according to Supervisor specs
validate_name() {
	local name="$1"
	# Check if name contains colons or brackets (explicitly forbidden)
	if [[ "$name" =~ [:\]\[[:cntrl:]] ]]; then
		return 1
	fi
	# Check if name is not empty
	if [[ -z "$name" ]]; then
		return 1
	fi
	return 0
}

generate_job_config() {
	local job_file="$1"
	local job_name
	job_name=$(basename "$job_file" .sh)

	# Validate job name for supervisor
	if ! validate_name "$job_name"; then
		echo "Skipping job '$job_name': invalid name (cannot contain colons, brackets or control characters)"
		return 0
	fi

	echo "Generating configuration for $job_name"

	# Check if a custom configuration exists
	local custom_config_file="${job_file%.sh}.conf"
	if [ -f "$custom_config_file" ]; then
		echo "Using custom configuration for $job_name"
		cp "$custom_config_file" "$CONFIG_DIR/$job_name.conf"
	else
		# Default configuration
		cat >"$CONFIG_DIR/$job_name.conf" <<EOF
[program:$job_name]
process_name=%(program_name)s
command=/usr/local/bin/run_job.sh $job_file
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/supervisor/$job_name.log
EOF
	fi
}

echo "Processing job scripts in $JOBS_DIR"
shopt -s nullglob # Handle case where no .sh files exist
for job_file in "$JOBS_DIR"/*.sh; do
	if [ -f "$job_file" ]; then
		echo "Found job script: $job_file"
		generate_job_config "$job_file"
	fi
done

exec "$@"
