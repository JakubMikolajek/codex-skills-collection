---
name: uikit-app-modernization
description: UIKit modernization for multi-window and scene-based iOS. Use when Codex needs to replace `UIScreen.main`, `interfaceOrientation`, or symmetric safe-area assumptions, or migrate an app from the application lifecycle to the scene lifecycle in Swift or Objective-C UIKit code.
---

# UIKit App Modernization Patterns

Use this skill to make UIKit apps behave correctly in resizable, multi-window environments by removing legacy shared-state APIs. The full Apple-authored workflow, core principles, and task registry live in `references/workflow.md`; read it before editing.

## When to Use

- Code references `UIScreen.main` / `UIScreen.mainScreen`
- Code reads `interfaceOrientation` for layout decisions
- App still uses application-lifecycle `AppDelegate` window setup and needs scene lifecycle
- Layout hard-codes insets or assumes symmetric safe areas
- User asks to prepare a UIKit app for multi-window or resizable scenes

## When NOT to Use

- App is SwiftUI-only - use `swiftui`
- Task is general UIKit feature work with no deprecated shared-state API
- Task would require opportunistic cleanup of unrelated lines

## Delivery Workflow

Use the checklist below and track progress:

```
UIKit modernization progress:
- [ ] Step 1: Detect target API occurrences across all in-scope files
- [ ] Step 2: Read the active task reference before editing
- [ ] Step 3: Apply the replacement for every occurrence (no TODO-only or empty diffs)
- [ ] Step 4: Verify every input file has a non-empty diff and control flow is preserved
```

## Task Registry

Apply every task unless the request scopes to a subset. Each task has its own detection patterns, decision tree, and verification rules.

| Task | Reference | Description |
|---|---|---|
| UIScreen.main modernization | `references/uiscreen-task.md` | Replace `UIScreen.main` with context-appropriate APIs |
| Orientation modernization | `references/orientation-task.md` | Replace layout-related orientation checks with size classes or window bounds |
| Scene lifecycle migration | `references/scene-lifecycle-task.md` | Migrate AppDelegate to SceneDelegate |
| Safe area insets | `references/safe-area-task.md` | Replace hard-coded insets and support asymmetric safe areas |

Key rules (full list in `references/workflow.md`):
- Always apply a concrete replacement when the target API is present; a TODO-only or empty diff is a failure.
- Never replace dynamic values with literals or walk global state (`UIApplication.shared`, `UIScreen.main`).
- Never remove the old method when adding a new overload; keep it as a deprecated forwarder.
- Ask before risky signature or behavior changes; stay in scope with no opportunistic cleanup.

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| TODO-only or empty diff for a file containing the target API | Apply the replacement from the task reference |
| Deleting the old method when adding an overload | Keep it as a deprecated wrapper that forwards |
| Collapsing `if`/`else` or removing guards while editing | Change only the deprecated reference |
| Substituting `UIScreen.main` with another global | Use the view, trait collection, or window scene nearest the use |

## Connected Skills

- `swiftui` - SwiftUI side of mixed apps
- `technical-context-discovery` - project conventions before editing
- `modernize-tests` - verify with Swift Testing
