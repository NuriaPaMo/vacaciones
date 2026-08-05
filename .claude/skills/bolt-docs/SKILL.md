---
name: bolt-docs
description: "Generate and maintain project documentation for Bolt Framework — README, API contracts, architecture docs, user journeys, ADR index, runbooks. Keeps docs in sync with code and spec. Triggers: 'generate docs', 'documentation', 'README', 'api docs', 'doc update', 'project documentation', '/bolt-docs'."
---

# Bolt Docs — Methodology

Generate and maintain comprehensive project documentation that stays in sync
with code and specs.

**Bolt Framework Stage**: CROSS-PHASE
**Responsible Agent**: Documentation Lead

## Documentation map

| Doc type | Location | Source agent |
|----------|----------|--------------|
| README (root) | `README.md` | `bolt-docs` |
| API contracts | `docs/api/<service>-api.md` | `api-contracts-doc` |
| Architecture | `docs/design/architecture/` | `bolt-architect` |
| DDD | `docs/design/ddd/` | `bolt-ddd` |
| ADRs | `docs/adr/ADR-NNN-*.md` | `bolt-adr` |
| User journeys | `docs/functional/user-journeys/` | `user-journey-doc` |
| Personas | `docs/functional/actors/personas.md` | `user-journey-doc` |
| Runbooks | `docs/ops/runbooks/` | `bolt-ops` |
| Postmortems | `docs/postmortems/` | `bolt-postmortem` |
| Plans | `docs/plans/` | (planning workflows) |

## Process

1. Detect what changed (spec / code / config).
2. Update affected docs via the responsible skill/agent (do not duplicate
   content).
3. Update root `README.md` if scope, install, or run instructions changed.
4. Regenerate API contract docs from controllers (`api-contracts-doc`).
5. Refresh diagrams (Mermaid via `mermaid-creator`).
6. Cross-check links and references.

## Style

Use `markdown-formatting` skill rules: CommonMark, line wrapping, no MD060
warnings, table column alignment.

Spanish (Spain) for documentation per project convention, except when
quoting code, commands or third-party docs.

## Quality gates

- All links valid (no 404 to internal docs).
- Diagrams render (Mermaid syntax valid).
- API docs match controllers.
- ADR index updated.
- README reflects current install / run flow.

## Related agents (next steps)

- → `api-contracts-doc`: regenerate API specs from controllers.
- → `bolt-architect`: update C4 / arch docs.
- → `bolt-ddd`: update domain model docs.
- → `bolt-adr`: file a new decision when surfaced.
- → `user-journey-doc`: refresh personas / journeys.
