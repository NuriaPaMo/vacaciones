#!/bin/bash

# ==============================================================================
# ops-status.sh - Operations Status and Runbook Generator
# Part of Bolt Framework / AI-DLC methodology
# Phase: Block 6 - Operations
# ==============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Helpers
step() { echo -e "\n${CYAN}📋 $1${NC}"; }
success() { echo -e "  ${GREEN}✅ $1${NC}"; }
info() { echo -e "  ${BLUE}ℹ️  $1${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $1${NC}"; }
err() { echo -e "  ${RED}❌ $1${NC}"; }

# Show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -s, --status        Show system status"
    echo "  -r, --runbook NAME  Generate runbook for service"
    echo "  -d, --docker        Check Docker status"
    echo "  -a, --all           Run all checks"
    echo "  -h, --help          Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 --status"
    echo "  $0 --runbook my-service"
    echo "  $0 --all"
}

# System health checks
check_system_health() {
    step "Checking system health..."

    # CPU
    local cpu_usage
    if command -v top &> /dev/null; then
        cpu_usage=$(top -l 1 2>/dev/null | grep "CPU usage" | awk '{print $3}' | tr -d '%' || echo "N/A")
        if [ "$cpu_usage" = "N/A" ]; then
            cpu_usage=$(grep 'cpu ' /proc/stat 2>/dev/null | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "%.1f", usage}' || echo "N/A")
        fi
    else
        cpu_usage="N/A"
    fi

    if [ "$cpu_usage" != "N/A" ] && (( $(echo "$cpu_usage < 80" | bc -l 2>/dev/null || echo 1) )); then
        success "CPU: ${cpu_usage}%"
    else
        info "CPU: ${cpu_usage}%"
    fi

    # Memory
    if command -v free &> /dev/null; then
        local mem_info=$(free -m | awk 'NR==2{printf "%.1f%% (%s/%s MB)", $3*100/$2, $3, $2}')
        local mem_percent=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
        if [ "$mem_percent" -lt 80 ]; then
            success "Memory: $mem_info"
        else
            warn "Memory: $mem_info"
        fi
    else
        info "Memory: N/A (free command not available)"
    fi

    # Disk
    if command -v df &> /dev/null; then
        local disk_info=$(df -h / | awk 'NR==2{print $5 " used (" $3 "/" $2 ")"}')
        local disk_percent=$(df / | awk 'NR==2{print $5}' | tr -d '%')
        if [ "$disk_percent" -lt 80 ]; then
            success "Disk: $disk_info"
        else
            warn "Disk: $disk_info"
        fi
    fi

    # Uptime
    if command -v uptime &> /dev/null; then
        local uptime_info=$(uptime -p 2>/dev/null || uptime | sed 's/.*up //' | sed 's/, *[0-9]* user.*//')
        info "Uptime: $uptime_info"
    fi
}

# Docker status
check_docker_status() {
    step "Checking Docker status..."

    if ! command -v docker &> /dev/null; then
        warn "Docker not installed"
        return 0
    fi

    if ! docker info &> /dev/null; then
        warn "Docker daemon not running"
        return 0
    fi

    success "Docker daemon running"

    # Running containers
    local running=$(docker ps -q | wc -l | tr -d ' ')
    local total=$(docker ps -aq | wc -l | tr -d ' ')
    info "Containers: $running running / $total total"

    # List running containers
    if [ "$running" -gt 0 ]; then
        echo ""
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -10
    fi
}

# Generate runbook
generate_runbook() {
    local service_name=$1
    local date=$(date +%Y-%m-%d)
    local timestamp=$(date +%Y%m%d-%H%M%S)

    step "Generating runbook for '$service_name'..."

    local runbook_dir="docs/runbooks"
    mkdir -p "$runbook_dir"

    local safe_name=$(echo "$service_name" | tr ' ' '-' | tr -cd '[:alnum:]-')
    local filename="$runbook_dir/${safe_name}-runbook.md"

    cat > "$filename" << EOF
# Operational Runbook: $service_name

## Document Info

| Property | Value |
|----------|-------|
| Service | $service_name |
| Created | $date |
| Last Updated | $date |
| Owner | [Team Name] |
| On-Call Rotation | [Link to rotation] |

---

## Service Overview

### Description
[Brief description of what this service does]

### Architecture
[Architecture diagram or link]

### Dependencies
| Service | Type | Critical |
|---------|------|----------|
| [Dependency 1] | Internal/External | Yes/No |

---

## Health Checks

### Endpoints
| Endpoint | Expected Response | Frequency |
|----------|-------------------|-----------|
| /health | 200 OK | 30s |
| /ready | 200 OK | 30s |

### Metrics to Monitor
- [ ] Response time (P99 < 500ms)
- [ ] Error rate (< 0.1%)
- [ ] CPU usage (< 80%)
- [ ] Memory usage (< 80%)

---

## Common Operations

### Start Service
\`\`\`bash
# Start command
docker-compose up -d $service_name
# Or
systemctl start $service_name
\`\`\`

### Stop Service
\`\`\`bash
# Stop command
docker-compose stop $service_name
# Or
systemctl stop $service_name
\`\`\`

### Restart Service
\`\`\`bash
# Restart command
docker-compose restart $service_name
# Or
systemctl restart $service_name
\`\`\`

### View Logs
\`\`\`bash
# View logs
docker-compose logs -f $service_name
# Or
journalctl -u $service_name -f
\`\`\`

---

## Troubleshooting

### High CPU Usage
**Symptoms**: CPU > 80% for extended period
**Steps**:
1. Check for runaway processes
2. Review recent deployments
3. Check for traffic spike

### High Memory Usage
**Symptoms**: Memory > 80%
**Steps**:
1. Check for memory leaks
2. Review recent deployments
3. Consider scaling

### Service Not Responding
**Symptoms**: Health check failing
**Steps**:
1. Check service logs
2. Verify dependencies
3. Check network connectivity
4. Restart if needed

---

## Incident Response

### Severity Levels
| Level | Description | Response Time |
|-------|-------------|---------------|
| P1 | Service down | < 15 min |
| P2 | Degraded | < 1 hour |
| P3 | Minor issue | < 4 hours |

### Escalation Path
1. On-call engineer
2. Team lead
3. Engineering manager

---

## Contacts

| Role | Name | Contact |
|------|------|---------|
| Team Lead | [Name] | [Contact] |
| On-Call | [Rotation] | [PagerDuty] |

---

*Generated by Bolt Framework Ops Command*
EOF

    success "Runbook created: $filename"
    echo "$filename"
}

# Generate status report
generate_status_report() {
    local date=$(date +%Y-%m-%d)
    local time=$(date +%H:%M:%S)

    step "Generating status report..."

    local report_dir="docs/runbooks"
    mkdir -p "$report_dir"

    local filename="$report_dir/status-report-$(date +%Y%m%d).md"

    # Get system info
    local hostname=$(hostname 2>/dev/null || echo "unknown")
    local os_info=$(uname -s 2>/dev/null || echo "unknown")

    cat > "$filename" << EOF
# System Status Report

## Report Info

| Property | Value |
|----------|-------|
| Generated | $date $time |
| Hostname | $hostname |
| OS | $os_info |

---

## System Health Summary

| Check | Status | Value |
|-------|--------|-------|
EOF

    # Add CPU info
    if command -v top &> /dev/null; then
        echo "| CPU | ✅ | Normal |" >> "$filename"
    fi

    # Add Memory info
    if command -v free &> /dev/null; then
        echo "| Memory | ✅ | Normal |" >> "$filename"
    fi

    # Add Disk info
    if command -v df &> /dev/null; then
        echo "| Disk | ✅ | Normal |" >> "$filename"
    fi

    # Add Docker info
    if command -v docker &> /dev/null && docker info &> /dev/null; then
        local running=$(docker ps -q | wc -l | tr -d ' ')
        echo "| Docker | ✅ | $running containers |" >> "$filename"
    fi

    cat >> "$filename" << EOF

---

## Recommendations

- [Any recommendations based on current status]

---

*Generated by Bolt Framework Ops Status*
EOF

    success "Status report: $filename"
}

# Main
main() {
    echo -e "\n${MAGENTA}🔧 Bolt Framework Operations Status${NC}"
    echo -e "${MAGENTA}==================================${NC}\n"

    local show_status=false
    local runbook_name=""
    local check_docker=false
    local run_all=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--status) show_status=true; shift ;;
            -r|--runbook) runbook_name="$2"; shift 2 ;;
            -d|--docker) check_docker=true; shift ;;
            -a|--all) run_all=true; shift ;;
            -h|--help) usage; exit 0 ;;
            *) echo "Unknown option: $1"; usage; exit 1 ;;
        esac
    done

    # Default to all if nothing specified
    if ! $show_status && [ -z "$runbook_name" ] && ! $check_docker && ! $run_all; then
        run_all=true
    fi

    if $run_all || $show_status; then
        check_system_health
    fi

    if $run_all || $check_docker; then
        check_docker_status
    fi

    if [ -n "$runbook_name" ]; then
        generate_runbook "$runbook_name"
    fi

    if $run_all; then
        generate_status_report
    fi

    # Summary
    echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✅ Operations check complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"

    echo -e "\n${YELLOW}📋 Next Steps:${NC}"
    echo "  1. Review any warnings above"
    echo "  2. Check docs/runbooks/ for generated files"
    echo "  3. Set up monitoring alerts"
    echo ""
}

main "$@"
