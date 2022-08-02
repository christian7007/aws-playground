#!/bin/bash

set -e -o pipefail

###############################################################################
# Define flags default values
###############################################################################

ID="aws-cli-$(uuidgen)"
CLASS="db.t3.micro"
ENGINE="mariadb"
USER="admin"
PASSWD="adminrds"
SG="sg-0c00d8d1059df4ba9"
PUBLIC="--no-publicly-accessible"

###############################################################################
# Parse arguments
###############################################################################

while getopts i:c:e:u:p:s:ad flag
do
    case "${flag}" in
        i) ID="${OPTARG}";;
        c) CLASS="${OPTARG}";;
        e) ENGINE="${OPTARG}";;
        u) USER="${OPTARG}";;
        p) PASSWD="${OPTARG}";;
        s) SG="${OPTARG}";;
        a) PUBLIC="--publicly-accessible";;
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
# --allocated-storage is forced to 10 to ensure free tier limits (20GiB) is not surpassed
# --storage-type is forced to standard as it the only one which support less than 20GiB
# --backup-retention-period force to 0 to disable backups
OUTPUT="$(aws rds create-db-instance --db-instance-identifier "$ID" \
                                     --allocated-storage 10 \
                                     --db-instance-class "$CLASS" \
                                     --engine "$ENGINE" \
                                     --master-username "$USER" \
                                     --master-user-password "$PASSWD" \
                                     --vpc-security-group-ids "$SG" \
                                     --backup-retention-period 0 \
                                     --no-multi-az \
                                     --auto-minor-version-upgrade \
                                     $PUBLIC \
                                     --storage-type standard \
                                     $DUMMY)"

###############################################################################
# Output
###############################################################################
LOG_PATH="/tmp/log-rds-$ID"

echo "$OUTPUT" > "$LOG_PATH"
echo "ID:       $(echo "$OUTPUT" | jq .DBInstance.DBInstanceIdentifier)"
echo "ENGINE:   $(echo "$OUTPUT" | jq .DBInstance.Engine)"
echo "INSTANCE: $(echo "$OUTPUT" | jq .DBInstance.DBInstanceClass)"
echo "USER:     $(echo "$OUTPUT" | jq .DBInstance.MasterUsername)"
echo "LOG:      $LOG_PATH"
echo "RM CMD:   $CURRENT_DIR/delete-rds.sh -i \"$ID\""