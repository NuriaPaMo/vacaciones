---
name: bolt-deps
description: "Smart dependency management and auto-installation for Bolt Framework projects based on feature keywords (authentication, database, testing, validation, styling, state management…) and constitution constraints. Validates security, licenses and performance impact. Triggers: 'install dependency', 'add package', 'manage dependencies', 'dependency audit', 'update packages', 'bundle size', '/bolt-deps'."
---

# Bolt Dependencies — Methodology

Intelligently detect, suggest, and install packages based on feature
requirements and constitution constraints.

## Auto-detection rules

### "authentication"

**Frontend dependencies**:

- `@auth0/auth0-react` (if Auth0 mentioned).
- `react-router-dom` (for protected routes).
- `@types/react-router-dom`.
- `js-cookie` (for token management).

**Backend dependencies**:

- `Microsoft.AspNetCore.Authentication.JwtBearer`.
- `Microsoft.AspNetCore.Identity.EntityFrameworkCore`.
- `System.IdentityModel.Tokens.Jwt`.

### "database"

**SQL Database**:

- `Microsoft.EntityFrameworkCore`.
- `Npgsql.EntityFrameworkCore.PostgreSQL` (PostgreSQL).
- `Microsoft.EntityFrameworkCore.SqlServer` (SQL Server).
- `Microsoft.EntityFrameworkCore.Design`.
- `Microsoft.EntityFrameworkCore.Tools`.

**NoSQL Database**:

- `MongoDB.Driver` (.NET).
- `mongoose` (Node.js).

### "testing"

**Frontend testing**:

- `@testing-library/react`, `@testing-library/jest-dom`,
  `@testing-library/user-event`.
- `vitest` (if Vite).
- `jsdom`.

**Backend testing**:

- `Microsoft.AspNetCore.Mvc.Testing`.
- `Microsoft.EntityFrameworkCore.InMemory`.
- `FluentAssertions`, `Moq`.

### "api documentation"

- `Swashbuckle.AspNetCore` (.NET).
- `Microsoft.AspNetCore.OpenApi`.

### "validation"

**Frontend**: `react-hook-form`, `@hookform/resolvers`, `zod`.

**Backend**: `FluentValidation`, `FluentValidation.AspNetCore`.

### "styling"

- `tailwindcss`, `@headlessui/react`, `lucide-react`, `clsx`.

### "state management"

**React**: `@reduxjs/toolkit`, `react-redux` (complex); `zustand` (simple).

**Vue**: `pinia` (Vue 3), `@pinia/nuxt` (Nuxt).

## Smart installation commands

```bash
# Scan feature specs and suggest dependencies
./.boltf/scripts/bash/analyze-dependencies.sh --feature F001-authentication

# Install dependencies for specific feature
./.boltf/scripts/bash/install-feature-dependencies.sh F001-authentication

# Update all dependencies with compatibility check
./.boltf/scripts/bash/update-dependencies.sh --check-compatibility

# Remove unused dependencies
./.boltf/scripts/bash/cleanup-dependencies.sh --unused
```

## Constitution-based constraints

Before installing ANY dependency, check the constitution for:

- **Allowed frameworks** (don't install Vue if React specified).
- **Security requirements** (prefer packages with good security records).
- **Performance constraints** (avoid heavy packages if performance is
  critical).
- **License compatibility** (check license requirements).

## Dependency validation

### Security checks

```bash
# Scan for vulnerabilities
npm audit --audit-level high
dotnet list package --vulnerable

# Check dependency licenses
./.boltf/scripts/bash/check-licenses.sh --constitution .boltf/memory/constitution.md
```

### Performance impact

```bash
# Analyze bundle size impact (frontend)
./.boltf/scripts/bash/analyze-bundle-size.sh --before --after

# Check dependency tree depth
npm ls --depth=2
```

## Auto-installation logic

When processing user requests:

1. **Parse request** for feature keywords.
2. **Check constitution** for tech stack and constraints.
3. **Suggest dependencies** based on patterns.
4. **Validate compatibility** with existing packages.
5. **Install with proper versions** (compatible ranges).
6. **Update configuration** files if needed.
7. **Generate usage examples** and documentation.

## Example dependency mappings

### E-commerce feature

```yaml
feature: "e-commerce checkout"
frontend_deps:
  - "stripe"            # payment processing
  - "react-hook-form"   # form handling
  - "zod"               # validation
  - "lucide-react"      # icons
backend_deps:
  - "Stripe.net"                          # payment API
  - "FluentValidation"                    # input validation
  - "Microsoft.Extensions.Http"           # HTTP client
```

### Real-time chat feature

```yaml
feature: "real-time chat"
frontend_deps:
  - "@microsoft/signalr"   # WebSocket client
  - "date-fns"             # date formatting
backend_deps:
  - "Microsoft.AspNetCore.SignalR"  # WebSocket server
```

### File upload feature

```yaml
feature: "file upload"
frontend_deps:
  - "react-dropzone"   # drag & drop
  - "axios"            # file upload with progress
backend_deps:
  - "Microsoft.AspNetCore.Http.Features"   # large file support
  - "Azure.Storage.Blobs"                  # cloud storage (if Azure)
```

## Package.json / project file management

### Smart scripts generation

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "test": "vitest",
    "test:coverage": "vitest --coverage",
    "lint": "eslint . --ext .ts,.tsx",
    "lint:fix": "eslint . --ext .ts,.tsx --fix",
    "type-check": "tsc --noEmit"
  }
}
```

### Dependency organization

- **dependencies**: runtime packages.
- **devDependencies**: build / development tools.
- **peerDependencies**: expected by library consumers.

## Version management

### Semantic versioning strategy

- `^1.2.3`: compatible minor updates (recommended).
- `~1.2.3`: compatible patch updates (conservative).
- `1.2.3`: exact version (only for problematic packages).

### Update strategy

```bash
# Check for updates
npm outdated
dotnet outdated

# Safe updates (patch + minor)
npm update
dotnet outdated --upgrade

# Major version updates (manual review)
./.boltf/scripts/bash/review-major-updates.sh
```

## Quality gates

- All installed deps pass `npm audit` / `dotnet list package --vulnerable`.
- Licenses align with constitution policy.
- Bundle size impact within budget.
- No duplicate transitive dependencies above an agreed threshold.

## Related agents (next steps)

- → `bolt-testing`: generate tests for newly installed deps.
- → `bolt-docs`: update docs with new dependencies and their usage.
- → `bolt-security`: review SCA findings for installed deps.
- → `bolt-cicd`: include dependency caching in workflows.
