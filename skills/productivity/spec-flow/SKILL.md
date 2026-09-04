---
name: spec-flow
description: Run a grilling session over one product flow (a group of related screens) and write every decision into Notion tickets that an agent can build from later, without the person in the room. Invoked explicitly as /spec-flow <flow>; it never auto-triggers, so plain "grill X" still goes to /grilling. Not for a single screen about to be built right now — that's /grilling on its own.
argument-hint: "<flow or work-stream name> — e.g. Trigger, Settings"
disable-model-invocation: true
---

# Spec a flow

Interview the person about one flow until every decision an implementing agent would
otherwise have to guess is made — then write those decisions, with their reasons, into
tickets. The point is to separate *deciding* from *building*: decide once across a whole
flow, then any fresh session can pick up any ticket.

The tickets carry decisions and reasoning, not implementation plans. Detail invites rigid
following; reasoning lets an agent adapt with fresh context. Some redundant reading per
build session is the accepted cost.

Project-specific pointers live in the project at `docs/spec-sources.md`, deliberately
outside this skill's folder so the skill sync doesn't wipe them. Read that file before
starting. If there isn't one, ask for what's missing and write it, so the next session
doesn't have to ask again. It needs, at minimum:

- **Boards** — each ticket board's data source, its properties, and how "ready" is marked
  there (boards differ: a checkbox on one, a Status option on another).
- **Flow pages** — where each flow's decisions live, and which of them carry a ticket list.
- **Design** — where the committed design export is and how to read the actual screens.
- **Backend** — where the code is and the reading order (handlers, validation, store,
  migrations), since the API docs usually lack required/nullable information.
- **Process page** — the one Phase 5 appends to, if the project keeps one.
- **Skills implementing agents load** — the eligible list the ticket's *Skills to load*
  section draws from. Skills only; path-scoped rules apply on their own and shouldn't be
  listed.
- **Conventions** — ticket title format, numbering, deferred prefixes.

## Phase 1 — Read, in this order

Most answers already exist somewhere. Asking for them again wastes the session, and worse,
the person may answer from memory and contradict what's written down.

1. **The project's docs first.** The flow's work-stream page, then everything it references
   — API design pages, architecture, message templates, privacy policy. These hold product
   decisions the wireframes don't show.
2. **The backend second.** Handlers, validation, and DB constraints — not just the swagger,
   which usually lacks required/nullable information. Note every status code and error code
   the flow can hit; those constrain the client more than anything in the design.
3. **The design third.** The committed wireframe export. Read the actual screen components,
   not just the artboard labels — copy, controls, and layout live there.
4. **The code last.** What exists, what's stubbed with a `TODO`, what the models already
   carry, where the flow's entry points are. Check open PRs against the flow too — a screen
   may already be built on a branch.

Keep a running list of **drift** as you read: claims in one source the others contradict, or
things the design promises that nothing implements. This list is usually the most valuable
output of the session, so don't lose it.

## Phase 2 — Open with the state of play

Before the first question, tell the person what you found, in three parts:

- **Pinned** — what the backend or design already fixes, so you won't ask about it.
- **Drifted** — the contradictions from your list.
- **Gaps** — the decisions nothing covers yet.

Then ask the first question. Start with the decision the most other decisions depend on —
usually a data-model question, not a screen one.

## Phase 3 — Grill

One question per message. Each carries:

- the options, lettered, so the answer can be a single letter
- your recommendation and why
- the strongest argument *against* your recommendation

The counter-argument matters. Several decisions will go against your recommendation once the
person reads it — that is the process working. A session that only asks is worth much less
than one that also argues, and a session that only argues one side is just persuasion.

Look things up instead of asking. If the codebase or the backend can answer, that's not a
question for the person.

**Push back when it matters.** If an answer would silently lose user data, make a claim on
screen that isn't true, or fail toward the dangerous side in a safety-relevant flow, say so
plainly and ask again. Take the second answer as final.

**Stop and brainstorm when a question turns out to be bigger than a question.** Sometimes
what looked like a UI choice is really a model choice — how recipients are stored, what a
permission denial does to persisted state. Set the interview aside, lay out the models side
by side with their failure modes, recommend one, and only then return to the interview.
These moments produce the simplest designs of the session.

**Flag what you find as you go**, in a line or two, and keep moving. Anything already
written and marked ready that this session has just invalidated goes at the top of that list
— fix it before the session ends, not after.

## Phase 4 — Sweep the tail

When the interesting decisions run out, don't keep asking one at a time. List what's left —
usually five to eight small things — each with a proposed default, and ask for "all defaults"
or the ones to discuss. This is typically the last third of the decisions and takes one
message.

## Phase 5 — Write

Confirm the set of writes in one message before making them — creates, renames, rewrites,
deferrals — then do them all.

**Tickets.** Follow the ticket bodies at the end of this file. Each ticket is self-contained: someone
with the ticket, the codebase, and the project docs needs nothing from this session.

**The work-stream page.** Update it to point at the tickets and to record anything the
session changed about the flow's shape. A page that still describes the pre-session design
contradicts the tickets an agent reads next to it.

**Change-request tickets** for everything on the drift list that this flow's tickets don't
themselves fix — a wireframe that needs an edit, a policy naming the wrong thing, a backend
gap. Put them on the board that owns the fix, not the board you happen to be on, and check
that board first so you don't duplicate one that exists.

**Deferred tickets** keep their reasoning. Record what deferring buys, what picking it up
would cost, and — most importantly — which other decisions it reopens. That last part is
what's expensive to rediscover.

**The process page**, if the project has one: a line on what this session found about the
workflow itself.

## Numbering

When a session adds tickets that must land *between* existing ones, renumber with decimals
(`11.1`, `11.2`) rather than shifting numbers that are already done — those are referenced
from commits and PRs. Prefix deferred tickets so they sort together and read as deferred at
a glance.

## What tends to go wrong

- **A ticket marked ready goes stale** when a later session changes a shared model. Anything
  touching a domain type used across flows can invalidate a ready ticket elsewhere. Check
  before marking ready; re-check tickets that share a model with what you just changed.
- **The screen is already built.** Open PRs and recent branches before writing a ticket for
  work that exists.
- **Duplicate tickets on another board.** Query the target board before creating on it.
- **The design and the tickets diverge.** Deliberate divergences are fine, but each needs to
  be argued on the ticket so an implementing agent doesn't "fix" it back.
- **Copy that makes a promise the system can't keep** — a retention period nobody enforces,
  a live location nobody sends. The screen must never claim more than the system does. When
  the design over-promises, correct the copy and raise the real feature separately.

## What not to do

- Don't write implementation plans into tickets. File lists, class names, and step-by-step
  instructions go stale and get followed rigidly. Say what to build and why; let the agent
  read the code.
- Don't ask what the code can answer.
- Don't batch questions. Several at once is bewildering and the answers get worse.
- Don't skip the state-of-play. The person needs to know what's pinned before they'll trust
  what you're not asking about.

## Ticket bodies

Every section below earns its place. Skip one only when there's genuinely nothing to say.

```markdown
<One or two sentences: what this ticket delivers, which screens, where it's reached from.>

## Scope
- <bullets: the concrete things this ticket builds>

## Out of scope
- <what an implementer might reasonably think is included, and isn't — with the ticket that owns it>

## Decisions
**<Decision, as a short declarative sentence.>**
<Why. Then what was considered and rejected, and why. One paragraph each; two if the
rejected option is the one an agent would reach for by default.>

**<Next decision.>**
...

## Screens
<What's drawn, by wireframe id, in enough words that the agent knows what to look for.
Note any deliberate divergence from the wireframe here, with a pointer to the decision.>

## API contract
- <endpoint → status codes and error codes the client must handle>
- <payload rules that constrain the UI: length caps, required fields, enum values>

## Agreed defaults
- <the tail-sweep decisions, one line each, with a clause of reasoning where it isn't obvious>

## Skills to load
<from the pointer file's list — only the ones this ticket needs>

## Notes
- <dependencies on other tickets, by number>
- <entry points in code: the `TODO` this replaces, the scene that pushes it>
- <anything true that an agent might report as a bug>
```

### The parts that do the work

**Decisions carry rejected alternatives.** An agent reading "recipients resolve to all
contacts" will wonder about per-action selection and may build it. An agent reading *why* per-
action selection was rejected, and what the V2 design is, won't. The rejected option is often
the one the agent would have reached for — say why it's wrong.

**Out of scope names the owner.** "Not this ticket" invites the agent to do it anyway when it
seems small. "Ticket 12.1 owns the form" doesn't.

**API contract is facts, not prose.** Status codes, error codes, caps, enums. The agent will
read the backend anyway; this section tells it which parts matter for this screen.

**Notes pre-empt false bug reports.** If renaming an action doesn't rewrite history, and that's
correct, say so — otherwise it comes back as a finding.

### Deferred tickets

Prefix the title (`[Deferred]`, `[V2]`). Body:

```markdown
**Deferred** until <what unblocks it>.

## Why deferred
<The reasoning, in full. Someone will want to reopen this; give them the argument they'd
have to reconstruct.>

## What it would cost
<Platform work, store review, permissions — the parts that aren't obvious from the title.>

## What it reopens
<Other decisions that were made assuming this stays deferred.>

## Unblocked by
<Ticket names, on whichever board.>
```

### Change-request tickets

For drift found while reading — wrong copy in a wireframe, a policy naming the wrong
processor, a backend claim that's false. Short:

```markdown
<What's wrong, where, and how it was noticed.>

## Change
- <the specific edit>

## Leave alone
- <the nearby thing that looks wrong but is deliberate, with why>
```

Put it on the board that owns the fix. A wireframe edit is a Design ticket on the mobile
board; a backend behaviour is a Backend ticket; a published document is Legal or Content.
