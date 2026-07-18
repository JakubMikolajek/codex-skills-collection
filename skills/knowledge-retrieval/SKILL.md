---
name: knowledge-retrieval
description: Retrieve a small, bounded set of relevant prior notes from the Obsidian vault (concepts, patterns, playbooks, comparisons, ADRs, debug traces, experiments) before planning or implementing, instead of re-discovering decisions the vault already recorded. Returns a context pack of 3-7 notes with an explicit token budget and a stated reason for each pick. Degrades to targeted file search when no embedding/vector infrastructure is available.
---

# Knowledge Retrieval

This skill is the read side of the vault. `obsidian-note` writes durable knowledge;
this skill retrieves it back into task context, bounded and justified, instead of either ignoring
the vault entirely or dumping it wholesale into a prompt.

## When to Use

- Before `architecture-design` or `/plan`, when the project has an established vault with
  `_index.md`/`_context.md` already populated
- Before implementing something that plausibly has prior art in the vault (a pattern, a playbook,
  an ADR that already decided this trade-off)
- When a debug task's symptom resembles something in `04-debug/` or `03-skills/playbooks/`

## When NOT to Use

- No vault configured yet (`_codex-config.md` missing) — nothing to retrieve
- Purely trivial task with no plausible prior art
- The task already has an explicit, sufficient context (don't re-fetch what's already in hand)

## Core Principle: Bounded, Justified, Degradable

- **Bounded**: return 3-7 notes/snippets within an explicit token budget (default: treat ~1500
  tokens of note content as the ceiling for a normal task; state the number used when it differs).
  Never return "everything that matched" — rank and cut.
- **Justified**: every note in the pack gets one line saying why it was selected. A context pack
  with unexplained inclusions is not trustworthy enough to hand to an implementer.
- **Degradable**: this skill must work with nothing more than the filesystem and `grep`/keyword
  search. Treat semantic ranking as an enhancement layered on top when available, never a
  precondition for functioning at all.

## Retrieval Process

```
Knowledge Retrieval progress:
- [ ] Step 1: Read the project's _context.md and _index.md
- [ ] Step 2: Gather candidates
- [ ] Step 3: Rank candidates
- [ ] Step 4: Cut to budget
- [ ] Step 5: Return the context pack with reasons
```

**Step 1: Read `_context.md` and `_index.md` first**

These are the cheapest, highest-value reads — `_context.md` (see `obsidian-note`'s
`references/context-file.md`) already summarizes current state, constraints, and known traps.
Read them before anything else; they may already answer the question without needing a single
additional note.

**Step 2: Gather candidates**

Search across the note types most likely to hold prior art for this task:
`02-adr/`, `03-skills/{concepts,patterns,playbooks,comparisons,domains}/`, `04-debug/`,
`05-systems/`, `06-experiments/`. Use keyword/grep search against the task's key terms
(technology names, symptom words, the specific decision being weighed) as the baseline mechanism.

**Step 3: Rank candidates**

Apply these dimensions, in this priority order, using whatever signal is actually available:

1. **Lexical/keyword match** — always available, the deterministic baseline (grep/BM25-style
   term overlap against title, tags, technologies).
2. **Semantic match** — only if an embeddings/vector layer is configured for this vault; skip
   silently otherwise, do not fake it with keyword matching relabeled as semantic.
3. **RRF fusion** of 1 and 2 — only meaningful once both exist; with keyword-only, rank is just
   the keyword score.
4. **Project/domain boost** — a note whose `scope` matches this project, or whose
   `technologies` list overlaps the current task's stack, ranks above an equally-matched but
   unrelated-scope note.
5. **Confidence/source-authority boost** — `status: verified`/`stable` and `confidence: high`
   outrank `status: seed`/`confidence: low` at equal topical relevance.
6. **Freshness/version compatibility** — prefer a more recent `last_verified` when two notes
   otherwise tie; a `status: stale` note ranks below its superseding note if one is linked via
   `supersedes`.
7. **Explicit wikilink proximity** — a note directly linked from `_context.md`, `_index.md`, or
   an already-selected top candidate ranks above an equally-scored but unlinked note.

This skill's baseline implementation only reliably has (1), (4), (5), (6), (7) — (2) and (3)
require infrastructure that may not exist yet. See "Future: pluggable ranking" below.

**Step 4: Cut to budget**

Keep the top 3-7 by the ranking above, subject to the token budget. Prefer fewer, well-justified
notes over padding to 7 with marginal matches.

**Step 5: Return the context pack**

```
CONTEXT PACK — <task one-liner>

1. [[03-skills/patterns/vue-offline-cache-dexie-tanstack-query]] (pattern, verified, high confidence)
   Why: directly matches "offline cache" + "Vue" in the task; scope=this project.
2. [[ADR-0015-lsp-concurrency]] (adr, accepted)
   Why: prior decision on the same concurrency trade-off this task revisits.
...

Token budget: ~1500 (used: ~1100)
Degraded mode: <yes/no — state if semantic/RRF layers were unavailable this run>
```

## Runtime Ownership

- **Standalone** (Codex without Claude): Codex invokes this skill directly and incorporates the
  context pack into its own work.
- **Hybrid** (Claude + Codex): Claude orchestrates retrieval **before** composing the delegation
  prompt, and decides what actually reaches Codex — this skill produces the candidate pack, Claude
  makes the inclusion call alongside conversation-level context Codex doesn't have. Codex may
  request missing project knowledge in its result (an `OBSIDIAN EVIDENCE`-adjacent note: "this
  would have been faster with X"), but must not independently build a competing retrieval/context
  state — that risks two different views of "what the vault says" existing in the same session.

## Future: Pluggable Ranking (BM25 + embeddings + RRF)

This skill's interface is designed so a richer ranking backend can be plugged in later without
changing how it's invoked or what it returns:

- The interface is: task description + project scope in, ranked context pack out. Nothing about
  the calling convention assumes keyword-only ranking.
- When an external BM25 + embeddings + RRF pipeline exists, steps 2-3 delegate the actual scoring
  to it, but step 4 (cut to budget) and step 5 (justify) stay identical.
- Until then, keyword/frontmatter-based ranking (dimensions 1, 4-7 above) is the complete,
  functioning implementation — not a stub waiting to be replaced. Do not describe it as
  non-functional or block on the future backend existing.

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Returning the entire vault or an entire folder as "context" | Rank and cut to 3-7, always |
| Fabricating a semantic-match score with no embeddings layer configured | Skip that dimension silently, rank on what's actually available |
| Omitting the "why" for a selected note | Always state the one-line reason |
| Claude and Codex each independently deciding what vault knowledge applies | Claude orchestrates and makes the final call in hybrid mode |
| Treating a `seed`/unreviewed candidate the same as a `verified` note | Confidence/status boost must actually affect ranking |
| Blocking retrieval entirely because no vector infra exists | Degrade to keyword search — it must still return something useful |

## Connected Skills

- `obsidian-note` — writes what this skill reads; see its `references/context-file.md` and
  `references/note-types.md`
- `architecture-design`, `task-analysis` — typical consumers of a context pack before planning
- `technical-context-discovery` — code-level conventions; this skill is vault-level prior
  knowledge. Run both when a task needs current codebase conventions AND historical rationale.
