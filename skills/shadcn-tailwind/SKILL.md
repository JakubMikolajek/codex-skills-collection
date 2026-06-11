---
name: shadcn-tailwind
description: shadcn/ui and Tailwind CSS implementation and review patterns for React and Next.js interfaces. Use when Codex needs to build, refactor, debug, or review UI built with shadcn/ui components, Tailwind utility classes, component variants, Radix-based primitives, design tokens, or reusable app-facing component composition.
---

# shadcn Tailwind Implementation Patterns

Use this skill when the UI stack is React or Next.js with shadcn/ui and Tailwind CSS. Reuse the general `react` or `react-nextjs` skill for application logic and use this skill for component styling, primitives, variants, and utility hygiene.

## When to Use

- Building or modifying UI with shadcn/ui components and Radix primitives
- Styling components with Tailwind CSS utility classes in a React or Next.js project
- Creating component variants, extending shadcn primitives, or composing design system elements
- Reviewing Tailwind class hygiene, responsive behavior, or design token consistency

## When NOT to Use

- Task is about React logic, hooks, or state without styling specifics — use `react`
- Task is about Vue/Nuxt with Vuetify or PrimeVue — use `vuetify-primevue`
- Task is about visual design decisions (color palette, typography scale, animation craft) — use `ui-design-quality` alongside this skill

## Delivery Workflow

Use the checklist below and track progress:

```
shadcn Tailwind progress:
- [ ] Step 1: Discover existing UI primitives, tokens, and utility conventions
- [ ] Step 2: Reuse or extend existing shadcn/ui components
- [ ] Step 3: Implement variants and layout with disciplined Tailwind usage
- [ ] Step 4: Verify accessibility and responsive behavior
- [ ] Step 5: Review class hygiene, consistency, and reuse
```

## Component Reuse Rules

- Reuse existing shadcn/ui primitives before creating new wrappers.
- Keep wrappers thin and capability-focused; do not create parallel component libraries casually.
- Extend components through variants and composition rather than copy-pasting markup.
- Preserve the expected API shape of shared primitives unless a project-wide migration is intended.

## Tailwind Utility Discipline

- Prefer readable class grouping over long unstructured class strings.
- Keep layout, spacing, typography, and state styles intentional.
- Reuse the project's utility helpers such as `cn` or equivalent merge helpers when available.
- Avoid one-off arbitrary values unless the design system genuinely needs them.
- Map recurring visual patterns into shared components or variants instead of repeating the same utility bundles.

## Variants and Primitive Composition

- Model size, tone, emphasis, and state through explicit variants.
- Keep variant combinations predictable and limited.
- Preserve Radix/shadcn accessibility behavior when composing triggers, content, and overlays.
- Avoid burying behavior-critical classes in deeply nested wrappers.

## Animation Integration

- Use Radix `data-state` attributes (`open`, `closed`) as CSS animation triggers — no JavaScript animation library needed for basic transitions.
- For complex animations (springs, layout transitions): wrap shadcn primitives with `motion` components from `motion/react`.
- Keep animation timing consistent with project tokens (`--duration-normal: 200ms`, `--ease-out`).
- Radix handles accessibility (focus trap, keyboard) — focus animation efforts on the visual layer only.
- Tailwind `animate-*` utilities work for simple cases; use CSS custom properties for reusable easing and duration tokens.

```css
/* Animate Dialog content via Radix data-state */
[data-state="open"] {
  animation: dialogEnter 200ms cubic-bezier(0.22, 1, 0.36, 1);
}
[data-state="closed"] {
  animation: dialogExit 150ms cubic-bezier(0.55, 0, 1, 0.45);
}

@keyframes dialogEnter {
  from { opacity: 0; transform: scale(0.96); }
  to   { opacity: 1; transform: scale(1); }
}
@keyframes dialogExit {
  from { opacity: 1; transform: scale(1); }
  to   { opacity: 0; transform: scale(0.96); }
}
```

## Tailwind Version Awareness

- Check the project's Tailwind version in `package.json` before generating configuration.
- **v4 (CSS-first):** Config lives in CSS via `@theme {}` blocks. No `tailwind.config.js` needed. Use `@import "tailwindcss"` in the main CSS file. Custom colors, spacing, and fonts are defined as CSS theme variables.
- **v3 (JS config):** Config in `tailwind.config.js` or `tailwind.config.ts`. Use `@tailwind base/components/utilities` directives.
- Never mix v3 and v4 config patterns — check which version the project uses before writing any config.
- In v4: use `@tailwindcss/postcss` or the Vite plugin, not the `tailwindcss` PostCSS plugin directly.

## Responsive and Visual Consistency

- Build mobile-to-desktop intentionally; do not patch responsiveness at the end.
- Keep spacing and typography consistent with the existing token scale.
- Use semantic color roles from the project's theme rather than ad hoc color choices.
- Ensure focus, hover, disabled, invalid, and open states are visibly distinct.

## shadcn Tailwind Review Checklist

```
Reuse:
- [ ] Existing primitives are reused before new ones are invented
- [ ] Repeated utility bundles are extracted when justified
- [ ] Component variants stay coherent and limited

Quality:
- [ ] Class strings remain readable and maintainable
- [ ] Responsive behavior is intentional
- [ ] Focus and interaction states are visible

Accessibility:
- [ ] Radix/shadcn semantics are preserved
- [ ] Interactive elements keep keyboard support
- [ ] Visual state is not communicated by color alone
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Copy-pasting and forking base shadcn components repeatedly | Extend with variants or focused wrappers |
| Massive unreadable utility strings | Group logically and extract reusable patterns |
| Arbitrary values for every spacing/color decision | Reuse the token scale and theme roles |
| Styling wrappers that break primitive behavior | Preserve trigger/content/control semantics |
| New bespoke component set beside shadcn/ui | Keep one shared UI vocabulary |

## Connected Skills

- `react` - use for component boundaries and interaction flow
- `react-nextjs` - use when the app structure is Next.js-specific
- `ui-design-quality` - apply visual design quality rules for typography, color, animation, and micro-interactions
- `frontend-implementation` - apply accessibility and design-system rules
- `ui-verification` - compare implementation against approved design output
