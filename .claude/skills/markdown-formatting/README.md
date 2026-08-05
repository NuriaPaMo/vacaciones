# Markdown Formatting Skill

Comprehensive guide for writing well-formatted Markdown documents following CommonMark specification.

## Structure

```text
markdown-formatting/
├── SKILL.md           # Main skill instructions
├── README.md          # This file
├── examples/          # Real-world examples
│   ├── feature-spec-example.md
│   ├── agent-example.md
│   └── adr-example.md
└── templates/         # Reusable templates
    ├── feature-spec-template.md
    ├── agent-template.md
    └── adr-template.md
```

## Quick Start

### When Creating New Documents

1. **Read the skill**: [SKILL.md](SKILL.md)
2. **Choose a template**: See [templates/](templates/)
3. **Follow best practices**: CommonMark + Bolt Framework conventions
4. **Validate**: Use markdownlint

### Installation

```bash
# Install markdownlint CLI
npm install -g markdownlint-cli

# Validate document
markdownlint your-document.md

# Auto-fix issues
markdownlint --fix your-document.md
```

### Key Conventions

- ✅ Use ATX headings (`#`)
- ✅ Fenced code blocks with language
- ✅ One H1 per document
- ✅ Blank lines around blocks
- ✅ `-` for unordered lists
- ✅ 2-space indentation

## Examples

See [examples/](examples/) for complete, real-world examples of:

- Feature specifications
- Agent definitions
- Architecture Decision Records
- README files
- API documentation

## Templates

See [templates/](templates/) for ready-to-use templates.

## Validation

Use the provided markdownlint configuration:

```bash
# Copy to your project root
cp .markdownlint.json ../../..

# Validate all markdown
markdownlint "**/*.md"
```

## Support

For questions or improvements, see the main [new-skill](../new-skill/) documentation.

---

**Version**: 1.0.0
**Updated**: 2026-02-13
