# Research Report: React Development Skills & Best Practices

**Date**: 2026-02-25
**Phase**: DISCOVERY
**Researcher**: Bolt Researcher Agent
**Request**: Sintetizar skills, prompts, instrucciones y buenas prácticas para desarrollo con React

---

## Question

Buscar información útil (skills, prompts, instrucciones, buenas prácticas) para desarrollo con React que pueda descargarse y disponibilizarse en `.boltf/available-skills/react/`.

## Context

**Project**: Bolt Framework
**Phase**: DISCOVERY - Building skill repository
**Constitution Constraints**:

- React 18.x/19.x supported as frontend framework option (Article II, Section 2.2)
- TypeScript strongly preferred
- Test coverage required
- Azure deployment via Static Web Apps
- Skill format: YAML frontmatter + Markdown (workflow-based)

**Existing Patterns**:

- Vue.js skills in `.boltf/available-skills/vue/` serve as template
- Skills structure: `SKILL.md` + `references/` subfolder
- Workflow approach with required/optional sections

---

## Findings

### Source 1: Project Constitution & Existing Skills

**Constitution References**:

- React 18.x: Stable with Hooks, Concurrent Mode
- React 19.x: Server Components, Actions, enhanced Suspense
- Testing: Vitest (preferred), React Testing Library
- Build Tool: Vite (preferred over Create React App)

**Skill Template Pattern** (from Vue.js skills):

```yaml
---
name: react-hooks-best-practices
description: >-
  React Hooks patterns, optimization and best practices
version: 1.0.0
license: MIT
author: Bolt Framework
---
```

**Required Sections**:

1. **Core Principles** - Verify understanding of architecture
2. **Confirm Requirements** - Check constitution alignment
3. **Must-Read References** - Link to detailed patterns
4. **Essential Foundations** - Required patterns (always apply)
5. **Optional Features** - Conditional patterns (apply when needed)
6. **Final Self-Check** - Quality gates

### Source 2: Context7 React Documentation

**Library ID**: `/websites/react_dev` (react.dev official docs)
**Quality**: 2796 snippets, High reputation, 93.5 benchmark score
**React Version**: 19.x (latest)

#### React Hooks Best Practices

**useMemo** - Cache expensive calculations:

```javascript
// ✅ DO: Memoize expensive computations
const requirements = useMemo(() => computeRequirements(product), [product]);

// ✅ DO: Optimize Context values
const contextValue = useMemo(
  () => ({
    theme,
    setTheme,
  }),
  [theme]
);

// ❌ DON''T: Memoize cheap operations
const fullName = useMemo(() => `${firstName} ${lastName}`, [firstName, lastName]); // Overkill
```

**useCallback** - Memoize function references:

```javascript
// ✅ DO: Memoize callbacks passed to optimized components
const ShippingForm = memo(function ShippingForm({ onSubmit }) {
  // ...
});

function ProductPage({ productId, referrer }) {
  const handleSubmit = useCallback((orderDetails) => {
    post(''/product/'' + productId + ''/buy'', {
      referrer,
      orderDetails,
    });
  }, [productId, referrer]);

  return <ShippingForm onSubmit={handleSubmit} />;
}

// ❌ DON''T: Wrap every function
const handleClick = useCallback(() => console.log(''clicked''), []); // Unnecessary
```

**useEffect** - Side effects with cleanup:

```javascript
// ✅ DO: Clean up subscriptions
useEffect(() => {
  const connection = createConnection();
  connection.connect();

  return () => {
    connection.disconnect(); // Cleanup
  };
}, []);

// ✅ DO: Cancel async operations
useEffect(() => {
  let cancelled = false;

  async function fetchData() {
    const data = await fetch(''/api/data'');
    if (!cancelled) {
      setData(data);
    }
  }

  fetchData();
  return () => { cancelled = true; };
}, []);
```

## Synthesis: Recommended React Skills

Based on research, create these skills in `.boltf/available-skills/react/`:

### 1. `react-hooks-best-practices/`

**Focus**: useState, useEffect, useMemo, useCallback, custom hooks
**References**:

- `use-state-patterns.md` - State management patterns
- `use-effect-cleanup.md` - Subscription cleanup, cancellation
- `use-memo-callback.md` - Performance optimization
- `custom-hooks.md` - Reusable logic extraction

### 2. `react-testing-best-practices/`

**Focus**: Testing Library, Vitest, component testing
**References**:

- `testing-library-queries.md` - Query priorities
- `async-testing.md` - waitFor, findBy pattern
- `error-boundary-testing.md` - Error handling tests
- `suspense-testing.md` - Async component tests

### 3. `react-components-patterns/`

**Focus**: Component architecture, composition, props
**References**:

- `component-composition.md` - Children, render props, HOCs
- `server-components.md` - React 19 async components
- `client-components.md` - ''use client'' directive
- `props-patterns.md` - Typing, defaults, spreading

### 4. `react-performance-optimization/`

**Focus**: Memoization, code splitting, profiling

### 5. `react-state-management/`

**Focus**: Context, useReducer, external libraries

### 6. `react-azure-integration/`

**Focus**: Static Web Apps, deployment, Azure services

---

## Decision Matrix

| Skill                          | Priority | Complexity | Dependencies        | Constitution Fit |
| ------------------------------ | -------- | ---------- | ------------------- | ---------------- |
| react-hooks-best-practices     | **HIGH** | Medium     | None                | ✅ Perfect       |
| react-testing-best-practices   | **HIGH** | Medium     | Vitest, Testing Lib | ✅ Perfect       |
| react-components-patterns      | **HIGH** | High       | TypeScript          | ✅ Perfect       |
| react-performance-optimization | Medium   | High       | React DevTools      | ✅ Good          |
| react-state-management         | Medium   | High       | Zustand/Tanstack    | ✅ Good          |
| react-azure-integration        | **HIGH** | Medium     | Azure subscription  | ✅ Perfect       |

**RECOMMENDATION**: Start with **react-hooks-best-practices**, **react-testing-best-practices**, and **react-azure-integration** (HIGH priority skills).

---

## Recommendation

### Primary Skills to Create (Phase 1)

**1. react-hooks-best-practices** - Foundation for all React development
**2. react-testing-best-practices** - Quality gate requirement
**3. react-azure-integration** - Constitution mandates Azure deployment

### Rationale

1. **Constitution Alignment**: React explicitly supported, testing required, Azure deployment mandatory
2. **Workflow Dependency**: Hooks knowledge required before component patterns
3. **Best Practices Foundation**: Official React docs + Microsoft-verified Azure patterns

---

## Next Steps

### Immediate Actions (Priority 1)

- [ ] Create `react/` folder structure in `.boltf/available-skills/`
- [ ] Write `react-hooks-best-practices/SKILL.md`
- [ ] Create reference files in `references/` subfolder
- [ ] Write `react-testing-best-practices/SKILL.md`
- [ ] Write `react-azure-integration/SKILL.md`

### Validation (Priority 2)

- [ ] Test skill auto-discovery
- [ ] Verify skills load with @react-hooks-best-practices
- [ ] Create sample React project to test workflow

---

**Research Complete** ✅
**Sources**: Constitution, Vue skills, Context7 react.dev, Microsoft Docs, Project structure
**Confidence**: HIGH - All findings align with constitution and official documentation
**Ready for Implementation**: ✅
