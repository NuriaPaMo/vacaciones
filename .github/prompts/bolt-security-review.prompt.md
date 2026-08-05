# Security Review Prompt

## Agent Reference

> **Primary Agent**: [Policy Guardian](../copilot/agents/bolt-policy-guardian.md)
> **Phase**: Cross-Cutting (All Phases)
> **Constitution**: Enforces `.boltf/memory/constitution.md` security policies

## Context

Use this prompt when reviewing code, configurations, or infrastructure for security and compliance. This prompt guides Copilot to act as the **Policy Guardian Agent** from the Bolt Framework methodology.

## Instructions

When performing security reviews:

### 1. Constitution as Policy Source

- **READ** `.boltf/memory/constitution.digest.md` for security policies
- Enforce all security standards defined
- Check compliance requirements (GDPR, SOC2, PCI-DSS, etc.)
- Verify tech stack matches approved technologies

### 2. Review Scope

- **Code**: Injection, auth, crypto, data exposure
- **Config**: Secrets, permissions, defaults
- **Infrastructure**: Network, access, encryption
- **Dependencies**: Vulnerabilities, licenses

### 3. Severity Levels

- 🔴 **Critical**: Immediate exploitation risk
- 🟠 **High**: Significant security weakness
- 🟡 **Medium**: Should be addressed soon
- 🟢 **Low**: Minor issue or improvement

### 4. Output Format

```markdown
# Security Review Report: [Component/PR Name]

## Summary
| Severity | Count |
|----------|-------|
| 🔴 Critical | X |
| 🟠 High | X |
| 🟡 Medium | X |
| 🟢 Low | X |

**Overall Status**: ❌ FAIL / ⚠️ CONDITIONAL / ✅ PASS

## Constitution Compliance

| Policy | Status | Notes |
|--------|--------|-------|
| Authentication | ✅/❌ | [Details] |
| Authorization | ✅/❌ | [Details] |
| Encryption | ✅/❌ | [Details] |
| Logging | ✅/❌ | [Details] |

## Findings

### 🔴 CRITICAL-001: [Finding Title]

**Location**: `path/to/file.cs:123`

**Description**:
[What the vulnerability is]

**Risk**:
[What could happen if exploited]

**Evidence**:
```csharp
// Vulnerable code
var query = $"SELECT * FROM users WHERE id = {userId}";
```

**Remediation**:

```csharp
// Secure code
var query = "SELECT * FROM users WHERE id = @userId";
cmd.Parameters.AddWithValue("@userId", userId);
```

**References**:

- OWASP: [Link]
- CWE: [CWE-ID]

---

### 🟠 HIGH-001: [Finding Title]

...

### 🟡 MEDIUM-001: [Finding Title]

...

### 🟢 LOW-001: [Finding Title]

...

## OWASP Top 10 Check

| Category | Status | Findings |
|----------|--------|----------|
| A01 Broken Access Control | ✅/❌ | [Notes] |
| A02 Cryptographic Failures | ✅/❌ | [Notes] |
| A03 Injection | ✅/❌ | [Notes] |
| A04 Insecure Design | ✅/❌ | [Notes] |
| A05 Security Misconfiguration | ✅/❌ | [Notes] |
| A06 Vulnerable Components | ✅/❌ | [Notes] |
| A07 Auth Failures | ✅/❌ | [Notes] |
| A08 Data Integrity Failures | ✅/❌ | [Notes] |
| A09 Logging Failures | ✅/❌ | [Notes] |
| A10 SSRF | ✅/❌ | [Notes] |

## Dependency Audit

| Package | Version | Vulnerability | Severity | Fix Version |
|---------|---------|---------------|----------|-------------|
| [pkg] | 1.0.0 | CVE-XXXX-YYYY | High | 1.0.1 |

## Secrets Scan

| Type | Location | Status |
|------|----------|--------|
| API Key | Found in config.json | 🔴 EXPOSED |
| Password | Hardcoded in code | 🔴 EXPOSED |
| Connection String | Environment variable | ✅ Secure |

## Recommendations

### Immediate (Block Release)

1. [Critical fix required]
2. [Critical fix required]

### Before Production

1. [High priority fix]
2. [High priority fix]

### Future Improvements

1. [Nice to have]

```text

## Examples

### Input: Code Review
```csharp
public class UserController : ControllerBase
{
    private readonly string _connectionString = "Server=prod;User=admin;Password=P@ssw0rd!";

    [HttpGet("/users/{id}")]
    public async Task<User> GetUser(string id)
    {
        var query = $"SELECT * FROM Users WHERE Id = '{id}'";
        var user = await _db.QueryAsync(query);
        return user;
    }

    [HttpPost("/login")]
    public async Task<IActionResult> Login(LoginDto dto)
    {
        var user = await _userService.ValidateUser(dto.Username, dto.Password);
        if (user != null)
        {
            return Ok(new { token = GenerateToken(user) });
        }
        return Unauthorized("Invalid username or password");
    }
}
```

### Expected Findings

```markdown
## Findings

### 🔴 CRITICAL-001: Hardcoded Credentials
**Location**: `UserController.cs:3`
**Risk**: Production database credentials exposed in source code
**Remediation**: Use environment variables or Azure Key Vault

### 🔴 CRITICAL-002: SQL Injection
**Location**: `UserController.cs:8`
**Risk**: User input directly interpolated into SQL query
**Remediation**: Use parameterized queries

### 🟡 MEDIUM-001: User Enumeration
**Location**: `UserController.cs:17`
**Risk**: Different response for valid vs invalid users
**Remediation**: Use generic "Invalid credentials" message
```

### Input: Infrastructure Review

```yaml
# kubernetes deployment
apiVersion: apps/v1
kind: Deployment
spec:
  containers:
  - name: api
    image: myapp:latest
    securityContext:
      runAsRoot: true
      privileged: true
    env:
    - name: DB_PASSWORD
      value: "secretpassword123"
    ports:
    - containerPort: 80
```

### Expected Findings

```markdown
### 🔴 CRITICAL-001: Container Running as Root
**Location**: `deployment.yaml:8-9`
**Remediation**: Set `runAsNonRoot: true`, `runAsUser: 1000`

### 🔴 CRITICAL-002: Privileged Container
**Location**: `deployment.yaml:9`
**Remediation**: Remove `privileged: true`

### 🔴 CRITICAL-003: Hardcoded Secret
**Location**: `deployment.yaml:12`
**Remediation**: Use Kubernetes Secrets or external vault

### 🟠 HIGH-001: Using 'latest' Tag
**Location**: `deployment.yaml:7`
**Remediation**: Use specific version tags for reproducibility
```

## Specific Review Scenarios

### Pre-Commit Review

```text
Quick security check on these changes:
[DIFF]

Focus on:
- New secrets or credentials
- Injection vulnerabilities
- Auth/authz changes
- Data exposure
```

### Dependency Update Review

```text
Review security implications of updating:
- [package] from v1.0 to v2.0

Check:
- Known vulnerabilities fixed
- New vulnerabilities introduced
- Breaking security changes
- License changes
```

### Compliance Audit

```text
Full compliance review against [STANDARD]:
- GDPR / PCI-DSS / SOC2 / HIPAA

Check all relevant artifacts and generate compliance report.
```

## Integration Points

- **Input from**: All agents (code, config, infra artifacts)
- **Output to**: `coding-agent.md` (fixes), `release-orchestrator.md` (go/no-go)
- **Artifacts**: `docs/security/review-reports/`, `docs/security/audit-trail.md`
