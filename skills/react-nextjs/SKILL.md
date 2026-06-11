---
name: react-nextjs
description: React and Next.js implementation and review patterns for server-rendered and hybrid web apps. Use when Codex needs to build, refactor, debug, or review Next.js routes, layouts, server components, client components, server actions, route handlers, metadata, caching, or full-stack React application flows.
---

# React Next.js Implementation Patterns

Use this skill when the task is specifically about Next.js behavior on top of React. Reuse the general `react` skill for component discipline and this skill for app-structure, rendering model, and data-fetching rules.

## When to Use

- Building, refactoring, or debugging Next.js routes, layouts, loading/error states, or server/client component boundaries
- Implementing data fetching, server actions, route handlers, or cache/revalidation logic in Next.js
- Working with Next.js metadata, SEO, Open Graph, or font optimization
- Reviewing Next.js code for correct server/client boundary usage, runtime safety, or rendering model

## When NOT to Use

- Task is about React component logic, hooks, or state without Next.js specifics — use `react` alone
- Task is about Vue, Nuxt, or non-React frameworks — use the appropriate framework skill
- Task is about backend API logic in a separate service (not Next.js route handlers) — use backend skills

## Delivery Workflow

Use the checklist below and track progress:

```
React Next.js progress:
- [ ] Step 1: Discover App Router or Pages Router conventions
- [ ] Step 2: Map server and client boundaries explicitly
- [ ] Step 3: Implement data flow, routing, and mutations
- [ ] Step 4: Verify caching, metadata, and error/loading states
- [ ] Step 5: Test the route behavior and runtime assumptions
```

## Routing and Composition

- Follow the existing router model first. Do not introduce App Router patterns into Pages Router code or the reverse without need.
- Keep route structure intentional: layout, page, loading, error, and nested segments should reflect real product boundaries.
- Keep framework-level concerns in route files and push reusable UI into shared React components.
- Treat route params, search params, and server-derived state as explicit inputs, not implicit globals.

## Server and Client Boundaries

- Default to server-first where the project already uses that model.
- Add client components only when interactivity, browser APIs, or client-side state actually require them.
- Keep client boundaries small so most rendering can stay server-driven.
- Do not pass unnecessary heavy objects across server-client boundaries.
- Make serialization constraints visible when designing props and action payloads.

## Data Fetching and Mutations

- Keep reads and writes close to the route or capability that owns them.
- Model loading, empty, success, and error states explicitly.
- Use server actions, route handlers, or project-standard APIs intentionally rather than mixing multiple mutation styles casually.
- Be explicit about cache invalidation and revalidation after mutations.
- Avoid hiding network behavior deep inside presentational components.

## Rendering, Metadata, and SEO

- Keep metadata generation close to the route that owns the content.
- Avoid rendering client-only placeholders when the data is available server-side.
- Ensure loading and error boundaries match the route tree and user experience.
- Treat redirects, not-found states, and auth gating as first-class route outcomes.

### Metadata Best Practices

- Export `metadata` object or `generateMetadata()` function from every route `page.tsx`.
- Always include: `title`, `description`, `openGraph` (title, description, images), `twitter` (card type).
- Use `generateMetadata()` for dynamic routes — construct titles and descriptions from params or fetched data.
- Set `metadataBase` in root `layout.tsx` so all relative OG image URLs resolve correctly.
- Use `robots: { index: true, follow: true }` explicitly on public pages.
- Add `alternates.canonical` to prevent duplicate content issues.

```typescript
// Dynamic metadata pattern
export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const product = await getProduct(params.slug);
  return {
    title: product.name,
    description: product.summary,
    openGraph: {
      title: product.name,
      description: product.summary,
      images: [{ url: product.image, width: 1200, height: 630 }],
    },
    alternates: { canonical: `/products/${params.slug}` },
  };
}
```

### Font Loading

- Always use `next/font/google` or `next/font/local` — never load fonts via `<link>` tags or `@import` in CSS. Next.js font optimization inlines font declarations and eliminates extra network requests.
- Apply font variables to `<html>` or `<body>` via `className` — not via CSS custom properties manually.
- Set `display: 'swap'` for body fonts (readability), `display: 'optional'` for decorative fonts (no layout shift).
- Subset fonts when possible: `subsets: ['latin', 'latin-ext']`.
- For Tailwind: extend `fontFamily` in config with the CSS variable from `next/font`.

```typescript
import { Inter } from 'next/font/google';

const inter = Inter({
  subsets: ['latin', 'latin-ext'],
  display: 'swap',
  variable: '--font-sans',
});

// In root layout
<html className={inter.variable}>
```

## Runtime and Integration Safety

- Respect environment boundaries between server-only code and browser code.
- Keep secrets and privileged access on the server side.
- Avoid importing Node-only modules into client components.
- Keep edge/runtime assumptions explicit if the project uses them.

## Next.js Review Checklist

```
Structure:
- [ ] Route boundaries and shared component boundaries are clear
- [ ] Server vs client component choices are justified
- [ ] Metadata, loading, and error handling align with the route

Behavior:
- [ ] Data fetching and mutation paths are explicit
- [ ] Cache invalidation/revalidation is handled intentionally
- [ ] Redirect, not-found, and auth-sensitive flows are covered

Quality:
- [ ] Browser-only code stays in client components
- [ ] Sensitive/server-only logic stays on the server
- [ ] Tests or verification cover route-level behavior
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Marking large subtrees as client by default | Keep client boundaries small and intentional |
| Mixing multiple fetch/mutation patterns ad hoc | Reuse the project's dominant route/data pattern |
| Hiding revalidation needs after writes | Make invalidation explicit and local to the mutation |
| Route files full of UI detail | Extract reusable React components |
| Browser APIs in server components | Move that logic behind a client boundary |

## Connected Skills

- `react` - use for component, hooks, and client interaction discipline
- `shadcn-tailwind` - use when UI is built with shadcn/ui and Tailwind CSS
- `ui-design-quality` - apply visual design quality rules for typography, color, spacing, animation, and micro-interactions
- `technical-context-discovery` - follow project Next.js conventions before editing
- `frontend-implementation` - apply design-system tokens, performance, and accessibility guidance
- `code-review` - validate routing, rendering, and integration quality
