# Clarification Summary

## Metadata

| Property     | Value                                     |
| ------------ | ----------------------------------------- |
| Project      | Vacation Management & Approval System     |
| Session Date | 2026-08-06                                |
| Features     | F-001 through F-007                       |
| Status       | Awaiting Stakeholder Response             |
| Source RFP   | `origin/RFP-Vacaciones.md`                |
| Source FRD   | `origin/Documento Funcional de Requisitos.html` |

---

## Category 1: Functional Clarification — Vacation Request Rules

### CL-001: Minimum Advance Days for Request Submission

**Original Statement** (RF-005, BR-002):
> "Start date must be >= today + 1 business day"

**Ambiguity**: Not confirmed by stakeholders. The 1-business-day minimum is an assumption.

**Questions**:

1. Can an employee submit a same-day vacation request? 
2. If not, what is the minimum advance notice required (1 day? 3 days? 1 week)? No, it will be needed 1 day.
3. Does the minimum vary by department or role?

**Blocker Level**: High — affects form validation logic in US-001
**Owner**: Business Stakeholder (Laura Sánchez)
**Affects**: F-001 (AC-001.1, BR-002)

---

### CL-002: Maximum Consecutive Vacation Days

**Original Statement**: Not specified in RFP or functional requirements.

**Ambiguity**: No maximum limit is defined. Is there a policy limit on consecutive days?

**Questions**:

1. Is there a maximum number of consecutive vacation days allowed per request? No
2. If so, does it vary by employee type (e.g., managers vs. individual contributors)?
3. Can an employee submit a 30-day vacation without restriction?

**Blocker Level**: Medium — affects validation rules in US-001
**Owner**: HR Operations (Laura Sánchez)
**Affects**: F-001 (BR-001)

---

### CL-003: Blackout Periods

**Original Statement**: Not mentioned in any source document.

**Ambiguity**: Are there periods where vacations cannot be requested (e.g., project deadlines, audit seasons)?

**Questions**:

1. Are there blackout periods when no vacations can be requested? No
2. If yes, who defines and manages them (admin? PM? DM?)?
3. Should the system enforce blackouts or just warn?

**Blocker Level**: Low — can be deferred to Phase 2 if not critical
**Owner**: Department Manager / HR
**Affects**: F-001 (UC-001 Step 9 validation)

---

### CL-004: "No Alternatives" Clarification

**Original Statement** (RF-014):
> "No se propondrán alternativas en el proceso."

**Ambiguity**: Not clear what "alternatives" means in context. Does it mean the system should NOT suggest alternative dates when a period is over-capacity?

**Questions**:

1. When a request is for an over-requested period, should the system suggest alternative dates? Yes
2. Or does RF-014 mean the system never proposes alternatives (employee must decide)?
3. Should over-capacity only be shown as a warning (no blocking)? Yes

**Blocker Level**: Medium — affects capacity visualization behavior
**Owner**: Business Stakeholder
**Affects**: F-003 (UC-009), F-002 (UC-004, UC-005)

---

## Category 2: Approval Workflow Clarification

### CL-005: PM as DM Self-Approval

**Original Statement**: Not addressed in RFP.

**Ambiguity**: What happens when a PM is also the DM? Do they self-approve at both levels?

**Questions**:

1. Can a PM who is also DM approve their own team's requests at both levels? Yes
2. Can a DM approve their own vacation request? (self-approval) Yes
3. If self-approval is not allowed, who approves the DM's vacation? 

**Blocker Level**: High — affects approval routing logic
**Owner**: Business Stakeholder
**Affects**: F-002 (US-004, US-005, BR-019)

---

### CL-006: Appeal Mechanism After Project-Level Rejection

**Original Statement** (BR-016):
> "Rejection at project level is final (no escalation to department)"

**Ambiguity**: Can an employee or DM override a project-level rejection?

**Questions**:

1. If the PM rejects a request, is that absolutely final? No
2. Can the employee appeal to the DM? Yes
3. Can the DM override a PM rejection (e.g., escalation path)? Yes

**Blocker Level**: Medium — affects workflow design
**Owner**: Business Stakeholder
**Affects**: F-002 (UC-004, UC-005)

---

### CL-007: Escalation Bypass Duration

**Original Statement** (BR-032):
> "DM can bypass project level on escalation"

**Ambiguity**: When escalation grants bypass authority to the DM, is it permanent or temporary?

**Questions**:

1. Once a request is escalated, does the DM permanently have authority over it? No
2. Or can the PM still approve after escalation (both can act)? Yes
3. What happens if the PM acts on the request after DM was alerted via escalation? This is not required for this phase.

**Blocker Level**: Medium — affects workflow state machine
**Owner**: Business Stakeholder
**Affects**: F-002 (US-007, UC-007)

---

### CL-008: Number of Approvers per Level

**Original Statement** (RF-023):
> "Cada solicitud debe estar aprobada por cada uno de los responsables antes de ser enviada a Service Now."

**Ambiguity** (RF-034):
> "En departamentos grandes (~50 personas) debe existir al menos un aprobador."

**Questions**:

1. Is it one PM approval per project, or can there be multiple PMs that ALL must approve? one PM approval.
2. For departments with multiple project managers, does only the employee's direct PM approve? Yes
3. Does the DM approve alone, or do multiple department managers exist? DM approve alone

**Blocker Level**: High — affects the entire approval chain design
**Owner**: Business Stakeholder
**Affects**: F-002 (UC-004, UC-005, BR-015 through BR-024)

---

### CL-009: Delegation Rules and Scope

**Original Statement** (RF-031, RF-035):
> "La aprobación debe poder delegarse a otras personas del mismo proyecto."

**Ambiguity**: Delegation rules are loosely defined.

**Questions**:

1. Can delegation be to anyone in the project, or only to designated backup approvers? only designated backup approvers
2. Can a PM delegate to an Employee (not another PM)? No
3. Is there a mandatory delegation when a PM goes on vacation (auto-trigger)? Yes
4. Can delegation include conditions (e.g., only for requests < 5 days)? No

**Blocker Level**: Medium — affects delegation entity design
**Owner**: Business Stakeholder
**Affects**: F-002 (US-006, UC-006, BR-025 through BR-029)

---

## Category 3: Data & Integration Clarification

### CL-010: Source of "Project" Information

**Original Statement** (RF-038, RF-039):
> "El sistema debe obtener la información de quién es el responsable de cada proyecto."

**Ambiguity**: Neither AD nor ServiceNow clearly defines "projects."

**Questions**:

1. Where does "project" information live? (AD groups? ServiceNow? Manual configuration?) 
2. If in AD, what attribute or group defines a project?
3. If not in AD, should the system have manual project management in the admin panel?
4. How is an employee assigned to a project? (Can they belong to multiple projects?)

**Blocker Level**: High — affects the entire organizational model and approval routing
**Owner**: Avanade IT (Carlos Martínez)
**Affects**: F-004 (US-012, US-013, UC-012, UC-013)

---

### CL-011: Department Manager Identification in AD

**Original Statement** (RF-002, RF-030):
> "El responsable del departamento debe poder aprobar."

**Ambiguity**: How is the DM identified in Active Directory?

**Questions**:

1. Is the DM identified by a specific AD attribute (title, group membership, manager chain root)?
2. Is there always exactly one DM per department?
3. Can there be multiple DMs (e.g., DM + deputy DM)?
4. If by AD group: what is the group naming convention?

**Blocker Level**: High — affects role assignment and sync logic
**Owner**: Avanade IT (Carlos Martínez)
**Affects**: F-004 (US-013, UC-013, BR-062)

---

### CL-012: ServiceNow Table and Field Mapping

**Original Statement** (RF-021):
> "El sistema debe enviar a Service Now el listado de vacaciones aprobadas."

**Ambiguity**: Exact table name, field names, and API configuration are undefined.

**Questions**:

1. What ServiceNow table should receive vacation records? (e.g., `sn_hr_core_case`, custom table?)
2. What is the exact field mapping (from RFP Appendix D we have a proposal — is it correct)?
3. What authentication method does the ServiceNow instance use? (OAuth 2.0? Basic? API key?)
4. Are there ServiceNow API rate limits?
5. Does the ServiceNow instance have a sandbox for testing?

**Blocker Level**: High — cannot implement F-005 without this
**Owner**: Avanade IT / ServiceNow Admin
**Affects**: F-005 (US-016, UC-016)

---

### CL-013: Vacation Balance Import Priority

**Original Statement** (US-017):
> "Import employee vacation balance from ServiceNow"

**Ambiguity**: RFP mentions this as optional Phase 2 but the use case exists.

**Questions**:

1. Is vacation balance import required for Phase 1 (MVP)? Yes
2. If Phase 1, should the system validate available balance before submission? Yes
3. If deferred, should the UI simply not show balance, or show "N/A"?

**Blocker Level**: Medium — affects scope of Bolt 5
**Owner**: Business Stakeholder
**Affects**: F-005 (US-017, UC-017)

---

### CL-014: Conflicting Data Sources (AD vs. ServiceNow for Departments)

**Original Statement** (RF-036, RF-037):
> RF-036: "obtener desde ServiceNow qué personas pertenecen al departamento"
> RF-037: "obtener desde Active Directory qué personas pertenecen al departamento"

**Ambiguity**: Both AD and ServiceNow are mentioned as sources for department membership. Which is authoritative?

**Questions**:

1. Which is the single source of truth for employee-department assignment? AD or ServiceNow?
2. If both are used, what happens when they conflict?
3. Should the system reconcile differences and alert admins?

**Blocker Level**: High — affects the entire data model and sync design
**Owner**: Avanade IT (Carlos Martínez)
**Affects**: F-004, F-005 (UC-012, UC-013)

---

## Category 4: Notifications & Communication Clarification

### CL-015: SMTP Server Details

**Original Statement**: "SMTP server provided by Avanade IT"

**Questions**:

1. What is the SMTP server address and port?
2. What authentication method? (TLS, STARTTLS, OAuth?)
3. Is there a rate limit on emails sent per minute/hour?
4. What is the sender address? (e.g., `no-reply@avanade.com`)
5. Are there anti-spam policies that could affect delivery?

**Blocker Level**: High — cannot implement F-006 without this
**Owner**: Avanade IT
**Affects**: F-006 (US-019, UC-019)

---

### CL-016: Avanade Email Branding Templates

**Original Statement**: "HTML email templates with Avanade branding"

**Questions**:

1. Are there existing Avanade HTML email templates/brand guidelines?
2. What colors, logos, and fonts should be used?
3. Should the vendor design templates or will Avanade provide them?
4. Does the legal department need to review email content?

**Blocker Level**: Low — can use placeholder branding initially
**Owner**: Marketing / Business Stakeholder
**Affects**: F-006 (UC-019)

---

### CL-017: Teams Notification Target

**Original Statement** (RF-028):
> "El sistema puede enviar la información opcionalmente por Teams."

**Ambiguity**: Not clear if messages go to 1:1 chats, team channels, or both.

**Questions**:

1. Should Teams notifications go to 1:1 chats with the user only?
2. Or should they also post to a shared approval channel?
3. If shared channel: which Teams team and channel?

**Blocker Level**: Medium — affects Graph API permissions model
**Owner**: Business Stakeholder
**Affects**: F-006 (US-021, UC-021, BR-097)

---

### CL-018: Notification Opt-Out

**Original Statement**: Not addressed in RFP.

**Questions**:

1. Should employees be able to opt out of certain notification types?
2. If yes, which notifications are mandatory (cannot opt out)?
3. Should opt-out be per-channel (email yes, Teams no) or per-event-type?

**Blocker Level**: Low — can default to "all notifications on" in Phase 1
**Owner**: Business Stakeholder
**Affects**: F-006 (US-019)

---

## Category 5: Visualization & UI Clarification

### CL-019: "Very Visual" Representation Definition

**Original Statement** (RNF-002):
> "El sistema debe mostrar de manera muy visual cuándo un periodo está sobresolicitado."

**Ambiguity**: "Very visual" is subjective. The mockup shows a calendar with colored cells, but no formal approval from stakeholders.

**Questions**:

1. Is the heat map approach (colored cells with percentages) the correct interpretation?
2. Should it be a Gantt-like view, a calendar grid, or a heatmap table?
3. Should it support both daily and weekly granularity?
4. Are there accessibility concerns (colorblind users)?

**Blocker Level**: Medium — Mockup validation with stakeholders needed
**Owner**: Business Stakeholder (Department Manager)
**Affects**: F-003 (US-009, UC-009)

**Recommendation**: Invoke `bolt-mockup` (mode: generate) before planning F-003.

---

### CL-020: Capacity Includes Pending or Only Approved?

**Original Statement**: Not explicitly defined.

**Ambiguity**: Should the heat map count Pending requests toward capacity, or only Approved ones?

**Questions**:

1. Do Pending requests count toward the 70% threshold?
2. If yes, could this create false positives (pending requests that get rejected)?
3. If no, the heat map won't reflect the real upcoming capacity until approvals are complete.
4. Should there be two indicators: "confirmed capacity" (approved) and "projected capacity" (approved + pending)?

**Blocker Level**: High — affects the capacity calculation formula and alerts
**Owner**: Business Stakeholder (Department Manager)
**Affects**: F-003 (US-009, BR-043), F-006 (US-022)

---

### CL-021: Employee Visibility into Team Calendar

**Original Statement** (RNF-004):
> "El usuario debe poder ver los calendarios fácilmente."

**Ambiguity**: Can employees see their teammates' vacation calendars, or only their own?

**Questions**:

1. Can a regular employee see when teammates are on vacation?
2. If yes, do they see only Approved vacations or also Pending?
3. Should employees see the team calendar before submitting (to avoid over-requested periods)?
4. Can employees see department-level heat maps?

**Blocker Level**: Medium — affects authorization rules for calendar views
**Owner**: Business Stakeholder
**Affects**: F-003 (US-008, UC-008)

---

## Category 6: Business Rules Clarification

### CL-022: Organizational Hierarchy — Single Level Confirmed?

**Original Statement** (RF-043):
> "La estructura organizativa debe tener un solo nivel."

**Ambiguity**: The note says "se supone" (it is assumed), introducing uncertainty. RT-002 confirms "La población debe tener un único nivel de estructura."

**Questions**:

1. Is the organizational hierarchy truly single-level (Department only)?
2. If yes, are Projects managed separately from the hierarchy (not in AD)?
3. Does the system need to support future multi-level hierarchies?

**Blocker Level**: High — defines the entire data model for hierarchy
**Owner**: Business Stakeholder
**Affects**: F-003 (US-011), F-004 (US-013, BR-059)

---

### CL-023: Escalation Timer Definition (Business Days or Calendar Days)

**Original Statement** (RF-032):
> "Si una solicitud no se aprueba en un tiempo determinado, generar alarma."

**Ambiguity**: Is the "time determined" measured in business days (Mon–Fri) or calendar days?

**Questions**:

1. Is the escalation threshold counted in business days or calendar days?
2. Default threshold: is 3 business days correct for reminder? 5 for escalation?
3. If submitted on Friday, does the timer start Monday?

**Blocker Level**: Medium — affects escalation calculation
**Owner**: Business Stakeholder
**Affects**: F-002 (US-007, UC-007, BR-034)

---

### CL-024: Terminated Employee Data Retention

**Original Statement**: Not addressed.

**Questions**:

1. When an employee is deactivated (leaves the company), are their historical vacation records preserved?
2. Should their name still appear in reports and audit trails?
3. Are there GDPR implications for retaining departed employee data?
4. What is the data retention period for departed employees?

**Blocker Level**: Medium — affects soft-delete logic and GDPR compliance
**Owner**: Legal / Compliance / HR
**Affects**: F-004 (US-012, BR-056), F-007 (US-026)

---

## Clarification Summary Table

| ID     | Category         | Blocker | Feature(s)   | Owner                    | Status       |
| ------ | ---------------- | ------- | ------------ | ------------------------ | ------------ |
| CL-001 | Request Rules    | High    | F-001        | Business (Laura Sánchez) | **Resolved** |
| CL-002 | Request Rules    | Medium  | F-001        | HR Operations            | **Resolved** |
| CL-003 | Request Rules    | Low     | F-001        | Dept Manager / HR        | **Resolved** |
| CL-004 | Business Rules   | Medium  | F-002, F-003 | Business Stakeholder     | **Resolved** |
| CL-005 | Approval         | High    | F-002        | Business Stakeholder     | **Resolved** |
| CL-006 | Approval         | Medium  | F-002        | Business Stakeholder     | **Resolved** |
| CL-007 | Approval         | Medium  | F-002        | Business Stakeholder     | **Resolved** |
| CL-008 | Approval         | High    | F-002        | Business Stakeholder     | **Resolved** |
| CL-009 | Approval         | Medium  | F-002        | Business Stakeholder     | **Resolved** |
| CL-010 | Data/Integration | High    | F-004        | Avanade IT (Carlos)      | Open         |
| CL-011 | Data/Integration | High    | F-004        | Avanade IT (Carlos)      | Open         |
| CL-012 | Data/Integration | High    | F-005        | Avanade IT / SN Admin    | Open         |
| CL-013 | Data/Integration | Medium  | F-005        | Business Stakeholder     | **Resolved** |
| CL-014 | Data/Integration | High    | F-004, F-005 | Avanade IT (Carlos)      | Open         |
| CL-015 | Notifications    | High    | F-006        | Avanade IT               | Open         |
| CL-016 | Notifications    | Low     | F-006        | Marketing / Business     | Open         |
| CL-017 | Notifications    | Medium  | F-006        | Business Stakeholder     | Open         |
| CL-018 | Notifications    | Low     | F-006        | Business Stakeholder     | Open         |
| CL-019 | UI/Visualization | Medium  | F-003        | Business (Dept Manager)  | Open         |
| CL-020 | Business Rules   | High    | F-003, F-006 | Business (Dept Manager)  | Open         |
| CL-021 | Authorization    | Medium  | F-003        | Business Stakeholder     | Open         |
| CL-022 | Data Model       | High    | F-003, F-004 | Business Stakeholder     | Open         |
| CL-023 | Business Rules   | Medium  | F-002        | Business Stakeholder     | Open         |
| CL-024 | Compliance       | Medium  | F-004, F-007 | Legal / Compliance / HR  | Open         |

---

## Priority Summary

| Blocker Level | Total | Resolved | Remaining | Must Resolve Before    |
| ------------- | ----- | -------- | --------- | ---------------------- |
| **High**      | 9     | 3        | 6         | Planning (bolt-plan)   |
| **Medium**    | 11    | 7        | 4         | Implementation (Bolt 1 start) |
| **Low**       | 4     | 1        | 3         | Can defer to Phase 2   |

---

## Recommended Next Steps

1. **Immediate (before bolt-plan)** — Schedule stakeholder session to resolve 9 HIGH blockers:
   - CL-001, CL-005, CL-008, CL-010, CL-011, CL-012, CL-014, CL-015, CL-020, CL-022

2. **Before Bolt 1 kickoff** — Resolve 11 MEDIUM blockers:
   - CL-002, CL-004, CL-006, CL-007, CL-009, CL-013, CL-017, CL-019, CL-021, CL-023, CL-024

3. **Can proceed with assumptions** — 4 LOW items can use safe defaults:
   - CL-003 (no blackouts in Phase 1)
   - CL-016 (placeholder branding until templates provided)
   - CL-018 (all notifications on; no opt-out in Phase 1)

4. **Invoke `bolt-mockup`** for F-003 to validate CL-019 visually with stakeholders.

---

## Proposed Default Assumptions (if stakeholders don't respond)

| ID     | Default Assumption                                          |
| ------ | ----------------------------------------------------------- |
| CL-001 | Minimum 1 business day advance required                    |
| CL-002 | No maximum consecutive days limit                           |
| CL-003 | No blackout periods in Phase 1                             |
| CL-004 | No alternative suggestions; warning only                    |
| CL-005 | PM/DM cannot self-approve; escalates to next level          |
| CL-006 | PM rejection is final; no appeal                            |
| CL-007 | Escalation grants DM permanent authority for that request   |
| CL-008 | Single PM approves per project; single DM approves per dept |
| CL-009 | Delegate must have same role (PM→PM or DM→DM)              |
| CL-010 | Projects managed manually in admin panel (not from AD)      |
| CL-011 | DM identified by manager-chain root for the department      |
| CL-013 | Vacation balance import deferred to Phase 2                 |
| CL-014 | AD is the authoritative source for employee-department      |
| CL-017 | Teams notifications go to 1:1 chats only                    |
| CL-018 | All notifications mandatory (no opt-out) in Phase 1        |
| CL-020 | Capacity includes both Approved + Pending requests          |
| CL-021 | Employees can see approved vacations of their own team only |
| CL-022 | Single level confirmed (Department); Projects separate      |
| CL-023 | Escalation counted in business days                         |
| CL-024 | Terminated employee data retained (soft delete, 7-year)     |
