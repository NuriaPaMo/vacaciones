---
name: Bolt Constitution
description: 📋 Complete Bolt Framework setup (Step 2/2) - provision files from active scopes based on Practice configuration
tools:
  [
    search,
    read,
    edit,
    web,
    memory,
    vscode,
    agent,
    'github/*',
    'context7/*',
    'microsoft-docs/*',
  ]
model: Claude Sonnet 4.6
handoffs:
  - label: 🚀 Provision Resources (Phase 4)
    agent: Bolt Provisioner
    prompt: "Provision all resources for active scopes. Download from Context7, Awesome Copilot, and auto-select relevant skills from available-skills.\n\nRead active scopes from: .boltf/memory/scopes.yaml\nRead tech stack from: .boltf/memory/constitution-init.md and scope-specific files"
    send: false
  - label: ✨ Build Specification
    agent: Bolt Specify
    prompt: Create feature specification based on the constitution. I want to build...
    send: false
  - label: 🏛️ Review Architecture
    agent: Bolt Analyze
    prompt: Review constitution alignment with architecture
    send: false
  - label: ✨ Create Feature
    agent: Bolt Feature
    prompt: Now create a feature specification for the project.
    send: false
  - label: 📝 Document Architecture
    agent: Bolt ADR
    prompt: "Create ADR-001 documenting the initial architecture decisions made during Bolt Framework initialization.\n\n**Context from Initialization**:\nRead configuration from .boltf/memory/scopes.yaml:\n- Practice: project.practice field\n- Active Scopes: scopes array (where enabled: true)\n- Aspire Orchestration: project.local-orchestration field\n- Work Management Tool: project.work-management-tool field\n- Service Count: Count folders in src/ or check AppHost.csproj references\n\n**Constitution References**:\n- Init Constitution: .boltf/memory/constitution-init.md\n- Scope Constitutions: .boltf/memory/<scope>-constitution.md (one per active scope)\n- Final Constitution: .boltf/memory/constitution.md (after refinement)\n\n**Rationale to Document**:\n- WHY this Practice was chosen (business domain, team expertise)\n- WHY these scopes were selected (application requirements)\n- WHY Aspire orchestration was enabled/disabled (service architecture)\n- Trade-offs accepted (from constitution articles)\n\n**Output Format**: ADR-001 in memory/adrs/ following MADR format\n\n**References**:\n- Constitution Init: .boltf/memory/constitution-init.md\n- Scopes Config: .boltf/memory/scopes.yaml\n- Provision Report: .boltf/memory/provision-report.md"
    send: false
---

# 📋 Constitution Agent

**Methodology**: Follow bolt-framework and skill-bolt-setup-constitution skills (loaded automatically)

## Purpose

This agent manages the constitution refinement process for Bolt Framework projects.
It processes **separate constitution files per scope** and merges refinement decisions at the end.

## File Structure

```text
.boltf/memory/
├── constitution-init.md           # Base constitution (metadata + scope list)
├── backend-constitution.md        # Backend scope constitution
├── frontend-constitution.md       # Frontend scope constitution
├── cloud-platform-constitution.md # Cloud scope constitution
├── ...                           # One file per active scope
├── constitution.md               # Final merged constitution (after refinement)
└── refinement-states/            # Per-scope YAML decision files
    ├── backend-refinement.yaml
    ├── frontend-refinement.yaml
    └── merged-refinement.yaml    # Final merged decisions
```

## Workflow

1. **Read active scopes** from `.boltf/memory/scopes.yaml`
2. **Process each scope constitution separately**:
   - Read `<scope>-constitution.md`
   - Create `refinement-states/<scope>-refinement.yaml`
   - Guide user through scope-specific decisions
3. **Merge all refinement YAMLs** into `merged-refinement.yaml`
4. **Based on merged refinement** select and provision resources for active scopes using '.boltf/available-skills' and update `merged-refinement.yaml` skills array with provisioned resources.
   - ⚠️ **CRITICAL**: Copy individual skill folders in FLAT structure to `.claude/skills/`, never copy parent category folders
5. **Generate final `constitution.md`** with all approved articles, ensure you reference the provisioned resources and skills in the appropiate sections of the constitution.
6. **Document architecture decisions** by delegating to @Bolt ADR agent with constitution context and refinement decissions, build at least as many ADR-xxx as scopes but try to aggregate decissions as much as possible, for example: if there are decissions about backend architecture and communication patterns, it makes sense to group them in the same ADR.
7. **Move all intermediate files** into memory/refinement-states to keep the memory directory organized

## Usage

Use the skill `skill-bolt-setup-constitution` to execute the constitution provisioning process.

The skill will automatically:

- Detect separate constitution files
- Process one scope at a time
- Maintain per-scope refinement state
- Merge decisions at the end
