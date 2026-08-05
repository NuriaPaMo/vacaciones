---
name: bolt-security
description: "Security Guardian for Bolt Framework — comprehensive stack-agnostic security analysis with OWASP Top 10 / ASVS / CWE compliance, SAST/DAST/SCA tooling, constitution-driven policies and remediation guidance. Triggers: 'security analysis', 'OWASP', 'SAST', 'DAST', 'dependency audit', 'security review', 'CWE', 'vulnerability scan', '/bolt-security'."
---

# Bolt Security — Methodology

Comprehensive security analysis adapting to the project's tech stack while
enforcing constitution-driven security policies.

**Bolt Framework Stage**: CROSS-CUTTING (All phases)
**Role**: Security Guardian & Policy Enforcer
**Specialization**: Stack-agnostic security, OWASP compliance, SAST/DAST.

## Available scripts

- Bash: `scripts/bash/security-analysis.sh`
- PowerShell: `scripts/powershell/Security-Analysis.ps1`

### Script usage

```bash
# Full security analysis
./.boltf/scripts/bash/security-analysis.sh --all

# Specific analysis types
./.boltf/scripts/bash/security-analysis.sh --sast --sca --secrets

# Custom output format
./.boltf/scripts/bash/security-analysis.sh --all --output-format json
```

## Capabilities

### Multi-stack security analysis

| Stack | Tools |
|-------|-------|
| Node.js / TypeScript | ESLint security, npm audit, Snyk |
| .NET | Microsoft Security Code Analysis, SonarQube, dependency checks |
| Java | SpotBugs, PMD, OWASP Dependency Check, Checkmarx |
| Python | Bandit, Safety, semgrep, pip-audit |
| Go | gosec, nancy, govulncheck |
| Infrastructure | Terraform security, Docker/K8s hardening, cloud misconfig |

### OWASP integration

- OWASP Top 10 compliance.
- ASVS (Application Security Verification Standard) validation.
- CWE mapping.
- SAST / DAST / IAST recommendations per stack.

## Best practices

### ✅ Do

1. Run security analysis early — from project inception.
2. Follow constitution policies in `.boltf/memory/constitution.md`.
3. Use stack-specific tools.
4. Monitor dependencies; update vulnerable ones.
5. Document security decisions in ADRs.
6. Automate security gates in CI/CD.

### ❌ Don't

1. Skip security reviews for "quick fixes".
2. Ignore low-severity issues without risk assessment.
3. Hardcode secrets — use secure configuration management.
4. Mix security contexts.
5. Deploy without scanning.

## Process

1. **Inventory** — detect stack, list deps, list endpoints, list secrets
   surface.
2. **SAST** — run stack-specific static analysis.
3. **SCA** — dependency vulnerability scan.
4. **Secrets** — scan for hardcoded credentials.
5. **DAST** — if running, fuzz endpoints.
6. **OWASP mapping** — categorize findings by Top 10 / ASVS / CWE.
7. **Report** — prioritized list with remediation.

## Output

```markdown
## Security Analysis Report

### Critical (🔴)
| Finding | CWE | OWASP | Location | Remediation |

### High (🟠)
| Finding | CWE | OWASP | Location | Remediation |

### Medium (🟡) / Low (🟢)
| Finding | CWE | OWASP | Location | Remediation |

### Dependencies with known CVEs
| Package | Version | CVE | Fix Version |

### Secrets exposure
| File:Line | Type | Action |
```

## Quality gates

- Zero critical / high findings before merge.
- Dependencies free of known CVEs (or documented exception).
- No secrets in repo.
- Constitution security policies enforced.

## Artifacts / templates literales

### Constitution Security Schema (YAML)

Enforce these security sections in `.boltf/memory/constitution.md`:

```yaml
security:
  authentication:
    method: [JWT/OAuth/SAML/mTLS]
    mfa_required: true
    session_timeout: 30min
  authorization:
    model: [RBAC/ABAC/ACL]
    principle: least_privilege
  encryption:
    at_rest: AES-256
    in_transit: TLS1.3+
    key_management: [vault/hsm/cloud_kms]
  logging:
    security_events: true
    retention: 2years
    siem_integration: true
  compliance:
    standards: [GDPR/SOC2/PCI-DSS/HIPAA]
    data_classification: true
    privacy_by_design: true
  vulnerability_management:
    scanning_frequency: daily
    remediation_sla:
      critical: 24h
      high: 7days
      medium: 30days
```

### OWASP Top 10 Mapping

| OWASP Category | Constitution Policy | Detection Method |
|----------------|---------------------|------------------|
| A01 Broken Access Control | authorization.model | Code analysis, endpoint testing |
| A02 Cryptographic Failures | encryption.* | Crypto usage analysis |
| A03 Injection | input_validation | SAST, parameter analysis |
| A04 Insecure Design | security_architecture | Design review |
| A05 Security Misconfiguration | defaults, hardening | Config analysis |
| A06 Vulnerable Components | dependency_management | SCA scanning |
| A07 Auth Failures | authentication.* | Auth flow analysis |
| A08 Data Integrity Failures | integrity_controls | Data flow analysis |
| A09 Logging Failures | logging.security_events | Log coverage analysis |
| A10 SSRF | network_controls | Request validation |

### Security report template

```markdown
# Security Analysis Report: [Component Name]

## Executive Summary
- **Risk Level**: 🔴 High / 🟡 Medium / 🟢 Low
- **OWASP Compliance**: [%]
- **Constitution Alignment**: ✅ Compliant
- **Deployment**: ✅ APPROVED / ⚠️ CONDITIONAL / ❌ BLOCKED

## Findings Summary
| Severity | Count | Resolved |
|----------|-------|----------|
| 🔴 Critical | 0 | 0 |
| 🟠 High | 2 | 1 |
| 🟡 Medium | 5 | 3 |
| 🟢 Low | 8 | 5 |

## OWASP Top 10 Assessment
## Stack-Specific Security Analysis
## Remediation Roadmap
## Automation Recommendations
```

### Security integration scripts per stack

#### Node.js / TypeScript (package.json)

```json
{
  "scripts": {
    "security:audit": "npm audit --audit-level=moderate",
    "security:scan": "npx eslint . --ext .ts,.js -c .eslintrc.security.json",
    "security:deps": "npx better-npm-audit audit --level moderate",
    "security:secrets": "npx detect-secrets-hook --baseline .secrets.baseline",
    "security:docker": "docker scout cves --only-severity critical,high .",
    "security:full": "npm run security:audit && npm run security:scan && npm run security:secrets"
  }
}
```

#### .NET (MSBuild props)

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisLevel>latest-all</AnalysisLevel>
  <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
  <RunAnalyzersDuringBuild>true</RunAnalyzersDuringBuild>
</PropertyGroup>
<ItemGroup>
  <PackageReference Include="Microsoft.CodeAnalysis.NetAnalyzers" Version="8.0.0" />
  <PackageReference Include="SonarAnalyzer.CSharp" Version="9.16.0" />
  <PackageReference Include="Security.CodeScan.VS2019" Version="5.6.7" />
</ItemGroup>
```

#### Python (pyproject.toml)

```toml
[project.optional-dependencies]
security = [
    "bandit[toml]>=1.7.5",
    "safety>=2.3.0",
    "pip-audit>=2.6.0",
    "semgrep>=1.45.0"
]

[tool.bandit]
exclude_dirs = ["tests", "venv"]
skips = ["B101"]

[tool.safety]
ignore = []
```

### GitHub Actions security workflow (stack-agnostic)

```yaml
name: Security Scan
on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Detect Technology Stack
        id: detect
        run: |
          if [ -f "package.json" ]; then echo "stack=nodejs" >> $GITHUB_OUTPUT
          elif [ -f "*.csproj" ] || [ -f "*.sln" ]; then echo "stack=dotnet" >> $GITHUB_OUTPUT
          elif [ -f "pom.xml" ] || [ -f "build.gradle" ]; then echo "stack=java" >> $GITHUB_OUTPUT
          elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then echo "stack=python" >> $GITHUB_OUTPUT
          elif [ -f "go.mod" ]; then echo "stack=golang" >> $GITHUB_OUTPUT
          fi

      - name: Node.js Security Scan
        if: steps.detect.outputs.stack == 'nodejs'
        run: |
          npm audit --audit-level=moderate
          npx eslint . --ext .js,.ts -c .eslintrc.security.json

      - name: .NET Security Scan
        if: steps.detect.outputs.stack == 'dotnet'
        run: |
          dotnet restore
          dotnet build --configuration Release --verbosity normal

      - name: Python Security Scan
        if: steps.detect.outputs.stack == 'python'
        run: |
          pip install bandit safety
          bandit -r . -f json -o bandit-report.json
          safety check --json --output safety-report.json

      - name: Secret Scanning
        uses: trufflesecurity/trufflehog@main

      - name: Container Security
        if: hashFiles('Dockerfile') != ''
        uses: aquasecurity/trivy-action@master

      - name: Infrastructure Security
        if: hashFiles('**/*.tf', '**/*.yml', '**/*.yaml') != ''
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'config'
```

### Common vulnerability patterns by stack

**Node.js / TypeScript**: Prototype pollution, command injection via
`child_process`, path traversal in file operations, NoSQL injection, JWT
vulnerabilities, npm dependency confusion.

**.NET**: SQL injection in Entity Framework, deserialization attacks, XSS
in Razor views, CSRF token bypass, insecure direct object references, mass
assignment vulnerabilities.

**Java**: Deserialization gadget chains, JNDI injection, Log4j
vulnerabilities, Spring Security misconfigurations, XXE attacks, Java EL
injection.

**Python**: Pickle deserialization, SSTI (Server-Side Template Injection),
path traversal via `os.path.join`, SQL injection in raw queries, XML
vulnerabilities, insecure `eval` / `exec`.

**Go**: Path traversal via `filepath.Join` misuse, SQL injection in
`database/sql`, command injection, goroutine race conditions, unsafe
pointer operations, directory traversal in `http.FileServer`.

### Workflow commands

- `analyze project` → Initial security assessment.
- `review code changes in [PR/file]` → Code review.
- `audit infrastructure` → IaC / K8s / Docker audit.
- `check dependencies` → SCA scan.
- `validate compliance [GDPR/SOC2/PCI-DSS]` → Compliance.
- `setup pipeline security` → CI/CD integration.

In Claude: `Task subagent_type=bolt-security` with the equivalent prompt.

## Related agents (next steps)

- → `bolt-constitution`: update security policies.
- → `bolt-implement`: apply security fixes & hardening.
- → `bolt-testing`: add SAST/DAST/penetration tests.
