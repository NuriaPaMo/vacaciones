# Mockups — F-002: Approval Workflow

## Index

| Flow | Step | State | File |
|------|------|-------|------|
| pm-approval | queue | default | [pm-queue-default.html](pm-queue-default.html) |
| pm-approval | reject-reason | default | [reject-reason-default.html](reject-reason-default.html) |
| dm-approval | queue | default | [dm-queue-default.html](dm-queue-default.html) |
| delegation | form | default | [delegation-form-default.html](delegation-form-default.html) |

## Assumptions

- PM queue shows only requests from employees in their assigned projects
- DM queue shows both project-approved and appealed project-rejected requests
- Capacity impact badge shown inline per queue row (green/orange/red)
- Reject reason modal enforces minimum 10 characters; submit disabled until met
- PM rejection is NOT final — info banner states employee can appeal to DM
- Delegation dropdown shows only designated backups from the same project/department
- Escalated requests (pending > 5 days) marked with a clock icon in the PM queue

## States Omitted

| State | Justification |
|-------|---------------|
| empty | PM queue empty state is straightforward ("No pending requests") |
| loading | Queue loads from cache (< 2s); skeleton not critical for lo-fi |
