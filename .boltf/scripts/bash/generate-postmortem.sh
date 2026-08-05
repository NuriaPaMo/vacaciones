#!/bin/bash

# ==============================================================================
# generate-postmortem.sh - Incident Postmortem Generator
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
    echo "  -t, --title TITLE       Incident title"
    echo "  -s, --severity SEV      Severity: P1|P2|P3|P4"
    echo "  -d, --date DATE         Incident date (YYYY-MM-DD)"
    echo "  -i, --interactive       Interactive mode with prompts"
    echo "  -h, --help              Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 --interactive"
    echo "  $0 --title 'API Outage' --severity P1 --date 2024-01-15"
}

# Read user input with default
read_input() {
    local prompt=$1
    local default=$2
    local result
    
    if [ -n "$default" ]; then
        echo -en "${YELLOW}$prompt [$default]: ${NC}"
    else
        echo -en "${YELLOW}$prompt: ${NC}"
    fi
    
    read result
    
    if [ -z "$result" ]; then
        echo "$default"
    else
        echo "$result"
    fi
}

# Interactive mode
interactive_mode() {
    step "Interactive Postmortem Creation"
    
    INCIDENT_TITLE=$(read_input "Incident title")
    SEVERITY=$(read_input "Severity (P1/P2/P3/P4)" "P2")
    INCIDENT_DATE=$(read_input "Incident date (YYYY-MM-DD)" "$(date +%Y-%m-%d)")
    DURATION=$(read_input "Duration (e.g., 2h 30m)" "Unknown")
    SERVICES=$(read_input "Affected services" "Unknown")
    SUMMARY=$(read_input "Brief summary" "Incident under investigation")
    ROOT_CAUSE=$(read_input "Root cause (if known)" "Under investigation")
    IMPACT=$(read_input "Business impact" "Users experienced service degradation")
}

# Generate postmortem document
generate_postmortem() {
    local date_created=$(date +%Y-%m-%d)
    local timestamp=$(date +%Y%m%d-%H%M%S)
    
    step "Generating postmortem document..."
    
    local postmortem_dir="docs/postmortems"
    mkdir -p "$postmortem_dir"
    
    local safe_title=$(echo "$INCIDENT_TITLE" | tr ' ' '-' | tr -cd '[:alnum:]-' | head -c 50)
    local filename="$postmortem_dir/${INCIDENT_DATE:-$date_created}-${safe_title:-incident}.md"
    
    # Severity emoji
    local sev_emoji
    case $SEVERITY in
        P1) sev_emoji="🔴" ;;
        P2) sev_emoji="🟠" ;;
        P3) sev_emoji="🟡" ;;
        P4) sev_emoji="🟢" ;;
        *) sev_emoji="⚪" ;;
    esac
    
    cat > "$filename" << EOF
# Postmortem: ${INCIDENT_TITLE:-Incident Report}

## Incident Summary

| Property | Value |
|----------|-------|
| **Document ID** | PM-$timestamp |
| **Date** | ${INCIDENT_DATE:-$date_created} |
| **Severity** | $sev_emoji ${SEVERITY:-P2} |
| **Duration** | ${DURATION:-Unknown} |
| **Status** | 📝 Draft |
| **Author** | [Your Name] |
| **Review Date** | $(date -d "+7 days" +%Y-%m-%d 2>/dev/null || date -v+7d +%Y-%m-%d 2>/dev/null || echo "TBD") |

---

## Executive Summary

${SUMMARY:-Brief description of the incident.}

### Impact

${IMPACT:-Description of business/user impact.}

### Affected Services

${SERVICES:-List of affected services}

---

## Blameless Culture Reminder

> 🎯 **This postmortem follows blameless principles.**
>
> We focus on systems, processes, and circumstances—not individuals.
> The goal is learning and improvement, not assigning blame.
> Everyone involved acted with the best intentions given the information available.

---

## Timeline

| Time | Event |
|------|-------|
| HH:MM | 🔔 Alert triggered / Issue detected |
| HH:MM | 👀 First responder engaged |
| HH:MM | 🔍 Investigation started |
| HH:MM | 💡 Root cause identified |
| HH:MM | 🔧 Mitigation applied |
| HH:MM | ✅ Service restored |
| HH:MM | 📊 Full resolution confirmed |

---

## Root Cause Analysis

### What Happened

${ROOT_CAUSE:-Detailed description of what went wrong.}

### 5 Whys Analysis

1. **Why did the incident occur?**
   - [Answer]

2. **Why did [answer 1] happen?**
   - [Answer]

3. **Why did [answer 2] happen?**
   - [Answer]

4. **Why did [answer 3] happen?**
   - [Answer]

5. **Why did [answer 4] happen?**
   - [Root cause identified]

### Contributing Factors

- [ ] Recent deployment
- [ ] Configuration change
- [ ] Infrastructure issue
- [ ] External dependency failure
- [ ] Human error (process gap)
- [ ] Monitoring gap
- [ ] Other: ___________

---

## Detection & Response

### How Was It Detected?

- [ ] Automated monitoring/alerting
- [ ] User report
- [ ] Internal user noticed
- [ ] Routine check
- [ ] Other: ___________

### Response Effectiveness

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Time to detect (TTD) | [X min] | < 5 min | ✅/⚠️/❌ |
| Time to engage (TTE) | [X min] | < 15 min | ✅/⚠️/❌ |
| Time to mitigate (TTM) | [X min] | < 60 min | ✅/⚠️/❌ |
| Time to resolve (TTR) | [X min] | < 4 hours | ✅/⚠️/❌ |

---

## What Went Well

- ✅ [Positive aspect 1]
- ✅ [Positive aspect 2]
- ✅ [Positive aspect 3]

## What Could Be Improved

- 🔧 [Improvement area 1]
- 🔧 [Improvement area 2]
- 🔧 [Improvement area 3]

---

## Action Items

| ID | Action | Owner | Priority | Due Date | Status |
|----|--------|-------|----------|----------|--------|
| 1 | [Prevent recurrence action] | [Name] | High | [Date] | ⬜ Open |
| 2 | [Improve detection action] | [Name] | Medium | [Date] | ⬜ Open |
| 3 | [Documentation update] | [Name] | Low | [Date] | ⬜ Open |

---

## Lessons Learned

### Technical

- [Technical lesson 1]

### Process

- [Process lesson 1]

### Communication

- [Communication lesson 1]

---

## Appendix

### Related Incidents

| Incident | Date | Related How |
|----------|------|-------------|
| [Link to related postmortem] | [Date] | [Relationship] |

### References

- [Link to monitoring dashboard]
- [Link to relevant runbook]
- [Link to architecture docs]

### Raw Data/Logs

<details>
<summary>Click to expand logs</summary>

\`\`\`
[Relevant log excerpts here]
\`\`\`

</details>

---

## Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Author | | | ⬜ |
| Reviewer | | | ⬜ |
| Team Lead | | | ⬜ |

---

*Generated by Bolt Framework Postmortem Command*
*Template follows industry best practices for blameless postmortems*
EOF

    success "Postmortem created: $filename"
    echo "$filename"
}

# Main
main() {
    echo -e "\n${MAGENTA}📋 Bolt Framework Postmortem Generator${NC}"
    echo -e "${MAGENTA}====================================${NC}\n"
    
    # Default values
    INCIDENT_TITLE=""
    SEVERITY="P2"
    INCIDENT_DATE=$(date +%Y-%m-%d)
    DURATION=""
    SERVICES=""
    SUMMARY=""
    ROOT_CAUSE=""
    IMPACT=""
    
    local interactive=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--title) INCIDENT_TITLE="$2"; shift 2 ;;
            -s|--severity) SEVERITY="$2"; shift 2 ;;
            -d|--date) INCIDENT_DATE="$2"; shift 2 ;;
            -i|--interactive) interactive=true; shift ;;
            -h|--help) usage; exit 0 ;;
            *) echo "Unknown option: $1"; usage; exit 1 ;;
        esac
    done
    
    # Default to interactive if no title provided
    if [ -z "$INCIDENT_TITLE" ] && ! $interactive; then
        interactive=true
    fi
    
    if $interactive; then
        interactive_mode
    fi
    
    # Validate required fields
    if [ -z "$INCIDENT_TITLE" ]; then
        err "Incident title is required"
        usage
        exit 1
    fi
    
    # Generate the postmortem
    local pm_file=$(generate_postmortem)
    
    # Summary
    echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✅ Postmortem document created!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    
    echo -e "\n${YELLOW}📋 Next Steps:${NC}"
    echo "  1. Fill in timeline details"
    echo "  2. Complete 5 Whys analysis"
    echo "  3. Add action items with owners"
    echo "  4. Schedule review meeting"
    echo "  5. Get sign-offs"
    echo ""
}

main "$@"
