# Automated Formatting Configuration - Bolt Framework

Configuration completed on 2026-02-13 for automatic formatting of Markdown and other files.

## ✅ Installed Extensions

- **Prettier** (`esbenp.prettier-vscode`) - Automatic formatting
- **Markdownlint** (`davidanson.vscode-markdownlint`) - Validation and linting
- **Markdown All in One** (`yzhang.markdown-all-in-one`) - Full suite
- **Markdown Mermaid** (`bierner.markdown-mermaid`) - Diagrams

## 🎯 Daily Usage

### Automatic Format on Save

**Already configured** ✅ - Just save the file with `Ctrl+S` and it will be formatted automatically.

### Manual Formatting

| Action                  | Shortcut                   |
| ----------------------- | -------------------------- |
| Format entire document  | `Shift+Alt+F`              |
| Format selection        | `Ctrl+K Ctrl+F`            |
| Fix markdownlint issues | `Ctrl+Shift+P` → "Fix all" |
| Preview Markdown        | `Ctrl+Shift+V`             |
| Side-by-side preview    | `Ctrl+K V`                 |

### Terminal Commands

```powershell
# Format a specific file
npx prettier --write file.md

# Format all markdown files
npx prettier --write "**/*.md"

# Validate without modifying
npx prettier --check "**/*.md"

# Markdownlint fix
npx markdownlint --fix "**/*.md"
```

## ⚙️ Applied Configuration

### `.vscode/settings.json`

- ✅ Automatic format on save (Markdown only)
- ✅ Word wrap enabled
- ✅ Rulers at columns 80 and 100
- ✅ Trim trailing whitespace
- ✅ Insert final newline
- ✅ Markdownlint with Bolt Framework rules

### `.prettierrc.json`

- ✅ Print width: 100 characters
- ✅ 2-space indentation
- ✅ LF line endings
- ✅ File-type-specific configuration

## 🔧 Customization

### Change Line Width

Edit `.prettierrc.json`:

```json
{
  "printWidth": 100 // Change from 80 to 100
}
```

### Disable Format-on-Save

Edit `.vscode/settings.json`:

```json
"[markdown]": {
  "editor.formatOnSave": false  // Change to false
}
```

### Use Markdownlint Instead of Prettier

```json
"[markdown]": {
  "editor.defaultFormatter": "DavidAnson.vscode-markdownlint"
}
```

## 📋 Active Markdownlint Rules

See full configuration at:
`.claude/skills/markdown-formatting/.markdownlint.json`

Key rules:

- ✅ Single H1 per document
- ✅ ATX headings style (`#`)
- ✅ Fenced code blocks with language
- ✅ No trailing whitespace
- ✅ Lists with blank lines
- ❌ Line length (disabled for flexibility)

## 🚀 Try It Out

1. Open any `.md` file
2. Write content without proper formatting
3. Save with `Ctrl+S`
4. It should format automatically!

## 🐛 Troubleshooting

### "Formatting is not working"

1. Verify Prettier is installed: `code --list-extensions | grep prettier`
2. Verify it is set as the default formatter: Check status bar (bottom right)
3. Reload VS Code: `Ctrl+Shift+P` → "Reload Window"

### "Conflicts between Prettier and Markdownlint"

Prettier formats, Markdownlint validates. They should not conflict if you use this project's configuration.

### "Format on save is not working"

Check in `.vscode/settings.json`:

```json
"[markdown]": {
  "editor.formatOnSave": true
}
```

## 📚 References

- [Prettier Documentation](https://prettier.io/docs/en/)
- [Markdownlint Rules](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md)
- [Markdown All in One](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one)

---

**Configured by**: Bolt Framework AI Assistant
**Date**: 2026-02-13
**Skill**: [markdown-formatting](.claude/skills/markdown-formatting/)
