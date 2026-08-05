---
name: bolt-constitution
description: "Bolt Framework Constitution provisioning (Step 2 of init). Process separate constitution files per active scope, capture per-scope refinement YAMLs, merge final decisions, and generate the master `constitution.md`. Triggers: 'constitution provisioning', 'bolt step 2', 'scope-based constitution', 'merge refinement', 'project DNA setup', '/bolt-constitution'. Use AFTER `bolt-init` has created `.boltf/memory/scopes.yaml`."
---

# Bolt Constitution — Methodology

## Purpose

Manage the constitution refinement process for Bolt Framework projects.
Process **separate constitution files per scope** and merge refinement decisions
at the end.

## When to use

- Step 2/2 of Bolt Framework initialization (after `bolt-init` produces the
  scope list).
- When tech stack, principles or governance rules need to be reset/refined.

## File Structure

```text
.boltf/memory/
├── constitution-init.md           # Base constitution (metadata + scope list)
├── backend-constitution.md        # Backend scope constitution
├── frontend-constitution.md       # Frontend scope constitution
├── cloud-platform-constitution.md # Cloud scope constitution
├── ...                            # One file per active scope
├── constitution.md                # Final merged constitution (after refinement)
└── refinement-states/
    ├── backend-refinement.yaml
    ├── frontend-refinement.yaml
    └── merged-refinement.yaml     # Final merged decisions
```

## Process

1. **Read active scopes** from `.boltf/memory/scopes.yaml`.
2. **Process each scope constitution separately**:
   - Read `<scope>-constitution.md`.
   - Create `refinement-states/<scope>-refinement.yaml`.
   - Guide user through scope-specific decisions.
3. **Merge all refinement YAMLs** into `merged-refinement.yaml`.
4. **Provision resources** for active scopes from `.boltf/available-skills`
   and update `merged-refinement.yaml` skills array. ⚠️ **CRITICAL**: copy
   individual skill folders in FLAT structure to `.claude/skills/`, never
   parent category folders.
5. **Generate final `constitution.md`** referencing provisioned resources and
   skills in the appropriate sections.
5b. **Generate the token-optimized digest** (`skill-bolt-setup-constitution` Phase 5):
   emit `constitution.digest.md` and the Tier-0 scope card into `CLAUDE.md` /
   `.github/copilot-instructions.md` from `merged-refinement.yaml`, then run
   `validate_constitution_digest.py` to enforce completeness. Downstream agents read
   the digest by default; the full `constitution.md` stays canonical for governance.
6. **Document architecture decisions** by delegating to the `bolt-adr`
   subagent with constitution context and refinement decisions. Produce at
   least as many ADR-xxx as scopes, aggregating decisions when sensible
   (e.g. backend architecture + communication patterns → single ADR).
7. **Move intermediate files** into `memory/refinement-states/` to keep the
   memory directory organized.

## Execution

Use the skill `skill-bolt-setup-constitution` to execute the constitution
provisioning. It automatically:

- Detects separate constitution files.
- Processes one scope at a time.
- Maintains per-scope refinement state.
- Merges decisions at the end.

## Quality gates

- All active scopes have a `*-refinement.yaml` before merge.
- Final `constitution.md` references every provisioned skill.
- `constitution.digest.md` generated and passes the completeness gate; Tier-0 scope card emitted.
- At least one ADR per major architectural decision.

## Related agents (next steps)

- → `bolt-provisioner`: provision resources from active scopes if not done.
- → `bolt-adr`: document architectural decisions taken during refinement.
- → `bolt-feature`: create the first feature spec based on the constitution.
- → `bolt-analyze`: verify architecture alignment with constitution.
