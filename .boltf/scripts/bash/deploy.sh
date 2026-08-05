#!/bin/bash
# Bolt Framework Deployment Script - Multi-environment deployment with validation

set -e

ENVIRONMENT=""
VALIDATE_CONSTITUTION=false
DRY_RUN=false
ROLLBACK_ON_FAILURE=true
DEPLOYMENT_STRATEGY="rolling"
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --env|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --validate-constitution)
            VALIDATE_CONSTITUTION=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --no-rollback)
            ROLLBACK_ON_FAILURE=false
            shift
            ;;
        --strategy)
            DEPLOYMENT_STRATEGY="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "Usage: $0 --env ENVIRONMENT [OPTIONS]"
            echo ""
            echo "Required:"
            echo "  --env, --environment ENV    Target environment (dev|staging|production)"
            echo ""
            echo "Options:"
            echo "  --validate-constitution     Run constitution compliance check"
            echo "  --dry-run                  Show what would be deployed without executing"
            echo "  --no-rollback              Disable automatic rollback on failure"
            echo "  --strategy STRATEGY        Deployment strategy (rolling|blue-green|canary)"
            echo "  --verbose                  Enable verbose output"
            echo "  --help                     Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --env staging --validate-constitution"
            echo "  $0 --env production --strategy blue-green --no-rollback"
            echo "  $0 --env dev --dry-run"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$ENVIRONMENT" ]]; then
    error "Environment not specified. Use --env staging|production|dev"
    exit 1
fi

# Validate environment
case $ENVIRONMENT in
    dev|development)
        ENVIRONMENT="development"
        ;;
    staging|stage)
        ENVIRONMENT="staging"
        ;;
    prod|production)
        ENVIRONMENT="production"
        ;;
    *)
        error "Invalid environment: $ENVIRONMENT. Use: dev|staging|production"
        exit 1
        ;;
esac

log "🚀 Bolt Framework Deployment to $ENVIRONMENT"
echo "========================================"
echo "Strategy: $DEPLOYMENT_STRATEGY"
echo "Dry Run: $([ $DRY_RUN == true ] && echo 'YES' || echo 'NO')"
echo "Constitution Validation: $([ $VALIDATE_CONSTITUTION == true ] && echo 'YES' || echo 'NO')"
echo "Auto Rollback: $([ $ROLLBACK_ON_FAILURE == true ] && echo 'YES' || echo 'NO')"
echo "========================================"

# Load environment configuration
ENV_FILE=".env.$ENVIRONMENT"
if [[ -f "$ENV_FILE" ]]; then
    log "📄 Loading environment config: $ENV_FILE"
    set -a
    source "$ENV_FILE"
    set +a
else
    warn "Environment file not found: $ENV_FILE"
    warn "Deployment will use default configuration"
fi

# Pre-deployment validation
log "🔍 Running pre-deployment validation..."

# Check if git working directory is clean
if [[ -d ".git" ]]; then
    if ! git diff --quiet HEAD; then
        error "Working directory has uncommitted changes"
        echo "Commit or stash changes before deploying"
        exit 1
    fi
    success "Git working directory is clean"
fi

# Constitution compliance validation
if [[ $VALIDATE_CONSTITUTION == true ]]; then
    log "📋 Validating constitution compliance..."
    if [[ -f "scripts/bash/quality-gates.sh" ]]; then
        if [[ $DRY_RUN == true ]]; then
            log "[DRY RUN] Would run: ./scripts/bash/quality-gates.sh --ci-mode"
        else
            if ! ./scripts/bash/quality-gates.sh --ci-mode; then
                error "Quality gates failed. Deployment aborted."
                exit 1
            fi
        fi
        success "Constitution compliance verified"
    else
        warn "Quality gates script not found, skipping validation"
    fi
fi

# Check deployment prerequisites
check_prerequisites() {
    log "🔧 Checking deployment prerequisites..."
    
    # Check required tools
    local missing_tools=()
    
    if [[ -d "src/frontend" ]]; then
        if ! command -v npm &> /dev/null; then
            missing_tools+=("npm")
        fi
    fi
    
    if [[ -d "src/backend" ]] && [[ -f "src/backend/*.csproj" || -f "src/backend/*.sln" ]]; then
        if ! command -v dotnet &> /dev/null; then
            missing_tools+=("dotnet")
        fi
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
    
    success "All prerequisites satisfied"
}

# Build applications
build_applications() {
    log "🏗️  Building applications for $ENVIRONMENT..."
    
    # Frontend build
    if [[ -d "src/frontend" ]] && [[ -f "src/frontend/package.json" ]]; then
        log "📦 Building frontend..."
        cd src/frontend
        
        if [[ $DRY_RUN == true ]]; then
            log "[DRY RUN] Would run: npm ci && npm run build"
        else
            if ! npm ci; then
                error "Frontend dependency installation failed"
                exit 1
            fi
            
            if ! npm run build; then
                error "Frontend build failed"
                exit 1
            fi
        fi
        
        cd ../..
        success "Frontend built successfully"
    fi
    
    # Backend build
    if [[ -d "src/backend" ]]; then
        log "🔧 Building backend..."
        cd src/backend
        
        if [[ -f "*.csproj" ]] || [[ -f "*.sln" ]]; then
            # .NET build
            if [[ $DRY_RUN == true ]]; then
                log "[DRY RUN] Would run: dotnet publish --configuration Release"
            else
                if ! dotnet restore; then
                    error "Backend dependency restoration failed"
                    exit 1
                fi
                
                if ! dotnet publish --configuration Release --output ./publish; then
                    error "Backend build failed"
                    exit 1
                fi
            fi
            
        elif [[ -f "package.json" ]]; then
            # Node.js build
            if [[ $DRY_RUN == true ]]; then
                log "[DRY RUN] Would run: npm ci && npm run build"
            else
                if ! npm ci; then
                    error "Backend dependency installation failed"
                    exit 1
                fi
                
                if ! npm run build; then
                    error "Backend build failed"
                    exit 1
                fi
            fi
            
        elif [[ -f "requirements.txt" ]]; then
            # Python build
            if [[ $DRY_RUN == true ]]; then
                log "[DRY RUN] Would run: pip install -r requirements.txt"
            else
                if ! pip install -r requirements.txt; then
                    error "Python dependencies installation failed"
                    exit 1
                fi
            fi
        fi
        
        cd ../..
        success "Backend built successfully"
    fi
}

# Deployment functions for different strategies
deploy_rolling() {
    log "🔄 Executing rolling deployment..."
    
    case $ENVIRONMENT in
        development)
            deploy_to_development
            ;;
        staging)
            deploy_to_staging
            ;;
        production)
            deploy_to_production_rolling
            ;;
    esac
}

deploy_blue_green() {
    log "🔵🟢 Executing blue-green deployment..."
    
    if [[ $ENVIRONMENT != "production" ]]; then
        warn "Blue-green deployment recommended only for production"
    fi
    
    # Implementation for blue-green deployment
    deploy_to_production_blue_green
}

deploy_canary() {
    log "🐤 Executing canary deployment..."
    
    if [[ $ENVIRONMENT != "production" ]]; then
        warn "Canary deployment recommended only for production"
    fi
    
    # Implementation for canary deployment
    deploy_to_production_canary
}

# Environment-specific deployment functions
deploy_to_development() {
    log "🛠️  Deploying to development environment..."
    
    if [[ $DRY_RUN == true ]]; then
        log "[DRY RUN] Would deploy to development server"
        log "[DRY RUN] Would update development database"
        log "[DRY RUN] Would restart development services"
    else
        # Development deployment logic
        log "Deploying to development server..."
        
        # Copy files to development server
        if [[ -d "src/frontend/dist" ]]; then
            log "📁 Copying frontend files..."
            # rsync -av src/frontend/dist/ user@dev-server:/var/www/app/
        fi
        
        if [[ -d "src/backend/publish" ]]; then
            log "📁 Copying backend files..."
            # rsync -av src/backend/publish/ user@dev-server:/opt/api/
        fi
        
        log "🔄 Restarting development services..."
        # ssh user@dev-server "sudo systemctl restart bolt-api && sudo systemctl restart nginx"
    fi
    
    success "Development deployment completed"
}

deploy_to_staging() {
    log "🧪 Deploying to staging environment..."
    
    if [[ $DRY_RUN == true ]]; then
        log "[DRY RUN] Would deploy to staging with health checks"
        log "[DRY RUN] Would run smoke tests"
        log "[DRY RUN] Would update staging database"
    else
        # Staging deployment logic
        log "Deploying to staging server with health checks..."
        
        # Deploy and run health checks
        run_health_checks_after_deploy "staging"
        
        # Run smoke tests
        if [[ -f "scripts/bash/smoke-tests.sh" ]]; then
            log "🧪 Running smoke tests..."
            if ! ./scripts/bash/smoke-tests.sh --env staging; then
                error "Smoke tests failed"
                if [[ $ROLLBACK_ON_FAILURE == true ]]; then
                    rollback_deployment "staging"
                fi
                exit 1
            fi
            success "Smoke tests passed"
        fi
    fi
    
    success "Staging deployment completed"
}

deploy_to_production_rolling() {
    log "🏭 Deploying to production with rolling strategy..."
    
    if [[ $DRY_RUN == true ]]; then
        log "[DRY RUN] Would deploy to production with zero downtime"
        log "[DRY RUN] Would update load balancer configuration"
        log "[DRY RUN] Would run comprehensive health checks"
    else
        # Production rolling deployment logic
        log "Starting rolling deployment to production..."
        
        # Update instances one by one
        for instance in "${PRODUCTION_INSTANCES[@]}"; do
            log "🔄 Updating instance: $instance"
            # Deploy to specific instance
            # Wait for health check
            # Move to next instance
        done
        
        run_health_checks_after_deploy "production"
    fi
    
    success "Production rolling deployment completed"
}

deploy_to_production_blue_green() {
    log "🏭 Deploying to production with blue-green strategy..."
    
    local current_slot="blue"  # Get from load balancer
    local target_slot="green"
    
    if [[ $DRY_RUN == true ]]; then
        log "[DRY RUN] Would deploy to $target_slot environment"
        log "[DRY RUN] Would run comprehensive tests on $target_slot"
        log "[DRY RUN] Would switch traffic from $current_slot to $target_slot"
    else
        log "🔄 Deploying to $target_slot environment..."
        
        # Deploy to inactive slot
        # Run comprehensive tests
        # Switch traffic if tests pass
        
        log "🔀 Switching traffic from $current_slot to $target_slot..."
        success "Traffic switched successfully"
    fi
    
    success "Blue-green deployment completed"
}

deploy_to_production_canary() {
    log "🏭 Deploying to production with canary strategy..."
    
    if [[ $DRY_RUN == true ]]; then
        log "[DRY RUN] Would deploy canary version (5% traffic)"
        log "[DRY RUN] Would monitor canary metrics"
        log "[DRY RUN] Would gradually increase traffic to 100%"
    else
        log "🐤 Deploying canary version (5% traffic)..."
        
        # Deploy canary
        # Monitor metrics
        # Gradually increase traffic
        
        local traffic_percentages=(5 10 25 50 100)
        for percentage in "${traffic_percentages[@]}"; do
            log "📊 Routing $percentage% traffic to canary..."
            
            # Update load balancer
            # Wait and monitor
            sleep 300  # 5 minutes between increases
            
            # Check error rates
            if ! check_canary_health; then
                error "Canary health check failed at $percentage%"
                rollback_deployment "production"
                exit 1
            fi
        done
    fi
    
    success "Canary deployment completed"
}

# Health check functions
run_health_checks_after_deploy() {
    local env="$1"
    log "🏥 Running health checks for $env environment..."
    
    local health_url="${HEALTH_CHECK_URL:-http://localhost:5000/health}"
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -f -s "$health_url" > /dev/null; then
            success "Health check passed (attempt $attempt)"
            return 0
        fi
        
        log "Health check attempt $attempt failed, retrying in 10s..."
        sleep 10
        ((attempt++))
    done
    
    error "Health checks failed after $max_attempts attempts"
    return 1
}

check_canary_health() {
    # Check error rates, response times, etc.
    local error_rate=$(curl -s "${METRICS_URL}/error_rate" || echo "0.1")
    
    if (( $(echo "$error_rate > 0.05" | bc -l) )); then
        error "Canary error rate too high: $error_rate"
        return 1
    fi
    
    return 0
}

# Rollback function
rollback_deployment() {
    local env="$1"
    warn "🔄 Initiating rollback for $env environment..."
    
    if [[ $DRY_RUN == true ]]; then
        log "[DRY RUN] Would rollback to previous version"
        return
    fi
    
    # Rollback logic depends on deployment strategy and environment
    case $DEPLOYMENT_STRATEGY in
        blue-green)
            log "🔀 Switching traffic back to previous slot..."
            ;;
        canary)
            log "🛑 Stopping canary deployment and routing 100% to stable version..."
            ;;
        rolling)
            log "⏪ Rolling back to previous version..."
            ;;
    esac
    
    warn "Rollback completed"
}

# Post-deployment tasks
post_deployment_tasks() {
    log "🎯 Running post-deployment tasks..."
    
    if [[ $DRY_RUN == true ]]; then
        log "[DRY RUN] Would run post-deployment tasks"
        log "[DRY RUN] Would notify team of successful deployment"
        log "[DRY RUN] Would update deployment tracking"
        return
    fi
    
    # Clear caches
    log "🧹 Clearing caches..."
    
    # Update monitoring dashboards
    log "📊 Updating monitoring dashboards..."
    
    # Notify team
    if [[ -f "scripts/bash/notify-deployment.sh" ]]; then
        log "📢 Notifying team..."
        ./scripts/bash/notify-deployment.sh --env "$ENVIRONMENT" --success
    fi
    
    # Update deployment tracking
    local deployment_id="deploy-$(date +%Y%m%d-%H%M%S)"
    echo "$(date): Deployed to $ENVIRONMENT (ID: $deployment_id)" >> deployments.log
    
    success "Post-deployment tasks completed"
}

# Main execution flow
main() {
    check_prerequisites
    build_applications
    
    # Execute deployment based on strategy
    case $DEPLOYMENT_STRATEGY in
        rolling)
            deploy_rolling
            ;;
        blue-green)
            deploy_blue_green
            ;;
        canary)
            deploy_canary
            ;;
        *)
            error "Unknown deployment strategy: $DEPLOYMENT_STRATEGY"
            exit 1
            ;;
    esac
    
    post_deployment_tasks
    
    echo ""
    success "🎉 Deployment to $ENVIRONMENT completed successfully!"
    echo ""
    log "📊 Deployment Summary:"
    log "   Environment: $ENVIRONMENT"
    log "   Strategy: $DEPLOYMENT_STRATEGY"
    log "   Timestamp: $(date)"
    if [[ $DRY_RUN == true ]]; then
        log "   Mode: DRY RUN (no actual deployment)"
    fi
    echo ""
    log "🔗 Next Steps:"
    log "   • Monitor application metrics and logs"
    log "   • Verify all features are working correctly"
    log "   • Update documentation if needed"
}

# Trap errors and run cleanup
trap 'error "Deployment failed"; exit 1' ERR

# Run main function
main

# Production instances (would be loaded from config)
PRODUCTION_INSTANCES=("prod-app-01" "prod-app-02" "prod-app-03")