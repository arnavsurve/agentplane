#!/bin/bash

# Database Backup Verification Script
# Verifies that RDS backups are working and accessible

set -e

# Configuration
DB_IDENTIFIER="glyfs-db-production"
AWS_REGION="us-west-1"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[BACKUP-CHECK]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    log_error "AWS CLI not configured or not accessible"
    exit 1
fi

log_info "Checking RDS backups for $DB_IDENTIFIER..."

# Get latest backup
LATEST_BACKUP=$(aws rds describe-db-snapshots \
    --db-instance-identifier $DB_IDENTIFIER \
    --snapshot-type automated \
    --query 'DBSnapshots | sort_by(@, &SnapshotCreateTime) | [-1]' \
    --region $AWS_REGION)

if [[ "$LATEST_BACKUP" == "null" ]]; then
    log_error "No automated backups found!"
    exit 1
fi

# Extract backup details
BACKUP_TIME=$(echo "$LATEST_BACKUP" | jq -r '.SnapshotCreateTime')
BACKUP_STATUS=$(echo "$LATEST_BACKUP" | jq -r '.Status')
BACKUP_ID=$(echo "$LATEST_BACKUP" | jq -r '.DBSnapshotIdentifier')

log_info "Latest backup: $BACKUP_ID"
log_info "Created: $BACKUP_TIME"
log_info "Status: $BACKUP_STATUS"

# Check if backup is recent (within last 24 hours)
if command -v python3 > /dev/null 2>&1; then
    HOURS_AGO=$(python3 -c "
from datetime import datetime, timezone
import sys

backup_time = datetime.fromisoformat('$BACKUP_TIME'.replace('Z', '+00:00'))
now = datetime.now(timezone.utc)
hours_diff = (now - backup_time).total_seconds() / 3600
print(f'{hours_diff:.1f}')
")

    if (( $(echo "$HOURS_AGO > 25" | bc -l) )); then
        log_error "Last backup is $HOURS_AGO hours old - too old!"
        exit 1
    else
        log_info "Backup age: $HOURS_AGO hours (acceptable)"
    fi
fi

# Check backup status
if [[ "$BACKUP_STATUS" != "available" ]]; then
    log_warning "Backup status is '$BACKUP_STATUS', not 'available'"
fi

# List recent backups for reference
log_info "Recent backups:"
aws rds describe-db-snapshots \
    --db-instance-identifier $DB_IDENTIFIER \
    --snapshot-type automated \
    --query 'DBSnapshots | sort_by(@, &SnapshotCreateTime) | [-5:] | [].{ID: DBSnapshotIdentifier, Time: SnapshotCreateTime, Status: Status}' \
    --output table \
    --region $AWS_REGION

# Check manual snapshots too
MANUAL_COUNT=$(aws rds describe-db-snapshots \
    --db-instance-identifier $DB_IDENTIFIER \
    --snapshot-type manual \
    --query 'length(DBSnapshots)' \
    --region $AWS_REGION)

log_info "Manual snapshots available: $MANUAL_COUNT"

log_info "✅ Backup verification completed successfully"

# Create a simple backup health status file
cat > /tmp/backup-status.json <<EOF
{
    "last_check": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "latest_backup_id": "$BACKUP_ID",
    "latest_backup_time": "$BACKUP_TIME",
    "latest_backup_status": "$BACKUP_STATUS",
    "backup_age_hours": $HOURS_AGO,
    "status": "healthy"
}
EOF

log_info "Backup status written to /tmp/backup-status.json"
