---
name: frontend-implementation
description: Frontend implementation patterns, accessibility requirements, design system usage, and web performance guidelines. Use for implementing UI components, working with design tokens, ensuring a11y compliance, optimizing Core Web Vitals, and building reusable frontend code.
---

# Frontend Implementation Patterns

This skill provides patterns and guidelines for implementing frontend features that are accessible, performant, maintainable, and consistent with the design system.

## When to Use

- Before implementing any UI component or feature
- When working with design systems and tokens
- When ensuring accessibility compliance
- When optimizing frontend performance

## Core Principles

### Component Design

- **Reusable over page-specific**: Implement composable UI components rather than tightly coupled page-specific code
- **Respect architecture boundaries**: Always follow the component hierarchy and boundaries defined in the implementation plan
- **Extend, don't duplicate**: Extend the existing design system and component library instead of creating parallel one-off styles
- **Single responsibility**: Each component should have one clear purpose

### Design System Usage

- **Use existing tokens**: Always use design tokens (colors, spacing, typography) from the project's design system
- **Map design spec values to tokens**: When a mockup/spec shows raw values (e.g., `#3B82F6`), map them to existing tokens (e.g., `--color-primary-500`)
- **Never hardcode values**: Avoid hardcoded colors, spacing, or typography values that bypass the design system
- **Document new tokens**: If a new token is absolutely required, document and justify it in the changelog

### Token Mapping Process

1. Extract value from the approved design specification
2. Search codebase for matching design token
3. If token exists → use it
4. If no exact match → find closest existing token and document deviation
5. If truly new → request architect approval before creating

## Accessibility Requirements

### Semantic Markup

- Use correct HTML elements for their semantic meaning (`<button>`, `<nav>`, `<main>`, `<article>`, etc.)
- Choose interactive elements appropriately (`<button>` for actions, `<a>` for navigation)
- Use heading hierarchy correctly (`<h1>` → `<h2>` → `<h3>`, no skipping levels)

### ARIA Usage

- **Prefer native semantics**: Use ARIA only when native HTML cannot convey the meaning
- **Follow ARIA patterns**: When ARIA is needed, follow WAI-ARIA Authoring Practices
- **Common patterns**:
  - `aria-label` for icon-only buttons
  - `aria-expanded` for collapsible sections
  - `aria-live` for dynamic content updates
  - `role` only when semantic HTML isn't available

### Keyboard Navigation

- All interactive elements must be focusable
- Tab order must follow visual/logical order
- Custom components need keyboard handlers (Enter, Space, Escape, Arrow keys as appropriate)
- Focus must be visible (never remove focus outline without replacement)
- Modal dialogs must trap focus

### Color & Contrast

- Minimum 4.5:1 contrast ratio for normal text
- Minimum 3:1 contrast ratio for large text (18px+ or 14px+ bold)
- Don't rely on color alone to convey information

## Performance Guidelines

### Core Web Vitals Targets

These are the metrics Google and users care about. Measure before shipping any significant UI change.

| Metric | Good | Needs Work | Poor | What it measures |
|---|---|---|---|---|
| LCP (Largest Contentful Paint) | ≤2.5s | ≤4s | >4s | Loading — when main content appears |
| INP (Interaction to Next Paint) | ≤200ms | ≤500ms | >500ms | Responsiveness — delay on click/tap |
| CLS (Cumulative Layout Shift) | ≤0.1 | ≤0.25 | >0.25 | Visual stability — elements jumping |

Measure in production conditions (not localhost): use Lighthouse CI, `web-vitals` library, or Chrome DevTools with CPU throttling 4x + Fast 3G.

Common CWV fixes:
- **LCP slow**: missing `loading="eager"` + `fetchpriority="high"` on hero image; render-blocking JS; no `<link rel="preload">` for critical fonts
- **INP high**: long tasks (>50ms) on the main thread; heavy event handlers; synchronous layout reads inside click handlers
- **CLS non-zero**: images and embeds without explicit `width`/`height` or `aspect-ratio`; dynamic content inserted above existing content; font swap causing reflow

### Bundle Analysis

Check bundle size before and after any significant dependency addition or refactor:

```bash
# Next.js — built-in bundle analyzer
ANALYZE=true next build
# or: @next/bundle-analyzer in next.config.js

# Vite
vite build  # with rollup-plugin-visualizer in vite.config.ts

# Generic webpack
webpack --profile --json > stats.json
# upload to https://webpack.github.io/analyse/
```

Bundle size guidelines:
- Initial JS bundle (gzipped): target <200KB, hard limit <350KB
- Per-route chunk: target <100KB gzipped
- A single third-party library should not exceed 50KB gzipped without justification
- Always check `import cost` (VS Code extension) before importing a new library

Tree-shaking hygiene:
- Import named exports, not the entire module: `import { format } from 'date-fns'` not `import * as dateFns`
- Verify tree-shaking actually works — check the bundle output for unexpected inclusions
- Replace heavy libraries with lighter alternatives: `date-fns` over `moment`, `zod` over `joi`

### Code Splitting and Lazy Loading

Split routes and heavy components so the initial bundle only contains what the user sees first:

```typescript
// Next.js — automatic per-route splitting, manual for heavy components
import dynamic from 'next/dynamic';
const HeavyEditor = dynamic(() => import('./HeavyEditor'), {
  loading: () => <EditorSkeleton />,
  ssr: false,  // for client-only components (e.g. those using window)
});

// React — lazy + Suspense
import { lazy, Suspense } from 'react';
const ChartPanel = lazy(() => import('./ChartPanel'));

<Suspense fallback={<ChartSkeleton />}>
  <ChartPanel />
</Suspense>
```

What to lazy-load:
- Routes not on the critical path
- Components only visible after user interaction (modals, drawers, tooltips with heavy content)
- Third-party widgets (maps, rich text editors, video players)
- Admin/settings sections rarely visited by most users

What NOT to lazy-load:
- Components visible on initial render (causes LCP regression)
- Small components where the loading state costs more than the split saves

### Image Optimization

Images are the most common LCP bottleneck. Apply in this order:

```tsx
// Next.js — use next/image for automatic optimization
import Image from 'next/image';

<Image
  src="/hero.jpg"
  alt="Dashboard overview"
  width={1200}
  height={600}
  priority            // for above-the-fold images — disables lazy loading, adds preload
  sizes="(max-width: 768px) 100vw, 50vw"  // tells browser which size to fetch
/>

// Plain HTML — for non-Next.js
<img
  src="hero.webp"
  alt="Dashboard overview"
  width="1200"
  height="600"        // prevents CLS — always set explicit dimensions
  loading="eager"     // default; use "lazy" for below-fold images
  fetchpriority="high" // for the LCP image only
  decoding="async"
/>
```

Image rules:
- Always set explicit `width` and `height` (or `aspect-ratio` in CSS) — prevents CLS
- Use `loading="lazy"` for all images below the fold
- Use `loading="eager"` + `fetchpriority="high"` for the LCP image (usually the hero)
- Serve modern formats: WebP for photos, AVIF where browser support allows
- Provide `srcset` for responsive images — never serve a 2400px image on mobile

### DOM Optimization

- Avoid unnecessary wrapper elements — each extra DOM node has a cost
- Keep DOM depth shallow where possible
- Use semantic elements that don't require extra wrappers

### Rendering Performance

- Avoid layout thrashing (batch DOM reads/writes)
- Use CSS transforms for animations (not `top`/`left`)
- Consider `will-change` for frequently animated elements
- Avoid expensive operations in render paths

### React-Specific (when applicable)

- Memoize expensive computations with `useMemo`
- Memoize callbacks with `useCallback` when passed to child components
- Use `React.memo` for pure presentational components
- Avoid creating objects/arrays in render (causes unnecessary re-renders)

## CRITICAL: Never Guess - Always Ask

**If you are unsure about ANYTHING, STOP and ask the user.**

Check your available tools for a way to ask the user questions (e.g., a tool that allows user interaction or questions). Use it to get the missing information before continuing.

Your job is to implement UI that matches the design exactly. If you don't have the design, credentials, tokens, or any other required information - you cannot do your job correctly. Do not guess. Do not assume. Do not improvise.

**The rule is simple:**

- If something is missing → ask
- If something is broken → ask
- If something is unexpected → ask
- If you're not 100% sure what to implement → ask

**Never:**

- Continue working based on assumptions
- Hardcode values you should look up
- Create new tokens/components without approval
- "Work around" missing information

## Component Implementation Checklist

Before marking a component complete, verify:

```
Accessibility:
- [ ] Semantic HTML elements used
- [ ] Keyboard navigable
- [ ] Focus states visible
- [ ] ARIA attributes added where needed
- [ ] Color contrast sufficient

Design System:
- [ ] Design tokens used (no hardcoded values)
- [ ] Existing components reused where possible
- [ ] Consistent with similar components in codebase

Web Performance:
- [ ] LCP image has priority + explicit dimensions (no CLS)
- [ ] Below-fold images use loading="lazy"
- [ ] Heavy components lazy-loaded (not on initial render path)
- [ ] No new large dependencies added without bundle size check
- [ ] No long tasks (>50ms) introduced on click/input handlers

Code Quality:
- [ ] Component is reusable (not page-specific)
- [ ] Props are well-typed and documented
- [ ] Edge cases handled (empty states, errors, loading)
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Hardcoded colors (`#3B82F6`) | Use design tokens (`var(--color-primary-500)`) |
| `<div>` for everything | Use semantic elements (`<button>`, `<nav>`, etc.) |
| Removing focus outline | Replace with visible custom focus style |
| Creating similar components | Extend existing component with variants |
| Inline styles for theming | Use CSS custom properties / design tokens |
| `tabindex="0"` on non-interactive | Use interactive elements (`<button>`) |
| Color-only error indication | Add icons, text, or ARIA announcements |
| No `width`/`height` on images | Always set explicit dimensions — prevents CLS |
| `import * as _ from 'lodash'` | Named imports: `import { debounce } from 'lodash-es'` |
| Heavy component on initial render | `dynamic()` / `lazy()` for below-fold weight |
| Serving JPEG for photos | WebP with JPEG fallback |

## Connected Skills

- `ui-verification` - for verifying implementation against approved design specifications
- `technical-context-discovery` - for understanding project conventions before implementing
- `accessibility` - for full WCAG 2.1 AA depth on interactive component patterns
- `performance-profiling` - for profiling and measuring actual bottlenecks when CWV targets are missed
