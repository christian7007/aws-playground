#!/bin/bash

set -e -o pipefail

###############################################################################
# Parse arguments
###############################################################################

while getopts i:d flag
do
    case "${flag}" in
        i) ID="${OPTARG}";;
        d) DUMMY="--generate-cli-skeleton output";;
        *) echo "Not supported option: ${OPTARG}" 1>&2;;
    esac
done

###############################################################################
# Define credentials
###############################################################################
CURRENT_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"

export AWS_ACCESS_KEY_ID="$(cat $CURRENT_DIR/../credentials/access_key)"
export AWS_SECRET_ACCESS_KEY="$(cat $CURRENT_DIR/../credentials/secret_key)"
export AWS_DEFAULT_REGION=eu-west-2

###############################################################################
# Build command
###############################################################################
# --skip-final-snapshot and --delete-automated-backups are forced to ensure no
# residual files are keept
OUTPUT="$(aws rds delete-db-instance --db-instance-identifier "$ID" \
                                     --skip-final-snapshot \
                                     --delete-automated-backups \
                                     $DUMMY)"

###############################################################################
# Output
###############################################################################
LOG_PATH="/tmp/log-rds-$ID"

echo "$OUTPUT" > "$LOG_PATH"
echo "LOG: $LOG_PATH"