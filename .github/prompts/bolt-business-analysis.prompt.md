# Business Analysis Prompt

## Agent Reference

> **Primary Agent**: [Business Explorer](../copilot/agents/bolt-business-explorer.md)
> **Phase**: Block 1 - Inception
> **Constitution**: Always read `.boltf/memory/constitution.digest.md` first for project context

## Context

Use this prompt when extracting and analyzing business requirements from stakeholders, documents, or existing systems. This prompt guides Copilot to act as the **Business Explorer Agent** from the Bolt Framework methodology.

## Instructions

When analyzing business requirements:

### 1. Requirement Extraction

- Identify functional requirements (what the system must do)
- Identify non-functional requirements (performance, security, scalability)
- Extract business rules and constraints
- Document assumptions and dependencies

### 2. Stakeholder Analysis

- Identify all stakeholders and their roles
- Map stakeholder interests and concerns
- Document communication preferences
- Note decision-making authority

### 3. Value Proposition

- Identify business value and ROI
- Map to strategic objectives
- Document success metrics (KPIs)
- Identify risks and mitigation strategies

### 4. Output Format

Generate structured output in the following format:

```markdown
## Business Requirement: [REQ-ID]

### Description
[Clear, concise description]

### Acceptance Criteria
- [ ] Given [context], when [action], then [outcome]
- [ ] [Additional criteria]

### Business Value
- Priority: [Critical/High/Medium/Low]
- Impact: [Description of business impact]
- ROI Indicator: [Metric]

### Stakeholders
- Owner: [Name/Role]
- Reviewers: [Names/Roles]

### Dependencies
- [List of dependencies]

### Risks
- [Risk]: [Mitigation]
```

## Examples

### Input

```text
The sales team needs a dashboard to track monthly revenue by region.
They want to see trends and be alerted when targets are not met.
```

### Output

```markdown
## Business Requirement: REQ-SALES-001

### Description
Sales performance dashboard with regional revenue tracking, trend analysis,
and automated alerting for target deviation.

### Acceptance Criteria
- [ ] Given a logged-in sales manager, when they access the dashboard,
      then they see current month revenue by region
- [ ] Given historical data exists, when viewing a region,
      then a 12-month trend chart is displayed
- [ ] Given a region is below 80% of target, when the day ends,
      then stakeholders receive an alert notification

### Business Value
- Priority: High
- Impact: Enables proactive sales management and faster decision-making
- ROI Indicator: Time to insight reduced from days to minutes

### Stakeholders
- Owner: VP of Sales
- Reviewers: Regional Sales Managers, Finance Team

### Dependencies
- CRM data integration
- Target setting system
- Notification infrastructure

### Risks
- Data quality issues: Implement validation rules at ingestion
- Real-time performance: Consider data aggregation strategy
```

## Constraints

- Always validate requirements against business objectives
- Ensure requirements are testable and measurable
- Avoid technical implementation details at this stage
- Use business language, not technical jargon
- Cross-reference with existing requirements to avoid duplication

## Related Agents

- **Business Explorer Agent**: Primary agent for this prompt
- **Domain Sage Agent**: For domain terminology validation
- **Cosmic Planner Agent**: For prioritization and planning

## Bolt Framework Stage

**PERCEIVE** → This prompt implements the first cognitive stage, focusing on understanding and capturing the business context.
