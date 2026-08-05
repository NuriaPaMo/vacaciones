# Design Tokens with Tailwind CSS v4

Complete guide to design tokens, CSS custom properties, OKLCH color system, semantic naming, and
theming with Tailwind v4's `@theme` directive.

## Core Concepts

### Design Token Hierarchy

```text
┌─────────────────────┐
│   Brand Tokens      │  Abstract values (colors, sizes)
│   (primitives)      │  Example: oklch(45% 0.2 260)
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Semantic Tokens    │  Purpose-based (primary, destructive)
│  (meaningful)       │  Example: --color-primary
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Component Tokens    │  Component-specific
│  (contextual)       │  Example: bg-primary, text-primary-foreground
└─────────────────────┘
```

### @theme Directive

The `@theme` block replaces `tailwind.config.ts` for defining custom design tokens:

```css
@import "tailwindcss";

@theme {
  /* All your design tokens go here */
  --color-primary: oklch(53% 0.2 260);
  --radius-lg: 0.5rem;
  --font-sans: "Inter", system-ui, sans-serif;
}
```

**Benefits**:

- ✅ CSS-first configuration (no JavaScript)
- ✅ Better IDE autocomplete
- ✅ Easier theme switching at runtime
- ✅ Supports CSS cascade and inheritance

## Color Tokens

### OKLCH Color System

**Why OKLCH over HSL?**

| Feature                   | HSL                         | OKLCH                              |
| ------------------------- | --------------------------- | ---------------------------------- |
| **Perceptual Uniformity** | ❌ Brightness varies by hue | ✅ Consistent perceived lightness  |
| **Color Gamut**           | sRGB only                   | sRGB, P3, Rec.2020 (HDR-ready)     |
| **Lightness**             | Not perceptually uniform    | Lightness matches human perception |
| **saturation**            | Absolute (0-100%)           | Chroma (intensity, varies by hue)  |
| **Hue Rotation**          | Smooth but inconsistent     | Smooth and perceptually uniform    |

**OKLCH Syntax**:

```css
oklch(L C H / A)
```

- **L** (Lightness): 0% (black) to 100% (white)
- **C** (Chroma): 0 (gray) to ~0.4 (vibrant) - varies by hue
- **H** (Hue): 0-360° (same as HSL - red, yellow, green, cyan, blue, magenta)
- **A** (Alpha): 0 to 1 (optional, for transparency)

**Examples**:

```css
/* Pure black */
oklch(0% 0 0)

/* Pure white */
oklch(100% 0 0)

/* Vibrant blue (primary color) */
oklch(53% 0.2 260)

/* Muted gray */
oklch(60% 0.01 264)

/* With transparency */
oklch(53% 0.2 260 / 0.8)
```

### Complete Color Token System

```css
@theme {
  /* ===== LIGHT MODE (Default) ===== */

  /* Background colors */
  --color-background: oklch(100% 0 0); /* Pure white */
  --color-foreground: oklch(14.5% 0.025 264); /* Near black */

  /* Primary brand color */
  --color-primary: oklch(45% 0.2 260); /* Blue */
  --color-primary-foreground: oklch(98% 0.01 0); /* White text */

  /* Secondary color */
  --color-secondary: oklch(96% 0.01 264); /* Light gray */
  --color-secondary-foreground: oklch(14.5% 0.025 264); /* Dark text */

  /* Muted (subtle backgrounds) */
  --color-muted: oklch(96% 0.01 264);
  --color-muted-foreground: oklch(46% 0.02 264);

  /* Accent (interactive elements) */
  --color-accent: oklch(96% 0.01 264);
  --color-accent-foreground: oklch(14.5% 0.025 264);

  /* Destructive (errors, delete actions) */
  --color-destructive: oklch(53% 0.22 27); /* Red */
  --color-destructive-foreground: oklch(98% 0.01 0);

  /* Success (positive actions) */
  --color-success: oklch(60% 0.15 145); /* Green */
  --color-success-foreground: oklch(14.5% 0.025 264);

  /* Warning (caution states) */
  --color-warning: oklch(70% 0.18 75); /* Orange/Yellow */
  --color-warning-foreground: oklch(14.5% 0.025 264);

  /* Info (informational messages) */
  --color-info: oklch(60% 0.15 230); /* Cyan */
  --color-info-foreground: oklch(14.5% 0.025 264);

  /* Borders */
  --color-border: oklch(91% 0.01 264); /* Light gray border */
  --color-input: oklch(91% 0.01 264); /* Input border */

  /* Focus ring */
  --color-ring: oklch(45% 0.2 260); /* Matches primary */
  --color-ring-offset: oklch(100% 0 0); /* White offset */

  /* Card container */
  --color-card: oklch(100% 0 0);
  --color-card-foreground: oklch(14.5% 0.025 264);

  /* Popover */
  --color-popover: oklch(100% 0 0);
  --color-popover-foreground: oklch(14.5% 0.025 264);
}

/* ===== DARK MODE OVERRIDES ===== */
.dark {
  --color-background: oklch(14.5% 0.025 264); /* Dark gray/black */
  --color-foreground: oklch(98% 0.01 0); /* Near white */

  --color-primary: oklch(70% 0.15 260); /* Lighter blue */
  --color-primary-foreground: oklch(14.5% 0.025 264); /* Dark text */

  --color-secondary: oklch(22% 0.02 264); /* Dark gray */
  --color-secondary-foreground: oklch(98% 0.01 0);

  --color-muted: oklch(22% 0.02 264);
  --color-muted-foreground: oklch(65% 0.02 264);

  --color-accent: oklch(22% 0.02 264);
  --color-accent-foreground: oklch(98% 0.01 0);

  --color-destructive: oklch(55% 0.18 27); /* Slightly muted red */
  --color-destructive-foreground: oklch(98% 0.01 0);

  --color-success: oklch(65% 0.12 145);
  --color-success-foreground: oklch(98% 0.01 0);

  --color-warning: oklch(75% 0.15 75);
  --color-warning-foreground: oklch(14.5% 0.025 264);

  --color-info: oklch(65% 0.12 230);
  --color-info-foreground: oklch(98% 0.01 0);

  --color-border: oklch(22% 0.02 264);
  --color-input: oklch(22% 0.02 264);

  --color-ring: oklch(70% 0.15 260);
  --color-ring-offset: oklch(14.5% 0.025 264);

  --color-card: oklch(14.5% 0.025 264);
  --color-card-foreground: oklch(98% 0.01 0);

  --color-popover: oklch(14.5% 0.025 264);
  --color-popover-foreground: oklch(98% 0.01 0);
}
```

### Usage in Components

```tsx
// Automatic color class generation
<div className="bg-primary text-primary-foreground">Primary Button</div>
<div className="bg-destructive text-destructive-foreground">Delete</div>

// With opacity modifier
<div className="bg-primary/80">80% opacity</div>

// Hover states
<button className="bg-primary hover:bg-primary/90">Hover me</button>
```

## Spacing & Radius Tokens

```css
@theme {
  /* Spacing scale (use sparingly - Tailwind's default is good) */
  --spacing-xs: 0.25rem; /* 4px */
  --spacing-sm: 0.5rem; /* 8px */
  --spacing-md: 1rem; /* 16px */
  --spacing-lg: 1.5rem; /* 24px */
  --spacing-xl: 2rem; /* 32px */
  --spacing-2xl: 3rem; /* 48px */

  /* Border radius tokens */
  --radius-none: 0;
  --radius-sm: 0.25rem; /* 4px */
  --radius-md: 0.375rem; /* 6px - default for most components */
  --radius-lg: 0.5rem; /* 8px */
  --radius-xl: 0.75rem; /* 12px */
  --radius-2xl: 1rem; /* 16px */
  --radius-full: 9999px; /* Pill shape */

  /* Component-specific radius */
  --radius-button: var(--radius-md);
  --radius-input: var(--radius-md);
  --radius-card: var(--radius-lg);
  --radius-dialog: var(--radius-xl);
}

/* Usage */
.btn {
  @apply rounded-button; /* Uses --radius-button */
}

.card {
  @apply rounded-card; /* Uses --radius-card */
}
```

## Typography Tokens

```css
@theme {
  /* Font families */
  --font-sans: "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  --font-serif: "Merriweather", Georgia, serif;
  --font-mono: "JetBrains Mono", "Fira Code", Consolas, monospace;

  /* Font sizes with line heights */
  --font-size-xs: 0.75rem; /* 12px */
  --font-size-sm: 0.875rem; /* 14px */
  --font-size-base: 1rem; /* 16px */
  --font-size-lg: 1.125rem; /* 18px */
  --font-size-xl: 1.25rem; /* 20px */
  --font-size-2xl: 1.5rem; /* 24px */
  --font-size-3xl: 1.875rem; /* 30px */
  --font-size-4xl: 2.25rem; /* 36px */

  /* Font weights */
  --font-weight-light: 300;
  --font-weight-normal: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;

  /* Line heights */
  --line-height-tight: 1.25;
  --line-height-normal: 1.5;
  --line-height-relaxed: 1.75;
}

/* Usage */
body {
  font-family: var(--font-sans);
  font-size: var(--font-size-base);
  line-height: var(--line-height-normal);
}
```

## Animation Tokens

```css
@theme {
  /* Duration tokens */
  --duration-fast: 150ms;
  --duration-normal: 300ms;
  --duration-slow: 500ms;

  /* Easing functions */
  --ease-in: cubic-bezier(0.4, 0, 1, 1);
  --ease-out: cubic-bezier(0, 0, 0.2, 1);
  --ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);

  /* Animation tokens with keyframes */
  --animate-fade-in: fade-in var(--duration-fast) var(--ease-out);
  --animate-fade-out: fade-out var(--duration-fast) var(--ease-in);
  --animate-slide-in: slide-in var(--duration-normal) var(--ease-out);
  --animate-slide-out: slide-out var(--duration-normal) var(--ease-in);
  --animate-dialog-in: dialog-in var(--duration-normal) var(--ease-out);
  --animate-dialog-out: dialog-out var(--duration-normal) var(--ease-in);

  @keyframes fade-in {
    from { opacity: 0; }
    to { opacity: 1; }
  }

  @keyframes fade-out {
    from { opacity: 1; }
    to { opacity: 0; }
  }

  @keyframes slide-in {
    from {
      transform: translateY(-0.5rem);
      opacity: 0;
    }
    to {
      transform: translateY(0);
      opacity: 1;
    }
  }

  @keyframes slide-out {
    from {
      transform: translateY(0);
      opacity: 1;
    }
    to {
      transform: translateY(-0.5rem);
      opacity: 0;
    }
  }

  @keyframes dialog-in {
    from {
      opacity: 0;
      transform: translate(-50%, -48%) scale(0.96);
    }
    to {
      opacity: 1;
      transform: translate(-50%, -50%) scale(1);
    }
  }

  @keyframes dialog-out {
    from {
      opacity: 1;
      transform: translate(-50%, -50%) scale(1);
    }
    to {
      opacity: 0;
      transform: translate(-50%, -48%) scale(0.96);
    }
  }
}

/* Usage */
<div className="animate-fade-in">Fades in</div>
<div className="animate-dialog-in">Dialog entrance</div>
```

## Best Practices

### ✅ DO

- ✅ Use OKLCH for brand colors (better color perception)
- ✅ Use semantic token names (`--color-primary`, not `--color-blue-500`)
- ✅ Group related tokens (colors, spacing, typography)
- ✅ Document token purpose in comments
- ✅ Keep dark mode overrides minimal (only what differs)
- ✅ Use CSS variables for runtime theme switching

### ❌ DON'T

- ❌ Hardcode color values in components (use tokens)
- ❌ Create too many token variations (keep it simple)
- ❌ Mix HSL and OKLCH (choose one system)
- ❌ Forget to test dark mode
- ❌ Duplicate Tailwind's default scale unnecessarily

---

**Return to**: [SKILL.md](../SKILL.md) for main documentation.
