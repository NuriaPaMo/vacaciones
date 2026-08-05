# Tailwind CSS v3 → v4 Migration Guide

Complete guide for upgrading from Tailwind CSS v3 to v4, including configuration changes, breaking
changes, and updated patterns.

## Key Changes Overview

| Aspect                 | Tailwind v3                       | Tailwind v4                                                                 |
| ---------------------- | --------------------------------- | --------------------------------------------------------------------------- |
| **Configuration**      | `tailwind.config.ts`              | `@theme` directive in CSS                                                   |
| **Imports**            | `@tailwind base/components/utils` | `@import "tailwindcss"`                                                     |
| **Dark Mode**          | `darkMode: "class"`               | `@custom-variant dark (&:where(.dark, .dark *))`                            |
| **Colors**             | `theme.extend.colors`             | `@theme { --color-*: value }`                                               |
| **Animations**         | `require("tailwindcss-animate")`  | CSS `@keyframes` in `@theme` + `@starting-style` for entry animations       |
| **Custom Variants**    | `plugins: [plugin()]`             | `@custom-variant name (selector)`                                           |
| **Breakpoints**        | `screens: { ... }`                | `@theme { --breakpoint-*: value }`                                          |
| **Content Paths**      | `content: ["./src/**/*.tsx"]`     | Automatic (scans project, or specify in `@config`)                          |
| **JIT Mode**           | Opt-in (`mode: "jit"`)            | Always on (default behavior)                                                |
| **Important Selector** | `important: "#app"`               | `@utility important-modifier { ... }` or `@import "tailwindcss" important;` |
| **Prefix**             | `prefix: "tw-"`                   | `@config { prefix: "tw-" }`                                                 |

## Step-by-Step Migration

### Step 1: Update Dependencies

```bash
# Remove old dependencies
npm uninstall tailwindcss postcss autoprefixer tailwindcss-animate

# Install Tailwind v4 (requires Node 18+)
npm install tailwindcss@next @tailwindcss/postcss@next

# Optional: Install compatibility plugin if using complex v3 config
npm install @tailwindcss/upgrade@next
```

**package.json**:

```json
{
  "devDependencies": {
    "tailwindcss": "^4.0.0",
    "@tailwindcss/postcss": "^4.0.0"
  }
}
```

### Step 2: Update PostCSS Config

```javascript
// postcss.config.js (or .mjs)
export default {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};
```

### Step 3: Convert Configuration to CSS

#### Before (v3 - tailwind.config.ts)

```typescript
import type { Config } from "tailwindcss";

export default {
  darkMode: "class",
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        border: "hsl(var(--border))",
        background: "hsl(var(--background))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
      },
      keyframes: {
        "fade-in": {
          from: { opacity: "0" },
          to: { opacity: "1" },
        },
      },
      animation: {
        "fade-in": "fade-in 0.2s ease-out",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
} satisfies Config;
```

#### After (v4 - app.css)

```css
@import "tailwindcss";

/* Dark mode variant */
@custom-variant dark (&:where(.dark, .dark *));

@theme {
  /* Color tokens - use OKLCH for better color perception */
  --color-border: oklch(91% 0.01 264);
  --color-background: oklch(100% 0 0);

  --color-primary: oklch(14.5% 0.025 264);
  --color-primary-foreground: oklch(98% 0.01 264);

  /* Radius tokens */
  --radius: 0.5rem;

  /* Animation tokens - keyframes inside @theme */
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
  --color-background: oklch(14.5% 0.025 264);
  --color-border: oklch(22% 0.02 264);
  --color-primary: oklch(98% 0.01 264);
  --color-primary-foreground: oklch(14.5% 0.025 264);
}
```

### Step 4: Update CSS Imports

#### Before (v3)

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

#### After (v4)

```css
@import "tailwindcss";

/* Optional: Base styles layer */
@layer base {
  * {
    @apply border-border;
  }

  body {
    @apply bg-background text-foreground antialiased;
  }
}
```

### Step 5: Update Custom Variants

#### Before (v3)

```typescript
// tailwind.config.ts
import plugin from "tailwindcss/plugin";

export default {
  plugins: [
    plugin(({ addVariant }) => {
      addVariant("hocus", ["&:hover", "&:focus"]);
      addVariant("group-hocus", [":merge(.group):hover &", ":merge(.group):focus &"]);
    }),
  ],
};
```

#### After (v4)

```css
/* app.css */
@custom-variant hocus (&:where(:hover, :focus));
@custom-variant group-hocus (:merge(.group):where(:hover, :focus) &);

/* Usage: hocus:bg-primary group-hocus:text-accent */
```

### Step 6: Migrate Animations

#### Before (v3)

```typescript
// tailwind.config.ts + separate plugin
export default {
  theme: {
    extend: {
      keyframes: {
        "accordion-down": {
          from: { height: "0" },
          to: { height: "var(--radix-accordion-content-height)" },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
};
```

#### After (v4)

```css
@theme {
  /* Animation token with keyframe */
  --animate-accordion-down: accordion-down 0.2s ease-out;

  @keyframes accordion-down {
    from {
      height: 0;
    }
    to {
      height: var(--radix-accordion-content-height);
    }
  }
}

/* Usage: animate-accordion-down */
```

### Step 7: Entry/Exit Animations with @starting-style

```css
/* Before (v3): Required framer-motion or custom JS */

/* After (v4): Use @starting-style for entry animations */
@theme {
  --animate-dialog-enter: dialog-enter 0.2s ease-out;

  @keyframes dialog-enter {
    from {
      opacity: 0;
      transform: translate(-50%, -48%) scale(0.96);
    }
  }
}

/* Automatically triggers when element added to DOM */
.dialog {
  @starting-style {
    opacity: 0;
    transform: translate(-50%, -48%) scale(0.96);
  }

  /* Animates to these values */
  opacity: 1;
  transform: translate(-50%, -50%) scale(1);
  transition: all 0.2s ease-out;
}
```

## Breaking Changes

### 1. Class Name Changes

| v3 Class            | v4 Replacement         | Notes                                   |
| ------------------- | ---------------------- | --------------------------------------- |
| `h-screen`          | `h-dvh`                | Dynamic viewport height (better mobile) |
| `overflow-ellipsis` | `text-ellipsis`        | Renamed for clarity                     |
| `flex-shrink`       | `shrink`               | Simplified naming                       |
| `flex-grow`         | `grow`                 | Simplified naming                       |
| `decoration-slice`  | `box-decoration-slice` | More explicit                           |
| `decoration-clone`  | `box-decoration-clone` | More explicit                           |

### 2. Removed Features

- **Deprecated utilities**: `overflow-ellipsis` (use `text-ellipsis`), `decoration-slice` (use
  `box-decoration-slice`)
- **Safelist**: No longer needed - v4 scans your files automatically and adds used classes
- **PurgeCSS**: Built-in optimization, no configuration needed

### 3. Color Format Changes

```css
/* v3: HSL with alpha channel */
--primary: 221 83% 53%;
/* Usage: bg-primary/80 → hsla(221, 83%, 53%, 0.8) */

/* v4: OKLCH (recommended) - better perceptual uniformity */
--color-primary: oklch(53% 0.2 260);
/* Usage: bg-primary/80 → oklch(53% 0.2 260 / 0.8) */
```

**Why OKLCH?**

- ✅ Better color perception (brightness is perceptually uniform)
- ✅ Wider color gamut (supports P3, Rec.2020)
- ✅ More consistent lightness across hues
- ✅ Future-proof for HDR displays

## Common Migration Issues

### Issue 1: `@apply` with Arbitrary Values

```css
/* ❌ WRONG (v4 doesn't support this) */
.btn {
  @apply px-[20px] py-[10px];
}

/* ✅ FIX: Use CSS custom properties */
.btn {
  padding-inline: 20px;
  padding-block: 10px;
}

/* OR: Use Tailwind classes only */
.btn {
  @apply px-5 py-2.5;
}
```

### Issue 2: Missing `tailwind.config.ts`

```bash
# v4 doesn't require config file, but if you need one:
# .github/tailwind.config.ts (for IDE autocomplete only)
export default {
  theme: {},
  plugins: [],
}
```

### Issue 3: Content Paths Not Working

```css
/* app.css - Manually specify content paths if auto-detection fails */
@config "./tailwind.config.ts";
```

## TypeScript Support

```typescript
// globals.css.d.ts - Add CSS module types
declare module "*.css" {
  const content: Record<string, string>;
  export default content;
}

// For @theme autocomplete in VS Code
// Install: Tailwind CSS IntelliSense extension (v4 compatible)
```

## Verification Checklist

- [ ] `npm install tailwindcss@next @tailwindcss/postcss@next` completed
- [ ] `postcss.config.js` updated to use `@tailwindcss/postcss`
- [ ] `@import "tailwindcss"` in main CSS file
- [ ] Color tokens converted to OKLCH (or kept as HSL if preferred)
- [ ] Dark mode using `@custom-variant dark`
- [ ] Animations moved to `@theme { @keyframes }`
- [ ] Custom variants converted to `@custom-variant`
- [ ] `tailwind.config.ts` removed (or kept for IDE autocomplete)
- [ ] Build process works (`npm run build`)
- [ ] Dark mode toggle works correctly
- [ ] All components render with correct styles

---

**Return to**: [SKILL.md](../SKILL.md) for main documentation.
