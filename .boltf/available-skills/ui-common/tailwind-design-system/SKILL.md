---
name: tailwind-design-system
description:
  Build scalable design systems with Tailwind CSS v4, design tokens, component libraries, and
  responsive patterns. Use when creating component libraries, implementing design systems, or
  standardizing UI patterns.
---

# Tailwind Design System (v4) - CSS-First Configuration

Build production-ready design systems with Tailwind CSS v4's CSS-first approach, OKLCH color system,
design tokens, and modern component patterns.

## When to Use This Skill

✅ Creating component libraries with Tailwind v4  
✅ Implementing design tokens and theming with `@theme` directive  
✅ Building responsive and accessible React components  
✅ Migrating from Tailwind v3 to v4  
✅ Setting up dark mode with native CSS features  
✅ Standardizing UI patterns across a codebase  
✅ Using CVA (Class Variance Authority) for component variants

## What's New in v4

Tailwind v4 introduces a **CSS-first configuration** model that replaces JavaScript config files:

| v3 Approach                       | v4 Approach (CSS-First)                                                         |
| --------------------------------- | ------------------------------------------------------------------------------- |
| `tailwind.config.ts`              | `@theme` directive in CSS                                                       |
| `@tailwind base/components/utils` | `@import "tailwindcss"`                                                         |
| `darkMode: "class"`               | `@custom-variant dark (&:where(.dark, .dark *))`                                |
| `theme.extend.colors`             | `@theme { --color-*: oklch(...) }`                                              |
| `require("tailwindcss-animate")`  | CSS `@keyframes` in `@theme` + `@starting-style` for automatic entry animations |

📖 **Full v3→v4 Migration**: See [Migration Guide](references/v4-migration-guide.md)

## Quick Start

### 1. Install Tailwind v4

```bash
npm install tailwindcss@next @tailwindcss/postcss@next
```

**postcss.config.js**:

```javascript
export default {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};
```

### 2. Define Theme with @theme Directive

```css
/* app.css - CSS-first configuration */
@import "tailwindcss";

/* Dark mode variant */
@custom-variant dark (&:where(.dark, .dark *));

@theme {
  /* Color tokens using OKLCH (better color perception than HSL) */
  --color-background: oklch(100% 0 0); /* White */
  --color-foreground: oklch(14.5% 0.025 264); /* Near black */

  --color-primary: oklch(45% 0.2 260); /* Blue */
  --color-primary-foreground: oklch(98% 0.01 0); /* White text */

  --color-destructive: oklch(53% 0.22 27); /* Red */
  --color-destructive-foreground: oklch(98% 0.01 0);

  /* Radius tokens */
  --radius-sm: 0.25rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;

  /* Animation with keyframes */
  --animate-fade-in: fade-in 0.2s ease-out;

  @keyframes fade-in {
    from {
      opacity: 0;
    }
    to {
      opacity: 1;
    }
  }
}

/* Dark mode overrides */
.dark {
  --color-background: oklch(14.5% 0.025 264); /* Dark */
  --color-foreground: oklch(98% 0.01 0); /* Light */
  --color-primary: oklch(70% 0.15 260); /* Lighter blue */
}

/* Base styles */
@layer base {
  * {
    @apply border-border;
  }

  body {
    @apply bg-background text-foreground antialiased;
  }
}
```

**Why OKLCH?**

- ✅ Perceptually uniform lightness (looks consistent across hues)
- ✅ Wider color gamut (P3, Rec.2020 - future-proof for HDR)
- ✅ Better than HSL for accessible color systems

📖 **Deep Dive**: See [Design Tokens](references/design-tokens.md) for complete token system,
semantic naming, and color theory.

### 3. Build Components with CVA

```typescript
// components/ui/button.tsx
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const buttonVariants = cva(
  // Base styles
  'inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:ring-2',
  {
    variants: {
      variant: {
        default: 'bg-primary text-primary-foreground hover:bg-primary/90',
        destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
        outline: 'border border-border hover:bg-accent',
        ghost: 'hover:bg-accent hover:text-accent-foreground',
      },
      size: {
        default: 'h-10 px-4 py-2',
        sm: 'h-9 px-3',
        lg: 'h-11 px-8',
        icon: 'size-10',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'default',
    },
  }
)

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {}

export function Button({ className, variant, size, ...props }: ButtonProps) {
  return (
    <button
      className={cn(buttonVariants({ variant, size, className }))}
      {...props}
    />
  )
}

// Usage
<Button variant="destructive" size="lg">Delete</Button>
<Button variant="outline">Cancel</Button>
```

**Core Utility**:

```typescript
// lib/utils.ts
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

📖 **Deep Dive**: See [Component Patterns](references/component-patterns.md) for CVA patterns,
compound components, forms with validation, responsive grids, and Radix UI integration.

### 4. Setup Dark Mode

```typescript
// providers/ThemeProvider.tsx
'use client'

import { createContext, useContext, useEffect, useState } from 'react'

type Theme = 'dark' | 'light' | 'system'

const ThemeContext = createContext<{
  theme: Theme
  setTheme: (theme: Theme) => void
  resolvedTheme: 'dark' | 'light'
} | undefined>(undefined)

export function ThemeProvider({
  children,
  defaultTheme = 'system',
}: {
  children: React.ReactNode
  defaultTheme?: Theme
}) {
  const [theme, setTheme] = useState<Theme>(defaultTheme)
  const [resolvedTheme, setResolvedTheme] = useState<'dark' | 'light'>('light')

  useEffect(() => {
    const stored = localStorage.getItem('theme') as Theme | null
    if (stored) setTheme(stored)
  }, [])

  useEffect(() => {
    const root = document.documentElement
    root.classList.remove('light', 'dark')

    const resolved =
      theme === 'system'
        ? window.matchMedia('(prefers-color-scheme: dark)').matches
          ? 'dark'
          : 'light'
        : theme

    root.classList.add(resolved)
    setResolvedTheme(resolved)
  }, [theme])

  return (
    <ThemeContext.Provider
      value={{
        theme,
        setTheme: (newTheme) => {
          localStorage.setItem('theme', newTheme)
          setTheme(newTheme)
        },
        resolvedTheme,
      }}
    >
      {children}
    </ThemeContext.Provider>
  )
}

export const useTheme = () => {
  const context = useContext(ThemeContext)
  if (!context) throw new Error('useTheme must be used within ThemeProvider')
  return context
}
```

```typescript
// components/ThemeToggle.tsx
import { Moon, Sun } from 'lucide-react'
import { useTheme } from '@/providers/ThemeProvider'
import { Button } from '@/components/ui/button'

export function ThemeToggle() {
  const { resolvedTheme, setTheme } = useTheme()

  return (
    <Button
      variant="ghost"
      size="icon"
      onClick={() => setTheme(resolvedTheme === 'dark' ? 'light' : 'dark')}
    >
      <Sun className="rotate-0 scale-100 dark:-rotate-90 dark:scale-0" />
      <Moon className="absolute rotate-90 scale-0 dark:rotate-0 dark:scale-100" />
    </Button>
  )
}
```

📖 **Deep Dive**: See [Dark Mode Setup](references/dark-mode-setup.md) for theme provider, system
preference detection, FOUC prevention, and per-page theme overrides.

## Core Principles

### 1. Semantic Token Naming

```text
Brand Tokens (abstract)      → Semantic Tokens (purpose)          → Component Tokens (specific)
oklch(45% 0.2 260)           → --color-primary                    → bg-primary, text-primary-foreground
```

Always use **semantic names** (`--color-primary`) instead of **descriptive names**
(`--color-blue-500`).

### 2. Progressive Disclosure

Start with essential styles in main SKILL.md, link to deep references for advanced topics:

- 📖 **[v4 Migration Guide](references/v4-migration-guide.md)** - Complete v3→v4 upgrade path
- 📖 **[Design Tokens](references/design-tokens.md)** - OKLCH colors, spacing, typography,
  animations
- 📖 **[Component Patterns](references/component-patterns.md)** - CVA, forms, grids, dialogs
- 📖 **[Dark Mode Setup](references/dark-mode-setup.md)** - ThemeProvider, toggle, system preference

### 3. Design Token Hierarchy

```css
@theme {
  /* 1. Primitives (brand colors) */
  --color-blue-base: oklch(45% 0.2 260);

  /* 2. Semantic tokens (purpose-based) */
  --color-primary: var(--color-blue-base);

  /* 3. Component tokens (context-specific) */
  --color-button-primary-bg: var(--color-primary);
}

/* Usage: Prefer highest abstraction level */
<button className="bg-primary">Click me</button>
```

## Best Practices

### ✅ DO

- ✅ Use `@theme` directive for all design tokens (CSS-first)
- ✅ Use OKLCH colors for semantic tokens (better perception)
- ✅ Use CVA for component variants (type-safe, composable)
- ✅ Use semantic naming (`--color-primary`, not `--color-blue`)
- ✅ Test components in both light and dark modes
- ✅ Provide 'system' theme option (respect OS preference)
- ✅ Use `cn()` utility to merge Tailwind classes safely
- ✅ Keep dark mode overrides minimal (only what changes)

### ❌ DON'T

- ❌ Use JavaScript config file (v4 is CSS-first)
- ❌ Hardcode `bg-white` / `bg-black` (use `bg-background`)
- ❌ Mix HSL and OKLCH (choose one color system)
- ❌ Create too many token variations (keep it simple)
- ❌ Forget `suppressHydrationWarning` on `<html>` tag
- ❌ Ignore FOUC (flash of unstyled content)
- ❌ Skip accessibility testing in dark mode

## Common Patterns

### Responsive Design

```tsx
<div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
  <Card>Item 1</Card>
  <Card>Item 2</Card>
  <Card>Item 3</Card>
</div>
```

### Conditional Styling

```tsx
<Button
  variant={isDestructive ? "destructive" : "default"}
  className={cn("w-full", isPending && "opacity-50")}
>
  Submit
</Button>
```

### Dark Mode Overrides

```tsx
<div className="bg-white dark:bg-zinc-900">
  <span className="text-gray-900 dark:text-white">Custom colors</span>
</div>
```

## References

📖 **[v4 Migration Guide](references/v4-migration-guide.md)**  
Step-by-step upgrade path from Tailwind v3 to v4, breaking changes, configuration conversion,
animation migration.

📖 **[Design Tokens](references/design-tokens.md)**  
Complete token system: OKLCH color theory, semantic naming, spacing, typography, animation tokens,
dark mode overrides.

📖 **[Component Patterns](references/component-patterns.md)**  
CVA button variants, compound components (Card), form validation, responsive grids, Radix UI
dialogs, utility functions.

📖 **[Dark Mode Setup](references/dark-mode-setup.md)**  
ThemeProvider implementation, theme toggle component, system preference detection, FOUC prevention,
per-page overrides.

---

**Last Updated**: 2026-01-26  
**Version**: 2.0 (Progressive Disclosure - CSS-First)
