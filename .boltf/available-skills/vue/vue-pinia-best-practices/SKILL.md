---
name: vue-pinia-best-practices
description: Pinia state management for Vue 3 with stores, actions, getters, reactivity gotchas (destructuring, method binding), and setup store patterns (getActivePinia errors). Vuex successor recommended for all new Vue 3 projects. Use for global state, shared data, or store patterns. Triggers => "Pinia", "Vuex alternative", "Vue state management", "store", "defineStore", "Pinia actions", "getActivePinia", "destructure store", "Pinia reactivity", "shared state Vue".
version: 1.0.0
license: MIT
author: github.com/vuejs-ai
---

Pinia best practices, common gotchas, and state management patterns.

### Store Setup

- Getting "getActivePinia was called" error at startup → See [pinia-no-active-pinia-error](reference/pinia-no-active-pinia-error.md)
- Setup stores missing state in DevTools or SSR → See [pinia-setup-store-return-all-state](reference/pinia-setup-store-return-all-state.md)

### Reactivity

- Store destructuring stops updating UI reactively → See [pinia-store-destructuring-breaks-reactivity](reference/pinia-store-destructuring-breaks-reactivity.md)
- Store methods lose context in template calls → See [store-method-binding-parentheses](reference/store-method-binding-parentheses.md)

### State Patterns

- Filters reset on refresh or can't be shared → See [state-url-for-ephemeral-filters](reference/state-url-for-ephemeral-filters.md)
- Building production app without DevTools or conventions → See [state-use-pinia-for-large-apps](reference/state-use-pinia-for-large-apps.md)
