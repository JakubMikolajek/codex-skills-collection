---
name: i18n
description: Web internationalization (i18n) implementation patterns using i18next and react-i18next. Covers translation file structure, pluralization, ICU message format, locale routing in Next.js/Nuxt, date and number formatting, RTL support, and missing translation handling. Use when adding multi-language support to a web application or reviewing existing i18n implementation.
---

# Internationalization (i18n)

This skill covers the practical patterns for shipping a multi-language web application. It focuses on the JavaScript ecosystem (i18next, react-i18next, next-i18next) — for native Apple platforms see `swift-localization`.

## When to Use

- Adding a second language to an existing web application
- Setting up i18n from scratch in a new project
- Reviewing i18n implementation for correctness (pluralization, interpolation, locale routing)
- A language is displaying incorrectly (wrong pluralization, hardcoded strings, locale mismatch)

## When NOT to Use

- iOS/macOS/SwiftUI apps — use `swift-localization`
- Backend-only services where user-facing strings are not generated (API error codes are not translated — only client-facing text is)

## Core Principles

### No Strings in Components

Every user-visible string lives in a translation file. A hardcoded string in a component is a bug, not a shortcut. This includes: button labels, error messages, placeholder text, `aria-label` values, and `<title>` tags.

### Translation Keys are Contracts

A translation key is a stable identifier. Renaming a key breaks all translations for that key in every language. Keys are kebab-case, descriptive, and namespaced to their feature.

### ICU Format for Complex Messages

Use ICU message format (supported natively by `i18next-icu`) for plurals, selects, and interpolated values. Do not concatenate translated strings — word order differs between languages.

## Setup

**Install:**
```bash
pnpm add i18next react-i18next i18next-resources-to-backend
# For Next.js App Router:
pnpm add next-i18next
# ICU message format:
pnpm add i18next-icu
```

**i18n configuration:**
```typescript
// src/i18n/config.ts
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import resourcesToBackend from 'i18next-resources-to-backend';
import ICU from 'i18next-icu';

i18n
  .use(ICU)
  .use(resourcesToBackend((language: string, namespace: string) =>
    import(`../locales/${language}/${namespace}.json`)
  ))
  .use(initReactI18next)
  .init({
    lng: 'en',
    fallbackLng: 'en',
    supportedLngs: ['en', 'pl', 'de'],
    defaultNS: 'common',
    interpolation: { escapeValue: false }, // React escapes by default
    missingKeyHandler: (lng, ns, key) => {
      // Log missing keys in dev, silently fall back in prod
      if (process.env.NODE_ENV === 'development') {
        console.warn(`Missing translation: ${lng}/${ns}/${key}`);
      }
    },
  });

export default i18n;
```

## Translation File Structure

```
src/locales/
├── en/
│   ├── common.json       # shared: buttons, labels, errors
│   ├── documents.json    # documents feature
│   └── auth.json         # auth flows
├── pl/
│   ├── common.json
│   ├── documents.json
│   └── auth.json
└── de/
    └── ...
```

**Namespace convention:**
- `common` — shared across the entire app
- Feature namespaces (`documents`, `auth`, `settings`) — loaded on demand
- One namespace per major feature area

**Key structure (nested for large namespaces):**
```json
// en/documents.json
{
  "title": "Documents",
  "empty-state": {
    "heading": "No documents yet",
    "description": "Create your first document to get started.",
    "cta": "Create document"
  },
  "actions": {
    "create": "Create",
    "delete": "Delete",
    "delete-confirm": "Are you sure you want to delete \"{{title}}\"?"
  },
  "status": {
    "saving": "Saving...",
    "saved": "Saved",
    "error": "Failed to save"
  }
}
```

## ICU Message Format

Use ICU for any message with pluralization, gender, or complex interpolation. Do not use simple string concatenation.

**Plural:**
```json
{
  "document-count": "{count, plural, =0 {No documents} one {# document} other {# documents}}",
  "tag-count": "{count, plural, =0 {No tags} one {# tag} other {# tags}}"
}
```

```tsx
// Usage
t('document-count', { count: 0 })  // "No documents"
t('document-count', { count: 1 })  // "1 document"
t('document-count', { count: 5 })  // "5 documents"
```

**Select (for gendered languages like Polish/German):**
```json
{
  "created-by": "{gender, select, male {Created by him} female {Created by her} other {Created by them}}"
}
```

**Date and number formatting — always use `Intl`, never manual:**
```typescript
// Dates
const formatter = new Intl.DateTimeFormat(locale, {
  dateStyle: 'medium',
  timeStyle: 'short',
});
formatter.format(new Date()); // "Mar 15, 2025, 2:30 PM" (en) / "15 mar 2025, 14:30" (pl)

// Numbers
new Intl.NumberFormat(locale).format(1234567);    // "1,234,567" (en) / "1 234 567" (pl)
new Intl.NumberFormat(locale, { style: 'currency', currency: 'EUR' }).format(42.5);
// "€42.50" (en) / "42,50 €" (de)

// Relative time
new Intl.RelativeTimeFormat(locale, { numeric: 'auto' }).format(-1, 'day');
// "yesterday" (en) / "wczoraj" (pl)
```

## React Usage

```tsx
import { useTranslation } from 'react-i18next';

function DocumentCard({ document }: { document: Document }) {
  const { t } = useTranslation('documents');

  return (
    <article>
      <h2>{document.title}</h2>
      <p>{t('document-count', { count: document.pageCount })}</p>
      <button
        aria-label={t('actions.delete')}  // translated aria-label
        onClick={() => confirm(t('actions.delete-confirm', { title: document.title }))}
      >
        {t('actions.delete')}
      </button>
    </article>
  );
}
```

**Trans component** — for translations with embedded JSX:
```tsx
import { Trans } from 'react-i18next';

// Translation: "Read the <link>documentation</link> for more information."
<Trans
  i18nKey="common:docs-link"
  components={{
    link: <a href="/docs" />
  }}
/>
```

Never concatenate translated strings with JSX elements — word order will break in other languages.

## Locale Routing

**Next.js App Router:**
```
app/
├── [locale]/
│   ├── layout.tsx
│   ├── page.tsx
│   └── documents/
│       └── page.tsx
├── i18n/
│   └── routing.ts
└── middleware.ts
```

```typescript
// middleware.ts — detect and redirect to locale
import { NextRequest, NextResponse } from 'next/server';
import { match } from '@formatjs/intl-localematcher';
import Negotiator from 'negotiator';

const locales = ['en', 'pl', 'de'];
const defaultLocale = 'en';

function getLocale(request: NextRequest): string {
  const headers = { 'accept-language': request.headers.get('accept-language') ?? '' };
  const languages = new Negotiator({ headers }).languages();
  return match(languages, locales, defaultLocale);
}

export function middleware(request: NextRequest) {
  const pathname = request.nextUrl.pathname;
  const pathnameHasLocale = locales.some(
    (locale) => pathname.startsWith(`/${locale}/`) || pathname === `/${locale}`
  );

  if (!pathnameHasLocale) {
    const locale = getLocale(request);
    return NextResponse.redirect(new URL(`/${locale}${pathname}`, request.url));
  }
}
```

**Nuxt i18n** (`@nuxtjs/i18n`):
```typescript
// nuxt.config.ts
export default defineNuxtConfig({
  modules: ['@nuxtjs/i18n'],
  i18n: {
    locales: [
      { code: 'en', iso: 'en-US', file: 'en.json' },
      { code: 'pl', iso: 'pl-PL', file: 'pl.json' },
    ],
    defaultLocale: 'en',
    strategy: 'prefix_except_default',
    lazy: true,
    langDir: 'locales/',
  },
});
```

## RTL Support

For Arabic, Hebrew, Persian, and other RTL languages:

```tsx
// Set dir attribute on html element
<html lang={locale} dir={locale === 'ar' ? 'rtl' : 'ltr'}>

// CSS logical properties — work in both LTR and RTL
.container {
  margin-inline-start: 1rem;  /* instead of margin-left */
  padding-inline-end: 2rem;   /* instead of padding-right */
  border-inline-start: 1px solid; /* instead of border-left */
}
```

Tailwind CSS supports logical properties with `ps-` (padding-start) and `pe-` (padding-end) prefixes — prefer these over `pl-` and `pr-` for any text-adjacent spacing.

## i18n Checklist

```
Setup:
- [ ] ICU plugin enabled for pluralization
- [ ] Fallback locale configured (en)
- [ ] Missing key handler logs in dev, silent in prod

Translations:
- [ ] No hardcoded strings in components
- [ ] Plural forms use ICU, not string concatenation
- [ ] Dates and numbers use Intl API
- [ ] aria-label and title attributes translated
- [ ] All languages have the same key set (no missing translations)

Routing:
- [ ] Locale detected from Accept-Language header
- [ ] Locale persisted in URL path or cookie
- [ ] Language switcher updates locale without page reload

RTL (if supporting Arabic/Hebrew):
- [ ] dir attribute set on html element
- [ ] CSS logical properties used (margin-inline-*, padding-inline-*)
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| `"Hello, " + t('name')` | `t('greeting', { name })` — ICU interpolation |
| `t('documents') + " " + t('found')` | Single key: `t('documents-found', { count })` |
| `new Date().toLocaleDateString()` | `new Intl.DateTimeFormat(locale).format(date)` |
| Hardcoded `aria-label="Close"` | `aria-label={t('common:actions.close')}` |
| Storing translations in a database and fetching at runtime | Static JSON files, loaded at build time or lazy-loaded by route |
| One giant `translations.json` | Namespace per feature, loaded on demand |

## Connected Skills

- `accessibility` — translated `aria-label` and `title` attributes are part of both a11y and i18n
- `react` / `vue` — framework-specific hook usage (`useTranslation`, `useI18n`)
- `swift-localization` — native Apple platform equivalent of this skill
