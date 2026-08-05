# Markdown Formatting Skill - Quick Start

## Installation

```bash
# Install markdownlint CLI globally
npm install -g markdownlint-cli

# Or in your project
npm install --save-dev markdownlint-cli
```

## Quick Validation

```bash
# Validate a single file
markdownlint document.md

# Validate all markdown files
markdownlint "**/*.md"

# Auto-fix issues
markdownlint --fix document.md
```

## Common Fixes

### 1. Add Space After Heading

❌ Before:

```markdown
#Heading
##Subheading
```

✅ After:

```markdown
# Heading

## Subheading
```

### 2. Add Language to Code Blocks

❌ Before:

```markdown

```

function hello() {}
\```

```text

```

✅ After:

`````markdown
````javascript
function hello() {}
\```
````
`````

````text

### 3. Add Blank Lines Around Lists

❌ Before:

```markdown
Some text.

- Item 1
- Item 2
  More text.
```

✅ After:

```markdown
Some text.

- Item 1
- Item 2

More text.
```

### 4. Fix Bare URLs

❌ Before:

```markdown
Visit https://example.com for more info.
```

✅ After:

```markdown
Visit <https://example.com> for more info.
```

Or:

```markdown
Visit [the documentation](https://example.com) for more info.
```

### 5. Use Only One H1

❌ Before:

```markdown
# First Title

# Second Title
```

✅ After:

```markdown
# Document Title

## First Section

## Second Section
```

## VS Code Integration

### Install Extensions

1. `DavidAnson.vscode-markdownlint` - Linting
2. `yzhang.markdown-all-in-one` - All-in-one Markdown support

### Configure Workspace Settings

Add to `.vscode/settings.json`:

```json
{
  "markdownlint.config": {
    "MD013": false,
    "MD033": {
      "allowed_elements": ["details", "summary", "kbd", "br"]
    }
  },
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "[markdown]": {
    "editor.formatOnSave": true,
    "editor.rulers": [80, 100]
  }
}
```

## Using Templates

### Create New Feature Spec

```bash
# Copy template
cp .claude/skills/markdown-formatting/templates/feature-spec-template.md \
   specs/XXX-my-feature/feature.md

# Edit the file
code specs/XXX-my-feature/feature.md
```

### Create New Agent

```bash
# Copy template
cp .claude/skills/markdown-formatting/templates/agent-template.md \
   .github/agents/my-agent.agent.md

# Edit the file
code .github/agents/my-agent.agent.md
```

### Create New ADR

```bash
# Copy template
cp .claude/skills/markdown-formatting/templates/adr-template.md \
   docs/adrs/015-my-decision.md

# Edit the file
code docs/adrs/015-my-decision.md
```

## Bolt Framework Document Types

| Document Type    | Template                                                       | Example                                                     |
| ---------------- | -------------------------------------------------------------- | ----------------------------------------------------------- |
| Feature Spec     | [feature-spec-template.md](templates/feature-spec-template.md) | [feature-spec-example.md](examples/feature-spec-example.md) |
| Agent Definition | [agent-template.md](templates/agent-template.md)               | [agent-example.md](examples/agent-example.md)               |
| ADR              | [adr-template.md](templates/adr-template.md)                   | [adr-example.md](examples/adr-example.md)                   |

## Pre-commit Hook

Add to `.husky/pre-commit`:

```bash
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

# Lint all staged markdown files
npx markdownlint $(git diff --cached --name-only --diff-filter=ACM | grep '.md$')
```

## CI/CD Integration

Add to `.github/workflows/lint.yml`:

```yaml
name: Lint Markdown

on: [push, pull_request]

jobs:
  markdown-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Lint Markdown files
        uses: avto-dev/markdown-lint@v1
        with:
          args: '**/*.md'
```

## Quick Reference

### Bolt Framework Markdown Conventions

- ✅ ATX headings (`#`) not Setext (`===`)
- ✅ Fenced code blocks (` ``` `) with language
- ✅ Asterisks (`*`) for emphasis
- ✅ Dashes (`-`) for unordered lists
- ✅ 2-space indentation for nested lists
- ✅ `---` for horizontal rules
- ✅ One H1 per document
- ✅ Blank lines around all block elements
- ✅ Descriptive link text (not "click here")

### Common Linting Rules

| Rule  | Description                             |
| ----- | --------------------------------------- |
| MD001 | Heading levels increment by one         |
| MD003 | ATX style headings                      |
| MD022 | Headings surrounded by blank lines      |
| MD025 | Single H1 per document                  |
| MD031 | Fenced code blocks surrounded by blanks |
| MD040 | Fenced code blocks should have language |
| MD047 | Files should end with newline           |

## Getting Help

- **Full Documentation**: [SKILL.md](SKILL.md)
- **Examples**: [examples/](examples/)
- **Templates**: [templates/](templates/)
- **Skill Development**: [../new-skill/](../new-skill/)

## Troubleshooting

### markdownlint reports false positive

Create `.markdownlint.json` in project root:

```json
{
  "MD013": false
}
```

### Build time increased

Use [markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2) for faster performance:

```bash
npm install -g markdownlint-cli2
markdownlint-cli2 "**/*.md"
```

### Need custom rule

See [markdownlint custom rules](https://github.com/DavidAnson/markdownlint/blob/main/doc/CustomRules.md) documentation.

---

**Version**: 1.0.0
**Last Updated**: 2026-02-13
````
