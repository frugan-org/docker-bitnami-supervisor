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

# With run_job.sh wrapper (recommended):
# e.g. command=/usr/local/bin/run_job.sh /etc/supervisor/jobs.d/job.sh)
#
# - Works even if horizon.sh does not have +x
# - If the file is missing → Supervisor fails immediately
# - exec ensures that the parent process is the script itself
#
# Without run_job.sh wrapper:
# e.g. command=/etc/supervisor/jobs.d/job.sh
#
# - Fails silently if +x permission is missing
# - If the file is missing, Supervisor may log the error but keep looping
# - Child process is the script, but without exec you may have different behavior in PID tracing

JOB_SCRIPT="$1"

if [ ! -f "$JOB_SCRIPT" ]; then
	echo "Script $JOB_SCRIPT not found!"
	exit 1
fi

# Make the script executable if it isn't already
chmod +x "$JOB_SCRIPT"

# Run the script
echo "Start job: $JOB_SCRIPT"
exec "$JOB_SCRIPT"
