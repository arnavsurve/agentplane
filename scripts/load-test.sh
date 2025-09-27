#!/bin/bash

# Simple Load Testing for Glyfs
# Tests basic capacity and identifies bottlenecks

set -e

# Configuration
BASE_URL=${1:-"http://52.8.122.166:8080"}
CONCURRENT_USERS=${2:-10}
DURATION=${3:-60} # seconds

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[LOAD-TEST]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if required tools are available
check_tools() {
    local missing_tools=()
    
    if ! command -v curl > /dev/null; then
        missing_tools+=("curl")
    fi
    
    if ! command -v bc > /dev/null; then
        missing_tools+=("bc")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
}

# Single request test
test_single_request() {
    log_info "Testing single request latency..."
    
    local response_time=$(curl -o /dev/null -s -w "%{time_total}" "$BASE_URL/health")
    local http_code=$(curl -o /dev/null -s -w "%{http_code}" "$BASE_URL/health")
    
    if [[ "$http_code" == "200" ]]; then
        log_info "✅ Single request: ${response_time}s (HTTP $http_code)"
        echo "$response_time"
    else
        log_error "❌ Single request failed: HTTP $http_code"
        return 1
    fi
}

# Concurrent request test  
test_concurrent_requests() {
    local users=$1
    local duration=$2
    
    log_info "Testing $users concurrent users for ${duration}s..."
    
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    local request_count=0
    local success_count=0
    local total_time=0
    
    # Create temp directory for results
    local temp_dir="/tmp/glyfs-load-test-$$"
    mkdir -p "$temp_dir"
    
    # Start concurrent workers
    for ((i=1; i<=users; i++)); do
        (
            while [[ $(date +%s) -lt $end_time ]]; do
                local start_req=$(date +%s.%3N)
                local http_code=$(curl -o /dev/null -s -w "%{http_code}" --max-time 10 "$BASE_URL/health" 2>/dev/null || echo "000")
                local end_req=$(date +%s.%3N)
                local req_time=$(echo "$end_req - $start_req" | bc)
                
                echo "$http_code $req_time" >> "$temp_dir/worker-$i.log"
                sleep 0.1 # Small delay between requests
            done
        ) &
    done
    
    # Wait for all workers to complete
    wait
    
    # Aggregate results
    local total_requests=0
    local successful_requests=0
    local failed_requests=0
    local total_response_time=0
    
    for log_file in "$temp_dir"/worker-*.log; do
        if [[ -f "$log_file" ]]; then
            while read -r http_code response_time; do
                total_requests=$((total_requests + 1))
                if [[ "$http_code" == "200" ]]; then
                    successful_requests=$((successful_requests + 1))
                    total_response_time=$(echo "$total_response_time + $response_time" | bc)
                else
                    failed_requests=$((failed_requests + 1))
                fi
            done < "$log_file"
        fi
    done
    
    # Calculate metrics
    local requests_per_second=$(echo "scale=2; $total_requests / $duration" | bc)
    local success_rate=0
    local avg_response_time=0
    
    if [[ $total_requests -gt 0 ]]; then
        success_rate=$(echo "scale=2; $successful_requests * 100 / $total_requests" | bc)
    fi
    
    if [[ $successful_requests -gt 0 ]]; then
        avg_response_time=$(echo "scale=3; $total_response_time / $successful_requests" | bc)
    fi
    
    # Display results
    log_info "📊 Load Test Results:"
    echo "  Total Requests: $total_requests"
    echo "  Successful: $successful_requests"
    echo "  Failed: $failed_requests"
    echo "  Success Rate: $success_rate%"
    echo "  Requests/second: $requests_per_second"
    echo "  Avg Response Time: ${avg_response_time}s"
    
    # Performance assessment
    if (( $(echo "$success_rate >= 99" | bc -l) )); then
        log_info "✅ Excellent reliability ($success_rate% success rate)"
    elif (( $(echo "$success_rate >= 95" | bc -l) )); then
        log_warning "⚠️  Good reliability ($success_rate% success rate)"
    else
        log_error "❌ Poor reliability ($success_rate% success rate)"
    fi
    
    if (( $(echo "$requests_per_second >= 50" | bc -l) )); then
        log_info "✅ Good throughput ($requests_per_second req/s)"
    elif (( $(echo "$requests_per_second >= 20" | bc -l) )); then
        log_warning "⚠️  Moderate throughput ($requests_per_second req/s)"
    else
        log_error "❌ Low throughput ($requests_per_second req/s)"
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
}

# API endpoint tests
test_api_endpoints() {
    log_info "Testing API endpoints..."
    
    local endpoints=(
        "/health"
        "/api/auth/providers"
    )
    
    for endpoint in "${endpoints[@]}"; do
        local url="$BASE_URL$endpoint"
        local http_code=$(curl -o /dev/null -s -w "%{http_code}" --max-time 5 "$url")
        local response_time=$(curl -o /dev/null -s -w "%{time_total}" --max-time 5 "$url")
        
        if [[ "$http_code" == "200" ]]; then
            log_info "✅ $endpoint: ${response_time}s (HTTP $http_code)"
        else
            log_warning "⚠️  $endpoint: HTTP $http_code"
        fi
    done
}

# Main execution
main() {
    log_info "🧪 Starting Glyfs Load Test"
    log_info "Target: $BASE_URL"
    log_info "Concurrent Users: $CONCURRENT_USERS"
    log_info "Duration: ${DURATION}s"
    
    check_tools
    
    # Basic connectivity test
    if ! test_single_request > /dev/null; then
        log_error "Basic connectivity failed. Aborting load test."
        exit 1
    fi
    
    # API endpoints test
    test_api_endpoints
    
    # Load test
    test_concurrent_requests "$CONCURRENT_USERS" "$DURATION"
    
    log_info "🎯 Load testing completed!"
    log_warning "For Asylum Ventures production loads, consider running with higher concurrency"
    log_info "Example: ./load-test.sh $BASE_URL 25 120"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
