# Bolt Framework Project Structure Generator from Constitution
# PowerShell equivalent of generate-project-structure.sh

[CmdletBinding()]
param(
    [string]$ConstitutionFile = "memory\constitution.md",
    [switch]$Verbose,
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: Generate-ProjectStructure.ps1 [OPTIONS]"
    Write-Host "Options:"
    Write-Host "  -ConstitutionFile FILE    Constitution file to read (default: memory\constitution.md)"
    Write-Host "  -Verbose                  Enable verbose output"
    Write-Host "  -Help                     Show this help message"
    exit 0
}

function Write-Log {
    param([string]$Message)
    if ($Verbose) {
        Write-Host "ℹ️  $Message" -ForegroundColor Cyan
    }
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

Write-Host "🏗️  Bolt Framework Project Structure Generator" -ForegroundColor Blue
Write-Host "=====================================" -ForegroundColor Blue

# Check if constitution exists
if (-not (Test-Path $ConstitutionFile)) {
    Write-Error "Constitution file not found: $ConstitutionFile"
    Write-Host "💡 Run 'Init.ps1' first to create project structure"
    exit 1
}

Write-Log "Reading constitution from: $ConstitutionFile"

# Parse constitution file
$constitution = Get-Content $ConstitutionFile -Raw
$projectType = ""
$techStack = ""

# Extract project information from constitution
if ($constitution -match "## 🎯 Project Type\s*.*?`r?`n- \[x\] (.+?)(?:`r?`n|$)") {
    $projectType = $Matches[1].Trim()
    Write-Log "Detected project type: $projectType"
}

if ($constitution -match "## 🛠️ Technology Stack\s*.*?`r?`n### Primary Stack\s*(.*?)(?:`r?`n##|$)" -or
    $constitution -match "### Primary Stack\s*(.*?)(?:`r?`n##|$)") {
    $stackSection = $Matches[1]
    if ($stackSection -match "- \[x\] (.+?)(?:`r?`n|$)") {
        $techStack = $Matches[1].Trim()
        Write-Log "Detected tech stack: $techStack"
    }
}

# Create base directory structure
Write-Log "Creating base directory structure..."

$directories = @(
    "src",
    "tests",
    "docs",
    "scripts",
    "reports",
    "reports\architecture",
    "reports\coverage",
    "reports\quality"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Log "Created directory: $dir"
    }
}

# Generate structure based on project type and tech stack
switch -Regex ($techStack) {
    "React.*\.NET|\.NET.*React" {
        Write-Log "Generating React + .NET structure..."

        # Frontend structure
        $frontendDirs = @(
            "src\frontend",
            "src\frontend\src",
            "src\frontend\src\components",
            "src\frontend\src\pages",
            "src\frontend\src\services",
            "src\frontend\src\utils",
            "src\frontend\src\types",
            "src\frontend\public",
            "tests\frontend"
        )

        # Backend structure
        $backendDirs = @(
            "src\backend",
            "src\backend\src",
            "src\backend\src\Domain",
            "src\backend\src\Application",
            "src\backend\src\Infrastructure",
            "src\backend\src\WebApi",
            "tests\backend",
            "tests\backend\Unit",
            "tests\backend\Integration"
        )

        ($frontendDirs + $backendDirs) | ForEach-Object {
            if (-not (Test-Path $_)) {
                New-Item -ItemType Directory -Path $_ -Force | Out-Null
                Write-Log "Created directory: $_"
            }
        }

        # Create frontend package.json if not exists
        $packageJsonPath = "src\frontend\package.json"
        if (-not (Test-Path $packageJsonPath)) {
            $packageJson = @{
                name = "bolt-frontend"
                version = "1.0.0"
                private = $true
                dependencies = @{
                    react = "^18.2.0"
                    "react-dom" = "^18.2.0"
                    "react-router-dom" = "^6.8.0"
                    axios = "^1.3.0"
                }
                devDependencies = @{
                    "@vitejs/plugin-react" = "^3.1.0"
                    vite = "^4.1.0"
                    "@types/react" = "^18.0.27"
                    "@types/react-dom" = "^18.0.10"
                    typescript = "^4.9.4"
                }
                scripts = @{
                    dev = "vite"
                    build = "vite build"
                    preview = "vite preview"
                    test = "vitest"
                }
            } | ConvertTo-Json -Depth 10

            Set-Content -Path $packageJsonPath -Value $packageJson -Encoding UTF8
            Write-Success "Created: $packageJsonPath"
        }
    }

    "Vue.*Python|Python.*Vue" {
        Write-Log "Generating Vue + Python structure..."

        $vueDirs = @(
            "src\frontend",
            "src\frontend\src",
            "src\frontend\src\components",
            "src\frontend\src\views",
            "src\frontend\src\router",
            "src\frontend\src\store",
            "src\frontend\public"
        )

        $pythonDirs = @(
            "src\backend",
            "src\backend\app",
            "src\backend\app\models",
            "src\backend\app\services",
            "src\backend\app\api",
            "src\backend\tests"
        )

        ($vueDirs + $pythonDirs) | ForEach-Object {
            if (-not (Test-Path $_)) {
                New-Item -ItemType Directory -Path $_ -Force | Out-Null
                Write-Log "Created directory: $_"
            }
        }
    }

    "Angular.*Node|Node.*Angular" {
        Write-Log "Generating Angular + Node.js structure..."

        $angularDirs = @(
            "src\frontend",
            "src\frontend\src",
            "src\frontend\src\app",
            "src\frontend\src\assets",
            "src\frontend\src\environments"
        )

        $nodeDirs = @(
            "src\backend",
            "src\backend\src",
            "src\backend\src\controllers",
            "src\backend\src\services",
            "src\backend\src\models",
            "src\backend\src\middleware"
        )

        ($angularDirs + $nodeDirs) | ForEach-Object {
            if (-not (Test-Path $_)) {
                New-Item -ItemType Directory -Path $_ -Force | Out-Null
                Write-Log "Created directory: $_"
            }
        }
    }

    default {
        Write-Log "Generating generic project structure..."

        $genericDirs = @(
            "src\core",
            "src\utils",
            "src\config",
            "tests\unit",
            "tests\integration"
        )

        $genericDirs | ForEach-Object {
            if (-not (Test-Path $_)) {
                New-Item -ItemType Directory -Path $_ -Force | Out-Null
                Write-Log "Created directory: $_"
            }
        }
    }
}

# Create common files
$commonFiles = @(
    @{ Path = ".gitignore"; Content = @"
# Dependencies
node_modules/
*/node_modules/

# Build outputs
dist/
build/
out/
bin/
obj/

# IDE
.vscode/
.idea/
*.swp
*.swo

# Logs
*.log
logs/

# Environment
.env
.env.local
.env.*.local

# Coverage
coverage/
*.coverage

# OS
.DS_Store
Thumbs.db
"@ },
    @{ Path = ".editorconfig"; Content = @"
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.{js,jsx,ts,tsx,vue,json,md}]
indent_style = space
indent_size = 2

[*.{cs,csproj,sln}]
indent_style = space
indent_size = 4

[*.py]
indent_style = space
indent_size = 4
"@ }
}

foreach ($file in $commonFiles) {
    if (-not (Test-Path $file.Path)) {
        Set-Content -Path $file.Path -Value $file.Content -Encoding UTF8
        Write-Success "Created: $($file.Path)"
    }
}

# Create README if not exists
$readmePath = "README.md"
if (-not (Test-Path $readmePath)) {
    $readmeContent = @"
# Bolt Framework Project

Generated by Bolt Framework v2.2.0

## Project Structure

This project follows the Bolt Framework methodology with:

- **Constitution-driven development**: All decisions guided by \`.boltf/memory/constitution.md\`
- **Feature-based organization**: Each feature in \`specs/\` directory
- **Quality gates**: Automated validation and testing
- **Documentation**: Living documentation that evolves with code

## Getting Started

1. Review the constitution: \`.boltf/memory/constitution.md\`
2. Create your first feature: \`@Bolt Framework Feature\`
3. Run quality gates: \`./scripts/bash/quality-gates.sh\`

## Bolt Framework Agents

Use these VS Code agents to accelerate development:

- \`@Bolt Framework\` - Main orchestrator
- \`@Bolt Framework Feature\` - Create new features
- \`@Bolt Framework Implement\` - Generate implementation
- \`@Bolt Framework Testing\` - Generate test suites
- \`@Bolt Framework Docs\` - Generate documentation

## Project Type

**Type**: $projectType
**Stack**: $techStack

---

Generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

    Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
    Write-Success "Created: $readmePath"
}

Write-Success "Project structure generated successfully!"
Write-Host ""
Write-Host "📁 Generated structure based on:"
Write-Host "   Type: $projectType"
Write-Host "   Stack: $techStack"
Write-Host ""
Write-Host "🚀 Next steps:"
Write-Host "   1. Review generated structure"
Write-Host "   2. Initialize git repository"
Write-Host "   3. Install dependencies"
Write-Host "   4. Create your first feature with @Bolt Framework Feature"
