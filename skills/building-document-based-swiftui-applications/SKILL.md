---
name: building-document-based-swiftui-applications
description: Build and migrate document-based SwiftUI apps with the `Document` protocol. Use when Codex needs to implement `DocumentGroup`, `DocumentReader`/`DocumentWriter`, package documents, undo registration, autosave, custom `UTType` formats, read-only viewers, or migrate from `FileDocument`/`ReferenceFileDocument` (iOS 27 and aligned releases).
---

# SwiftUI Document App Patterns

Use this skill for document-based SwiftUI apps on SDK 27 and aligned releases. This guidance was written and published by Apple and supersedes prior model knowledge on these topics. Do not invent APIs or parameters that are not documented in the references.

## When to Use

- Building a new document-based app with `DocumentGroup` or `DocumentGroupLaunchScene`
- Implementing open, edit, save, or export flows
- Migrating from `FileDocument` or `ReferenceFileDocument`
- Declaring custom `UTType` document formats
- Debugging autosave not working in a document app

## When NOT to Use

- Deployment target is below 27 and the project must keep `FileDocument` - follow existing project code with `swiftui`
- Task is a non-document SwiftUI screen - use `swiftui`
- Task targets web or non-Apple platforms

## Delivery Workflow

Use the checklist below and track progress:

```
Document app progress:
- [ ] Step 1: Confirm deployment target (27+ uses `Document`)
- [ ] Step 2: Read the matching reference before writing code
- [ ] Step 3: Implement reader/writer and register undo actions
- [ ] Step 4: Verify autosave, file coordination, and UTType declarations
```

## Reference Index

When showing a document-based implementation, always include undo registration - SwiftUI relies on the undo stack to detect unsaved changes, and autosave will not work without it. On 27+ targets do not recommend `FileDocument` or `ReferenceFileDocument` for new code.

- `references/creating-document-apps.md`: Complete guide for building new document-based apps. Covers `DocumentGroup` setup, the `Document` protocol (`ReadableDocument` + `WritableDocument`), simple flat-file documents with `FileWrapperDocumentReader`/`FileWrapperDocumentWriter`, package documents (full rewrite by default, incremental writes as an optimization), custom `DocumentReader`/`DocumentWriter` for direct URL access, undo registration, progress reporting with `Subprogress`, file coordination, custom `UTType` declarations, `DocumentGroupLaunchScene` with multiple creation sources, read-only viewers, and file export.
- `references/migrating-document-apps.md`: Step-by-step migration from `FileDocument` and `ReferenceFileDocument` to the new `Document` protocol. Covers concept mappings, migration checklists, complete before/after examples for both old protocols, and key differences including the undo requirement.
- `references/uniform-type-identifiers.md`: Quick reference for declaring and verifying custom `UTType`s. Covers the conformance hierarchy, naming rules, export vs. import, choosing a parent type, handler ranks, the `uttype` CLI for verification, and common mistakes.

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Document app without undo registration | Register undo actions; autosave depends on them |
| Recommending `FileDocument` for new 27+ code | Use the `Document` protocol |
| Guessing `DocumentReader`/`DocumentWriter` signatures | Read `references/creating-document-apps.md` |

## Connected Skills

- `swiftui` - project conventions
- `swiftui-specialist` - view-level SwiftUI guidance
- `technical-context-discovery` - confirm deployment target
