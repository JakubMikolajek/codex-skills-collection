---
name: ui-design-quality
description: >-
  Visual design quality rules for typography, color systems, spacing, animation,
  and micro-interactions. Prevents generic AI output by enforcing intentional design
  decisions. Framework-agnostic core with React and Vue adaptation notes.
---

# Design Taste

This skill enforces intentional, high-quality visual design decisions across frontend implementations. It provides concrete rules for typography, color, spacing, motion, and micro-interactions — preventing generic "AI slop" output and ensuring every visual choice is deliberate and refined.

## When to Use

- Building new UI components that require visual design decisions (color, typography, spacing, animation)
- Implementing animations, transitions, or micro-interactions for any frontend component
- Creating or extending a design system, design tokens, or visual foundations
- Polishing existing UI for production — improving visual quality, consistency, and feel
- Reviewing UI code for design quality issues

## When NOT to Use

- Pure backend, API, or infrastructure work — use the appropriate domain skill
- Pixel-perfect matching against an existing, complete design spec — use `ui-verification` instead
- Performance-only optimization with no visual changes — use `performance-profiling`

## Design Parameters

Three tunable parameters allow calibrating the visual direction. Set at the start of a task or use defaults.

```
Design Parameters (defaults: VARIANCE=5, MOTION=6, DENSITY=4):
- DESIGN_VARIANCE (1–10): 1 = Strict symmetry, grid-locked → 10 = Asymmetric, editorial, experimental
- MOTION_INTENSITY (1–10): 1 = Static, minimal transitions → 10 = Rich physics, spring animations, gestures
- VISUAL_DENSITY (1–10): 1 = Airy, generous whitespace → 10 = Dense, data-rich, information-packed
```

How parameters affect decisions:

| Parameter | Low (1–3) | Mid (4–7) | High (8–10) |
|-----------|-----------|-----------|-------------|
| VARIANCE | Centered layouts, uniform grid, symmetric | Subtle asymmetry, varied section rhythms | Bold asymmetry, editorial layouts, experimental composition |
| MOTION | CSS transitions only, minimal stagger | Custom easing, enter/exit animations, stagger | Spring physics, gestures, layout animations, parallax |
| DENSITY | Art gallery feel, generous padding, large whitespace | Balanced content-to-space ratio | Dashboard-like, compact cards, dense data presentation |

## Delivery Workflow

```
Design taste progress:
- [ ] Step 1: Analyze project context (existing design system, tokens, typography, palette)
- [ ] Step 2: Calibrate design parameters (VARIANCE / MOTION / DENSITY) — use defaults or user-specified
- [ ] Step 3: Establish or extend design tokens (colors, typography scale, spacing, easing, shadows)
- [ ] Step 4: Implement components with intentional design decisions
- [ ] Step 5: Add motion and micro-interactions appropriate to MOTION_INTENSITY
- [ ] Step 6: Verify against Design Quality Checklist
```

## Core Philosophy

1. **Intentionality** — Every pixel is a deliberate choice, not a framework default. If you cannot explain why a value is what it is, it needs to change.
2. **Restraint** — Remove before adding. Simplicity is sophistication. An element earns its place or gets cut.
3. **Feel** — An interface that works is not enough — it must feel right. The difference between good and great is in the micro-details.
4. **Subtlety** — The best animations are barely noticed consciously. They guide without demanding attention.
5. **Consistency** — Visual language must be uniform across the entire interface. One border-radius token, one shadow system, one spacing scale.
6. **Conscious font choice** — If you choose a common font like Inter or Roboto, document why it serves this project. Don't pick defaults because they're familiar — pick them because they're right.

## Typography System

### Type Scale

Use a modular scale to generate all font sizes. Never use arbitrary values.

| Scale Ratio | Name | Best For |
|-------------|------|----------|
| `1.125` | Major second | Dense UI, dashboards (DENSITY ≥ 7) |
| `1.200` | Minor third | Compact interfaces |
| `1.250` | Major third | General purpose (recommended default) |
| `1.333` | Perfect fourth | Editorial, marketing pages |
| `1.500` | Perfect fifth | Bold headlines, hero sections (VARIANCE ≥ 8) |

Generate sizes: `base × ratio^n` where `n` ranges from `-2` to `+5`.

### Rules

| Rule | Value |
|------|-------|
| Base font size | `16px` minimum, `18px` preferred for body |
| Font families | Max 2–3 per project (one sans for UI, optional serif/display for headlines) |
| Line height — body | `1.5` (`1.6` for long-form content) |
| Line height — headings | `1.2` to `1.3` |
| Measure (line width) | `65–75ch` max for readability |
| Letter-spacing — large text | Tighten: `-0.02em` to `-0.03em` |
| Letter-spacing — small caps/labels | Widen: `0.05em` to `0.1em` |
| Font weight variety | Use Medium (500) / SemiBold (600), not just 400 and 700 |
| Heading margins | `margin-top: 1.5em`, `margin-bottom: 0.5em` |
| Text wrapping | `text-wrap: balance` for headings, `text-wrap: pretty` for body |
| Tabular numbers | `font-variant-numeric: tabular-nums` for data and tables |
| Truncation | `text-overflow: ellipsis` + `overflow: hidden` — never cut text mid-word |
| Font stacks | Always include 3+ fallback fonts |

### Fluid Typography

Use `clamp()` for responsive font sizes instead of fixed pixels:

```css
/* Heading — scales from 1.5rem to 2.5rem */
font-size: clamp(1.5rem, 1rem + 2vw, 2.5rem);

/* Body — scales from 1rem to 1.25rem */
font-size: clamp(1rem, 0.875rem + 0.5vw, 1.25rem);
```

## Color Architecture

### Palette Construction

| Rule | Details |
|------|---------|
| Color model | HSL for simple palettes, OKLCH for perceptually uniform scales |
| Semantic tokens | `--color-primary`, `--color-surface`, `--color-text`, `--color-border`, `--color-success`, `--color-warning`, `--color-error`, `--color-info` |
| No pure black | Use off-blacks: `hsl(220, 15%, 8%)` or `#0a0a0a` — pure `#000` is harsh |
| No pure white | Use near-whites: `hsl(220, 15%, 97%)` or `#fafafa` |
| Accent limit | 1–2 accent colors max per interface |
| Tinted neutrals | Tint background grays with primary hue — not pure neutral gray |
| Full color scale | Generate 50 through 950 steps from a single hue for primary palette |

### Contrast Requirements

| Element | Minimum Ratio |
|---------|---------------|
| Normal text (< 18px) | 4.5:1 (WCAG AA) |
| Large text (≥ 18px or ≥ 14px bold) | 3:1 (WCAG AA) |
| UI components and graphical objects | 3:1 |

Never rely on color alone to convey information — always pair with icons, text, or patterns.

### Token Implementation

```css
:root {
  /* Semantic tokens — reference primitive scale */
  --color-primary: var(--blue-600);
  --color-surface: var(--gray-50);
  --color-text: var(--gray-900);
  --color-text-muted: var(--gray-500);
  --color-border: var(--gray-200);
  --color-error: var(--red-600);
  --color-success: var(--green-600);
}
```

All colors as CSS custom properties — never hardcode hex values inline in components.

## Spacing & Layout

### Grid System

8px base grid with 4px for fine adjustments. All spacing values must be multiples.

```css
:root {
  --space-xs:  4px;   /* 0.5 × base */
  --space-sm:  8px;   /* 1 × base */
  --space-md:  16px;  /* 2 × base */
  --space-lg:  24px;  /* 3 × base */
  --space-xl:  32px;  /* 4 × base */
  --space-2xl: 48px;  /* 6 × base */
  --space-3xl: 64px;  /* 8 × base */
  --space-4xl: 96px;  /* 12 × base */
}
```

### Layout Rules

| Rule | Details |
|------|---------|
| Gap over margins | Use `gap` between grid/flex children instead of margin hacks |
| Container widths | Content: `720px`, Wide: `1080px`, Full: `1440px` |
| Section padding | ≥ `64px` vertical on desktop, `32px` on mobile |
| Whitespace | Generous whitespace signals premium quality — don't fill every pixel |
| Grid vs Flexbox | CSS Grid for page-level layout, Flexbox for component-level alignment |
| Internal spacing | Padding over margin for component internals |
| Viewport units | `dvh` not `vh` on mobile (avoids address bar resize issues) |
| Visual rhythm | Consistent vertical spacing creates scan-ability |
| Logical properties | `margin-inline`, `padding-block` for RTL language support |

## Motion & Animation

### Decision Framework: Should This Animate?

| Interaction Frequency | Animation Rule |
|-----------------------|----------------|
| 100+ times/day (keyboard shortcuts, command palette) | **No animation. Ever.** Instant response. |
| Tens of times/day (hover effects, list navigation) | **Minimal or remove** — quick color/opacity shifts only |
| Occasional (modals, drawers, toasts) | **Standard animation** — full enter/exit with easing |
| Rare / first-time (onboarding, celebrations) | **Can add delight** — richer, longer animations acceptable |

Every animation must serve one clear purpose:
- **Spatial consistency** — elements enter/exit from the same direction
- **State indication** — visual feedback for state changes
- **Preventing jarring changes** — smoothing appearance/disappearance
- **Feedback** — confirming user actions

### Easing Curves

| Context | Curve | CSS Value |
|---------|-------|-----------|
| Element entering | Strong ease-out | `cubic-bezier(0.22, 1, 0.36, 1)` |
| Element exiting | Ease-in | `cubic-bezier(0.55, 0, 1, 0.45)` |
| On-screen movement | Ease-in-out | `cubic-bezier(0.77, 0, 0.175, 1)` |
| Hover states | Gentle ease | `cubic-bezier(0.25, 0.1, 0.25, 1)` |
| Drawer (iOS-like) | Drawer curve | `cubic-bezier(0.32, 0.72, 0, 1)` |

**Never use:** `linear` (except progress bars), default `ease`, or `ease-in` for UI entry.

```css
:root {
  --ease-out:    cubic-bezier(0.22, 1, 0.36, 1);
  --ease-in:     cubic-bezier(0.55, 0, 1, 0.45);
  --ease-in-out: cubic-bezier(0.77, 0, 0.175, 1);
  --ease-hover:  cubic-bezier(0.25, 0.1, 0.25, 1);

  --duration-fast:   100ms;
  --duration-normal: 200ms;
  --duration-slow:   300ms;
  --duration-slower: 500ms;
}
```

### Duration Rules

| Type | Duration |
|------|----------|
| Micro-interactions (hover, press) | `100–200ms` |
| Standard transitions (modal, dropdown, toast) | `200–300ms` |
| Page-level transitions | `300–500ms` |
| **Hard cap** | UI animations must not exceed `500ms` |
| Exit vs enter | Exit animations ~25% faster than entry |

### Performance

- **Only animate `transform` and `opacity`** — these are compositor-only, GPU-accelerated
- **Never animate** `width`, `height`, `top`, `left`, `margin`, `padding` — triggers layout recalculation
- Use `will-change` sparingly — set only during animation, remove after
- **Animations must be interruptible** — if user acts mid-animation, transition smoothly to new state
- Prefer CSS transitions over keyframes for interruptibility

### Stagger Patterns

- `30–50ms` between staggered children
- Never exceed `50ms` per item — slow staggers feel sluggish
- Total stagger sequence should complete within `300ms`
- Stagger direction should follow reading order (top-to-bottom, left-to-right in LTR)

### Enter / Exit Patterns

- **Enter:** fade in + slight translate (`8–16px` from direction of origin)
- **Never** animate from `scale(0)` — start from `scale(0.95)` or `scale(0.96)` minimum
- **Exit:** same pattern reversed, ~25% faster duration
- **Transform origin:** matches trigger point (dropdown scales from button, tooltip from hover target)

### Spring Animations (MOTION_INTENSITY ≥ 7)

Use springs for spatial movement, gestures, and drag interactions:

| Preset | Stiffness | Damping | Use Case |
|--------|-----------|---------|----------|
| Snappy | `400` | `30` | Toggles, checkboxes, small UI elements |
| Smooth | `300` | `25` | Modals, dropdowns, medium elements |
| Gentle | `200` | `20` | Page transitions, drawers, large elements |

Keep `mass` at `1` in most cases. Never use `bounce` type unless building a playful/game-like UI.

### Accessibility

- **`prefers-reduced-motion: reduce`** is mandatory — disable non-essential animations, replace with instant state changes or simple opacity fades
- **`prefers-reduced-transparency`** — reduce `backdrop-filter: blur()` intensity
- Test with motion preferences enabled in OS settings

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

## Micro-Interactions & Component Craft

### Buttons

| Property | Rule |
|----------|------|
| Press feedback | `scale(0.97)` on `:active` — not `0.95`, that's too dramatic |
| Variants | 3 minimum: Primary (filled), Secondary (outlined), Ghost (text-only) |
| Padding | Minimum `12px 24px` |
| Touch target | `44px` minimum (use pseudo-elements if visual button is smaller) |
| States | default, hover, active, focus-visible, disabled, loading |
| Loading | Spinner icon replacing content, not text change |
| Focus ring | `2px` solid, `2px` offset, high-contrast color |
| Touch hover | `@media (hover: hover) and (pointer: fine)` — prevent sticky hover on mobile |

### Inputs

| Property | Rule |
|----------|------|
| Height | `44px` minimum |
| Label | Always visible above input — never placeholder-only |
| Border | `1px` default → `2px` on focus, color transition `150ms` |
| Focus glow | `box-shadow` with primary color at `0.15` opacity |
| Error state | Red border + inline message below + error icon |
| Disabled vs read-only | Visually distinct — different opacity/background patterns |

### Cards

| Property | Rule |
|----------|------|
| Padding | Consistent `24px` (or spacing token `--space-lg`) |
| Border-radius | `12px` or design system token |
| Containment | Shadow OR border — not both simultaneously |
| Hover | `translateY(-1px)` max + subtle shadow escalation |
| Nesting | No cards inside cards — single elevation level per context |

### Modals / Dialogs

| Property | Rule |
|----------|------|
| Backdrop | `rgba(0,0,0,0.4)` + `backdrop-filter: blur(8px)` |
| Enter | Spring from `scale(0.96)` + `opacity: 0`, `250–300ms` |
| Exit | Tween to `scale(0.96)` + `opacity: 0`, `150–200ms` |
| Max dimensions | Width: `560px`, Height: `85vh` with internal scroll |
| Focus | Trap required — focus must not escape modal |
| Origin | Centered — no origin-aware scaling (unlike dropdowns) |

### Tooltips

| Property | Rule |
|----------|------|
| Enter delay | `150ms` — prevents accidental triggers |
| Exit delay | `0ms` — immediate |
| Animation | Fade + `translateY(4px)`, `150ms` |
| Sequential | Once one tooltip is open, subsequent hovers open instantly |

### Dropdowns / Popovers

| Property | Rule |
|----------|------|
| Origin | Scale from trigger element's position |
| Enter | From `scale(0.95, 0.9)` + `opacity: 0`, spring or `200ms` |
| Item stagger | `30ms` per item |
| Focus | First item focused on open, keyboard navigation supported |

### Tabs

| Property | Rule |
|----------|------|
| Active indicator | Animated underline or background highlight |
| Direction | Content slides in direction of tab change (left tab → slide left) |
| Indicator timing | `200ms` |
| Content timing | `150ms` crossfade or directional slide |

### Loading States

- **Skeletons > Spinners > Text-only** (preference order)
- Skeleton shape should match the content it replaces
- Pulse animation: `opacity` between `0.4` and `0.8`, `1.5s` infinite, ease-in-out
- Reserve space to prevent layout shift (use `aspect-ratio` for media)

### Toasts

- Slide in from edge + fade
- Stack with `translateY` and `scale` reduction for depth illusion
- Auto-dismiss: `5000ms` default, pause on hover
- Swipe to dismiss on touch devices

## Dark Mode

| Rule | Details |
|------|---------|
| Strategy | Elevation-based lightness — lighter surfaces = higher elevation. Don't just invert. |
| Background range | `hsl(220, 15%, 8%)` (base) to `hsl(220, 15%, 16%)` (elevated) |
| Surface tint | Subtle primary hue tint on dark surfaces, not pure neutral gray |
| Meta tag | Set `<meta name="color-scheme" content="light dark">` |
| Images | Reduce brightness: `filter: brightness(0.9)` |
| Shadows | Lower opacity — barely visible. Don't make shadows darker on dark backgrounds. |
| Borders | May need increased visibility (slightly lighter) in dark mode |
| Color tokens | Use the same semantic token names, swap primitive values via CSS custom properties |

```css
@media (prefers-color-scheme: dark) {
  :root {
    --color-surface: hsl(220, 15%, 10%);
    --color-surface-raised: hsl(220, 15%, 14%);
    --color-surface-overlay: hsl(220, 15%, 18%);
    --color-text: hsl(220, 15%, 92%);
    --color-text-muted: hsl(220, 15%, 60%);
    --color-border: hsl(220, 15%, 20%);
  }
}
```

## Responsive Strategy

### Breakpoints

| Name | Width | Typical Device |
|------|-------|----------------|
| `xs` | `480px` | Mobile landscape |
| `sm` | `640px` | Large phone |
| `md` | `768px` | Tablet |
| `lg` | `1024px` | Desktop |
| `xl` | `1280px` | Wide desktop |
| `2xl` | `1440px` | Large monitor |

### Rules

| Rule | Details |
|------|---------|
| Approach | Mobile-first — base styles for mobile, enhance upward with `min-width` |
| Touch targets | `44×44px` minimum on mobile |
| Fluid values | Use `clamp()` for typography and spacing |
| Container queries | Use `@container` for component-level responsiveness (where supported) |
| Test widths | `320px`, `375px`, `768px`, `1024px`, `1440px`, `1920px` |
| Mobile nav | Full-screen overlay or bottom sheet — never squeeze desktop nav |
| Hover detection | `@media (hover: hover) and (pointer: fine)` — prevent sticky hover on touch |
| Layout | Stack on mobile, don't just shrink desktop columns |

```css
/* Fluid spacing example */
padding: clamp(var(--space-md), 3vw, var(--space-2xl));
```

## Framework-Specific Notes

### React / Next.js

| Topic | Guidance |
|-------|----------|
| Animation library | `motion/react` (Framer Motion v11+) or `framer-motion` |
| Exit animations | Wrap conditional renders with `<AnimatePresence>` |
| Shared transitions | Use `layoutId` for elements that persist across states (tab indicators, list items) |
| Motion preferences | `useReducedMotion()` hook — check and disable non-essential animation |
| Spring configs | Define as constants **outside** components to avoid re-renders |
| Next.js App Router | Animation components must be `"use client"` leaf components |
| Shadcn / Radix | Extend via `cn()` composition; use `data-state` attributes for animation triggers |
| CSS entry animations | `@starting-style` for animating from `display: none` (where supported) |
| Page transitions | View Transitions API for route-level animations (when stable) |
| `LayoutGroup` | Scope `layoutId` animations to prevent cross-component conflicts |

### Vue / Nuxt

| Topic | Guidance |
|-------|----------|
| Enter/leave | Use `<Transition>` and `<TransitionGroup>` built-in components |
| Complex animation | JavaScript hooks (`@before-enter`, `@enter`, `@leave`) with GSAP or anime.js |
| Duration control | Set `:duration="{ enter: 300, leave: 200 }"` — exit faster than enter |
| List animation | `<TransitionGroup>` with `move` class for FLIP-based reorder |
| Nuxt transitions | `pageTransition` / `layoutTransition` in `nuxt.config.ts` |
| Motion preferences | `useMediaQuery('(prefers-reduced-motion: reduce)')` composable |
| Headless UI | `<TransitionRoot>` / `<TransitionChild>` from `@headlessui/vue` for coordinated animations |
| Route animation | Wrap `<NuxtPage>` with `<Transition>` for page-level effects |

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Arbitrary font sizes without scale system | Use modular type scale (`base × ratio^n`) |
| Same font weight/size for everything | Establish clear visual hierarchy with weight + size variation |
| Fixed pixel sizes without `clamp()` or `rem` | Use fluid typography with `clamp()` |
| Pure `#000000` on white backgrounds | Use off-black: `hsl(220, 15%, 8%)` or `#0a0a0a` |
| Colors defined inline without tokens | Use semantic CSS custom properties |
| Arbitrary spacing values | 8px grid with spacing tokens (`--space-sm` through `--space-4xl`) |
| Mixing `px`/`rem`/`em` inconsistently | Choose one unit system and apply consistently |
| `ease-in` for UI entry animations | Custom `cubic-bezier(0.22, 1, 0.36, 1)` |
| Default `ease` or `linear` for transitions | Custom easing curves matched to interaction type |
| Animations exceeding 500ms for standard UI | Keep standard interactions under 300ms |
| Missing exit animations | Every enter animation needs a matching exit |
| Same animation speed for all element sizes | Scale duration with element size and visual importance |
| Bounce/elastic easing in professional UI | Reserve for explicitly playful/game-like contexts |
| Animating `width`/`height`/`top`/`left` | Use `transform` and `opacity` exclusively |
| Stagger delay > 50ms between items | Keep ≤ 30–50ms for snappy perception |
| Hover-only interactions | Always provide `:focus-visible` equivalent |
| Placeholder text as only label | Label always visible above input field |
| Disabled buttons without explanation | Show tooltip or inline text explaining why disabled |
| Cards inside cards (nested elevation) | Single elevation level per context |
| Shadow + border simultaneously on same element | Choose one: shadow for elevation, border for containment |
| Dark mode by just inverting colors | Elevation-based surface lightness with tinted neutrals |
| Shrinking desktop layout for mobile | Redesign layout for mobile context |
| Inline styles for design values | CSS custom properties / design tokens |
| `!important` to fix styling conflicts | Fix specificity issues properly (increase selector specificity) |
| Z-index values pulled from thin air | Use z-index scale token system (`--z-dropdown: 100`, etc.) |
| `100vh` on mobile viewports | Use `100dvh` (dynamic viewport height) |

## Design Quality Checklist

```
Design Quality Gates:
- [ ] Typography uses a defined modular scale (not arbitrary sizes)
- [ ] Color palette uses semantic tokens (no inline hex values)
- [ ] Spacing follows 8px grid with spacing tokens
- [ ] Font choice is conscious and documented if using a common font
- [ ] Custom easing curves used (no default ease-in, linear, or ease)
- [ ] All state transitions have intentional animation with clear purpose
- [ ] Exit animations exist for every enter animation
- [ ] `prefers-reduced-motion` is respected and tested
- [ ] All interactive elements have hover + focus-visible states
- [ ] Touch targets ≥ 44px on mobile
- [ ] Dark mode is elevation-based (not just inverted colors)
- [ ] Responsive tested at 320px, 768px, 1024px, 1440px
- [ ] WCAG AA contrast ratios verified (4.5:1 text, 3:1 UI components)
- [ ] Loading, error, and empty states designed (not just happy path)
- [ ] No hardcoded colors, sizes, or spacing outside token system
- [ ] Animations run at 60fps (transform + opacity only)
- [ ] No anti-patterns from the registry present in output
```

## Connected Skills

- `frontend-implementation` — design system tokens, performance optimization, semantic HTML
- `accessibility` — full WCAG 2.1 AA depth, keyboard navigation, ARIA patterns
- `react` — React component patterns, hooks, state management
- `vue` — Vue component patterns, Composition API, reactivity
- `shadcn-tailwind` — Shadcn/UI + Tailwind CSS component library patterns
- `ui-verification` — verifying implementation matches approved design specification
