#!/bin/bash

# Simple Uptime Monitor for Glyfs
# Run this on a separate server or GitHub Actions every 5 minutes

set -e

# Configuration
HEALTH_URL="http://52.8.122.166:8080/health"
HTTPS_URL="https://glyfs.dev/health"
WEBHOOK_URL=${SLACK_WEBHOOK_URL:-""} # Set this in your environment

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[MONITOR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

send_alert() {
    local message="$1"
    local status="$2"
    
    if [[ -n "$WEBHOOK_URL" ]]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"🚨 Glyfs Alert: $message\", \"color\":\"$status\"}" \
            "$WEBHOOK_URL" || true
    fi
    
    # Also log to syslog if available
    logger "Glyfs Monitor: $message" 2>/dev/null || true
}

check_endpoint() {
    local url="$1"
    local name="$2"
    
    if curl -f -s --max-time 10 "$url" > /dev/null; then
        log_info "$name is healthy"
        return 0
    else
        log_error "$name is down!"
        send_alert "$name is down!" "danger"
        return 1
    fi
}

# Check HTTP endpoint
if check_endpoint "$HEALTH_URL" "HTTP Service"; then
    HTTP_STATUS=0
else
    HTTP_STATUS=1
fi

# Check HTTPS endpoint (if configured)
if check_endpoint "$HTTPS_URL" "HTTPS Service"; then
    HTTPS_STATUS=0
else
    HTTPS_STATUS=1
fi

# Check database connectivity (via API - public endpoint)
DB_CHECK_URL="http://52.8.122.166:8080/api/auth/providers"
# This endpoint returns 401 when working (needs auth), but connection error when DB is down
RESPONSE=$(curl -s -w "%{http_code}" --max-time 10 "$DB_CHECK_URL" 2>/dev/null || echo "000")
HTTP_CODE="${RESPONSE: -3}"

if [[ "$HTTP_CODE" == "401" || "$HTTP_CODE" == "200" ]]; then
    log_info "Database connectivity is healthy (HTTP $HTTP_CODE)"
    DB_STATUS=0
elif [[ "$HTTP_CODE" == "000" ]]; then
    log_error "Database connectivity failed - connection error!"
    send_alert "Database connectivity failed!" "danger"
    DB_STATUS=1
else
    log_warning "Database check returned HTTP $HTTP_CODE - investigate"
    DB_STATUS=0  # Don't fail for unexpected but non-connection errors
fi

# Overall status
TOTAL_FAILURES=$((HTTP_STATUS + HTTPS_STATUS + DB_STATUS))

if [[ $TOTAL_FAILURES -eq 0 ]]; then
    log_info "✅ All systems operational"
    exit 0
elif [[ $TOTAL_FAILURES -eq 1 ]]; then
    log_error "⚠️  1 service down - investigate immediately"
    exit 1
else
    log_error "🚨 Multiple services down - CRITICAL!"
    send_alert "CRITICAL: Multiple services down!" "danger"
    exit 2
fi
