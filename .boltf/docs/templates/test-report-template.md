# Test Report

> **BOLT Framework Stage:** VALIDATE - Quality Assurance

**Report ID:** TR-{FEATURE_ID}-{DATE}
**Feature:** {FEATURE_ID} - {FEATURE_NAME}
**Test Cycle:** {cycle number}
**Environment:** {Development | Staging | Production}
**Date:** {DATE}
**Tester:** {NAME}
**Status:** [Pass | Fail | Partial]

---

## 1. Executive Summary

### Overview

{Brief summary of testing performed and overall results}

### Verdict

- [ ] **PASS** - Ready for release
- [ ] **PASS WITH ISSUES** - Minor issues, can release with known issues
- [ ] **FAIL** - Critical issues found, requires fixes

### Key Metrics

| Metric              | Value | Target | Status |
| ------------------- | ----- | ------ | ------ |
| Test Cases Executed | {n}   | {n}    | ✅/❌  |
| Test Cases Passed   | {n}   | {n}    | ✅/❌  |
| Test Cases Failed   | {n}   | 0      | ✅/❌  |
| Pass Rate           | {%}   | ≥95%   | ✅/❌  |
| Code Coverage       | {%}   | ≥80%   | ✅/❌  |
| Critical Bugs       | {n}   | 0      | ✅/❌  |
| High Bugs           | {n}   | 0      | ✅/❌  |

---

## 2. Test Scope

### In Scope

- {feature/functionality 1}
- {feature/functionality 2}
- {feature/functionality 3}

### Out of Scope

- {excluded item 1}
- {excluded item 2}

### Test Types Performed

- [x] Unit Tests
- [x] Integration Tests
- [x] API Tests
- [ ] UI Tests
- [x] Security Tests
- [ ] Performance Tests
- [ ] Accessibility Tests

---

## 3. Test Results by Category

### Unit Tests

| Suite     | Total   | Passed  | Failed  | Skipped | Coverage |
| --------- | ------- | ------- | ------- | ------- | -------- |
| {suite}   | {n}     | {n}     | {n}     | {n}     | {%}      |
| {suite}   | {n}     | {n}     | {n}     | {n}     | {%}      |
| **Total** | **{n}** | **{n}** | **{n}** | **{n}** | **{%}**  |

### Integration Tests

| Suite     | Total   | Passed  | Failed  | Skipped |
| --------- | ------- | ------- | ------- | ------- |
| {suite}   | {n}     | {n}     | {n}     | {n}     |
| **Total** | **{n}** | **{n}** | **{n}** | **{n}** |

### API Tests

| Endpoint             | Method | Tests   | Passed  | Failed  |
| -------------------- | ------ | ------- | ------- | ------- |
| `/api/v1/{resource}` | GET    | {n}     | {n}     | {n}     |
| `/api/v1/{resource}` | POST   | {n}     | {n}     | {n}     |
| **Total**            | -      | **{n}** | **{n}** | **{n}** |

### E2E Tests

| Scenario   | Browser | Status | Duration |
| ---------- | ------- | ------ | -------- |
| {scenario} | Chrome  | ✅/❌  | {s}      |
| {scenario} | Firefox | ✅/❌  | {s}      |

---

## 4. Test Case Results

### Functional Tests

| TC-ID  | Test Case        | Priority | Status  | Notes              |
| ------ | ---------------- | -------- | ------- | ------------------ |
| TC-001 | {test case name} | High     | ✅ Pass | -                  |
| TC-002 | {test case name} | High     | ❌ Fail | BUG-001            |
| TC-003 | {test case name} | Medium   | ✅ Pass | -                  |
| TC-004 | {test case name} | Medium   | ⏭️ Skip | Blocked by BUG-001 |
| TC-005 | {test case name} | Low      | ✅ Pass | -                  |

### Non-Functional Tests

| TC-ID   | Test Case                | Type        | Target | Actual | Status |
| ------- | ------------------------ | ----------- | ------ | ------ | ------ |
| NFT-001 | Response time under load | Performance | <200ms | {x}ms  | ✅/❌  |
| NFT-002 | Concurrent users         | Load        | 100    | {x}    | ✅/❌  |
| NFT-003 | SQL injection prevention | Security    | Pass   | Pass   | ✅     |
| NFT-004 | XSS prevention           | Security    | Pass   | Pass   | ✅     |

---

## 5. Defects Found

### Summary

| Severity    | Open    | Fixed   | Verified | Won't Fix |
| ----------- | ------- | ------- | -------- | --------- |
| 🔴 Critical | {n}     | {n}     | {n}      | {n}       |
| 🟠 High     | {n}     | {n}     | {n}      | {n}       |
| 🟡 Medium   | {n}     | {n}     | {n}      | {n}       |
| 🟢 Low      | {n}     | {n}     | {n}      | {n}       |
| **Total**   | **{n}** | **{n}** | **{n}**  | **{n}**   |

### Defect Details

#### BUG-001: {Bug Title}

| Attribute       | Value                                      |
| --------------- | ------------------------------------------ |
| **Severity**    | 🔴 Critical / 🟠 High / 🟡 Medium / 🟢 Low |
| **Status**      | Open / In Progress / Fixed / Verified      |
| **Found In**    | TC-{id}                                    |
| **Assignee**    | {name}                                     |
| **Environment** | {env}                                      |

**Description:**
{What is the bug}

**Steps to Reproduce:**

1. {step 1}
2. {step 2}
3. {step 3}

**Expected Result:**
{What should happen}

**Actual Result:**
{What actually happened}

**Evidence:**
{Screenshot/log reference}

---

#### BUG-002: {Bug Title}

| Attribute    | Value      |
| ------------ | ---------- |
| **Severity** | {severity} |
| **Status**   | {status}   |
| **Found In** | TC-{id}    |

**Description:**
{description}

---

## 6. Code Coverage Report

### Summary

| Metric             | Value | Target | Status |
| ------------------ | ----- | ------ | ------ |
| Line Coverage      | {%}   | ≥80%   | ✅/❌  |
| Branch Coverage    | {%}   | ≥75%   | ✅/❌  |
| Function Coverage  | {%}   | ≥85%   | ✅/❌  |
| Statement Coverage | {%}   | ≥80%   | ✅/❌  |

### Coverage by Module

| Module               | Lines | Branches | Functions |
| -------------------- | ----- | -------- | --------- |
| `src/domain`         | {%}   | {%}      | {%}       |
| `src/application`    | {%}   | {%}      | {%}       |
| `src/infrastructure` | {%}   | {%}      | {%}       |
| `src/presentation`   | {%}   | {%}      | {%}       |

### Uncovered Areas

- `{file}:{lines}` - {reason}
- `{file}:{lines}` - {reason}

---

## 7. Performance Test Results

### Response Time

| Endpoint                | Avg  | P50  | P95  | P99  | Max  |
| ----------------------- | ---- | ---- | ---- | ---- | ---- |
| GET /api/v1/{resource}  | {ms} | {ms} | {ms} | {ms} | {ms} |
| POST /api/v1/{resource} | {ms} | {ms} | {ms} | {ms} | {ms} |

### Load Test

| Scenario    | Users | Duration | Throughput | Errors |
| ----------- | ----- | -------- | ---------- | ------ |
| Normal load | {n}   | {min}    | {rps}      | {%}    |
| Peak load   | {n}   | {min}    | {rps}      | {%}    |
| Stress test | {n}   | {min}    | {rps}      | {%}    |

---

## 8. Security Test Results

### OWASP Top 10 Check

| Vulnerability                  | Status     | Notes                     |
| ------------------------------ | ---------- | ------------------------- |
| A01: Broken Access Control     | ✅ Pass    | -                         |
| A02: Cryptographic Failures    | ✅ Pass    | -                         |
| A03: Injection                 | ✅ Pass    | -                         |
| A04: Insecure Design           | ✅ Pass    | -                         |
| A05: Security Misconfiguration | ✅ Pass    | -                         |
| A06: Vulnerable Components     | ⚠️ Warning | {dependency} needs update |
| A07: Auth Failures             | ✅ Pass    | -                         |
| A08: Integrity Failures        | ✅ Pass    | -                         |
| A09: Logging Failures          | ✅ Pass    | -                         |
| A10: SSRF                      | ✅ Pass    | -                         |

### Dependency Vulnerabilities

| Package   | Current   | Severity     | Fixed In  | Action |
| --------- | --------- | ------------ | --------- | ------ |
| {package} | {version} | High/Med/Low | {version} | Update |

---

## 9. Test Environment

### Configuration

| Component   | Version   | Configuration |
| ----------- | --------- | ------------- |
| Application | {version} | {config}      |
| Database    | {version} | {config}      |
| OS          | {version} | -             |

### Test Data

- Test data set: {name/version}
- Data seeding: {method}

---

## 10. Recommendations

### Must Fix Before Release

1. {critical issue 1}
2. {critical issue 2}

### Should Fix (Can Release With)

1. {issue 1}
2. {issue 2}

### Future Improvements

1. {improvement 1}
2. {improvement 2}

---

## 11. Sign-Off

| Role          | Name   | Date   | Signature |
| ------------- | ------ | ------ | --------- |
| QA Lead       | {name} | {date} | ☐         |
| Dev Lead      | {name} | {date} | ☐         |
| Product Owner | {name} | {date} | ☐         |

---

## 12. Appendices

### A. Test Execution Log

{Link to detailed test execution log}

### B. Screenshots/Evidence

{Links to evidence folder}

### C. Raw Test Results

{Link to CI/CD pipeline or test runner output}

---

*Generated by Bolt Testing Agent*
