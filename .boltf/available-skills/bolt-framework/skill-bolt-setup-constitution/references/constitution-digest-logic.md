# Constitution Digest Logic

This document describes how to generate `.boltf/memory/constitution.digest.md`: a condensed,
decision-only view of the constitution that downstream agents read **by default** to save tokens,
without dropping any binding decision.

## Why a digest

The full `constitution.md` (typically 200–500 lines) is read as a mandatory pre-task step by
~14 skills/agents (bolt-implement, bolt-review, bolt-testing, bolt-researcher, bolt-plan,
bolt-specify, bolt-feature, bolt-architect, bolt-ddd, skill-bolt-constitution-driven-development…).
Most of them only need the **binding decisions** (stack, patterns, thresholds, naming), not the
ceremony (Preamble, Governance ritual, Signatories, Revision History). The digest serves those
readers at ~1–2K tokens instead of ~5–6K.

This is the **Tier 1** artifact in the three-tier model:

| Tier | Artifact | Who reads it | Cost |
| ---- | -------- | ------------ | ---- |
| 0 | Scope card block in `CLAUDE.md` + `.github/copilot-instructions.md` | Everyone who only needs to "declare scenario/scope" | ~0 (auto-loaded) |
| 1 | `constitution.digest.md` | Validators / code-gen readers (default read) | ~1–2K tokens |
| 2 | `constitution.md` | Governance / amendment only (bolt-constitution, bolt-adr) | full, rarely read |

## Source and output

- **Source:** `.boltf/memory/refinement-states/merged-refinement.yaml` (the SAME structured source
  `constitution.md` is generated from — never re-parse the generated markdown; that reintroduces drift).
- **Output:** `.boltf/memory/constitution.digest.md`

## The one rule that protects the process: criticality drives VERBOSITY, not INCLUSION

The constitution is the SINGLE SOURCE OF TRUTH. If the digest silently omits a binding decision,
agents "read the constitution", see nothing, and emit non-compliant code — a failure nobody catches.
Therefore:

> **Every** article with `decision IN ['include', 'modified']` MUST appear in the digest.
> The `criticality` field only controls how much prose each one keeps.

| `criticality` | Digest treatment |
| ------------- | ---------------------------------------------------------------------------- |
| `HIGH`        | Full decision detail. Keep binding **code contracts** verbatim (e.g. the CQRS interface block), tables of thresholds, auth flows. |
| `MEDIUM`      | Collapse to a compact `**key**: value` line (or a short bullet list).        |
| `LOW`         | Single bullet.                                                               |
| missing       | Treat as MEDIUM (safe default — keep the decision, compact form).            |

For `modified` articles use `modified_content` only (same as Phase 4). For `include` use `content`.

## What to strip (non-decision content ONLY)

- Preamble / mission prose.
- Governance article (amendment process, "AI agent compliance" ritual).
- Signatories, Revision History, HTML comment banners, decorative rules.
- Repeated "Deferred — evaluate when cost-justified" prose → collapse to a single line listing the
  deferred items (e.g. `Deferred (cost): VNet, Private Endpoints, Azure Front Door + WAF`).
- Duplicated statements (e.g. feature-flag deploy strategy repeated across articles → state once).

Everything that is a decision an agent validates against is preserved.

## Generation process

```text
READ merged-refinement.yaml
WRITE digest header (project, scopes, "generated from merged-refinement.yaml", pointer to full constitution for governance)

FOR EACH scope IN merged-refinement (preserve order):
  approved = FILTER articles WHERE decision IN ['include','modified']
  IF approved is empty: skip scope
  WRITE "## <scope>"
  FOR EACH article IN approved (sort by criticality: HIGH → MEDIUM → LOW):
    text = article.modified_content IF decision=='modified' ELSE article.content
    stripped = remove non-decision prose from `text` (see "What to strip")
    IF criticality == HIGH:  WRITE stripped (keep code blocks / tables verbatim)
    ELIF criticality == LOW: WRITE one bullet summarizing the decision
    ELSE:                    WRITE compact key:value line(s)

# Completeness gate (MANDATORY)
FOR EACH article with decision IN ['include','modified']:
  ASSERT its decision is represented in the digest
IF any missing → FAIL, do not ship digest

WRITE footer: "Canonical source: .boltf/memory/constitution.md — read it for governance/amendments."
```

## Tier-0 scope card (Step 5.1)

Also regenerate the fenced block below in `CLAUDE.md` and `.github/copilot-instructions.md`. Both
files are auto-loaded by their client, so scope/scenario detection costs no extra read.

```markdown
<!-- BOLT:SCOPE-CARD (generated from merged-refinement.yaml — do not edit by hand) -->
**Active scopes:** <list>
- **backend:** <one-line stack>
- **frontend:** <one-line stack>
- **cloud-platform:** <one-line stack>
**Naming/format:** <one line per scope>
<!-- /BOLT:SCOPE-CARD -->
```

## Tiered-read rule for consumers

Skills/agents change their pre-task read from `constitution.md` to `constitution.digest.md`, EXCEPT
Tier-2 consumers that manage governance and therefore need the full file:

- `bolt-constitution` / `skill-bolt-setup-constitution` (they generate/manage it)
- `bolt-adr` (proposes amendments — needs full governance context)

All other readers use the digest. If a reader ever needs an article the digest compressed away,
it falls back to `constitution.md` (the pointer is in the digest footer).

## Design principles

1. **One source, two views.** Digest and constitution both derive from `merged-refinement.yaml`, so
   an amendment regenerates both — no drift.
2. **Completeness over size.** Verify by decision coverage, not by a line-count target.
3. **Resumable / deterministic.** Re-running the generator reproduces the digest.
