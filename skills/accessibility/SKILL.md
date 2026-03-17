---
name: accessibility
description: Web accessibility implementation and audit patterns conforming to WCAG 2.1 AA. Covers semantic HTML, ARIA roles and properties, keyboard navigation, focus management, screen reader compatibility, color contrast, and accessible component patterns for modals, menus, forms, and live regions. Use when implementing UI components that must be accessible, auditing existing UI for a11y issues, or reviewing code for WCAG 2.1 AA compliance.
---

# Accessibility (WCAG 2.1 AA)

Accessibility is not a checklist — it is a design constraint. This skill provides the depth needed to implement and audit WCAG 2.1 AA compliance in web UI components.

## When to Use

- Implementing any interactive UI component (modal, menu, combobox, tab panel, carousel)
- Auditing existing UI for accessibility issues before a release
- Reviewing a PR that touches interactive UI
- Implementing forms, error messages, or dynamic content updates
- A screen reader or keyboard navigation test reveals failures

## When NOT to Use

- Backend-only tasks with no HTML/DOM output
- Basic static content pages with no interactive components — `frontend-implementation` is sufficient
- Native mobile accessibility (SwiftUI/UIKit has its own a11y model — see `swiftui`)

## WCAG 2.1 AA — Four Principles

Everything traces back to **POUR**:
- **Perceivable** — information presented in ways users can perceive
- **Operable** — UI components operable by all input methods
- **Understandable** — content and operation understandable
- **Robust** — content interpretable by assistive technologies

AA conformance requires meeting all Level A and Level AA success criteria.

## Accessibility Process

```
Accessibility progress:
- [ ] Step 1: Semantic structure and landmark regions
- [ ] Step 2: Keyboard navigation and focus management
- [ ] Step 3: ARIA roles, states, and properties
- [ ] Step 4: Color contrast and visual presentation
- [ ] Step 5: Forms and error handling
- [ ] Step 6: Dynamic content and live regions
- [ ] Step 7: Test with keyboard, axe, and screen reader
```

**Step 1: Semantic structure and landmark regions**

Landmark regions give screen reader users the ability to jump to major sections:

```html
<header role="banner">          <!-- site header -->
<nav aria-label="Main navigation">
<main>                          <!-- primary content — one per page -->
<aside aria-label="Related articles">
<footer role="contentinfo">
```

Document structure rules:
- One `<main>` per page — never zero, never two
- Heading hierarchy: `h1` → `h2` → `h3` — never skip levels
- One `h1` per page, describing the page purpose
- `<section>` and `<article>` need accessible names (`aria-labelledby` pointing to a heading inside them)
- Don't use `<div>` or `<span>` for interactive elements — use `<button>`, `<a>`, `<input>`

**Step 2: Keyboard navigation and focus management**

Every interactive element must be keyboard-operable:

```
Tab           — move to next focusable element
Shift+Tab     — move to previous focusable element
Enter/Space   — activate button or checkbox
Enter         — follow link, submit form
Arrow keys    — navigate within composite widgets (menus, tabs, radio groups)
Escape        — close overlay, cancel action
```

Focus rules:
- Focus must always be visible — never `outline: none` without a custom focus indicator that meets 3:1 contrast
- Tab order must follow visual reading order — use DOM order, not `tabindex > 0` for reordering
- `tabindex="0"` — makes element focusable in natural DOM order (for custom interactive elements)
- `tabindex="-1"` — focusable programmatically only, not in tab sequence (for focus management)
- Never use `tabindex > 0` — it breaks the natural tab order

Focus management for dynamic UI:
```typescript
// When opening a modal — move focus into it
dialog.querySelector('[autofocus], button, [href], input').focus();

// When closing a modal — return focus to the trigger
triggerButton.focus();

// When content updates dynamically — announce to screen readers
// (see Live Regions section)
```

Focus trap for modals:
```typescript
function trapFocus(container: HTMLElement) {
  const focusableSelectors = 'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])';
  const focusable = Array.from(container.querySelectorAll(focusableSelectors));
  const first = focusable[0] as HTMLElement;
  const last = focusable[focusable.length - 1] as HTMLElement;

  container.addEventListener('keydown', (e) => {
    if (e.key !== 'Tab') return;
    if (e.shiftKey && document.activeElement === first) {
      e.preventDefault();
      last.focus();
    } else if (!e.shiftKey && document.activeElement === last) {
      e.preventDefault();
      first.focus();
    }
  });
}
```

**Step 3: ARIA roles, states, and properties**

Rule 1 of ARIA: do not use ARIA if native HTML can express the semantics.

```html
<!-- Prefer native -->
<button>Save</button>
<!-- Over custom -->
<div role="button" tabindex="0">Save</div>
```

When ARIA is necessary — use it correctly:

Required ARIA for common patterns:

```html
<!-- Icon-only button — must have accessible name -->
<button aria-label="Close dialog">
  <svg aria-hidden="true">...</svg>
</button>

<!-- Toggle button -->
<button aria-pressed="false">Enable notifications</button>

<!-- Expandable section -->
<button aria-expanded="false" aria-controls="details-panel">Details</button>
<div id="details-panel" hidden>...</div>

<!-- Loading state -->
<button aria-busy="true" aria-disabled="true">
  <span aria-hidden="true">Saving...</span>
  <span class="sr-only">Saving, please wait</span>
</button>

<!-- Required form field -->
<label for="email">Email <span aria-hidden="true">*</span></label>
<input id="email" type="email" required aria-required="true" aria-describedby="email-error"/>
<span id="email-error" role="alert" hidden>Email is required</span>
```

Widget roles and required keyboard behavior:

| Widget | Role | Required keyboard |
|---|---|---|
| Button | `button` | Enter, Space to activate |
| Link | `link` | Enter to follow |
| Checkbox | `checkbox` | Space to toggle |
| Radio group | `radiogroup` + `radio` | Arrow keys to select within group |
| Tab panel | `tablist` + `tab` + `tabpanel` | Arrow keys between tabs, Tab into panel |
| Menu | `menu` + `menuitem` | Arrow keys to navigate, Escape to close |
| Combobox | `combobox` + `listbox` | Arrow keys, Enter to select, Escape to close |
| Dialog | `dialog` | Focus trap, Escape to close |
| Slider | `slider` | Arrow keys to change value |

**Step 4: Color contrast and visual presentation**

WCAG 2.1 AA contrast requirements:
- **Normal text** (< 18px regular or < 14px bold): **4.5:1** minimum
- **Large text** (≥ 18px regular or ≥ 14px bold): **3:1** minimum
- **UI components** (input borders, focus indicators, icons): **3:1** minimum
- **Decorative elements**: no requirement

Tools: `axe DevTools`, `Colour Contrast Analyser`, browser DevTools accessibility panel

Never convey information with color alone:
```html
<!-- BAD — color-only status indicator -->
<span style="color: red">Error</span>

<!-- GOOD — icon + text, color is supplementary -->
<span class="error">
  <svg aria-hidden="true"><!-- error icon --></svg>
  Error: Email is required
</span>
```

Spacing and layout:
- Text must be resizable to 200% without loss of content or functionality (WCAG 1.4.4)
- Content must not require horizontal scrolling at 320px viewport width for single-column layout
- Sufficient spacing between interactive elements (minimum 44×44px touch target — iOS/Android HIG recommendation, aligns with WCAG 2.5.8 AA)

**Step 5: Forms and error handling**

Every form field needs:
```html
<div class="field">
  <!-- Visible label — always. Never placeholder-only. -->
  <label for="email">Email address</label>

  <!-- Input with id matching label's for -->
  <input
    id="email"
    type="email"
    autocomplete="email"
    aria-required="true"
    aria-describedby="email-hint email-error"
  />

  <!-- Hint text — visible, associated -->
  <p id="email-hint">We'll use this to send your receipt.</p>

  <!-- Error — hidden until validation fails, role="alert" for live announcement -->
  <p id="email-error" role="alert" hidden>
    Enter a valid email address.
  </p>
</div>
```

Error handling rules:
- Errors announced to screen readers via `role="alert"` or `aria-live="assertive"`
- Error message describes the problem and how to fix it (not just "Invalid input")
- Field `aria-invalid="true"` when it has an error
- On form submission failure: move focus to the error summary or first field with an error
- Never clear the form on submission error

**Step 6: Dynamic content and live regions**

For content that updates without a page load, screen readers need explicit notification:

```html
<!-- Polite — announces when user is idle (status messages, search results count) -->
<div aria-live="polite" aria-atomic="true" class="sr-only" id="status"></div>

<!-- Assertive — interrupts immediately (errors, critical alerts) -->
<div aria-live="assertive" aria-atomic="true" class="sr-only" id="alert"></div>
```

```typescript
function announce(message: string, priority: 'polite' | 'assertive' = 'polite') {
  const region = document.getElementById(priority === 'polite' ? 'status' : 'alert');
  region.textContent = ''; // clear first
  requestAnimationFrame(() => { region.textContent = message; }); // then set
}

// Usage
announce('3 results found for "TypeScript"');
announce('Your changes have been saved');
announce('Error: connection failed', 'assertive');
```

`aria-atomic="true"` — announces the entire region content when any part changes (not just the changed part).

**Step 7: Test with keyboard, axe, and screen reader**

Keyboard test (no mouse):
1. Tab through every interactive element — is tab order logical?
2. Can every action be performed with keyboard alone?
3. Is focus visible at every step?
4. Does focus move correctly when modals/popups open and close?

Automated audit with axe:
```bash
# axe CLI
npm install -g @axe-core/cli
axe http://localhost:3000 --exit

# In tests (jest-axe)
import { axe, toHaveNoViolations } from 'jest-axe';
expect.extend(toHaveNoViolations);
it('has no accessibility violations', async () => {
  const { container } = render(<MyComponent />);
  expect(await axe(container)).toHaveNoViolations();
});
```

Screen reader testing (manual — axe cannot catch everything):
- **macOS/iOS**: VoiceOver — `Cmd+F5` to enable, `VO+U` for rotor
- **Windows**: NVDA (free) — most common screen reader for Windows
- **Android**: TalkBack

Screen reader test checklist:
- [ ] Page title announced on load
- [ ] Landmark regions navigable via screen reader shortcut
- [ ] Every form field has an announced label
- [ ] Errors announced when they appear
- [ ] Modal opens with focus inside, closes with focus on trigger
- [ ] Dynamic content updates announced via live regions
- [ ] Images have meaningful alt text (or `alt=""` for decorative)

## Accessibility Checklist

```
Structure:
- [ ] Landmark regions present (main, nav, header, footer)
- [ ] Heading hierarchy correct (h1 → h2 → h3, no skips)
- [ ] One h1 and one main per page

Keyboard:
- [ ] All interactive elements reachable by Tab
- [ ] Tab order follows visual order
- [ ] Focus indicator visible on all focusable elements
- [ ] Composite widgets use arrow key navigation
- [ ] Modals trap focus and return it on close

ARIA:
- [ ] Native HTML used where possible (no div-button)
- [ ] Icon-only buttons have aria-label
- [ ] Toggle states use aria-pressed or aria-expanded
- [ ] Dynamic regions have aria-live

Color and contrast:
- [ ] Normal text: 4.5:1 minimum contrast
- [ ] Large text: 3:1 minimum contrast
- [ ] Information not conveyed by color alone
- [ ] Touch targets ≥ 44×44px

Forms:
- [ ] Every input has a visible label (not placeholder)
- [ ] Errors associated with field via aria-describedby
- [ ] Error messages describe the problem and fix
- [ ] role="alert" on error containers

Testing:
- [ ] Keyboard-only navigation works
- [ ] axe scan has zero violations
- [ ] Manual screen reader test completed for key flows
```

## Common Component Patterns

**Visually hidden but accessible** (sr-only utility):
```css
.sr-only {
  position: absolute;
  width: 1px; height: 1px;
  padding: 0; margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}
```

**Skip link** (mandatory for keyboard users):
```html
<a href="#main" class="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4">
  Skip to main content
</a>
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| `outline: none` without replacement | Custom focus style with 3:1 contrast vs background |
| `<div role="button">` | `<button>` — inherits all keyboard behavior for free |
| Placeholder as only label | Visible `<label>` — placeholder disappears on input |
| `aria-label` on every element | Use it only when there is no visible text to reference |
| `role="alert"` on static content | `role="alert"` only on content that dynamically appears |
| Color-only error indicators | Icon + text + `aria-invalid` + error message |
| `tabindex="2"` for ordering | Reorder in DOM — `tabindex > 0` breaks natural flow |

## Connected Skills

- `frontend-implementation` — base UI implementation patterns; accessibility extends them
- `react` — React-specific accessible component patterns (refs for focus, useId)
- `vue` — Vue-specific patterns (v-show vs v-if for ARIA state)
- `e2e-testing` — accessibility testing in Playwright with `getByRole` locators
