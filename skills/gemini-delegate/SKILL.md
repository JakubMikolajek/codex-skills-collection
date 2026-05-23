---
name: gemini-delegate
description: Delegate bounded research, summarization, support, and advisory reviews to Gemini CLI for large files, broad exploration, long logs, diffs, or second opinions. Do not use for main coding, security-sensitive logic, or final reviews.
---

# Gemini Delegate

Use Gemini CLI as a low-friction, large-context helper for bounded research, exploration, summarization, advisory review, and support. Codex remains responsible for deciding whether to delegate, judging the answer, editing files, implementing changes, and making final calls.

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
- The task depends on live system state Gemini cannot see, such as Redis keys, MQTT topics, deployed config, or private runtime data.

## Delegation Workflow

1. Run every Gemini CLI invocation outside the sandbox. Gemini uses local credentials/session state that are not available inside the sandbox, so sandboxed calls can block or fail before doing useful work.
2. Confirm `gemini` exists before relying on it:

```bash
which gemini || { echo "Gemini CLI not found"; exit 1; }
```

3. Scope the input tightly. Prefer one module or a focused file set over the whole repo.
4. Ask for a concrete output format: JSON, bullet list, findings table, risk list, or concise recommendation.
5. Treat Gemini output as an input to Codex reasoning, not as the answer of record.
6. If Gemini is unavailable, continue with normal Codex workflow and mention that delegation was skipped.

## Sandbox Rule

Any command segment that executes `gemini` must be run with escalated permissions. In Codex, use `exec_command` with `sandbox_permissions: "require_escalated"` and a short justification such as "Allow Gemini CLI to use local credentials outside the sandbox." This applies even when `gemini` is behind a pipe, receives redirected stdin, or is only checking model access.

For headless or automated calls, include `--skip-trust` unless the current directory is already trusted by Gemini CLI. Without it, Gemini can stop before model execution with a trusted-directory prompt.

Do not retry a failed sandboxed Gemini call inside the sandbox. Retry once outside the sandbox; if credentials still fail, fall back to normal Codex workflow.

When the response must be machine-parsed, protect the output from CLI diagnostics. Prefer a CLI-supported JSON/output mode if available; otherwise capture stdout and stderr separately so warnings do not corrupt JSON.

## Model Selection

Model names and access can change. Prefer Gemini CLI aliases unless the task needs a specific model and the local CLI confirms access.

| Choice | Use for |
|---|---|
| `pro` | Default for large-context code understanding and nuanced summaries |
| `flash` | Fast summaries, log triage, and low-risk exploratory passes |
| `gemini-3.1-pro-preview` | Only when `/model` shows access and the task benefits from the strongest available preview model |

If a concrete model fails, retry with `-m pro` or `-m flash`.

If an alias produces weak results or maps to an unsuitable local default, use `/model` to inspect available models and pass the exact model name with `-m`.

## Invoke Patterns

Single file as context:

```bash
gemini --skip-trust -m pro -p "Analyze this module. Return: purpose, key dependencies, risks, and open questions. Max 300 words." < src/example.ts
```

Multiple files with explicit labels:

```bash
{
  printf '%s\n' "=== src/ingest/mod.rs ==="
  cat src/ingest/mod.rs
  printf '%s\n' "=== src/storage/store.rs ==="
  cat src/storage/store.rs
} | gemini --skip-trust -m pro -p "Explain the data flow between these modules. Be concise."
```

Advisory review or refactor opinion:

```bash
gemini --skip-trust -m pro -p "Review this module as an advisory reviewer. Return: top 5 risks, missing tests, unclear assumptions, and refactor options. Do not write code." < src/services/devices.service.ts
```

Summarize logs:

```bash
gemini --skip-trust -m flash -p "Identify root cause, responsible component, and one-line fix suggestion." < server.log
```

For very large stdin, keep the file set bounded and use the shell or project-standard timeout wrapper when available so the process cannot hang indefinitely.

## Prompt Rules

- State the role and goal in one sentence.
- Define the exact output shape.
- Include only the files needed for the question.
- Ask Gemini to separate facts from guesses when analyzing unfamiliar code.
- Ask for tradeoffs and risks when requesting a second opinion.
- Ask for "no code" unless you explicitly need pseudocode to clarify an idea.

## Anti-Patterns

| Anti-Pattern | Instead Do |
|---|---|
| Sending an entire repo without a focused question | Send one module or file set with labels |
| Using Gemini as the main coder | Use Gemini for research, support, and advisory review; implement in Codex |
| Treating Gemini's review as the merge-gate review | Use it as an input; Codex performs the final review |
| Delegating security, auth, crypto, BLE/PKE, or precision-critical final review | Keep precision-critical work in Codex |
| Asking for vague output like "improve this" | Ask for findings, risks, tradeoffs, and recommendations |
| Running huge stdin with no bound | Limit scope and use a timeout wrapper when available |

## Connected Skills

- `technical-context-discovery` - load first when delegation supports an implementation task.
- `codebase-analysis` - use Gemini for bounded exploration, then Codex writes the analysis.
- `task-analysis` - use Gemini to summarize large context, then Codex produces the research output.
- `code-review` - Gemini can provide an advisory pass; Codex still performs the final review.
