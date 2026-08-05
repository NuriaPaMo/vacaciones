# RFP/Legacy Analysis Report

> **BOLT Framework Stage:** INCEPTION - Discovery & Analysis

**Document ID:** RFP-{ID}
**Project:** {PROJECT_NAME}
**Analyst:** {ANALYST_NAME}
**Date:** {DATE}
**Status:** [Draft | In Review | Approved]

---

## 1. Executive Summary

### Overview

{Brief description of the RFP or legacy system being analyzed}

### Key Findings

1. {finding 1}
2. {finding 2}
3. {finding 3}

### Recommendation

{Go/No-Go recommendation with brief justification}

---

## 2. Source Analysis

### Document Inventory

| Document   | Type          | Pages | Relevance       |
| ---------- | ------------- | ----- | --------------- |
| {doc name} | RFP/Spec/Code | {n}   | High/Medium/Low |

### Legacy System Inventory (if applicable)

| System   | Technology   | Age     | Status            |
| -------- | ------------ | ------- | ----------------- |
| {system} | {tech stack} | {years} | Active/Deprecated |

---

## 3. Requirements Extraction

### Functional Requirements

| ID     | Requirement   | Priority          | Complexity   | Source     |
| ------ | ------------- | ----------------- | ------------ | ---------- |
| FR-001 | {requirement} | Must/Should/Could | High/Med/Low | {doc:page} |

### Non-Functional Requirements

| ID      | Category    | Requirement   | Target     |
| ------- | ----------- | ------------- | ---------- |
| NFR-001 | Performance | {requirement} | {metric}   |
| NFR-002 | Security    | {requirement} | {standard} |
| NFR-003 | Scalability | {requirement} | {capacity} |

### Constraints

| ID    | Type       | Constraint   | Impact   |
| ----- | ---------- | ------------ | -------- |
| C-001 | Technical  | {constraint} | {impact} |
| C-002 | Business   | {constraint} | {impact} |
| C-003 | Regulatory | {constraint} | {impact} |

---

## 4. Technical Assessment

### Current Architecture (Legacy)

```text
{Mermaid diagram or description of existing architecture}
```

### Technology Stack Analysis

| Component | Current   | Proposed   | Migration Effort |
| --------- | --------- | ---------- | ---------------- |
| Language  | {current} | {proposed} | {effort}         |
| Database  | {current} | {proposed} | {effort}         |
| Framework | {current} | {proposed} | {effort}         |

### Code Quality Assessment

| Metric        | Current Value | Industry Standard | Gap   |
| ------------- | ------------- | ----------------- | ----- |
| Test Coverage | {%}           | 80%               | {gap} |
| Tech Debt     | {hours}       | -                 | -     |
| Complexity    | {score}       | <10               | {gap} |

### Data Migration Assessment

| Data Set  | Volume | Complexity   | Strategy       |
| --------- | ------ | ------------ | -------------- |
| {dataset} | {size} | High/Med/Low | ETL/CDC/Manual |

---

## 5. Risk Analysis

### Technical Risks

| Risk   | Probability  | Impact       | Mitigation   |
| ------ | ------------ | ------------ | ------------ |
| {risk} | High/Med/Low | High/Med/Low | {mitigation} |

### Business Risks

| Risk   | Probability  | Impact       | Mitigation   |
| ------ | ------------ | ------------ | ------------ |
| {risk} | High/Med/Low | High/Med/Low | {mitigation} |

### Dependencies

| Dependency   | Type              | Risk Level   | Owner   |
| ------------ | ----------------- | ------------ | ------- |
| {dependency} | External/Internal | High/Med/Low | {owner} |

---

## 6. Effort Estimation

### High-Level Estimate

| Phase       | Effort (Person-Days) | Duration    | Team Size |
| ----------- | -------------------- | ----------- | --------- |
| Discovery   | {days}               | {weeks}     | {people}  |
| Design      | {days}               | {weeks}     | {people}  |
| Development | {days}               | {weeks}     | {people}  |
| Testing     | {days}               | {weeks}     | {people}  |
| Deployment  | {days}               | {weeks}     | {people}  |
| **Total**   | **{days}**           | **{weeks}** | -         |

### Cost Estimate

| Category       | Estimate      | Notes   |
| -------------- | ------------- | ------- |
| Development    | ${amount}     | {notes} |
| Infrastructure | ${amount}     | {notes} |
| Licensing      | ${amount}     | {notes} |
| Training       | ${amount}     | {notes} |
| **Total**      | **${amount}** | -       |

---

## 7. Proposed Solution

### Architecture Overview

```mermaid
{Mermaid diagram of proposed architecture}
```

### Technology Recommendations

| Component   | Recommendation | Justification |
| ----------- | -------------- | ------------- |
| {component} | {technology}   | {why}         |

### Migration Strategy

- [ ] Big Bang
- [ ] Phased/Incremental
- [ ] Strangler Fig
- [ ] Parallel Run

### Implementation Phases

| Phase   | Scope   | Duration | Dependencies |
| ------- | ------- | -------- | ------------ |
| Phase 1 | {scope} | {weeks}  | {deps}       |
| Phase 2 | {scope} | {weeks}  | Phase 1      |

---

## 8. Go/No-Go Recommendation

### Scorecard

| Criteria              | Score (1-5) | Weight | Weighted Score |
| --------------------- | ----------- | ------ | -------------- |
| Technical Feasibility | {score}     | 25%    | {weighted}     |
| Business Value        | {score}     | 30%    | {weighted}     |
| Risk Level            | {score}     | 20%    | {weighted}     |
| Resource Availability | {score}     | 15%    | {weighted}     |
| Strategic Alignment   | {score}     | 10%    | {weighted}     |
| **Total**             | -           | 100%   | **{total}**    |

### Recommendation

- [ ] **GO** - Proceed with project
- [ ] **GO with conditions** - Proceed if {conditions}
- [ ] **NO-GO** - Do not proceed because {reasons}

### Next Steps

1. {step 1}
2. {step 2}
3. {step 3}

---

## 9. Appendices

### A. Glossary

| Term   | Definition   |
| ------ | ------------ |
| {term} | {definition} |

### B. References

| Document   | Location    |
| ---------- | ----------- |
| {document} | {link/path} |

### C. Interview Notes

| Stakeholder | Date   | Key Points |
| ----------- | ------ | ---------- |
| {name}      | {date} | {notes}    |

---

*Generated by Bolt Analyze Agent*
