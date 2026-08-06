# ADR-004: Use Vue 3.x with TypeScript, Vite, Pinia on Azure Static Web Apps

## Status

Accepted

## Date

2026-08-05

## Context

The project requires a modern Single Page Application (SPA) frontend for end users. The technology selection was influenced by a wizard-guided discovery process that identified Vue as the preferred framework. The project is greenfield (2026), Azure-hosted, and web-only (no mobile app).

Key requirements:
- **Modern SPA**: Component-based, reactive UI with client-side routing
- **Type safety**: TypeScript to reduce runtime errors and improve developer experience
- **Fast build and HMR**: Developer experience is critical for iteration speed
- **State management**: Application-level state shared across components (user session, filters, cart, etc.)
- **Azure hosting**: Seamlessly integrates with the Azure-first infrastructure strategy
- **No mobile app**: Web browser targets only; no React Native, Expo, or PWA-specific requirements
- **Mockups only**: Design tooling limited to static HTML mockups (no Penpot or Figma integration)

Key forces:
- Vue 3.x is the wizard-selected framework; alternatives are evaluated for completeness
- Vite (Evan You's build tool) is the officially recommended build tool for Vue 3
- Pinia is the officially recommended state management library for Vue 3 (successor to Vuex)
- Azure Static Web Apps provides zero-config global CDN hosting for SPAs with integrated API routing

## Decision Drivers

- MUST use Vue 3.x (wizard selection confirmed)
- MUST use TypeScript for type safety across the frontend codebase
- MUST use Vite as build tool (official Vue recommendation, fast HMR)
- MUST use Pinia for state management (official Vue recommendation)
- MUST deploy to Azure Static Web Apps
- SHOULD use Vue Router for client-side navigation
- MUST NOT include mobile app targets
- MUST NOT integrate Penpot or Figma design tools (HTML mockups only)

## Considered Options

### Option 1: Vue 3.x + TypeScript + Vite + Pinia + Azure Static Web Apps ✅ (Chosen)

The complete officially-recommended Vue 3 stack in 2026.

**Pros:**
- Vue 3 Composition API + `<script setup>` syntax provides excellent TypeScript inference and co-location of logic
- Vite delivers sub-second HMR and near-instant cold starts compared to Webpack-based alternatives
- Pinia is type-safe by design, devtools-integrated, and tree-shakeable; simpler API than Vuex/Redux
- Vue Router 4 supports typed routes (experimental) and lazy-loaded route chunks out of the box
- Azure Static Web Apps provides: global CDN, custom domain + free TLS, SPA fallback routing, GitHub/Azure DevOps deployment integration, and API routing to backend (Container Apps)
- Strong ecosystem: Vitest (unit tests), Playwright (E2E), VueUse (composables), PrimeVue/Vuetify (UI)
- TypeScript provides compile-time safety for API contracts, prop types, and store shapes

**Cons:**
- Vue ecosystem is smaller than React's — more niche libraries may require custom implementation
- TypeScript adds initial setup complexity (tsconfig, strict mode) — justified by long-term maintainability
- Azure Static Web Apps has routing constraints for complex scenarios (resolved via `staticwebapp.config.json`)

### Option 2: React 19 + TypeScript + Vite + Zustand + Azure Static Web Apps

**Pros:**
- Largest SPA ecosystem and community
- React 19 Server Components (if SSR is needed in future)
- Excellent TypeScript support

**Cons:**
- Vue was the wizard-confirmed selection; switching introduces unnecessary friction
- React's ecosystem fragmentation (many competing state management, routing, and data-fetching libraries) increases decision overhead
- JSX syntax is less HTML-like than Vue SFCs, which some team members may find less intuitive
- No official opinionated stack — requires more upfront architectural decisions

### Option 3: Angular 18 + TypeScript + Azure Static Web Apps

**Pros:**
- Fully opinionated framework with built-in CLI, router, forms, and HTTP client
- Strong TypeScript support (Angular was built on TypeScript)
- Good fit for large enterprise teams

**Cons:**
- Significantly more complex and verbose than Vue 3 for a product of this scale
- Slower iteration speed due to NgModule/standalone component migration complexity
- Not the wizard-confirmed choice
- Angular's bundle size and startup time are higher than Vue + Vite

### Option 4: Vue 3 + Nuxt 4 (SSR/SSG)

**Pros:**
- Server-side rendering improves SEO and initial page load
- Nuxt provides file-based routing, auto-imports, and full-stack capabilities

**Cons:**
- SSR adds server infrastructure (Node.js runtime) that conflicts with the Azure Static Web Apps zero-server model
- SSR is not required — the application is authenticated/internal and does not have SEO requirements
- Additional complexity without corresponding benefit for this use case

## Decision Outcome

**Chosen option: Vue 3.x + TypeScript + Vite + Pinia + Vue Router + Azure Static Web Apps**

Rationale: Vue 3 is the wizard-confirmed framework selection. The combination of Vite (build), Pinia (state), and Vue Router (navigation) represents the officially recommended, production-proven Vue 3 stack in 2026. TypeScript ensures compile-time correctness. Azure Static Web Apps provides zero-config CDN hosting with native Azure DevOps integration, consistent with the project's Azure-first strategy.

### Technology Versions (Reference)

| Technology | Version |
|-----------|---------|
| Vue | 3.x (latest stable) |
| TypeScript | 5.x |
| Vite | 6.x |
| Pinia | 3.x |
| Vue Router | 4.x |
| Vitest | latest |

### Positive Consequences

- Sub-second HMR with Vite dramatically improves developer iteration speed
- TypeScript catches prop mismatches, API contract violations, and store type errors at build time
- Pinia's simple `defineStore` API reduces boilerplate vs. Vuex while providing full devtools support
- Azure Static Web Apps auto-deploys from Azure DevOps pipeline, integrates with backend Container Apps via `linkedBackend` configuration
- Vue SFCs (`<template>`, `<script setup>`, `<style>`) co-locate component logic — maintainable and readable
- Vitest shares Vite configuration — zero extra setup for unit tests

### Negative Consequences

- Vue ecosystem is smaller than React's — some UI components or integrations may require custom code
- `staticwebapp.config.json` requires explicit route rewrite rules for SPA deep-linking — one-time configuration
- No SSR/SSG capabilities (not required for this use case, but future SEO needs would require migration to Nuxt)

## Compliance

- Infrastructure: Hosted on Azure Static Web Apps, provisioned via Terraform (ADR-005)
- CI/CD: Built and deployed via Azure DevOps Pipelines (ADR-006)
- Observability: Azure Application Insights JS SDK for frontend telemetry (ADR-006)

## Links

- [Vue 3 documentation](https://vuejs.org/)
- [Vite documentation](https://vitejs.dev/)
- [Pinia documentation](https://pinia.vuejs.org/)
- [Vue Router documentation](https://router.vuejs.org/)
- [Azure Static Web Apps documentation](https://learn.microsoft.com/en-us/azure/static-web-apps/)
- ADR-001: Backend Technology Stack
- ADR-005: Cloud Infrastructure — Azure Container Apps with Terraform
- ADR-006: CI/CD, Observability, and Security Baseline
