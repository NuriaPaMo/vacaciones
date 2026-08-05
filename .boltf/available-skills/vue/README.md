# Vue.js Skills

Skills especializados para desarrollo con Vue.js 3.

## 🎯 Skill Principal (Obligatorio)

### vue-best-practices

**Workflow completo de desarrollo Vue.js con Composition API + TypeScript**

- ✅ **OBLIGATORIO** cargar para cualquier tarea Vue.js
- Composition API con `<script setup lang="ts">` como estándar
- Workflow ordenado: arquitectura → fundamentos → features opcionales → optimización
- Referencias must-read: reactivity, SFC, component-data-flow, composables

[Ver documentación](vue-best-practices/SKILL.md)

---

## 🐛 Debugging & Solución de Problemas

### vue-debug-guides

**Guías de debugging para problemas runtime, warnings, async y SSR**

Cubre errores comunes en:

- Reactividad (refs, computed, watchers)
- Componentes, props, events
- Templates, forms, lifecycle
- TypeScript, SSR, performance

[Ver documentación](vue-debug-guides/SKILL.md)

---

## 📦 Ecosistema Vue.js

### vue-pinia-best-practices

**State management con Pinia**

- Setup stores, composition stores
- Reactivity patterns
- DevTools integration
- SSR state management

[Ver documentación](vue-pinia-best-practices/SKILL.md)

---

### vue-router-best-practices

**Navigation y routing con Vue Router 4**

- Navigation guards
- Route params & lifecycle
- Async routes
- Route meta fields

[Ver documentación](vue-router-best-practices/SKILL.md)

---

### vue-testing-best-practices

**Testing con Vitest, Vue Test Utils y Playwright**

- Component testing
- Composable testing
- Mocking & fixtures
- E2E testing

[Ver documentación](vue-testing-best-practices/SKILL.md)

---

## 🛠️ Skills Avanzados

### create-adaptable-composable

**Diseño de composables reusables tipo librería**

- MaybeRef / MaybeRefOrGetter types
- toValue() / toRef() normalization
- Reactive-friendly APIs

[Ver documentación](create-adaptable-composable/SKILL.md)

---

### vue-jsx-best-practices

**JSX en Vue.js (diferencias con React)**

- class vs className
- Configuración plugin JSX
- Patrones JSX en Vue

[Ver documentación](vue-jsx-best-practices/SKILL.md)

---

### vue-options-api-best-practices

**Options API (legacy, solo si el proyecto lo requiere)**

- data(), methods, computed
- this context & binding
- TypeScript con Options API

[Ver documentación](vue-options-api-best-practices/SKILL.md)

---

## 📋 Activación

Estos skills se activan desde el scope frontend:

`.boltf/scopes/frontend/scope.yaml`

Para activar todos los skills de Vue.js, cambiar `enabled: true` en cada entrada:

```yaml
# Skill principal (activar primero)
- id: frontend-vue-best-practices-skill
  kind: skills
  enabled: true  # Cambiar aquí
  tags: ['frontend', 'vue', 'composition-api']
  source:
    type: local_folder
    path: available-skills/vue/vue-best-practices
  destination:
    folder: .claude/skills
    name: vue-best-practices

# Debugging
- id: frontend-vue-debug-guides-skill
  kind: skills
  enabled: true
  tags: ['frontend', 'vue', 'debugging']
  source:
    type: local_folder
    path: available-skills/vue/vue-debug-guides
  destination:
    folder: .claude/skills
    name: vue-debug-guides

# Ecosistema (activar según necesidad)
- id: frontend-vue-pinia-skill  # State management
  enabled: true

- id: frontend-vue-router-skill  # Routing
  enabled: true

- id: frontend-vue-testing-skill  # Testing
  enabled: true

# Avanzados (activar solo si se necesitan)
- id: frontend-vue-composable-skill
  enabled: false  # Solo para crear composables reusables

- id: frontend-vue-jsx-skill
  enabled: false  # Solo si el proyecto usa JSX

- id: frontend-vue-options-api-skill
  enabled: false  # Solo para proyectos legacy con Options API
```

## 🚀 Workflow Recomendado

### Proyectos Nuevos con Vue 3

1. ✅ Activar: `vue-best-practices` (obligatorio)
2. ✅ Activar: `vue-pinia-best-practices` (si usa state management)
3. ✅ Activar: `vue-router-best-practices` (si es SPA con routing)
4. ✅ Activar: `vue-testing-best-practices` (para TDD/BDD)
5. ⚠️ Activar: `vue-debug-guides` (solo cuando se necesite debugging)

### Proyectos Legacy (Options API)

1. ✅ Activar: `vue-options-api-best-practices`
2. ⚠️ Activar: `vue-best-practices` (para reference cuando migre)

## 📚 Referencias

- [Vue.js Official Docs](https://vuejs.org/)
- [Pinia Docs](https://pinia.vuejs.org/)
- [Vue Router Docs](https://router.vuejs.org/)
- [Vue Test Utils](https://test-utils.vuejs.org/)
- [Vitest](https://vitest.dev/)

---

**Origen**: Skills de [vuejs-ai/skills](https://github.com/vuejs-ai/skills)
**Licencia**: MIT
**Autor**: github.com/vuejs-ai
