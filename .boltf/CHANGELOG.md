# Bolt Framework — Changelog

All notable changes to the Bolt Framework are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/) as defined in `bolt-manifest.yaml`.

---

## [0.2.0] — 2026-06-21

### Added — Penpot Design Integration (scope: frontend)

- **`bolt-penpot` agent** (`.github/agents/bolt-penpot.agent.md`, `.claude/agents/bolt-penpot.md`, `.claude/skills/bolt-penpot/`) — integrates Penpot (open-source design tool) into the design→code workflow. Modes: setup, read, validate, handoff, sync. Self-hostable via Podman.
- **`bolt-ux-design` agent** (`.github/agents/bolt-ux-design.agent.md`) — dedicated UX Design agent covering mockups, design tokens, and Penpot handoff to `bolt-implement`.
- **`bolt-mockup` agent** — low-fidelity wireframing before Penpot integration.
- Init wizard option: opt-in Penpot install from `Init.ps1` / `init.sh` (issue #24).
- MCP server for Penpot via `Sync-McpConfig.ps1` / `sync-mcp-config.sh`.

### Added — Update Scripts (consumer repo sync)

- **`Update-BoltFramework.ps1`** (`.boltf/scripts/powershell/`) — syncs agents and skills from framework source to a consumer repo. Hash-based classification: NEW / PRISTINE / MODIFIED / ORPHAN. Interactive conflict resolution with AI-assisted merge (`claude -p` via stdin). Backup before overwrite. `--dry-run` and `--force` (CI) modes.
- **`update-bolt-framework.sh`** (`.boltf/scripts/bash/`) — bash equivalent with same semantics. jq-based sync-state; graceful degradation without jq.
- **`bolt-sync-state.json`** (`.boltf/bolt-sync-state.json` in consumer repos) — per-file SHA-256 hash tracking enabling incremental syncs between framework versions.

### Added — New Agents

- `bolt-plan` agent — dedicated planning agent separate from `bolt-architect`.

### Added — Brownfield / Legacy modernization

- **`bolt-legacy-analyst` agent** (dual-client) — brownfield discovery: call graphs, data lineage, and business-rules extraction in Given/When/Then.
- **`skill-characterization-testing`** — characterization/equivalence testing (legacy as oracle: golden master / parity) to prove behavior preservation during modernization.
- **Equivalence gate** in `skill-bolt-quality-gates` (brownfield): equivalence pass rate and P0 legacy-behavior coverage.

### Changed

- `bolt-framework` orchestrator agent: Added update scripts to Available Scripts table.
- `bolt-manifest.yaml` `distribution` block: documents `agents-skills-update` scripts and `sync-state-file`.
- `bolt-testing`: legacy-oracle mode (characterization/equivalence) added to the decision matrix.
- `brownfield-workflow.md`: flow updated with `bolt-legacy-analyst`, the equivalence gate, and an explicit handoff contract (which artifact feeds which Bolt agent).
- `/modernize-legacy` (Claude + Copilot): reference the native legacy-analyst agent and the equivalence gate.

---

## [0.1.0] — 2026-05-31

### Added — Initial Release

- 6-phase AI-Driven Development Lifecycle: Inception → Discovery → Construction → Transition → Production → Retirement.
- Dual-client model: GitHub Copilot (`.github/agents/`) + Claude Code (`.claude/agents/`, `.claude/skills/`).
- Full agent suite (33 Claude agents, 44 Copilot agents): bolt-implement, bolt-testing, bolt-review, bolt-release, bolt-ops, bolt-status, bolt-monitoring, bolt-improve, bolt-clarify, bolt-feature, bolt-specify, bolt-architect, bolt-ddd, bolt-tasks, bolt-constitution, bolt-security, bolt-analyze, bolt-alignment, bolt-docs, bolt-researcher, bolt-adr, bolt-cicd, bolt-deps, bolt-gherkin, bolt-postmortem, bolt-retire, bolt-provisioner, bolt-skill-creator, bolt-templates, bolt-usecase.
- Scopes: ai, backend, cloud-platform, common, crm, data, frontend, integration, work-management.
- git-subtree distribution via `bolt-upstream` remote (prefix `.boltf/`).
- MCP dual-client config: `Sync-McpConfig.ps1` / `sync-mcp-config.sh`.
- Init wizard: `Init.ps1` / `init.sh` with greenfield/brownfield modes.
- Quality gates, branch management, constitution-driven development methodology.
