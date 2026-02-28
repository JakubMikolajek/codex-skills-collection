---
name: vuetify-primevue
description: Vuetify and PrimeVue implementation and review patterns for Vue and Nuxt interfaces. Use when Codex needs to build, refactor, debug, or review UI built with Vuetify components, PrimeVue components, theme tokens, forms, data tables, overlays, or reusable application-facing component composition in a Vue stack, especially alongside Nuxt 3 and Pinia.
---

# Vuetify PrimeVue Implementation Patterns

Use this skill when the UI stack is Vue or Nuxt with Vuetify or PrimeVue. Reuse `vue` or `nuxt` for application logic and use this skill for component-library composition, theming, responsiveness, and utility hygiene around those UI systems. Assume the current project is mostly client-driven unless the route explicitly requires stronger SSR behavior.

## Delivery Workflow

Use the checklist below and track progress:

```
Vuetify PrimeVue progress:
- [ ] Step 1: Discover the active UI library and theme conventions
- [ ] Step 2: Reuse existing components and wrappers first
- [ ] Step 3: Implement layout, forms, and interactive states consistently
- [ ] Step 4: Verify responsiveness and accessibility behavior
- [ ] Step 5: Review library-specific composition and visual consistency
```

## Reuse Rules

- Reuse existing wrappers, shared patterns, and design tokens before adding new abstractions.
- Do not mix Vuetify and PrimeVue patterns inside one feature unless the repository already does so intentionally.
- Keep wrappers thin and capability-focused.
- Extend existing component vocabulary rather than creating parallel bespoke components.

## Library Composition

- Preserve each library's expected component structure and interaction model.
- Keep forms, dialogs, menus, tables, and overlays aligned with the active library's conventions.
- Treat slots, pass-through props, and theming overrides as explicit design choices.
- Avoid burying behavior-critical props several wrapper levels away.
- Keep library usage compatible with the project's Nuxt 3 rendering mode; do not add SSR-specific workarounds unless the feature actually needs them.

## Visual and Responsive Consistency

- Use the project's spacing, typography, and color roles consistently.
- Keep responsive behavior intentional from the start.
- Ensure hover, focus, disabled, invalid, loading, and selected states remain visually clear.
- Prefer theme-driven customization over one-off styling hacks.

## Vuetify/PrimeVue Review Checklist

```
Reuse:
- [ ] Existing library wrappers and shared primitives are reused first
- [ ] New wrappers stay thin and justified
- [ ] The active library is used consistently in the feature

Quality:
- [ ] Layout and state styles are visually consistent
- [ ] Responsive behavior is intentional
- [ ] Library-specific props and slots are used coherently

Accessibility:
- [ ] Focus and keyboard behavior remain intact
- [ ] Form and overlay components preserve accessible behavior
- [ ] Visual state is not communicated by color alone
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Mixing Vuetify and PrimeVue ad hoc in one feature | Follow the project's dominant library choice per area |
| Adding SSR-specific UI complexity to mostly client-rendered screens | Match the project's current rendering posture |
| Heavy wrappers hiding core library behavior | Keep wrappers thin and explicit |
| One-off style hacks for every screen | Reuse theme and shared component patterns |
| Deeply nested slot composition that is hard to reason about | Extract focused wrapper components |
| Rebuilding library primitives from scratch | Compose the provided components first |

## Connected Skills

- `vue` - use for component boundaries and interaction flow
- `nuxt` - use when the app structure is Nuxt-specific
- `frontend-implementation` - apply accessibility and design-system discipline
- `ui-verification` - compare implementation against approved design output
