# Bolt Framework - Documentation

This directory contains technical documentation for Bolt Framework initialization and configuration.

## Available Guides

### [SCOPE-QUESTIONS-GUIDE.md](./SCOPE-QUESTIONS-GUIDE.md)

**Scope-Specific Questions System**

Explains how the initialization scripts (`Init.ps1` and `init.sh`) use conditional questioning based on active scopes. Essential reading for:

- Understanding why some questions are skipped during initialization
- Adding new scope-specific questions to the wizard
- Maintaining consistency between PowerShell and Bash implementations

**Key Topics**:

- Helper function: `Test-ScopeActive` / `test_scope_active`
- Current scope-to-question mappings
- Step-by-step guide for adding new questions
- Best practices and examples
- Troubleshooting common issues

---

## Quick Links

- [Bolt Framework Main README](../../README.md)
- [Scopes Configuration](../scopes/README.md)
- [Constitution Setup Guide](../../INITIALIZER.md)

---

**Maintained by**: Bolt Framework Team
**Version**: 2.0.0
