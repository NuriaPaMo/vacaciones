# Mockups — F-001: Vacation Request Management

## Index

| Flow | Step | State | File |
|------|------|-------|------|
| submit | form | default | [submit-form-default.html](submit-form-default.html) |
| submit | form | error | [submit-form-error.html](submit-form-error.html) |
| submit | confirmation | success | [submit-form-success.html](submit-form-success.html) |
| my-requests | list | default | [my-requests-list-default.html](my-requests-list-default.html) |
| my-requests | list | empty | [my-requests-list-empty.html](my-requests-list-empty.html) |
| my-requests | detail | default | [request-detail-default.html](request-detail-default.html) |

## Assumptions

- Employee is authenticated via Entra ID (SSO); name displayed in nav bar
- Vacation balance is loaded from ServiceNow import (F-005); shown as card on submit form
- Date picker uses a simple HTML calendar grid (lo-fi); library choice TBD by Tech Lead
- Status colour coding: Pending=amber, Approved=green, Rejected=red, Cancelled=grey
- Cancel action visible only on Pending and Approved requests
- Approved cancellation requires a confirmation dialog; Pending does not

## States Omitted

| State | Justification |
|-------|---------------|
| loading | Submit and list pages load fast (< 300 ms API); skeleton not critical for lo-fi |
| no-permissions | All authenticated employees can access these pages; no permission-denied state |
