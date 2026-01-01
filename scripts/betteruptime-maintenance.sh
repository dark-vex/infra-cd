#!/bin/bash
# Better Uptime Maintenance Mode Management Script
#
# This script helps manage maintenance mode for Better Uptime monitors
# during ingress controller transitions (nginx -> haproxy)
#
# Usage:
#   ./betteruptime-maintenance.sh enable    # Enable maintenance mode
#   ./betteruptime-maintenance.sh disable   # Disable maintenance mode
#   ./betteruptime-maintenance.sh status    # Check maintenance mode status

set -euo pipefail

# Configuration
BETTERUPTIME_API_TOKEN="${BETTERUPTIME_API_TOKEN:-}"
BETTERUPTIME_API_URL="https://betteruptime.com/api/v2"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if API token is set
check_api_token() {
    if [ -z "$BETTERUPTIME_API_TOKEN" ]; then
        log_error "BETTERUPTIME_API_TOKEN environment variable is not set"
        log_info "Export your Better Uptime API token:"
        log_info "  export BETTERUPTIME_API_TOKEN='your_token_here'"
        exit 1
    fi
}

# Get all monitors
get_monitors() {
    curl -s -X GET "$BETTERUPTIME_API_URL/monitors" \
        -H "Authorization: Bearer $BETTERUPTIME_API_TOKEN" \
        -H "Content-Type: application/json"
}

# Enable maintenance mode for all monitors
enable_maintenance() {
    log_info "Enabling maintenance mode for all monitors..."

    monitors=$(get_monitors)
    monitor_ids=$(echo "$monitors" | jq -r '.data[].id')

    if [ -z "$monitor_ids" ]; then
        log_warn "No monitors found"
        return
    fi

    for monitor_id in $monitor_ids; do
        monitor_name=$(echo "$monitors" | jq -r ".data[] | select(.id==\"$monitor_id\") | .attributes.pronounceable_name")

        log_info "Enabling maintenance for: $monitor_name (ID: $monitor_id)"

        curl -s -X POST "$BETTERUPTIME_API_URL/monitors/$monitor_id/maintenance" \
            -H "Authorization: Bearer $BETTERUPTIME_API_TOKEN" \
            -H "Content-Type: application/json" \
            -d '{
                "starts_at": "'$(date -u +%Y-%m-%dT%H:%M:%S)'Z",
                "duration": "3600"
            }' > /dev/null
    done

    log_info "Maintenance mode enabled for all monitors"
}

# Disable maintenance mode for all monitors
disable_maintenance() {
    log_info "Disabling maintenance mode for all monitors..."

    monitors=$(get_monitors)
    monitor_ids=$(echo "$monitors" | jq -r '.data[].id')

    if [ -z "$monitor_ids" ]; then
        log_warn "No monitors found"
        return
    fi

    for monitor_id in $monitor_ids; do
        monitor_name=$(echo "$monitors" | jq -r ".data[] | select(.id==\"$monitor_id\") | .attributes.pronounceable_name")

        log_info "Checking maintenance for: $monitor_name (ID: $monitor_id)"

        # Get ongoing maintenances
        maintenances=$(curl -s -X GET "$BETTERUPTIME_API_URL/monitors/$monitor_id/maintenance" \
            -H "Authorization: Bearer $BETTERUPTIME_API_TOKEN")

        maintenance_ids=$(echo "$maintenances" | jq -r '.data[].id')

        for maintenance_id in $maintenance_ids; do
            log_info "  Disabling maintenance ID: $maintenance_id"
            curl -s -X DELETE "$BETTERUPTIME_API_URL/monitors/$monitor_id/maintenance/$maintenance_id" \
                -H "Authorization: Bearer $BETTERUPTIME_API_TOKEN" > /dev/null
        done
    done

    log_info "Maintenance mode disabled for all monitors"
}

# Check maintenance mode status
check_status() {
    log_info "Checking maintenance mode status..."

    monitors=$(get_monitors)
    monitor_ids=$(echo "$monitors" | jq -r '.data[].id')

    if [ -z "$monitor_ids" ]; then
        log_warn "No monitors found"
        return
    fi

    for monitor_id in $monitor_ids; do
        monitor_name=$(echo "$monitors" | jq -r ".data[] | select(.id==\"$monitor_id\") | .attributes.pronounceable_name")

        maintenances=$(curl -s -X GET "$BETTERUPTIME_API_URL/monitors/$monitor_id/maintenance" \
            -H "Authorization: Bearer $BETTERUPTIME_API_TOKEN")

        maintenance_count=$(echo "$maintenances" | jq '.data | length')

        if [ "$maintenance_count" -gt 0 ]; then
            echo -e "  ${YELLOW}✓${NC} $monitor_name: Maintenance mode ACTIVE"
        else
            echo -e "  ${GREEN}✗${NC} $monitor_name: Maintenance mode INACTIVE"
        fi
    done
}

# Main script
main() {
    local command="${1:-}"

    if [ -z "$command" ]; then
        log_error "No command specified"
        echo "Usage: $0 {enable|disable|status}"
        exit 1
    fi

    check_api_token

    case "$command" in
        enable)
            enable_maintenance
            ;;
        disable)
            disable_maintenance
            ;;
        status)
            check_status
            ;;
        *)
            log_error "Unknown command: $command"
            echo "Usage: $0 {enable|disable|status}"
            exit 1
            ;;
    esac
}

main "$@"
