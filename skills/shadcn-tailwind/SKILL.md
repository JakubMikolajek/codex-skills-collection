---
name: shadcn-tailwind
description: shadcn/ui and Tailwind CSS implementation and review patterns for React and Next.js interfaces. Use when Codex needs to build, refactor, debug, or review UI built with shadcn/ui components, Tailwind utility classes, component variants, Radix-based primitives, design tokens, or reusable app-facing component composition.
---

# shadcn Tailwind Implementation Patterns

Use this skill when the UI stack is React or Next.js with shadcn/ui and Tailwind CSS. Reuse the general `react` or `react-nextjs` skill for application logic and use this skill for component styling, primitives, variants, and utility hygiene.

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
- `frontend-implementation` - apply accessibility and design-system rules
- `ui-verification` - compare implementation against approved design output
