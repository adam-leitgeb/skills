---
name: build-ticket
description: Build one ready-for-development ticket end to end in a single session — implement, /code-review, /qa, merge. Invoked explicitly as /build-ticket <ticket>; words after the ticket override a default (platforms, review effort, no merge).
argument-hint: "<ticket> [overrides] — e.g. 26.1, or 28 shared only, don't merge"
disable-model-invocation: true
---

# Build a ticket

Take one ticket that a spec session marked ready and carry it to merged. The ticket
holds the decisions and their reasons; the implementation is yours. One ticket per
session — never start the next one.

Words after the ticket override the defaults below: which platforms, the review
effort, whether to merge.

## 1. Read

- Load the ticket the way the project does — `/ticket-spec` if the project has it,
  otherwise fetch the ticket and its flow page yourself. Read the project's CLAUDE.md
  and the skills the ticket lists.
- Check it is marked ready. If it isn't, stop and say so.
- Move the ticket to in progress. Don't edit it beyond its status; what you decide or
  change goes in the PR.
- Trust the repo over the ticket's code pointers; tickets are written before the code
  they point at moves. If the ticket's *decisions* contradict the code, or each other,
  in a way that changes the product, ask. Everything else is yours to decide — say what
  you decided in the PR.

## 2. Build

- Branch from the default branch. Build the whole ticket: on a KMP project that is
  shared + iOS + Android unless the invocation says otherwise. Commit per phase, with
  `git-commit`.
- The project's build and unit tests pass before you go on.
- Open the PR now, so CI runs while you review and test: Conventional Commit title,
  a body that says what was built, what you decided where the ticket left it open,
  and where you deviated and why. Keep the body current as the next steps change things.

## 3. Review

Run `/code-review` at the effort you are running at, unless the invocation names one.
Fix the findings.

## 4. QA

QA is the last gate, so it runs on the code that will ship. Run `/qa` if the project
has it, otherwise test the way the project tests. Fix what it finds and retest — the
skill covers that loop. If a fix is more than a few lines, run `/code-review` again on
that diff.

## 5. Merge

Wait for CI to be green, then squash-merge — unless the invocation says to leave the
PR for review. Move the ticket to done.

## Never

- Chain into another ticket, or edit any ticket beyond this one's status.
- Skip the review or QA because the change looks small.
