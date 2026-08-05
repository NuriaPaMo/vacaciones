---
name: skill-frontend-framework-selection
description: Choose frontend framework (React, Angular, Vue.js, Blazor WebAssembly) or mobile framework (.NET MAUI, React Native). Use when building web SPAs, mobile apps, or evaluating technology stack. Critical because frontend framework choice is costly to reverse—complete rewrite if changed, impacts developer hiring, library ecosystem, and Azure integration patterns.
---

# Frontend Framework Selection

## When to Use This Skill

Invoke this skill when you need to:

- **Select a frontend framework** for new web application (React, Angular, Vue.js, Blazor)
- **Choose a mobile framework** for cross-platform apps (iOS/Android with .NET MAUI or React Native)
- **Evaluate framework trade-offs** based on team expertise, project requirements, Azure integration
- **Migrate between frameworks** (rare but costly—understand implications before committing)

**Critical because**: Frontend framework choice is one of the hardest decisions to reverse. Switching from React to Angular or .NET MAUI to React Native = complete rewrite. Decision affects developer hiring pool, library ecosystem availability, build tooling, Azure Static Web Apps integration, authentication patterns (MSAL.js vs MSAL Angular vs Blazor Authentication component), and long-term maintainability.

---

## Decision Framework: Web vs Mobile First

### Web SPA (Single-Page Application)

**Choose a web framework** if building browser-based applications deployed to Azure Static Web Apps, App Service, or CDN.

**Framework Options**: React, Angular, Vue.js, Blazor WebAssembly

### Cross-Platform Mobile

**Choose a mobile framework** if building native iOS/Android apps with shared codebase.

**Framework Options**: .NET MAUI, React Native

---

## Web Framework Selection

### React

**When to Choose**:

- Large developer pool (most popular framework)
- Flexibility in architecture (choose your own state management, routing)
- Component reusability across web and React Native
- Azure Static Web Apps deployment with MSAL.js authentication

**Trade-Offs**: More architectural decisions required (Redux? Zustand? Context API?), less opinionated structure than Angular.

### Angular

**When to Choose**:

- Enterprise applications requiring strong typing and opinionated architecture
- Long-term maintainability with large teams (dependency injection, services, modules)
- RxJS for reactive programming, Signals for performance
- Azure Static Web Apps with MSAL Angular (guards, interceptors)

**Trade-Offs**: Steeper learning curve (DI, RxJS), more verbose boilerplate than React/Vue.

### Vue.js

**When to Choose**:

- Gentle learning curve for team onboarding
- Progressive adoption (can start simple, scale to complex)
- Composition API for reactive state, Pinia for global state
- Azure Static Web Apps deployment with MSAL.js

**Trade-Offs**: Smaller enterprise adoption vs React/Angular, fewer large-scale architectural patterns.

### Blazor WebAssembly

**When to Choose**:

- .NET/C# team expertise (no context switching between frontend/backend)
- Code sharing between frontend and backend (DTOs, validation logic, libraries)
- Strong typing with C#, Razor component syntax
- Azure Static Web Apps with built-in Authentication component, MSAL integration

**Trade-Offs**: Larger initial download size (~2-3MB compressed), .NET runtime in browser via WebAssembly, smaller developer pool than React/Angular.

---

## Mobile Framework Selection

### .NET MAUI

**When to Choose**:

- C#/.NET team expertise across web and mobile
- Single codebase for iOS, Android, Windows, macOS
- MVVM pattern with CommunityToolkit.Mvvm
- Native performance, Azure SDK integration (.NET libraries)

**Trade-Offs**: XAML learning curve, smaller developer pool than React Native, less mature ecosystem than React Native.

### React Native

**When to Choose**:

- JavaScript/TypeScript team with React web experience
- Large npm ecosystem and native module availability
- Fast iteration with hot reload, Expo for simplified builds
- Cross-platform iOS/Android with shared component patterns

**Trade-Offs**: JavaScript bridge performance overhead (not fully native), native module integration complexity, React/React Native differences (View vs div, StyleSheet vs CSS).

---

## How to Proceed

1. **Assess Team Expertise**:
   - JavaScript/TypeScript → React, Angular, Vue.js, React Native
   - C#/.NET → Blazor WebAssembly, .NET MAUI
   - Mixed → Consider Blazor for code sharing or React for largest dev pool

2. **Evaluate Project Scope**:
   - Web SPA only → React, Angular, Vue.js, Blazor WebAssembly
   - Mobile iOS/Android → .NET MAUI, React Native
   - Web + Mobile → React web + React Native (shared patterns) OR Blazor WebAssembly + .NET MAUI (shared C# code)

3. **Check Azure Integration Needs**:
   - Microsoft Entra ID (Azure AD) authentication → MSAL.js (React/Vue), MSAL Angular, Blazor Authentication component
   - Azure Static Web Apps → All web frameworks supported (React, Angular, Vue, Blazor)
   - Azure Push Notifications, Cosmos DB → .NET MAUI (.NET SDKs), React Native (npm packages)

4. **Consider Long-Term Maintenance**:
   - Large teams, enterprise scale → Angular (opinionated structure), .NET MAUI (corporate .NET adoption)
   - Flexibility, component reuse → React (largest ecosystem)
   - Gentle learning curve → Vue.js (progressive adoption)
   - Code sharing frontend/backend → Blazor WebAssembly + ASP.NET Core

5. **Review Bundled Code Examples**:
   - `references/code-examples.md`: 6 complete examples (React SPA with MSAL, Angular standalone components, Vue 3 Composition API, Blazor WebAssembly authentication, .NET MAUI MVVM, React Native)
   - Framework comparison table: Learning curve, ecosystem, performance, developer pool, Azure integration

6. **Consult Official Documentation**:
   - `references/microsoft-learn.md`: React/Angular/Vue/Blazor deployment to Azure Static Web Apps, .NET MAUI/React Native Azure integration, authentication tutorials

7. **Validate Decision with Constitution**:
   - Check `memory/constitution.md` Article II (Technical Stack) for any existing framework constraints
   - Document framework choice as ADR (Architecture Decision Record) using `@Bolt ADR` agent

---

**Remember**: Frontend framework choice is nearly irreversible (complete rewrite to change). Spend adequate time validating team expertise, project scope, Azure integration needs, and long-term maintainability before committing.
