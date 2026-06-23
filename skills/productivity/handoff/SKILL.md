---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save it to the project's temporary folder — the existing top-level directory named `tmp` or `temp` (also accept `temporary`); prefer `tmp` if more than one exists. If none exists, create a `tmp` directory at the project root. Do not save to the OS temporary directory.

Make sure the temporary folder is gitignored so handoff documents aren't committed. If the project root has a `.gitignore` that doesn't already ignore the folder, append an entry for it (e.g. `tmp/`); if there's no `.gitignore`, create one with that entry.

Include a "suggested skills" section in the document, which suggests skills that the agent should invoke.

Do not duplicate content already captured in other artifacts (PRDs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
