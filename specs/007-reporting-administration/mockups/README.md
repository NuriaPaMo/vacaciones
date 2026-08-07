# Mockups — F-007: Reporting & Administration

## Index

| Flow | Step | State | File |
|------|------|-------|------|
| vacation-report | results | default | [vacation-report-default.html](vacation-report-default.html) |
| audit-trail | table | default | [audit-trail-default.html](audit-trail-default.html) |
| admin-config | panel | default | [admin-config-default.html](admin-config-default.html) |
| user-management | table | default | [user-management-default.html](user-management-default.html) |

## Assumptions

- Admin panel uses a tab layout: Configuration / Users & Roles / Delegations / Audit Trail / Integrations
- Vacation history report: DM sees own department only; admin sees all
- Audit trail: append-only; includes system events (sync, export, escalation); 7-year retention
- Config panel: inline numeric inputs per setting; department overrides as sub-rows
- User management: inline role dropdown; deactivate with confirmation; deactivated users greyed out
- Export buttons (CSV/Excel/PDF) on both reports and audit trail

## States Omitted

| State | Justification |
|-------|---------------|
| empty | Report with no results shows "No matching records" in the table body |
| error | API errors surfaced via standard toast notification pattern |
| loading | Reports < 5s; audit search < 2s; progressive loading not critical for lo-fi |
