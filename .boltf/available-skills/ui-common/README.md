# UI Common Skills

Common user interface and browser automation skills for web development.

## Overview

This folder contains skills for UI testing, browser automation, and common frontend development tasks that can be used across different technology stacks.

## Skills

| Skill                                              | Description                                                  | Use When                                      |
| -------------------------------------------------- | ------------------------------------------------------------ | --------------------------------------------- |
| [playwright-skill](playwright-skill/SKILL.md)      | Complete browser automation with Playwright                  | UI testing, E2E tests, browser automation     |

## Playwright Skill

Comprehensive browser automation skill that provides:

- **Auto-Detection**: Automatically finds running dev servers
- **Custom Automation**: Write task-specific Playwright scripts
- **Clean Execution**: Scripts execute in `/tmp` for automatic cleanup
- **Helper Functions**: Pre-built utilities for common tasks
- **Multi-Browser**: Support for Chromium, Firefox, and WebKit

### Common Use Cases

- **Testing**: Responsive design, login flows, form submission
- **Validation**: Check for broken links, validate UX
- **Screenshots**: Capture pages across multiple viewports
- **Automation**: Any browser-based task automation

### Setup

```bash
cd .boltf/available-skills/ui-common/playwright-skill
npm run setup
```

This installs Playwright and Chromium browser (only needed once).

### Quick Example

```javascript
// Detect running dev servers
const helpers = require('./lib/helpers');
const servers = await helpers.detectDevServers();

// Test responsive design
const browser = await chromium.launch({ headless: false });
const page = await browser.newPage();

await page.setViewportSize({ width: 1920, height: 1080 });
await page.goto('http://localhost:3000');
await page.screenshot({ path: '/tmp/desktop.png', fullPage: true });

await browser.close();
```

## Technology Support

These skills support:

- **React** - Component testing, responsive design
- **Angular** - E2E testing, form validation
- **Vue** - UI automation, screenshot testing
- **Plain HTML/JavaScript** - Any web application
- **Static Sites** - JAMstack, static generators

## Integration

UI Common skills activate when:

- Frontend development is detected
- Browser automation is needed
- E2E testing is required
- UI validation is part of quality gates

## Activation

Configure in `.boltf/scopes/frontend/scope.yaml`:

```yaml
skills:
  ui-common:
    playwright-skill:
      id: playwright-skill
      source: available-skills/ui-common/playwright-skill
      destination: .claude/skills/playwright-skill
      trigger: ui_testing
```

## References

- **Playwright Documentation**: [playwright.dev](https://playwright.dev)
- **Skill Details**: [playwright-skill/SKILL.md](playwright-skill/SKILL.md)
- **Helper Functions**: [playwright-skill/lib/helpers.js](playwright-skill/lib/helpers.js)

---

**Technology**: Playwright, Node.js
**Version**: 1.0.0
**Created**: 2026-02-23
