---
name: task-analysis
description: Analyse task description, performs gap analysis, expand the context for the task, analyse the current state of the system in the context of the task, helps build PRD, creates a context for the task, gathers information about the task from different sources.
---

# Task Analysis

This skill helps you gather and expand context about a specific task to be developed, looks for gaps in the task description and helps to understand the current state of the system.

## Task analysis process

Use the checklist below and track your progress:

```
Analysis progress:
- [ ] Step 0: Determine input source
- [ ] Step 1: Gather context from local sources
- [ ] Step 2: Gather information from repository artifacts
- [ ] Step 3: Identify gaps and ask clarification questions
- [ ] Step 4: Based on the answers and gathered information finalize the research report
```

**Step 0: Determine input source**

Before gathering information, determine how the task context was provided:

- **Research & plan files exist** (`*.research.md`, `*.plan.md`): Read them as the primary source of requirements, acceptance criteria, scope, and definition of done.
- **Context provided directly in the prompt**: Extract requirements, acceptance criteria, and scope from the user's message. Treat the prompt as the single source of truth. If critical information is missing, ask for clarification before proceeding.
- **Local project artifacts available**: Use local markdown docs, ADRs, tickets mirrored in files, and code comments as additional context.

This determination affects how much of Steps 1–2 you need to execute. If context is already fully provided inline or in local files, skip redundant discovery.

**Step 1: Gather context from local sources**

Collect all available local context first:
- Existing research and plan files
- Local docs in `docs/`, `README*`, ADRs, and architecture notes
- Open TODOs, comments, and implementation notes in the codebase

Do not assume external task management tools are available.

**Step 2: Gather information from repository artifacts**

Analyze the codebase based on task requirements. Identify modules, files, and flows related to the task domain.
When links are provided in task context, only use them if they are directly accessible from the current environment.
Prefer local, verifiable sources over assumptions.

**Step 3: Identify gaps and ask clarification questions**

Based on the gathered information and task description, look for ambiguities or missing information. Create the questions and ask them to the user. Don't proceed until all questions are answered or you are directly told to continue.

**Step 4: Based on the answers and gathered information finalize the research report**

Generate a report following the `./references/research.example.md` structure. Make sure to provide all necessary information that you gathered, all findings and all answered questions.

Don't add or remove any sections from the template. Follow the structure and naming conventions strictly to ensure clarity and consistency.

## Connected Skills

- `codebase-analysis` - for analyzing the existing codebase in the context of task requirements
- `implementation-gap-analysis` - for understanding what already exists vs what needs to be built
