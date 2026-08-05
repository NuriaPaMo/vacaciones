# Dark Mode Setup with Tailwind CSS v4

Complete guide to implementing dark mode using Tailwind v4's native CSS features, theme provider,
toggle component, and system preference detection.

## Dark Mode in Tailwind v4

### @custom-variant Dark Mode

Tailwind v4 uses `@custom-variant` instead of `darkMode: "class"` configuration:

```css
/* app.css */
@import "tailwindcss";

/* Define dark mode variant - applies when .dark class is present */
@custom-variant dark (&:where(.dark, .dark *));

/* Alternative: Media query-based (auto-follows system preference) */
@custom-variant dark (&:where(@media (prefers-color-scheme: dark)));
```

**Syntax explanation**:

- `&:where(.dark, .dark *)` - Targets elements with `.dark` class or any descendant of `.dark`
- `@media (prefers-color-scheme: dark)` - Automatic based on system preference

## Complete Dark Mode Setup

### Step 1: Define Theme Tokens

```css
/* app.css */
@import "tailwindcss";

@custom-variant dark (&:where(.dark, .dark *));

@theme {
  /* ===== LIGHT MODE (Default) ===== */
  --color-background: oklch(100% 0 0); /* White */
  --color-foreground: oklch(14.5% 0.025 264); /* Near black */
  --color-primary: oklch(45% 0.2 260); /* Blue */
  --color-primary-foreground: oklch(98% 0.01 0); /* White */
  --color-border: oklch(91% 0.01 264); /* Light gray */
  --color-ring: oklch(45% 0.2 260); /* Matches primary */
}

/* ===== DARK MODE OVERRIDES ===== */
.dark {
  --color-background: oklch(14.5% 0.025 264); /* Dark */
  --color-foreground: oklch(98% 0.01 0); /* Near white */
  --color-primary: oklch(70% 0.15 260); /* Lighter blue */
  --color-primary-foreground: oklch(14.5% 0.025 264); /* Dark */
  --color-border: oklch(22% 0.02 264); /* Dark gray */
  --color-ring: oklch(70% 0.15 260); /* Matches primary */
}

/* Base styles that respect theme */
@layer base {
  * {
    @apply border-border;
  }

  body {
    @apply bg-background text-foreground antialiased;
  }
}
```

### Step 2: Theme Provider (React)

```typescript
// providers/ThemeProvider.tsx
'use client'

import { createContext, useContext, useEffect, useState, type ReactNode } from 'react'

type Theme = 'dark' | 'light' | 'system'
type ResolvedTheme = 'dark' | 'light'

interface ThemeContextType {
  theme: Theme
  setTheme: (theme: Theme) => void
  resolvedTheme: ResolvedTheme
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined)

interface ThemeProviderProps {
  children: ReactNode
  defaultTheme?: Theme
  storageKey?: string
  attribute?: 'class' | 'data-theme'
}

export function ThemeProvider({
  children,
  defaultTheme = 'system',
  storageKey = 'app-theme',
  attribute = 'class',
}: ThemeProviderProps) {
  const [theme, setTheme] = useState<Theme>(defaultTheme)
  const [resolvedTheme, setResolvedTheme] = useState<ResolvedTheme>('light')

  // Load theme from localStorage on mount
  useEffect(() => {
    const stored = localStorage.getItem(storageKey) as Theme | null
    if (stored && ['dark', 'light', 'system'].includes(stored)) {
      setTheme(stored)
    }
  }, [storageKey])

  // Apply theme to DOM and resolve 'system' preference
  useEffect(() => {
    const root = document.documentElement

    // Remove existing theme classes/attributes
    if (attribute === 'class') {
      root.classList.remove('light', 'dark')
    } else {
      root.removeAttribute('data-theme')
    }

    // Resolve 'system' to actual preference
    const resolved: ResolvedTheme =
      theme === 'system'
        ? (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
        : theme

    // Apply resolved theme
    if (attribute === 'class') {
      root.classList.add(resolved)
    } else {
      root.setAttribute('data-theme', resolved)
    }

    setResolvedTheme(resolved)

    // Update meta theme-color for mobile browsers
    const metaThemeColor = document.querySelector('meta[name="theme-color"]')
    if (metaThemeColor) {
      metaThemeColor.setAttribute(
        'content',
        resolved === 'dark' ? '#09090b' : '#ffffff' // Tailwind zinc-950 / white
      )
    }
  }, [theme, attribute])

  // Listen for system preference changes when theme is 'system'
  useEffect(() => {
    if (theme !== 'system') return

    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')

    const handleChange = (e: MediaQueryListEvent) => {
      const resolved: ResolvedTheme = e.matches ? 'dark' : 'light'
      setResolvedTheme(resolved)

      if (attribute === 'class') {
        document.documentElement.classList.remove('light', 'dark')
        document.documentElement.classList.add(resolved)
      } else {
        document.documentElement.setAttribute('data-theme', resolved)
      }
    }

    mediaQuery.addEventListener('change', handleChange)
    return () => mediaQuery.removeEventListener('change', handleChange)
  }, [theme, attribute])

  const handleSetTheme = (newTheme: Theme) => {
    localStorage.setItem(storageKey, newTheme)
    setTheme(newTheme)
  }

  return (
    <ThemeContext.Provider
      value={{
        theme,
        setTheme: handleSetTheme,
        resolvedTheme,
      }}
    >
      {children}
    </ThemeContext.Provider>
  )
}

export const useTheme = () => {
  const context = useContext(ThemeContext)
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider')
  }
  return context
}
```

### Step 3: Theme Toggle Component

```typescript
// components/ThemeToggle.tsx
'use client'

import { Moon, Sun } from 'lucide-react'
import { useTheme } from '@/providers/ThemeProvider'
import { Button } from '@/components/ui/button'

export function ThemeToggle() {
  const { resolvedTheme, setTheme } = useTheme()

  const toggleTheme = () => {
    setTheme(resolvedTheme === 'dark' ? 'light' : 'dark')
  }

  return (
    <Button variant="ghost" size="icon" onClick={toggleTheme} aria-label="Toggle theme">
      <Sun className="size-5 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
      <Moon className="absolute size-5 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
    </Button>
  )
}
```

### Step 4: Theme Selector (with System Option)

```typescript
// components/ThemeSwitcher.tsx
'use client'

import { Monitor, Moon, Sun } from 'lucide-react'
import { useTheme } from '@/providers/ThemeProvider'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'

export function ThemeSwitcher() {
  const { theme, setTheme } = useTheme()

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="outline" size="icon">
          <Sun className="size-5 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
          <Moon className="absolute size-5 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
          <span className="sr-only">Toggle theme</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuItem onClick={() => setTheme('light')}>
          <Sun className="mr-2 size-4" />
          <span>Light</span>
          {theme === 'light' && <span className="ml-auto">✓</span>}
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme('dark')}>
          <Moon className="mr-2 size-4" />
          <span>Dark</span>
          {theme === 'dark' && <span className="ml-auto">✓</span>}
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme('system')}>
          <Monitor className="mr-2 size-4" />
          <span>System</span>
          {theme === 'system' && <span className="ml-auto">✓</span>}
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
```

### Step 5: Add to App Layout

```typescript
// app/layout.tsx (Next.js App Router)
import { ThemeProvider } from '@/providers/ThemeProvider'
import './globals.css'

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <meta name="theme-color" content="#ffffff" />
      </head>
      <body>
        <ThemeProvider defaultTheme="system" storageKey="app-theme">
          {children}
        </ThemeProvider>
      </body>
    </html>
  )
}

// Note: suppressHydrationWarning prevents Next.js warning when class is added by ThemeProvider
```

## Usage in Components

```tsx
// Automatic dark mode support via Tailwind utilities
<div className="bg-background text-foreground">
  <h1 className="text-primary">Title</h1>
  <p className="text-muted-foreground">Subtle text</p>
</div>

// Manual dark mode overrides (when needed)
<div className="bg-white dark:bg-zinc-900">
  <span className="text-gray-900 dark:text-white">Custom colors</span>
</div>

// Conditional rendering based on theme
import { useTheme } from '@/providers/ThemeProvider'

function Logo() {
  const { resolvedTheme } = useTheme()

  return (
    <img
      src={resolvedTheme === 'dark' ? '/logo-dark.png' : '/logo-light.png'}
      alt="Logo"
    />
  )
}
```

## Advanced Patterns

### Prevent Flash of Unstyled Content (FOUC)

```typescript
// app/layout.tsx
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        {/* Inline script runs before React hydration */}
        <script
          dangerouslySetInnerHTML={{
            __html: `
              (function() {
                const theme = localStorage.getItem('app-theme') || 'system';
                const resolved = theme === 'system'
                  ? (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
                  : theme;
                document.documentElement.classList.add(resolved);
              })();
            `,
          }}
        />
        <meta name="theme-color" content="#ffffff" />
      </head>
      <body>
        <ThemeProvider defaultTheme="system">{children}</ThemeProvider>
      </body>
    </html>
  )
}
```

### Per-Page Theme Override

```typescript
// app/admin/layout.tsx - Force dark mode for admin section
export default function AdminLayout({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    document.documentElement.classList.add('dark')
    return () => document.documentElement.classList.remove('dark')
  }, [])

  return <div>{children}</div>
}
```

## Best Practices

### ✅ DO

- ✅ Use semantic color tokens (`--color-background`, not hardcoded colors)
- ✅ Test all components in both light and dark modes
- ✅ Provide system preference option (respect user's OS setting)
- ✅ Add `suppressHydrationWarning` to `<html>` tag
- ✅ Use OKLCH colors for consistent brightness across themes
- ✅ Update `meta[name="theme-color"]` for mobile browsers

### ❌ DON'T

- ❌ Hardcode `bg-white` or `bg-black` (use `bg-background` instead)
- ❌ Forget to test images/logos in dark mode
- ❌ Ignore system preference (always offer 'system' option)
- ❌ Flash unstyled content (use inline script blocking strategy)
- ❌ Override theme classes manually outside ThemeProvider

---

**Return to**: [SKILL.md](../SKILL.md) for main documentation.
