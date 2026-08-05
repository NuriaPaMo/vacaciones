#!/bin/bash

# ==============================================================================
# create-release.sh - Release/Deployment Automation Script
# Part of Bolt Framework / AI-DLC methodology
# Phase: Block 5 - Release
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
    echo "  -v, --version VERSION   Version number (e.g., 1.2.3)"
    echo "  -t, --type TYPE         Version type: major|minor|patch"
    echo "  -n, --notes             Include release notes"
    echo "  -d, --deploy ENV        Target environment"
    echo "  -h, --help              Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 --version 1.2.0"
    echo "  $0 --type patch --notes"
    echo "  $0 --version 2.0.0 --deploy staging"
}

# Get current version from package.json or version file
get_current_version() {
    if [ -f "package.json" ]; then
        grep -o '"version": *"[^"]*"' package.json | cut -d'"' -f4
    elif [ -f "VERSION" ]; then
        cat VERSION
    elif [ -f "version.txt" ]; then
        cat version.txt
    else
        echo "0.0.0"
    fi
}

# Calculate next version
calculate_next_version() {
    local current=$1
    local type=$2
    
    IFS='.' read -ra parts <<< "$current"
    local major=${parts[0]:-0}
    local minor=${parts[1]:-0}
    local patch=${parts[2]:-0}
    
    case $type in
        major) echo "$((major + 1)).0.0" ;;
        minor) echo "${major}.$((minor + 1)).0" ;;
        patch) echo "${major}.${minor}.$((patch + 1))" ;;
        *) echo "$current" ;;
    esac
}

# Run quality gates
run_quality_gates() {
    step "Running quality gates..."
    
    local passed=0
    local failed=0
    
    # Check for tests
    if [ -d "tests" ] || [ -d "test" ] || [ -d "__tests__" ]; then
        success "Test directory exists"
        ((passed++))
    else
        warn "No test directory found"
        ((failed++))
    fi
    
    # Check for lint config
    if [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f "eslint.config.js" ]; then
        success "ESLint configuration found"
        ((passed++))
    fi
    
    # Check for TypeScript
    if [ -f "tsconfig.json" ]; then
        success "TypeScript configuration found"
        ((passed++))
    fi
    
    # Check README
    if [ -f "README.md" ]; then
        success "README.md exists"
        ((passed++))
    else
        warn "README.md not found"
        ((failed++))
    fi
    
    # Check CHANGELOG
    if [ -f "CHANGELOG.md" ]; then
        success "CHANGELOG.md exists"
        ((passed++))
    else
        warn "CHANGELOG.md not found - will create"
    fi
    
    info "Quality gates: $passed passed, $failed warnings"
    return 0
}

# Update CHANGELOG
update_changelog() {
    local version=$1
    local date=$(date +%Y-%m-%d)
    
    step "Updating CHANGELOG..."
    
    if [ ! -f "CHANGELOG.md" ]; then
        cat > CHANGELOG.md << EOF
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

EOF
    fi
    
    # Create temp file with new version entry
    local temp_file=$(mktemp)
    
    cat > "$temp_file" << EOF
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [$version] - $date

### Added
- [Document new features here]

### Changed
- [Document changes here]

### Fixed
- [Document fixes here]

EOF
    
    # Append rest of changelog (skip header)
    tail -n +8 CHANGELOG.md >> "$temp_file" 2>/dev/null || true
    mv "$temp_file" CHANGELOG.md
    
    success "CHANGELOG.md updated with version $version"
}

# Create deployment unit
create_deployment_unit() {
    local version=$1
    local environment=$2
    local date=$(date +%Y-%m-%d)
    local timestamp=$(date +%Y%m%d-%H%M%S)
    
    step "Creating deployment unit..."
    
    local deploy_dir="docs/deployment_units"
    mkdir -p "$deploy_dir"
    
    local filename="$deploy_dir/release-$version-$timestamp.md"
    
    cat > "$filename" << EOF
# Release $version - Deployment Unit

## Release Information

| Property | Value |
|----------|-------|
| Version | $version |
| Created | $date |
| Environment | ${environment:-Production} |
| Status | 📝 Ready for Review |

---

## Pre-Deployment Checklist

- [ ] All tests passing
- [ ] Code review completed
- [ ] CHANGELOG updated
- [ ] Documentation updated
- [ ] Rollback plan documented
- [ ] Stakeholder approval obtained

---

## Deployment Steps

1. **Backup current state**
   \`\`\`bash
   # Backup commands here
   \`\`\`

2. **Deploy new version**
   \`\`\`bash
   # Deployment commands here
   \`\`\`

3. **Verify deployment**
   \`\`\`bash
   # Verification commands here
   \`\`\`

---

## Rollback Procedure

If issues are detected:

\`\`\`bash
# Rollback commands here
\`\`\`

---

## Post-Deployment Verification

- [ ] Application accessible
- [ ] Key features functional
- [ ] Monitoring active
- [ ] No error spikes
- [ ] Performance acceptable

---

*Generated by Bolt Framework Release Command*
EOF

    success "Deployment unit created: $filename"
    echo "$filename"
}

# Main
main() {
    echo -e "\n${MAGENTA}🚀 Bolt Framework Release Manager${NC}"
    echo -e "${MAGENTA}==============================${NC}\n"
    
    local version=""
    local version_type=""
    local include_notes=false
    local deploy_env=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--version) version="$2"; shift 2 ;;
            -t|--type) version_type="$2"; shift 2 ;;
            -n|--notes) include_notes=true; shift ;;
            -d|--deploy) deploy_env="$2"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            *) echo "Unknown option: $1"; usage; exit 1 ;;
        esac
    done
    
    # Determine version
    local current_version=$(get_current_version)
    info "Current version: $current_version"
    
    if [ -n "$version" ]; then
        info "Target version: $version"
    elif [ -n "$version_type" ]; then
        version=$(calculate_next_version "$current_version" "$version_type")
        info "Calculated version ($version_type bump): $version"
    else
        version=$(calculate_next_version "$current_version" "patch")
        info "Default version (patch bump): $version"
    fi
    
    # Run quality gates
    run_quality_gates
    
    # Update changelog
    update_changelog "$version"
    
    # Create deployment unit
    local deploy_file=$(create_deployment_unit "$version" "$deploy_env")
    
    # Summary
    echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✅ Release preparation complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    
    echo -e "\n${YELLOW}📋 Next Steps:${NC}"
    echo "  1. Review CHANGELOG.md"
    echo "  2. Review deployment unit: $deploy_file"
    echo "  3. Create git tag: git tag -a v$version -m 'Release $version'"
    echo "  4. Push changes: git push && git push --tags"
    echo ""
}

main "$@"
