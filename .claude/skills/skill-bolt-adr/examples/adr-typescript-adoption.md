# ADR-015: Adopt TypeScript for Frontend Development

## Status

Accepted

## Context

### Background

Our frontend codebase is currently written in JavaScript (ES6+).
As the application grows, we're experiencing increasing issues with:

- Runtime type errors that could be caught at compile time
- Difficulty refactoring large codebases
- Poor IDE autocomplete and IntelliSense
- Lack of interface contracts between components

The team has 6 months of collective TypeScript experience from side projects.

### Problem Statement

We need to improve code quality, developer productivity, and maintainability of our frontend codebase as we scale from 50K to 200K lines of code.

### Forces

- **Developer Experience**: Current tooling provides limited type checking and autocomplete
- **Code Quality**: 23% of production bugs in last quarter were type-related
- **Team Expertise**: Team is proficient in JavaScript, learning TypeScript
- **Migration Cost**: 50K lines of existing JavaScript code
- **Build Time**: Current build completes in 12 seconds
- **Third-Party Libraries**: Most dependencies have TypeScript definitions
- **Time Constraint**: 3 months to stabilize before next major release

## Decision

### Chosen Option

**Option 2: Gradual Migration to TypeScript**

We will adopt TypeScript for all new frontend code and gradually migrate existing JavaScript files.

### Implementation Details

```typescript
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "jsx": "react-jsx",
    "strict": true,
    "moduleResolution": "node",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "allowJs": true,                    // Allow .js files during migration
    "checkJs": false,                   // Don't typecheck .js files yet
    "outDir": "./dist",
    "rootDir": "./src",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

**Migration strategy:**

1. Configure TypeScript with `allowJs: true`
2. All new files written in TypeScript
3. Convert JavaScript files when touching them (boy scout rule)
4. Critical paths (auth, payment) migrated first
5. Complete migration within 6 months

## Alternatives Considered

### Option 1: Full Rewrite to TypeScript

**Description:**
Stop all feature development and rewrite entire codebase to TypeScript in one sprint.

**Pros:**

- ✅ Clean break, no mixed codebase
- ✅ Fastest to 100% TypeScript
- ✅ No gradual migration complexity

**Cons:**

- ❌ 3-4 week feature freeze unacceptable to business
- ❌ High risk of introducing bugs
- ❌ Team burnout from repetitive conversion work
- ❌ No business value during rewrite

**Why not chosen:**
Business cannot afford feature freeze, and risk is too high.

### Option 3: JSDoc Type Annotations

**Description:**
Keep JavaScript but add type checking via JSDoc comments.

```javascript
/**
 * @param {string} name
 * @param {number} age
 * @returns {User}
 */
function createUser(name, age) {
  return { name, age };
}
```

**Pros:**

- ✅ No migration needed
- ✅ Stays in JavaScript
- ✅ TypeScript compiler can check JSDoc

**Cons:**

- ❌ Verbose and less expressive than TypeScript
- ❌ No compile-time enforcement
- ❌ Complex types become unwieldy
- ❌ Harder to refactor
- ❌ Team prefers TypeScript syntax

**Why not chosen:**
JSDoc is a half-measure that doesn't provide the full benefits of TypeScript.

### Option 4: Status Quo (JavaScript)

**Description:**
Continue with JavaScript, invest in better testing instead.

**Pros:**

- ✅ No migration cost
- ✅ Team already expert in JavaScript
- ✅ No build step changes

**Cons:**

- ❌ Doesn't address root cause of type errors
- ❌ Testing doesn't catch type mismatches
- ❌ Developer experience remains suboptimal
- ❌ Harder to onboard new developers
- ❌ Cannot compete with TypeScript's pattern matching

**Why not chosen:**
Doesn't solve the problem, just works around it.

## Consequences

### Positive

- ✅ Catches type errors at compile time (estimated 20-30% bug reduction)
- ✅ Better IDE support (autocomplete, refactoring, go-to-definition)
- ✅ Easier onboarding for new developers
- ✅ Self-documenting interfaces and types
- ✅ Safer refactoring with compiler assistance
- ✅ Better integration with modern frameworks (Next.js, React)

### Negative

- ❌ Increased build time (12s → 18s estimated)
- ❌ Initial learning curve for 2-3 team members
- ❌ Mixed codebase during 6-month migration period
- ❌ Some dependencies may lack type definitions
- ❌ More verbose code in some cases

### Neutral

- ➖ Team needs to learn TypeScript advanced features
- ➖ Need to configure TypeScript in all tools (ESLint, Jest, Webpack)
- ➖ Type definition maintenance overhead

## Compliance

[How this decision aligns with project constraints, standards, or regulations]

- [x] Complies with frontend modernization roadmap
- [x] Aligns with industry best practices
- [x] Reviewed by Frontend Architecture Team
- [x] Approved by Engineering Manager

## Implementation

### Migration Plan

**Phase 1: Setup (Week 1)**

```bash
# Install TypeScript and types
npm install -D typescript @types/react @types/react-dom @types/node

# Initialize TypeScript config
npx tsc --init

# Configure build tools
npm install -D ts-loader @babel/preset-typescript
```

**Phase 2: New Code Only (Weeks 2-4)**

- All new files in `.ts` or `.tsx`
- JavaScript files remain untouched
- Build both JS and TS together

**Phase 3: Critical Path Migration (Weeks 5-12)**

Convert in priority order:

1. Authentication module
2. Payment processing
3. API client layer
4. State management
5. Utility functions

**Phase 4: Remaining Code (Weeks 13-24)**

- Convert on touch (boy scout rule)
- Dedicated sprints for large modules
- Complete 100% migration by Month 6

### Rollback Strategy

If TypeScript proves problematic:

1. Set `allowJs: true` and `checkJs: false`
2. Rename `.ts` files back to `.js`
3. Remove TypeScript from build pipeline
4. Can rollback in < 1 day

### Validation

Measure success with:

- [ ] Build time: ≤ 20 seconds (baseline 12s, target ≤ 20s)
- [ ] Type coverage: ≥ 80% by month 3, ≥ 95% by month 6
- [ ] Bug reduction: 20% decrease in type-related bugs
- [ ] Developer satisfaction: ≥ 8/10 in quarterly survey

## Timeline

| Milestone               | Date       | Status         |
| ----------------------- | ---------- | -------------- |
| Decision Made           | 2026-02-13 | ✅             |
| TypeScript Setup        | 2026-02-20 | 🔄 In Progress |
| First Module Migrated   | 2026-03-06 | ⏳ Pending     |
| Critical Paths Complete | 2026-05-01 | ⏳ Pending     |
| 100% Migration          | 2026-08-01 | ⏳ Pending     |

## Related Decisions

- [ADR-010: Adopt React for UI Framework](./010-react-framework.md) - TypeScript has first-class React support
- [ADR-012: Use Jest for Testing](./012-jest-testing.md) - Will need `ts-jest` configuration
- [ADR-014: Webpack Build Pipeline](./014-webpack-build.md) - Add `ts-loader` to webpack config

## References

- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html)
- [React TypeScript Cheatsheet](https://react-typescript-cheatsheet.netlify.app/)
- [TypeScript Deep Dive](https://basarat.gitbook.io/typescript/)
- [DefinitelyTyped](https://github.com/DefinitelyTyped/DefinitelyTyped) - Type definitions repository

## Notes

### Type Definition Quality

Some older dependencies (`legacy-lib`) lack TypeScript definitions.
Plan to create and contribute type definitions to DefinitelyTyped.

### Team Training

Scheduled 2 training sessions:

1. TypeScript Basics (2 hours)
2. Advanced Types & Patterns (2 hours)

### Build Configuration

Need to update:

- Webpack config for `ts-loader`
- Jest config for `ts-jest`
- ESLint config for `@typescript-eslint`
- VSCode workspace settings

## Review History

| Date       | Reviewer                    | Notes                                                |
| ---------- | --------------------------- | ---------------------------------------------------- |
| 2026-02-10 | Alice (Senior Frontend Dev) | Concerned about build time, approved with monitoring |
| 2026-02-11 | Bob (Tech Lead)             | Approved, suggested gradual migration                |
| 2026-02-12 | Carol (Engineering Manager) | Approved, allocated budget for training              |
| 2026-02-13 | Team Vote                   | 5/6 in favor, 1 abstention                           |

---

**Author:** David Architect
**Date:** 2026-02-13
**Last Updated:** 2026-02-13
**Reviewers:** Alice, Bob, Carol, Team
