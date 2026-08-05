# 🔒 Bolt Security Agent - Complete Guide

> **Bolt Framework v2.2.0** - Comprehensive Security Integration Guide

## Table of Contents

1. [Overview](#overview)
2. [Agent Usage](#agent-usage)
3. [Security Analysis Scripts](#security-analysis-scripts)
4. [CI/CD Integration](#cicd-integration)
5. [Constitution Integration](#constitution-integration)
6. [Technology Stack Support](#technology-stack-support)
7. [Security Tools Integration](#security-tools-integration)
8. [Compliance Standards](#compliance-standards)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)

---

## Overview

The Bolt Security Agent is a comprehensive security orchestration system designed to integrate security analysis throughout the BOLT Framework development lifecycle. It provides:

- **Stack-Agnostic Security Analysis**: Automatically detects technology stack and applies appropriate security tools
- **OWASP Top 10 Compliance**: Built-in checks for all OWASP Top 10 vulnerabilities
- **Multi-Layer Security**: SAST, SCA, secrets scanning, infrastructure security
- **Constitution-Driven Policies**: Security policies defined in `.boltf/memory/constitution.md`
- **Automated CI/CD Integration**: GitHub Actions workflow for continuous security monitoring
- **Comprehensive Reporting**: Detailed security reports with actionable recommendations

### Architecture

```text
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Constitution  │────│  Bolt Security │────│   CI/CD Pipeline│
│   (Policies)    │    │     Agent        │    │   (Automation)  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ Stack Detection │    │ Security Analysis│    │ Report Generation│
│ - Node.js       │    │ - SAST (Static)  │    │ - OWASP Mapping │
│ - .NET          │    │ - SCA (Deps)     │    │ - Recommendations│
│ - Java          │    │ - Secrets        │    │ - Compliance    │
│ - Python        │    │ - Infrastructure │    │ - Artifacts     │
│ - Go            │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

---

## Agent Usage

### Basic Commands

Invoke the Bolt Security Agent using the `@Bolt Security` handle:

```text
@Bolt Security --analyze [OPTIONS]
@Bolt Security --validate-constitution
@Bolt Security --generate-report
@Bolt Security --setup-ci
```

### Common Usage Patterns

#### 1. Full Security Analysis

```text
@Bolt Security --analyze --all --severity medium --compliance owasp
```

#### 2. Quick SAST Check

```text
@Bolt Security --analyze --sast --stack nodejs
```

#### 3. Dependency Vulnerability Scan

```text
@Bolt Security --analyze --sca --auto-fix
```

#### 4. Infrastructure Security Review

```text
@Bolt Security --analyze --infrastructure --include-iac
```

#### 5. Constitution Validation

```text
@Bolt Security --validate-constitution --enforce-policies
```

### Advanced Options

| Option         | Description                | Example                |
| -------------- | -------------------------- | ---------------------- |
| `--stack`      | Override auto-detection    | `--stack dotnet`       |
| `--severity`   | Minimum severity threshold | `--severity high`      |
| `--compliance` | Compliance framework       | `--compliance pci-dss` |
| `--exclude`    | Exclude patterns           | `--exclude test/**`    |
| `--output`     | Output format              | `--output sarif`       |
| `--ci-mode`    | CI/CD optimized mode       | `--ci-mode`            |

---

## Security Analysis Scripts

### Local Analysis Scripts

Two equivalent scripts are provided for cross-platform support:

#### Bash Script (Linux/macOS/WSL)

```bash
# Full analysis
./scripts/bash/security-analysis.sh --all --severity medium

# Stack-specific analysis
./scripts/bash/security-analysis.sh --stack nodejs --sast --sca

# Constitution-driven analysis
./scripts/bash/security-analysis.sh --constitution .boltf/memory/constitution.md
```

#### PowerShell Script (Windows/Cross-platform)

```powershell
# Full analysis
.\scripts\powershell\Security-Analysis.ps1 -All -Severity medium

# Stack-specific analysis
.\scripts\powershell\Security-Analysis.ps1 -Stack nodejs -Sast -Sca

# Constitution-driven analysis
.\scripts\powershell\Security-Analysis.ps1 -Constitution ".boltf/memory/constitution.md"
```

### Script Features

- **Automatic Stack Detection**: Reads constitution.md or analyzes project files
- **Technology-Specific Tools**: Uses appropriate security tools for each stack
- **Comprehensive Reporting**: Generates markdown reports with OWASP mapping
- **Artifact Generation**: Creates structured analysis results for CI/CD

---

## CI/CD Integration

### GitHub Actions Workflow

The provided GitHub Actions workflow (`.github/workflows/security-analysis.yml`) provides:

- **Automatic Trigger**: Runs on push, PR, and manual dispatch
- **Stack Detection**: Automatically identifies technology stack
- **Parallel Analysis**: SAST, SCA, secrets, and infrastructure scanning in parallel
- **Report Generation**: Creates comprehensive security reports
- **PR Comments**: Automatically comments security findings on pull requests
- **Artifact Upload**: Stores all security analysis results for review

#### Workflow Configuration

```yaml
# Enable security scanning
on:
  push:
    branches: [main, master, develop]
  pull_request:
    branches: [main, master, develop]
  workflow_dispatch:
    inputs:
      severity_threshold:
        description: 'Minimum severity (critical|high|medium|low)'
        default: 'medium'
```

#### Custom Workflow Usage

To customize the security workflow for your project:

1. **Copy the workflow file**:

   ```bash
   cp .github/workflows/security-analysis.yml .github/workflows/security.yml
   ```

2. **Customize configuration**:

   ```yaml
   env:
     SEVERITY_THRESHOLD: 'high' # Adjust threshold
     COMPLIANCE_STANDARD: 'pci-dss' # Set compliance framework
     CONSTITUTION_PATH: '.boltf/memory/constitution.md'
   ```

3. **Add secrets** (if using commercial tools):
   - `SEMGREP_APP_TOKEN`: For Semgrep Pro features
   - `SNYK_TOKEN`: For Snyk integration
   - `SONARCLOUD_TOKEN`: For SonarCloud integration

### Azure Pipelines Integration

For Azure DevOps pipelines:

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include: [main, develop]

pool:
  vmImage: 'ubuntu-latest'

stages:
  - stage: SecurityAnalysis
    displayName: 'Security Analysis'
    jobs:
      - job: RunSecurityScan
        displayName: 'Run Security Scan'
        steps:
          - checkout: self

          - script: |
              chmod +x scripts/bash/security-analysis.sh
              ./scripts/bash/security-analysis.sh --all --ci-mode
            displayName: 'Run Bolt Security Analysis'

          - task: PublishTestResults@2
            inputs:
              testResultsFormat: 'JUnit'
              testResultsFiles: 'reports/security/**/*.xml'
              testRunTitle: 'Security Analysis Results'
```

---

## Constitution Integration

### Security Configuration

Add security policies to your `.boltf/memory/constitution.md`:

```yaml
security:
  policy:
    enabled: true
    enforcement_level: 'strict'
    compliance_frameworks: ['owasp-top-10']

  static_analysis:
    enabled: true
    tools:
      nodejs: ['eslint-security', 'semgrep']
      dotnet: ['microsoft-code-analysis', 'sonaranalyzer']

  dependency_scanning:
    enabled: true
    auto_update: 'security-only'

  secrets_management:
    enabled: true
    vault_provider: 'azure-keyvault'
```

### Template Usage

Use the provided template to get started:

```bash
# Copy security configuration template
cp .boltf/docs/templates/constitution-security-template.yml security-config.yml

# Merge into your constitution
cat security-config.yml >> .boltf/memory/constitution.md
```

### Validation

Validate your constitution security configuration:

```bash
@Bolt Security --validate-constitution --strict
```

---

## Technology Stack Support

### Node.js / JavaScript / TypeScript

**Security Tools**:

- **ESLint**: Security-focused linting rules
- **npm audit**: Native dependency vulnerability scanning
- **Semgrep**: Static analysis with JavaScript/TypeScript rules
- **yarn audit**: Alternative dependency scanning for Yarn projects

**Configuration**:

```json
// .eslintrc.json
{
  "extends": ["eslint:recommended"],
  "plugins": ["security"],
  "rules": {
    "security/detect-object-injection": "error",
    "security/detect-non-literal-regexp": "warn"
  }
}
```

**Key Security Considerations**:

- Prototype pollution vulnerabilities
- Command injection through user input
- XSS in client-side code
- Dependency confusion attacks

### .NET / C#

**Security Tools**:

- **Microsoft Code Analysis**: Built-in .NET security analyzers
- **SonarAnalyzer**: Advanced static analysis
- **Semgrep**: Cross-platform static analysis
- **dotnet list package --vulnerable**: Native vulnerability scanning

**Configuration**:

```xml
<!-- Directory.Build.props -->
<Project>
  <PropertyGroup>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.CodeAnalysis.NetAnalyzers" Version="8.0.0">
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
  </ItemGroup>
</Project>
```

**Key Security Considerations**:

- Deserialization vulnerabilities
- SQL injection in Entity Framework
- XSS in Razor views
- CSRF protection

### Java / Spring

**Security Tools**:

- **SpotBugs**: Static analysis for Java
- **PMD**: Source code analyzer
- **OWASP Dependency Check**: Vulnerability scanning
- **Semgrep**: Modern static analysis

**Configuration**:

```xml
<!-- pom.xml -->
<plugin>
  <groupId>com.github.spotbugs</groupId>
  <artifactId>spotbugs-maven-plugin</artifactId>
  <version>4.7.3</version>
</plugin>
```

**Key Security Considerations**:

- Deserialization attacks
- SQL injection
- Path traversal
- XML external entity (XXE) attacks

### Python

**Security Tools**:

- **Bandit**: Security-focused static analyzer for Python
- **Safety**: Dependency vulnerability scanner
- **pip-audit**: Official pip security scanner
- **Semgrep**: Modern static analysis

**Configuration**:

```toml
# pyproject.toml
[tool.bandit]
exclude_dirs = ["tests"]
skips = ["B101", "B601"]
```

**Key Security Considerations**:

- Code injection vulnerabilities
- Deserialization attacks
- Server-side template injection (SSTI)
- Path traversal

### Go / Golang

**Security Tools**:

- **gosec**: Security analyzer for Go
- **go vet**: Built-in Go analyzer
- **govulncheck**: Official vulnerability database
- **Semgrep**: Cross-platform analysis

**Configuration**:

```json
// .gosec.json
{
  "severity": "medium",
  "confidence": "medium",
  "exclude": ["G104"]
}
```

**Key Security Considerations**:

- Command injection
- Path traversal
- Race conditions
- Memory safety issues

---

## Security Tools Integration

### SAST (Static Application Security Testing)

| Tool                | Languages             | Integration         | Features                            |
| ------------------- | --------------------- | ------------------- | ----------------------------------- |
| **Semgrep**         | Multi-language        | GitHub Actions, CLI | Rule customization, SARIF output    |
| **ESLint Security** | JavaScript/TypeScript | npm, CI/CD          | Real-time analysis, IDE integration |
| **Bandit**          | Python                | pip, CI/CD          | Security-focused, configurable      |
| **gosec**           | Go                    | go install, CI/CD   | Go-specific vulnerabilities         |
| **SonarCloud**      | Multi-language        | GitHub Actions      | Quality gates, tech debt            |

### SCA (Software Composition Analysis)

| Tool                       | Package Managers | Features                      |
| -------------------------- | ---------------- | ----------------------------- |
| **npm audit**              | npm, yarn        | Native Node.js integration    |
| **Safety**                 | pip, pipenv      | Python vulnerability database |
| **OWASP Dependency Check** | Maven, Gradle    | Multi-language support        |
| **Snyk**                   | Multi-language   | Commercial, advanced features |
| **GitHub Dependabot**      | Multi-language   | Native GitHub integration     |

### Secrets Detection

| Tool                | Features             | Integration       |
| ------------------- | -------------------- | ----------------- |
| **TruffleHog**      | Git history scanning | GitHub Actions    |
| **GitLeaks**        | Real-time detection  | Pre-commit hooks  |
| **Azure Key Vault** | Secrets management   | Azure integration |
| **HashiCorp Vault** | Enterprise secrets   | Multi-cloud       |

### Infrastructure Security

| Tool             | Target     | Features                |
| ---------------- | ---------- | ----------------------- |
| **tfsec**        | Terraform  | Static analysis for IaC |
| **Checkov**      | Multi-IaC  | Policy as code          |
| **Docker Bench** | Docker     | Container security      |
| **kube-bench**   | Kubernetes | CIS benchmarks          |

---

## Compliance Standards

### OWASP Top 10 2021

| Category                             | Coverage  | Automation            | Tools                      |
| ------------------------------------ | --------- | --------------------- | -------------------------- |
| **A01: Broken Access Control**       | Partial   | Manual review + SAST  | Constitution policies      |
| **A02: Cryptographic Failures**      | Good      | SAST + Infrastructure | Pattern matching, IaC scan |
| **A03: Injection**                   | Excellent | SAST tools            | All language-specific SAST |
| **A04: Insecure Design**             | Manual    | Architecture review   | Constitution validation    |
| **A05: Security Misconfiguration**   | Good      | Infrastructure scan   | IaC tools, container scan  |
| **A06: Vulnerable Components**       | Excellent | SCA tools             | All dependency scanners    |
| **A07: Authentication Failures**     | Good      | SAST + Manual         | Code analysis + review     |
| **A08: Software/Data Integrity**     | Manual    | Design review         | Constitution compliance    |
| **A09: Security Logging**            | Partial   | Pattern matching      | Log analysis tools         |
| **A10: Server-Side Request Forgery** | Good      | SAST tools            | Code analysis              |

### Additional Compliance Frameworks

#### PCI DSS (Payment Card Industry)

- Encryption requirements validation
- Access control verification
- Network security scanning
- Audit logging compliance

#### GDPR (General Data Protection Regulation)

- Data classification validation
- Privacy by design checks
- Consent management verification
- Right to be forgotten compliance

#### HIPAA (Healthcare)

- PHI data handling verification
- Encryption compliance
- Access audit trails
- Breach notification procedures

---

## Troubleshooting

### Common Issues

#### 1. Stack Detection Problems

**Problem**: "Unable to detect technology stack"

**Solutions**:

```bash
# Explicitly specify stack
./scripts/bash/security-analysis.sh --stack nodejs

# Check constitution.md format
@Bolt Security --validate-constitution

# Verify project structure
ls -la package.json *.csproj go.mod requirements.txt
```

#### 2. Tool Installation Failures

**Problem**: Security tools not found

**Solutions**:

```bash
# Node.js tools
npm install -g @semgrep/semgrep eslint

# Python tools
pip install bandit safety pip-audit

# Go tools
go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest

# .NET tools (via NuGet packages in Directory.Build.props)
```

#### 3. CI/CD Pipeline Failures

**Problem**: GitHub Actions workflow failing

**Solutions**:

1. Check GitHub Actions logs for specific errors
2. Verify required secrets are configured
3. Ensure setup-stack action has correct permissions
4. Test scripts locally first

#### 4. False Positives in Security Scans

**Problem**: Too many false positive security alerts

**Solutions**:

```yaml
# Add exclusions to constitution.md
security:
  static_analysis:
    rules:
      exclude_patterns:
        - 'test/**'
        - '**/*.test.*'

  dependency_scanning:
    exclusions:
      - package: 'lodash'
        reason: 'Dev dependency only'
        expires: '2024-12-31'
```

#### 5. Report Generation Issues

**Problem**: Security report not generated properly

**Solutions**:

1. Check write permissions to `reports/security/` directory
2. Verify all analysis steps completed successfully
3. Run report generation separately:

   ```bash
   ./scripts/bash/security-analysis.sh --generate-report-only
   ```

### Debug Mode

Enable debug mode for detailed troubleshooting:

```bash
# Bash
DEBUG=1 ./scripts/bash/security-analysis.sh --all

# PowerShell
$env:DEBUG="1"; .\scripts\powershell\Security-Analysis.ps1 -All
```

---

## Best Practices

### Development Workflow

1. **Pre-commit Security Checks**

   ```bash
   # Setup pre-commit hooks
   pip install pre-commit
   pre-commit install

   # Add security checks to .pre-commit-config.yaml
   repos:
   - repo: local
     hooks:
     - id: bolt-security-check
       name: Bolt Security Check
       entry: ./scripts/bash/security-analysis.sh --sast --secrets
   ```

2. **IDE Integration**
   - Configure security-focused linting rules
   - Install security plugins for your IDE
   - Enable real-time vulnerability detection

3. **Regular Security Reviews**

   ```bash
   # Weekly dependency updates
   @Bolt Security --analyze --sca --auto-update

   # Monthly comprehensive analysis
   @Bolt Security --analyze --all --compliance owasp
   ```

### Security Policy Management

1. **Constitution-Driven Security**
   - Define security policies in `.boltf/memory/constitution.md`
   - Version control all security configurations
   - Regular policy reviews and updates

2. **Risk-Based Approach**

   ```yaml
   # Prioritize based on risk
   security:
     thresholds:
       critical_vulnerabilities: 0 # Zero tolerance
       high_vulnerabilities: 2 # Limited acceptance
       medium_vulnerabilities: 10 # Managed risk
   ```

3. **Continuous Improvement**
   - Regular security tool updates
   - Threat model reviews
   - Security training integration

### Team Collaboration

1. **Security Champions Program**
   - Designate security champions in each team
   - Regular security training and updates
   - Security-focused code reviews

2. **Documentation Standards**
   - Document security decisions in ADRs
   - Maintain security runbooks
   - Regular security documentation reviews

3. **Incident Response**
   - Clear escalation procedures
   - Regular incident response drills
   - Post-incident learning integration

### Performance Optimization

1. **Efficient CI/CD Integration**
   - Cache security tool installations
   - Parallelize security analyses
   - Incremental scanning where possible

2. **Smart Scheduling**

   ```yaml
   # Different scan frequencies
   schedule:
     sast: 'every-commit'
     sca: 'daily'
     infrastructure: 'weekly'
     penetration-testing: 'quarterly'
   ```

3. **Result Caching**
   - Cache unchanged analysis results
   - Differential scanning approaches
   - Smart re-analysis triggers

---

## Support and Resources

### Getting Help

1. **Bolt Security Agent Documentation**
   - Agent usage: `.github/agents/bolt-security.agent.md`
   - Constitution templates: `.boltf/docs/templates/`
   - Security guide: `.boltf/docs/templates/bolt-security-complete-guide.md`

2. **Community Resources**
   - OWASP Top 10 Guide: <https://owasp.org/Top10/>
   - Security tool documentation
   - Industry security frameworks

3. **Professional Support**
   - Security consultant engagement
   - Penetration testing services
   - Compliance auditing

### Updates and Maintenance

Keep your security setup current:

```bash
# Update security tools
npm update -g @semgrep/semgrep
pip install --upgrade bandit safety
go install -a github.com/securecodewarrior/gosec/v2/cmd/gosec@latest

# Update GitHub Actions
# Check for updates to actions in .github/workflows/security-analysis.yml

# Review and update constitution security policies
@Bolt Security --validate-constitution --update-recommendations
```

---

*BOLT Framework Security Agent - Comprehensive security integration for modern development workflows*

**Version**: 2.2.0
**Last Updated**: December 2024
**Compatibility**: All BOLT Framework supported technology stacks
