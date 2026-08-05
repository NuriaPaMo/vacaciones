#!/bin/bash
# Bolt Framework Project Structure Generator from Constitution

set -e

CONSTITUTION_FILE=".boltf/memory/constitution.md"
PROJECT_TYPE=""
TECH_STACK=""
VERBOSE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --from-constitution)
            CONSTITUTION_FILE="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --from-constitution FILE    Constitution file to read (default: .boltf/memory/constitution.md)"
            echo "  --verbose                   Enable verbose output"
            echo "  --help                      Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

log() {
    if [[ $VERBOSE == true ]]; then
        echo "ℹ️  $1"
    fi
}

echo "🏗️  Bolt Framework Project Structure Generator"
echo "====================================="

# Check if constitution exists
if [[ ! -f "$CONSTITUTION_FILE" ]]; then
    echo "❌ Constitution file not found: $CONSTITUTION_FILE"
    echo "💡 Run './scripts/bash/init.sh' first to create project structure"
    exit 1
fi

log "📋 Reading constitution from $CONSTITUTION_FILE"

# Extract tech stack from constitution
TECH_STACK=$(grep -A 20 "Tech Stack\|Technologies" "$CONSTITUTION_FILE" | grep -E "(React|Vue|Angular|\.NET|Python|Node\.js|TypeScript|JavaScript)" | tr '\n' ',' | sed 's/,$//')

if [[ -z "$TECH_STACK" ]]; then
    echo "⚠️  Could not determine tech stack from constitution"
    echo "💡 Make sure your constitution has a 'Tech Stack' section with specific technologies"
    exit 1
fi

echo "📋 Detected tech stack: $TECH_STACK"

# Create base directory structure
log "📁 Creating base directory structure..."
mkdir -p src/{frontend,backend,shared,infrastructure}
mkdir -p tests/{unit,integration,e2e,performance}
mkdir -p docs/{api,architecture,deployment,user-guide}
mkdir -p scripts/{development,deployment,maintenance}
mkdir -p .vscode
mkdir -p .github/{workflows,templates}

# Generate structure based on detected tech stack
if [[ $TECH_STACK == *"React"* ]]; then
    echo "⚛️  Setting up React frontend structure..."

    mkdir -p src/frontend/{components,pages,hooks,services,styles,types,utils,contexts}
    mkdir -p src/frontend/components/{common,forms,layout,ui}
    mkdir -p tests/unit/frontend/{components,hooks,services}

    # Create package.json for React project
    cat > src/frontend/package.json << 'EOF'
{
  "name": "bolt-frontend",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "lint:fix": "eslint . --ext ts,tsx --fix",
    "preview": "vite preview",
    "test": "vitest",
    "test:coverage": "vitest --coverage",
    "type-check": "tsc --noEmit"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.8.1"
  },
  "devDependencies": {
    "@types/react": "^18.2.43",
    "@types/react-dom": "^18.2.17",
    "@typescript-eslint/eslint-plugin": "^6.14.0",
    "@typescript-eslint/parser": "^6.14.0",
    "@vitejs/plugin-react": "^4.2.1",
    "eslint": "^8.55.0",
    "eslint-plugin-react-hooks": "^4.6.0",
    "eslint-plugin-react-refresh": "^0.4.5",
    "typescript": "^5.2.2",
    "vite": "^5.0.8",
    "vitest": "^1.1.0",
    "@vitest/coverage-v8": "^1.1.0"
  }
}
EOF

    # Create Vite configuration
    cat > src/frontend/vite.config.ts << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:5000',
        changeOrigin: true,
        secure: false,
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
  },
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test-setup.ts'],
  },
})
EOF

    # Create TypeScript configuration
    cat > src/frontend/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF

    log "✅ React frontend structure created"
fi

if [[ $TECH_STACK == *"Vue"* ]]; then
    echo "🟢 Setting up Vue frontend structure..."

    mkdir -p src/frontend/{components,views,composables,services,styles,types,utils,stores}
    mkdir -p src/frontend/components/{base,forms,layout}
    mkdir -p tests/unit/frontend/{components,composables,services}

    # Create package.json for Vue project
    cat > src/frontend/package.json << 'EOF'
{
  "name": "bolt-vue-frontend",
  "version": "0.0.0",
  "private": true,
  "scripts": {
    "dev": "vite",
    "build": "vue-tsc && vite build",
    "preview": "vite preview",
    "test": "vitest",
    "test:coverage": "vitest --coverage",
    "lint": "eslint . --ext .vue,.js,.jsx,.cjs,.mjs,.ts,.tsx,.cts,.mts --fix --ignore-path .gitignore",
    "type-check": "vue-tsc --noEmit"
  },
  "dependencies": {
    "vue": "^3.3.4",
    "vue-router": "^4.2.4",
    "pinia": "^2.1.6"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^4.3.4",
    "@vue/eslint-config-typescript": "^11.0.3",
    "eslint": "^8.45.0",
    "eslint-plugin-vue": "^9.15.1",
    "typescript": "~5.1.6",
    "vite": "^4.4.5",
    "vitest": "^0.34.1",
    "vue-tsc": "^1.8.5"
  }
}
EOF

    log "✅ Vue frontend structure created"
fi

if [[ $TECH_STACK == *".NET"* ]]; then
    echo "🔵 Setting up .NET backend structure..."

    mkdir -p src/backend/{Controllers,Services,Models,Data,Extensions,Middleware,Configuration}
    mkdir -p tests/unit/backend/{Controllers,Services,Models}
    mkdir -p tests/integration/backend

    # Create .NET solution file
    cd src/backend
    dotnet new sln -n Bolt Framework
    dotnet new webapi -n Bolt Framework.Api
    dotnet sln add Bolt Framework.Api

    # Add common NuGet packages
    cd Bolt Framework.Api
    dotnet add package Microsoft.EntityFrameworkCore
    dotnet add package Microsoft.EntityFrameworkCore.Design
    dotnet add package Serilog.AspNetCore
    dotnet add package FluentValidation.AspNetCore
    dotnet add package Swashbuckle.AspNetCore

    cd ../../..

    log "✅ .NET backend structure created"
fi

if [[ $TECH_STACK == *"Python"* ]]; then
    echo "🐍 Setting up Python backend structure..."

    mkdir -p src/backend/{api,models,services,database,middleware,config}
    mkdir -p tests/unit/backend/{api,services,models}

    # Create requirements.txt
    cat > src/backend/requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
sqlalchemy==2.0.23
alembic==1.13.0
python-multipart==0.0.6
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
pytest==7.4.3
pytest-asyncio==0.21.1
httpx==0.25.2
EOF

    # Create Python project structure
    touch src/backend/{__init__.py,main.py}
    touch src/backend/api/__init__.py
    touch src/backend/models/__init__.py
    touch src/backend/services/__init__.py

    log "✅ Python backend structure created"
fi

if [[ $TECH_STACK == *"Node"* ]]; then
    echo "🟡 Setting up Node.js backend structure..."

    mkdir -p src/backend/{controllers,services,models,middleware,config,routes}
    mkdir -p tests/unit/backend/{controllers,services,models}

    # Create package.json for Node.js project
    cat > src/backend/package.json << 'EOF'
{
  "name": "bolt-backend",
  "version": "1.0.0",
  "description": "Bolt Framework Backend API",
  "main": "src/server.js",
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js",
    "test": "jest",
    "test:coverage": "jest --coverage",
    "lint": "eslint src/",
    "lint:fix": "eslint src/ --fix"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "morgan": "^1.10.0",
    "dotenv": "^16.3.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.1",
    "jest": "^29.7.0",
    "supertest": "^6.3.3",
    "eslint": "^8.53.0"
  }
}
EOF

    log "✅ Node.js backend structure created"
fi

# Create common configuration files
echo "⚙️  Creating configuration files..."

# Create .gitignore
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
*/node_modules/

# Build outputs
dist/
build/
*/dist/
*/build/

# Environment files
.env
.env.local
.env.production
.env.staging

# IDE files
.vscode/settings.json
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Logs
logs/
*.log
npm-debug.log*

# Coverage reports
coverage/
*.lcov

# .NET
bin/
obj/
*.user
*.suo

# Python
__pycache__/
*.pyc
*.pyo
.pytest_cache/
.coverage

# Database
*.db
*.sqlite

# Temporary files
.tmp/
temp/
EOF

# Create VS Code workspace settings
cat > .vscode/settings.json << 'EOF'
{
  "typescript.preferences.importModuleSpecifier": "relative",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "files.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/build": true
  },
  "search.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/build": true
  }
}
EOF

# Create development scripts
cat > scripts/development/setup.sh << 'EOF'
#!/bin/bash
# Development environment setup script

echo "🔧 Setting up development environment..."

# Install frontend dependencies
if [[ -f "src/frontend/package.json" ]]; then
    echo "📦 Installing frontend dependencies..."
    cd src/frontend
    npm install
    cd ../..
fi

# Install backend dependencies
if [[ -f "src/backend/package.json" ]]; then
    echo "📦 Installing backend dependencies..."
    cd src/backend
    npm install
    cd ../..
elif [[ -f "src/backend/requirements.txt" ]]; then
    echo "🐍 Installing Python dependencies..."
    cd src/backend
    pip install -r requirements.txt
    cd ../..
elif [[ -f "src/backend/Bolt Framework.sln" ]]; then
    echo "🔵 Restoring .NET dependencies..."
    cd src/backend
    dotnet restore
    cd ../..
fi

echo "✅ Development environment setup complete!"
EOF

chmod +x scripts/development/setup.sh

# Create README.md
cat > README.md << EOF
# $(basename "$(pwd)")

> BOLT-powered project with intelligent development lifecycle

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ (for frontend)
$(if [[ $TECH_STACK == *".NET"* ]]; then echo "- .NET 8+ SDK (for backend)"; fi)
$(if [[ $TECH_STACK == *"Python"* ]]; then echo "- Python 3.11+ (for backend)"; fi)
- Git

### Setup Development Environment
\`\`\`bash
# Setup everything automatically
./scripts/development/setup.sh

# Or manually:
$(if [[ $TECH_STACK == *"React"* ]] || [[ $TECH_STACK == *"Vue"* ]]; then
echo "cd src/frontend && npm install"
fi)
$(if [[ $TECH_STACK == *".NET"* ]]; then
echo "cd src/backend && dotnet restore"
fi)
$(if [[ $TECH_STACK == *"Python"* ]]; then
echo "cd src/backend && pip install -r requirements.txt"
fi)
\`\`\`

### Run Development Servers
\`\`\`bash
# Frontend (if exists)
$(if [[ $TECH_STACK == *"React"* ]] || [[ $TECH_STACK == *"Vue"* ]]; then
echo "cd src/frontend && npm run dev"
fi)

# Backend
$(if [[ $TECH_STACK == *".NET"* ]]; then
echo "cd src/backend/Bolt Framework.Api && dotnet run"
fi)
$(if [[ $TECH_STACK == *"Python"* ]]; then
echo "cd src/backend && uvicorn main:app --reload"
fi)
$(if [[ $TECH_STACK == *"Node"* ]]; then
echo "cd src/backend && npm run dev"
fi)
\`\`\`

## 🏗️ Architecture

Tech Stack: $TECH_STACK

\`\`\`
$(echo "Project Structure:")
├── src/
$(if [[ $TECH_STACK == *"React"* ]] || [[ $TECH_STACK == *"Vue"* ]]; then
echo "│   ├── frontend/     # Frontend application"
fi)
│   ├── backend/      # Backend API
│   └── shared/       # Shared utilities
├── tests/           # Test suites
├── docs/            # Documentation
└── scripts/         # Automation scripts
\`\`\`

## 📚 Documentation

- [API Documentation](docs/api/)
- [Architecture Decisions](docs/architecture/)
- [Deployment Guide](docs/deployment/)

## 🧪 Testing

\`\`\`bash
# Run all tests
./scripts/bash/run-tests.sh

# Run quality gates
./scripts/bash/quality-gates.sh
\`\`\`

## 🚀 Deployment

\`\`\`bash
# Deploy to staging
./scripts/bash/deploy.sh --env staging

# Deploy to production
./scripts/bash/deploy.sh --env production
\`\`\`

---

*Generated by Bolt Framework-DLC v2.1.0*
EOF

echo ""
echo "✅ Project structure generated successfully!"
echo ""
echo "📁 Created structure for: $TECH_STACK"
echo "📋 Based on constitution: $CONSTITUTION_FILE"
echo ""
echo "🎯 Next Steps:"
echo "   1. Run: ./scripts/development/setup.sh"
echo "   2. Start development servers as shown in README.md"
echo "   3. Run: ./scripts/bash/quality-gates.sh to validate setup"
echo ""
echo "🎉 Happy coding with Bolt Framework!"