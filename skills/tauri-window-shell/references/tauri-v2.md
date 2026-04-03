# Tauri v2 Window Shell References

This reference supports `tauri-window-shell` for React + Tauri desktop shell tasks.

## Scope

Use this file for:
- native window controls from frontend
- titlebar drag region and interaction boundaries
- window-state synchronization and event listeners
- verification checklist before shipping

## API Surface (Tauri v2)

Primary import target:

```ts
import { getCurrentWindow } from "@tauri-apps/api/window";
```

Common operations:

```ts
const appWindow = getCurrentWindow();

await appWindow.minimize();
await appWindow.toggleMaximize();
await appWindow.close();
await appWindow.setFullscreen(true);
const isMaximized = await appWindow.isMaximized();
```

Drag behavior:

- Prefer HTML drag regions (`data-tauri-drag-region`) for custom titlebar UX.
- Keep interactive controls out of drag regions (buttons, inputs, tabs, menus).

## Frontend Adapter Pattern

Centralize window interactions in one adapter/hook to avoid inconsistent behavior:

```ts
import { getCurrentWindow } from "@tauri-apps/api/window";

export const windowShell = {
  async minimize() {
    await getCurrentWindow().minimize();
  },
  async toggleMaximize() {
    await getCurrentWindow().toggleMaximize();
  },
  async close() {
    await getCurrentWindow().close();
  },
  async isMaximized() {
    return getCurrentWindow().isMaximized();
  },
};
```

## State Sync Pattern

Synchronize UI state with native state:

- read native state on mount (`isMaximized`)
- subscribe to resize/window state events
- clean up listeners on unmount

Minimal pattern:

```ts
const unlisten = await getCurrentWindow().onResized(async () => {
  const maximized = await getCurrentWindow().isMaximized();
  setIsMaximized(maximized);
});

// later (cleanup)
unlisten();
```

## Verification Matrix

Before merge, verify:

- minimize/maximize/close works from custom buttons
- double-click on titlebar matches product decision (maximize/restore or disabled)
- drag works only in dedicated zones
- startup bounds and position are valid after relaunch
- behavior is correct on at least one secondary display setup

## Frequent Regressions

| Regression | Typical Root Cause | Mitigation |
|---|---|---|
| Controls stop receiving clicks | Drag region overlays interactive area | Split drag zone and no-drag controls |
| Maximize icon desync | UI state stored locally only | Re-read native state and subscribe to events |
| Works in browser dev, fails in desktop app | Validation skipped in Tauri runtime | Always test inside desktop runtime build |
| Double-click triggers random behavior | Implicit browser default behavior | Handle explicit titlebar double-click policy |

