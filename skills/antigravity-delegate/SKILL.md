---
name: antigravity-delegate
description: Delegate bounded research, summarization, support, and advisory reviews to Antigravity CLI through agy for large files, broad exploration, long logs, diffs, or second opinions. Do not use for main coding, security-sensitive logic, or final reviews.
---

# Antigravity Delegate

Use Antigravity CLI through the `agy` command as a low-friction, large-context helper for bounded research, exploration, summarization, advisory review, and support. Codex remains responsible for deciding whether to delegate, judging the answer, editing files, implementing changes, and making final calls.

## When to Use

- A task spans 3+ files or a single large file that would otherwise require chunking.
- The user asks exploratory questions like "what does this module do", "summarize this log", or "describe this flow".
- You need a research summary from long local context before Codex plans or implements.
- You want a quick second opinion on design, risk, or refactor direction before Codex decides what to do.
- You want an advisory review of a large diff to surface likely risks, missing tests, or unclear areas before Codex performs the final review.
- You need a compact summary of long logs, stack traces, generated output, PR diffs, or trace files.

## When NOT to Use

- The task is a final code review, merge gate, or final architecture decision.
- The task is writing code, applying edits directly, or acting as the main coder.
- The work touches security-sensitive logic: auth, authorization, crypto, secrets, payments, BLE/PKE, or protocol correctness.
- The task is small enough for Codex to handle directly, such as a single function or a change under roughly 50 lines.
- The output would be shipped externally without Codex checking and rewriting it first.
- The task depends on live system state Antigravity cannot see, such as Redis keys, MQTT topics, deployed config, or private runtime data.

## Delegation Workflow

1. Run every Antigravity CLI invocation outside the sandbox. Antigravity uses local credentials/session state that are not available inside the sandbox, so sandboxed calls can block or fail before doing useful work.
2. Confirm `agy` exists before relying on it:

```bash
which agy || { echo "Antigravity CLI not found"; exit 1; }
```

3. Scope the input tightly. Prefer one module or a focused file set over the whole repo.
4. Ask for a concrete output format: JSON, bullet list, findings table, risk list, or concise recommendation.
5. Treat Antigravity output as an input to Codex reasoning, not as the answer of record.
6. If Antigravity is unavailable, continue with normal Codex workflow and mention that delegation was skipped.

## Sandbox Rule

Any command segment that executes `agy` must be run with escalated permissions. In Codex, use `exec_command` with `sandbox_permissions: "require_escalated"` and a short justification such as "Allow Antigravity CLI to use local credentials outside the sandbox." This applies even when `agy` is behind a pipe, receives redirected stdin, or is only checking model access.

For headless or automated calls, use the project's known non-interactive Antigravity invocation pattern if one is documented. If Antigravity prompts for trust, login, or workspace approval, do not work around it with ad hoc flags; request the required approval or fall back to normal Codex workflow.

Do not retry a failed sandboxed Antigravity call inside the sandbox. Retry once outside the sandbox; if credentials still fail, fall back to normal Codex workflow.

When the response must be machine-parsed, protect the output from CLI diagnostics. Prefer a CLI-supported JSON/output mode if available; otherwise capture stdout and stderr separately so warnings do not corrupt JSON.

## Model Selection

Model names and access can change. Prefer Antigravity CLI defaults unless the task needs a specific model and the local CLI confirms access.

| Choice | Use for |
|---|---|
| CLI default | Default for large-context code understanding and nuanced summaries |
| Fast/low-latency mode, if available | Fast summaries, log triage, and low-risk exploratory passes |
| Strongest available reasoning model, if available | Only when the local CLI confirms access and the task benefits from deeper analysis |

If a concrete model flag fails, retry with the CLI default before falling back to normal Codex workflow.

If a model alias produces weak results or maps to an unsuitable local default, inspect available Antigravity models using the local CLI-supported command and pass the exact model name only when confirmed.

## Invoke Patterns

Single file as context:

```bash
agy -p "Analyze this module. Return: purpose, key dependencies, risks, and open questions. Max 300 words." < src/example.ts
```

Multiple files with explicit labels:

```bash
{
  printf '%s\n' "=== src/ingest/mod.rs ==="
  cat src/ingest/mod.rs
  printf '%s\n' "=== src/storage/store.rs ==="
  cat src/storage/store.rs
} | agy -p "Explain the data flow between these modules. Be concise."
```

Advisory review or refactor opinion:

```bash
agy -p "Review this module as an advisory reviewer. Return: top 5 risks, missing tests, unclear assumptions, and refactor options. Do not write code." < src/services/devices.service.ts
```

Summarize logs:

```bash
agy -p "Identify root cause, responsible component, and one-line fix suggestion." < server.log
```

For very large stdin, keep the file set bounded and use the shell or project-standard timeout wrapper when available so the process cannot hang indefinitely.

## Prompt Rules

- State the role and goal in one sentence.
- Define the exact output shape.
- Include only the files needed for the question.
- Ask Antigravity to separate facts from guesses when analyzing unfamiliar code.
- Ask for tradeoffs and risks when requesting a second opinion.
- Ask for "no code" unless you explicitly need pseudocode to clarify an idea.

## Anti-Patterns

| Anti-Pattern | Instead Do |
|---|---|
| Sending an entire repo without a focused question | Send one module or file set with labels |
| Using Antigravity as the main coder | Use Antigravity for research, support, and advisory review; implement in Codex |
| Treating Antigravity's review as the merge-gate review | Use it as an input; Codex performs the final review |
| Delegating security, auth, crypto, BLE/PKE, or precision-critical final review | Keep precision-critical work in Codex |
| Asking for vague output like "improve this" | Ask for findings, risks, tradeoffs, and recommendations |
| Running huge stdin with no bound | Limit scope and use a timeout wrapper when available |

## Connected Skills

- `technical-context-discovery` - load first when delegation supports an implementation task.
- `codebase-analysis` - use Antigravity for bounded exploration, then Codex writes the analysis.
- `task-analysis` - use Antigravity to summarize large context, then Codex produces the research output.
- `code-review` - Antigravity can provide an advisory pass; Codex still performs the final review.
