---
description: Detailed provisioning workflow for Bolt Constitution agent (Phase 4)
applies-to: bolt-constitution.agent.md
phase: 4
---

# Bolt Constitution - Phase 4 Provisioning Workflow

> **This prompt provides executable step-by-step instructions for provisioning scope resources**

## Overview

Phase 4 provisions resources from active scopes by:

1. Copying local files (via PowerShell script)
2. Downloading from Context7 (via MCP)
3. Downloading from Awesome Copilot (via MCP)
4. Generating provision report

## Prerequisites

- ✅ Phase 1 complete (constitution.master.md exists)
- ✅ Phase 3 complete (constitution.md exists)
- ✅ User confirmed provisioning (chose "A. Yes, provision now")

## Step 4.1: Dry Run Analysis

**Execute PowerShell dry-run to analyze what needs provisioning:**

```powershell
.\.boltf\scripts\powershell\Invoke-BoltSetupConstitution.ps1 -ProjectPath . -Provision -DryRun
```

**Parse the output to identify:**

1. **Core skills** to be copied (4 items)
   - bolt-framework
   - bolt-adr
   - new-skill
   - markdown-formatting

2. **Scope items** by source type:
   - `local_file` → Copy from `.boltf/scopes/...`
   - `context7` → Download via MCP
   - `awesome_copilot` → Download via MCP

**Group items by:**

- kind (prompts, instructions, skills, templates, agents)
- source type (local_file, context7, awesome_copilot)
- scope name

## Step 4.2: Present Provisioning Plan

Show user a detailed plan with item counts:

```markdown
## 📦 Phase 4: Resource Provisioning

### 🎯 Core Skills (4 items, always included)

- **bolt-framework** → `.claude/skills/bolt-framework/`
- **bolt-adr** → `.claude/skills/bolt-adr/`
- **new-skill** → `.claude/skills/new-skill/` (already in .github)
- **markdown-formatting** → `.claude/skills/markdown-formatting/` (already in .github)

### 🧩 Scope Resources ([X] total items)

#### Scope: backend ([N] items)

**Local Files** ([M] items - handled by script):

- `backend-testing-strategy` → `.claude/skills/backend-testing-strategy/`
- `backend-mcp-settings` → `.vscode/settings.json`

**Context7 Downloads** ([P] items - requires MCP):

- `backend-minimal-api-openapi` → `.github/prompts/backend-minimal-api-openapi.prompt.md`
  📦 Library: /dotnet/aspnetcore.docs
  🔍 Query: "Configure Minimal API with OpenAPI and Swagger"

**Awesome Copilot Downloads** ([Q] items - requires MCP):

- `backend-dotnet-architecture` → `.github/instructions/dotnet-architecture-good-practices.instructions.md`
  📦 Collection: csharp-dotnet-development
  📄 Path: instructions/dotnet-architecture-good-practices.instructions.md

[Repeat for each active scope]

### 📊 Summary

| Category                  | Count         |
| ------------------------- | ------------- |
| Core Skills               | 4             |
| Local Files               | [X]           |
| Context7 Downloads        | [Y]           |
| Awesome Copilot Downloads | [Z]           |
| **Total Items**           | **[X+Y+Z+4]** |

**Provisioning will execute in 3 steps:**

1. PowerShell script copies local files + core skills
2. Agent downloads Context7 resources via MCP
3. Agent downloads Awesome Copilot resources via MCP

⏱ **Estimated time**: ~[X] seconds

**Ready to proceed?**
```

Wait for user confirmation.

## Step 4.3: Execute Provisioning

### Step 4.3.1: Copy Local Files

Execute PowerShell script (actual run, not dry-run):

```powershell
.\.boltf\scripts\powershell\Invoke-BoltSetupConstitution.ps1 -ProjectPath . -Provision
```

**Monitor script output and report progress:**

```markdown
### ⚡ Step 1/3: Local Files + Core Skills

✓ Core Skills

- bolt-framework ✓
- bolt-adr ✓
- new-skill ✓ (preserved)
- markdown-formatting ✓ (preserved)

✓ Scope: backend ([M] local files)

- backend-testing-strategy ✓
- backend-mcp-settings ✓

[Continue for each scope]

**Local provisioning complete** ([X] items copied)
```

The script will skip items marked as context7/awesome_copilot and report them as "requires download".

### Step 4.3.2: Download from Context7

**For each item with `source.type: context7`:**

#### Load MCP Tools (one-time)

```typescript
// Search for context7 MCP tools
tool_search_tool_regex({ pattern: 'mcp_context7' });
```

Expected tools:

- `mcp_context7_resolve-library-id`
- `mcp_context7_query-docs`

#### For Each Context7 Item

**Example item from scope.yaml:**

```yaml
- id: backend-minimal-api-openapi
  kind: prompts
  enabled: true
  source:
    type: context7
    library: /dotnet/aspnetcore.docs
    query: Configure Minimal API with OpenAPI and Swagger
    resolved_url: https://learn.microsoft.com/aspnet/core/fundamentals/openapi/overview
  destination:
    folder: .github/prompts
    name: backend-minimal-api-openapi.prompt.md
```

**Execution:**

1. **Resolve library** (if library ID is path):

   ```typescript
   const library =
     (await mcp_context7_resolve) -
     library -
     id({
       libraryId: '/dotnet/aspnetcore.docs',
     });
   ```

2. **Fetch documentation**:

   ```typescript
   const docs =
     (await mcp_context7_query) -
     docs({
       libraryId: library.id || '/dotnet/aspnetcore.docs',
       query: 'Configure Minimal API with OpenAPI and Swagger',
       maxResults: 1,
     });
   ```

3. **Format content with frontmatter**:

   ```markdown
   ---
   source: context7
   library: /dotnet/aspnetcore.docs
   query: Configure Minimal API with OpenAPI and Swagger
   url: [resolved_url from docs]
   fetched: 2026-02-24 15:30:45
   license: Microsoft Learn terms
   ---

   # Backend - Minimal API with OpenAPI

   [Content from docs[0].content]
   ```

4. **Write to destination**:

   ```typescript
   create_file({
     filePath: '.github/prompts/backend-minimal-api-openapi.prompt.md',
     content: formattedContent,
   });
   ```

5. **Report progress**:

   ```markdown
   ✓ backend-minimal-api-openapi.prompt.md
   📦 Library: /dotnet/aspnetcore.docs
   📄 Saved: .github/prompts/backend-minimal-api-openapi.prompt.md
   ```

**Repeat for all Context7 items.**

Show summary:

```markdown
### ⚡ Step 2/3: Context7 Downloads

✓ Downloaded [Y] items from Context7

- backend-minimal-api-openapi.prompt.md ✓
- backend-integration-testing.prompt.md ✓
  [...]

**Context7 provisioning complete** ([Y] items downloaded)
```

### Step 4.3.3: Download from Awesome Copilot

**For each item with `source.type: awesome_copilot`:**

#### Load MCP Tools (one-time)

```typescript
// Search for awesome copilot MCP tools
tool_search_tool_regex({ pattern: 'mcp_awesome_copil' });
```

Expected tools:

- `mcp_awesome_copil_list_collections`
- `mcp_awesome_copil_load_collection`
- `mcp_awesome_copil_load_instruction`

#### For Each Awesome Copilot Item

**Example item from scope.yaml:**

```yaml
- id: backend-dotnet-architecture
  kind: instructions
  enabled: true
  source:
    type: awesome_copilot
    collection: csharp-dotnet-development
    item_path: instructions/dotnet-architecture-good-practices.instructions.md
    resolved_url: https://github.com/github/awesome-copilot/tree/main/collections/csharp-dotnet-development/instructions/...
  destination:
    folder: .github/instructions
    name: dotnet-architecture-good-practices.instructions.md
```

**Execution:**

1. **Load collection**:

   ```typescript
   const collection = await mcp_awesome_copil_load_collection({
     collectionName: 'csharp-dotnet-development',
   });
   ```

2. **Load instruction/item**:

   ```typescript
   const instruction = await mcp_awesome_copil_load_instruction({
     collectionName: 'csharp-dotnet-development',
     instructionPath: 'instructions/dotnet-architecture-good-practices.instructions.md',
   });
   ```

3. **Format content with frontmatter**:

   ```markdown
   ---
   source: awesome_copilot
   collection: csharp-dotnet-development
   item: instructions/dotnet-architecture-good-practices.instructions.md
   url: [resolved_url or GitHub URL]
   fetched: 2026-02-24 15:31:10
   license: repository-defined
   ---

   # .NET Architecture Good Practices

   [Content from instruction.content]
   ```

4. **Write to destination**:

   ```typescript
   create_file({
     filePath: '.github/instructions/dotnet-architecture-good-practices.instructions.md',
     content: formattedContent,
   });
   ```

5. **Report progress**:

   ```markdown
   ✓ dotnet-architecture-good-practices.instructions.md
   📦 Collection: csharp-dotnet-development
   📄 Saved: .github/instructions/dotnet-architecture-good-practices.instructions.md
   ```

**Repeat for all Awesome Copilot items.**

Show summary:

```markdown
### ⚡ Step 3/3: Awesome Copilot Downloads

✓ Downloaded [Z] items from Awesome Copilot

- dotnet-architecture-good-practices.instructions.md ✓
- csharp.instructions.md ✓
  [...]

**Awesome Copilot provisioning complete** ([Z] items downloaded)
```

## Step 4.4: Enhance Provision Report

The PowerShell script created `.boltf/memory/provision-report.md` but it only tracked local files.

**Read the existing report** and append download information:

```markdown
## External Downloads Completed

### Context7 ([Y] items)

| Item                                  | Library                 | Query                    | Fetched             |
| ------------------------------------- | ----------------------- | ------------------------ | ------------------- |
| backend-minimal-api-openapi.prompt.md | /dotnet/aspnetcore.docs | Configure Minimal API... | 2026-02-24 15:30:45 |
| backend-integration-testing.prompt.md | /dotnet/aspnetcore.docs | Minimal API returning... | 2026-02-24 15:30:52 |

### Awesome Copilot ([Z] items)

| Item                                               | Collection                | Path                                | Fetched             |
| -------------------------------------------------- | ------------------------- | ----------------------------------- | ------------------- |
| dotnet-architecture-good-practices.instructions.md | csharp-dotnet-development | instructions/dotnet-architecture... | 2026-02-24 15:31:10 |
| csharp.instructions.md                             | csharp-dotnet-development | instructions/csharp.instructions.md | 2026-02-24 15:31:15 |

---

**Total Provisioned**: [X+Y+Z+4] items

- ✓ Core Skills: 4
- ✓ Local Files: [X]
- ✓ Context7: [Y]
- ✓ Awesome Copilot: [Z]
```

## Step 4.5: Final Summary

Present complete provisioning results:

````markdown
## ✅ Phase 4 Complete - All Resources Provisioned

### Summary

**Core Skills** (4 items):

- bolt-framework ✓
- bolt-adr ✓
- new-skill ✓
- markdown-formatting ✓

**Scope Resources** ([X+Y+Z] items):

- Local files copied: [X]
- Context7 downloaded: [Y]
- Awesome Copilot downloaded: [Z]

### Files Created

**Skills** (.claude/skills/):

- [List all skill folders]

**Prompts** (.github/prompts/):

- [List all prompt files]

**Instructions** (.github/instructions/):

- [List all instruction files]

**Agents** (.github/agents/):

- [List all agent files]

**Templates** (various locations):

- [List all template files]

### Reports

📄 **Provision Report**: `.boltf/memory/provision-report.md`
📄 **Constitution**: `.boltf/memory/constitution.md`
📄 **Master Constitution**: `.boltf/memory/constitution.master.md`

### Verification

Run these commands to verify:

```bash
# List provisioned skills
ls .claude/skills/

# List prompts
ls .github/prompts/

# List instructions
ls .github/instructions/

# View provision report
cat .boltf/memory/provision-report.md
```
````

### Next Steps

1. **Review constitution**: Open `.boltf/memory/constitution.md`
2. **Explore skills**: Browse `.claude/skills/` folders
3. **Start building**: Use `@Bolt Framework` to begin AI-DLC
4. **Create features**: Use `@Bolt Feature` to define first feature

**Bolt Framework is now fully configured! 🚀**

````text

## Error Handling

### MCP Tool Not Available

If Context7 or Awesome Copilot MCP is not available:

```markdown
⚠️ **MCP Server Not Available**

I couldn't load the [Context7 | Awesome Copilot] MCP server.

**Missing Items** ([N] items):
- [List items that need this source]

**Options**:

A. **Skip these items** - Continue without them (can provision manually later)
B. **Manual download** - I'll provide URLs for manual download
C. **Abort** - Stop provisioning

Your choice? **(A, B, or C)**
````

### Download Failed

If a specific download fails:

```markdown
⚠️ **Download Failed**

Item: [item-id]
Source: [context7 | awesome_copilot]
Error: [error message]

**Options**:

A. **Skip and continue** - Mark as failed in report
B. **Retry** - Try downloading again
C. **Abort** - Stop all provisioning

Your choice? **(A, B, or C)**
```

Keep a `failed_items` list and include in final report.

## Notes for Agent

- **Always load MCP tools before using them** via `tool_search_tool_regex`
- **Parse scope.yaml carefully** to identify source types
- **Add frontmatter to all downloaded files** for traceability
- **Report progress incrementally** (not all at end)
- **Handle errors gracefully** (skip/retry/abort options)
- **Verify files were created** after each download
- **Update provision report** with download details
