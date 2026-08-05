---
name: angular-primeng-frontend
description: Angular 20 + PrimeNG 18 frontend development with standalone components, signals, typed forms, modern control flow (@if, @for), and inject() pattern. Use when developing Angular apps with PrimeNG, implementing Angular components, configuring PrimeNG themes, or building enterprise Angular UIs. Triggers => "Angular", "PrimeNG", "Angular 20", "p-button", "PrimeNG component", "Angular forms", "Angular routing", "standalone component", "ng generate", "signals Angular".
---

# Angular 20 + PrimeNG Frontend Development

## When to Use

- Developing Angular 20 applications with PrimeNG components
- Creating or modifying Angular components, services, or modules
- Implementing UI with PrimeNG component library
- Ensuring code follows Angular and PrimeNG best practices
- Whenever a user or an agent is building a frontend feature

## Quick Start

**MANDATORY FIRST STEPS:**

1. **Get Angular Best Practices** (REQUIRED before writing any Angular code):

   ```text
   Use tool: mcp_angular_cli_list_projects
   Then use: mcp_angular_cli_get_best_practices (with workspacePath)
   ```

   Example: inject(), standalone components, modern control flow (@if, @for), signals, typed forms,
   etc.

2. **List Available Projects** (for monorepo context):

   ```text
   Use tool: mcp_angular_cli_list_projects
   ```

3. **Search Angular Documentation** (for specific APIs/concepts):

   ```text
   Use tool: mcp_angular_cli_search_documentation
   ```

## Angular 20 Core Principles

### Standalone Components (Default)

```typescript
import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ButtonModule } from 'primeng/button';
import { MyService } from '../services/my.service';

@Component({
  selector: 'p-app-my-component',
  standalone: true,
  imports: [CommonModule, ButtonModule],
  template: `
    @if (isVisible) {
      <p-button label="Click me" (onClick)="handleClick()" />
    }
  `,
})
export class MyComponent {
  isVisible = true;

  // Prefer inject() over params in constructor
  service: MyService = inject(MyService);
  constructor() {}

  handleClick() {
    console.log('Button clicked');
  }
}
```

### Modern Control Flow (@if, @for, @switch)

```typescript
// ✅ Modern syntax (Angular 17+)
@if (user) {
  <p>Welcome {{ user.name }}</p>
} @else {
  <p>Please log in</p>
}

@for (item of items; track item.id) {
  <div>{{ item.name }}</div>
} @empty {
  <p>No items found</p>
}

@switch (status) {
  @case ('loading') { <p>Loading...</p> }
  @case ('error') { <p>Error occurred</p> }
  @default { <p>Data loaded</p> }
}

// ❌ Old syntax (avoid)
// *ngIf, *ngFor, *ngSwitch
```

### Typed Forms

```typescript
import { FormControl, FormGroup, Validators } from '@angular/forms';

interface UserForm {
  name: FormControl<string>;
  email: FormControl<string>;
}

export class MyComponent {
  userForm = new FormGroup<UserForm>({
    name: new FormControl('', { nonNullable: true, validators: [Validators.required] }),
    email: new FormControl('', {
      nonNullable: true,
      validators: [Validators.required, Validators.email],
    }),
  });
}
```

### Signals (Reactive State)

```typescript
import { signal, computed } from '@angular/core';

export class MyComponent {
  count = signal(0);
  doubleCount = computed(() => this.count() * 2);

  increment() {
    this.count.update((v) => v + 1);
  }
}
```

## PrimeNG Integration

### Essential MCP Tools for PrimeNG

**Before using any PrimeNG component:**

1. **Get Component Info**:

   ```text
   mcp_primeng_get_component (name: "Button")
   mcp_primeng_get_component_props (component: "DataTable")
   mcp_primeng_get_component_events (component: "Calendar")
   ```

2. **Get Correct Import**:

   ```text
   mcp_primeng_get_component_import (component: "DataTable")
   ```

3. **Get Usage Examples**:

   ```text
   mcp_primeng_get_component_sections (component: "DataTable")
   mcp_primeng_get_usage_example (component: "Button", section: "Basic")
   ```

4. **Find Components**:

   ```text
   mcp_primeng_list_components
   mcp_primeng_search_components (query: "table")
   mcp_primeng_suggest_component (description: "I need a date picker")
   ```

### Component Import Pattern

```typescript
// ✅ Correct (use MCP tool to verify)
import { ButtonModule } from 'primeng/button';
import { DataTable } from 'primeng/datatable';
import { CalendarModule } from 'primeng/calendar';

@Component({
  standalone: true,
  imports: [ButtonModule, DataTable, CalendarModule]
})
```

### Common PrimeNG Components

```typescript
// Button
<p-button label="Save" icon="pi pi-check" (onClick)="save()" />

// DataTable with modern control flow
<p-dataTable [value]="products()">
  <ng-template #header>
    <tr>
      <th>Name</th>
      <th>Price</th>
    </tr>
  </ng-template>
  <ng-template #body let-product>
    <tr>
      <td>{{ product.name }}</td>
      <td>{{ product.price }}</td>
    </tr>
  </ng-template>
</p-dataTable>

// Calendar with Forms
<p-calendar
  [formControl]="dateControl"
  dateFormat="dd/mm/yy"
  [showIcon]="true" />
```

## Key Development Workflows

### 1. Creating a New Component

```bash
# Use Angular CLI (execute from workspace directory)
ng generate component features/my-feature --standalone
```

**Then apply best practices:**

- Use signals for reactive state
- Use modern control flow (@if, @for)
- Import PrimeNG modules correctly (use MCP tools)
- Use typed forms if applicable

### 2. Adding PrimeNG Component

**Workflow:**

1. Use `mcp_primeng_suggest_component` or `mcp_primeng_search_components`
2. Use `mcp_primeng_get_component_import` for correct import
3. Use `mcp_primeng_get_component_props` to see available properties
4. Use `mcp_primeng_get_component_sections` for examples
5. Implement with Angular best practices

### 3. Modernizing Legacy Code

```text
# For OnPush/Zoneless migration:
Use tool: mcp_angular_cli_onpush_zoneless_migration (fileOrDirPath)
```

## Best Practices Checklist

- ✅ Use `mcp_angular_cli_get_best_practices` BEFORE writing code
- ✅ Use standalone components (default in Angular 20)
- ✅ Use modern control flow (@if, @for, @switch)
- ✅ Use signals for reactive state
- ✅ Use typed forms
- ✅ Verify PrimeNG imports with MCP tools
- ✅ Use OnPush change detection when possible
- ✅ Follow accessibility guidelines (`mcp_primeng_get_accessibility_guide`)
- ❌ Avoid NgModule (use only if necessary for legacy)
- ❌ Avoid old control flow (*ngIf,*ngFor)
- ❌ Avoid untyped forms

## MCP Tools Quick Reference

### Angular Tools

| Tool                                        | Purpose                                           |
| ------------------------------------------- | ------------------------------------------------- |
| `mcp_angular_cli_get_best_practices`        | **MANDATORY** Get version-specific best practices |
| `mcp_angular_cli_list_projects`             | List all Angular projects in workspace            |
| `mcp_angular_cli_search_documentation`      | Search official Angular docs                      |
| `mcp_angular_cli_onpush_zoneless_migration` | Migrate to OnPush/zoneless                        |
| `mcp_angular_cli_ai_tutor`                  | Start interactive Angular tutorial                |

### PrimeNG Tools

| Tool                                      | Purpose                                 |
| ----------------------------------------- | --------------------------------------- |
| `mcp_primeng_get_component`               | Get detailed component info             |
| `mcp_primeng_get_component_import`        | Get correct import statement            |
| `mcp_primeng_get_component_props`         | List all component properties           |
| `mcp_primeng_get_component_events`        | List all component events               |
| `mcp_primeng_get_component_sections`      | Get usage examples                      |
| `mcp_primeng_list_components`             | List all available components           |
| `mcp_primeng_search_components`           | Search components by keyword            |
| `mcp_primeng_suggest_component`           | Get component suggestion by description |
| `mcp_primeng_get_accessibility_guide`     | Get accessibility guidelines            |
| `mcp_primeng_generate_component_template` | Generate component template             |

## References

- [Angular Official Docs](https://angular.dev)
- [PrimeNG Components](https://primeng.org)
- Use `mcp_angular_cli_search_documentation` for specific Angular topics
- Use `mcp_primeng_search_components` for specific PrimeNG components
