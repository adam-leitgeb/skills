---
name: notion-project-board
description: Use when the user wants to create a new Notion board for a project (e.g. "create a Notion board for <project>", "set up a tasks board in Notion"). Builds one of two boards - a "<project> Milestones" board on the project root page, or a "<work-stream> Tasks" ticket board on a work-stream page - each with Status / Task Type / Ready-for-development and a board view grouped by Status. Covers only the board itself, not individual tickets.
argument-hint: "<project name> or the Notion page URL the board belongs on"
---

# Create a Notion project board

Create a fresh board at the **end of a Notion page**, via the Notion MCP, with no
manual setup. This skill builds **only the board** (database + view + the heading
and legend above it) — never any tickets.

## Two levels — pick the right one first

A project's boards form a two-level hierarchy. Ask which is wanted if it isn't
obvious from the target page:

| | **Milestone board** | **Ticket board** |
|---|---|---|
| Lives on | the project **root** page | a **work-stream** page (Mobile Apps, Backend, Admin Console…) |
| Titled | `<project> Milestones` | `<work-stream> Tasks` |
| One row = | a whole milestone (`M4.3 — Emergency Contacts`) | one ticket, usually one PR (`17 · Contacts — Add contact form`) |
| Has `Layer` | yes — which work-stream the milestone belongs to | no — the page it lives on already says |
| How many | exactly **one** per project | one per active work-stream |

Rows never cross levels: day-to-day tickets go on a work-stream board, and the
root board only ever gets a row for a whole milestone. A milestone's status is
the roll-up of the tickets under it, kept in sync by hand.

Reference: the **Guardian** project — root page holds `Guardian Milestones`, the
`Mobile Apps` page holds `Mobile Apps Tasks`.

## What the final result looks like

Appended to the end of the target page, in this order:

```
# Milestones                          (or: # Tasks)
<legend paragraph — see below>
[ <title> — inline database, "Board view" tab ]
```

> **Heads-up on view tabs.** `notion-create-database` always auto-creates a
> "Default view" (table) tab, and the MCP cannot delete, reorder, or retype a
> view. So the finished database has **two** tabs — `Default view` (table) first,
> then `Board view` — and Notion renders the *first* one (the table) by default.
> Getting a board-*only* database (like the reference boards) needs one manual
> click in Notion. See [Default view](#notes).

### Properties

Both board kinds share these:

| Property | Type | Values |
|----------|------|--------|
| `Name` | title | — |
| `Status` | select | `Backlog`, `In progress`, `Done` (in this order) |
| `Ready for development` | checkbox | checked = full spec written, ready for a coding agent |
| `Task Type` | select | `Feature`, `Bug`, `Enhancement`, `Refactor`, `Chore`, `Ops`, `Research`, `Design`, `Marketing`, `Content`, `Legal`, `Finance` |

A **milestone** board adds one more:

| Property | Type | Values |
|----------|------|--------|
| `Layer` | select | the project's work-streams, e.g. `Admin Console`, `Backend`, `Mobile` — ask the user |

> **Why `Ready for development` is a checkbox, not a Status column.** It is an
> *attribute* of a row, not a stage of work: a spec can be written long before
> anyone starts, and "specced" and "in progress" are independent. As a fourth
> kanban column it forced a false ordering and went stale. As a checkbox it can
> be filtered on and shows up on the card. Status stays a clean
> Backlog → In progress → Done.

> **Why `Status` is a `select`, not a `status` property.** A Notion `status`-type
> property's options/groups **cannot** be customized through the MCP DDL — only
> the default `Not started` / `In progress` / `Done` are created, there is no
> option syntax at creation, and `ALTER COLUMN "Status" SET STATUS(...)` is
> rejected as a parse error, so it can't be fixed after the fact either. A
> `select` gives full control over option names, colors, and left-to-right column
> order, and a board view groups by it identically. Do **not** "fix" this to a
> `status` type.

### Legends

Milestone board:

```
Whole-project view — one row per milestone, grouped by work-stream (`Layer`). Day-to-day tickets live on the work-stream boards. 
**Backlog** = not started · **In progress** = being worked on · **Done** = shipped · **Ready for development** ☑ = specced, ready for a coding agent
```

Ticket board:

```
**Backlog** = not yet fully specced · **In progress** = being worked on · **Done** = merged · **Ready for development** ☑ = full spec written, ready for a coding agent
```

## Steps

### 1. Identify the target page and board kind

- If the user gave a Notion URL or page name, `notion-fetch` it to confirm, and
  note its **page id**.
- Otherwise `notion-search` for the project name, show the best-matching page, and
  **confirm with the user** before continuing.
- Decide **milestone vs ticket** board from the table above; confirm if ambiguous.
- Derive the title: root page `Guardian` → `Guardian Milestones`; work-stream page
  `Mobile Apps` → `Mobile Apps Tasks`.
- For a milestone board, ask for the **work-stream names** that become `Layer`
  options (default to the sub-pages already listed under the root page's
  "Work-streams" heading, if there is one).

### 2. Append the heading and legend (do this BEFORE creating the database)

It must come first so the database lands after it. Use `notion-update-page` with
`command: "insert_content"` and `position: {type: "end"}` on the target page id —
`# Milestones` or `# Tasks`, then the matching legend from above.

### 3. Create the database under the target page

`notion-create-database` with `parent: {page_id: <target page id>}`, the title from
step 1, and this schema (column names double-quoted, option values single-quoted):

```sql
CREATE TABLE (
  "Name" TITLE,
  "Status" SELECT('Backlog':default, 'In progress':blue, 'Done':green),
  "Ready for development" CHECKBOX,
  "Layer" SELECT('Admin Console':brown, 'Backend':gray, 'Mobile':blue),
  "Task Type" SELECT('Feature':blue, 'Bug':red, 'Enhancement':green, 'Refactor':yellow, 'Chore':orange, 'Ops':gray, 'Research':pink, 'Design':purple, 'Marketing':brown, 'Content':default, 'Legal':gray, 'Finance':yellow)
)
```

Drop the `Layer` line entirely for a ticket board; for a milestone board replace
its options with the project's actual work-streams.

Keep the `Status` option order exactly as above — it sets the board's column order.
Save the returned **database id** and **data source id** (the `collection://…` URL).

### 4. Make the database inline

`notion-update-data-source` with the data source id and `is_inline: true`, so the
board renders on the page rather than as a sub-page link.

### 5. Create the board view

`notion-create-view` with the `database_id`, `data_source_id`, `name: "Board view"`,
`type: "board"`, and — milestone board:

```
GROUP BY "Status"
SHOW "Name", "Layer", "Task Type", "Ready for development"
```

ticket board:

```
GROUP BY "Status"
SHOW "Name", "Task Type", "Ready for development"
```

This adds `Board view` as a **second** view tab; the auto-created `Default view`
(table) stays and remains the default. There is no MCP tool to delete, reorder, or
convert it — see step 6 and the Default view note.

### 6. Verify, then offer the one manual cleanup

`notion-fetch` the **database** (and the target page) and confirm:
- page order is heading → legend paragraph → the inline database;
- a `board`-type view grouped by `Status` exists (read it from the `<views>` block);
- the `Status` select options are, in order, `Backlog`, `In progress`, `Done` — this
  option order *is* the board's left-to-right column order (board group sort is `manual`);
- `Ready for development` is a `checkbox`;
- `Task Type` has all 12 options, and `Layer` exists **only** on a milestone board.

`notion-fetch` returns each view's config and the schema's option order, so all of
the above is checkable; it does **not** render the board, so don't claim to have
"seen" the columns — confirm via the option order.

Then share the board URL and tell the user the one manual step the MCP can't do:
to make the board the only/default view, open the database in Notion and delete the
`Default view` (table) tab (or drag `Board view` to first). The reference boards
were finished this way.

## Notes

- **Default view (important — this is the one thing that isn't fully automatic).**
  `notion-create-database` always creates a `Default view` (table) as the database's
  **first** view, and Notion renders the first view by default. The board you add is
  a second tab, so the inline embed shows the *table* until someone switches or
  removes it. The MCP has **no** tool to delete, reorder, or change the type of a
  view, so this cannot be fixed programmatically. To match the reference boards
  (board only), the user must delete the `Default view` tab in Notion (open the
  database → click the `Default view` tab ▾ → Delete), or drag `Board view` to
  first. Always surface this step; do not describe the leftover table tab as harmless.
- **No deleting rows.** The MCP cannot trash a database row. To get a row off a
  board, `notion-move-pages` it to the data source where it belongs; only the user
  can delete it outright.
- **Moving a row between boards adds columns to the destination.** Any property the
  row carries that the target data source lacks is silently re-created there — a
  `Layer` from a milestone board reappears as a `Layer` column, and a same-named
  property of a different type lands as `Status 1`. Worse, a new `status`-type
  column back-fills *every existing row* with its first option. After any
  cross-board move, re-`notion-fetch` the destination schema and
  `DROP COLUMN` whatever the move invented.
- **Scope.** Do not create example/sample tickets. The board ships empty.
- **Re-runs.** This always creates a *new* data source. A project gets exactly one
  milestone board — if one may already exist, check first and confirm with the user
  before adding a second.
- **Older boards.** Boards built before this convention may still carry
  `Ready for development` as a fourth Status column. Leave them; don't migrate a
  board the user hasn't asked you to touch.
