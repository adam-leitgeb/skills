---
name: notion-project-board
description: Use when the user wants to create a new Notion board for a project (e.g. "create a Notion board for <project>", "set up a tasks board in Notion"). Builds one of two boards - a "<project> Milestones" board on the project root page (adds a Layer select for work-streams), or a "<work-stream> Tasks" ticket board on a work-stream page - each with Status / Task Type / a "Ready for development" checkbox and a board view grouped by Status. Covers only the board itself, not individual tickets.
argument-hint: "<project name> or the Notion page URL the board belongs on"
---

# Create a Notion project board

Appends a board — heading, legend, inline database, board view — to the **end of a
Notion page** via the Notion MCP. Board only, never tickets; it ships empty. One
manual click remains at the end (see [Default view](#notes)).

## Two levels — pick the right one first

| | **Milestone board** | **Ticket board** |
|---|---|---|
| Lives on | the project **root** page | a **work-stream** page (Mobile Apps, Backend, Admin Console…) |
| Heading | `# Milestones` | `# Tasks` |
| Titled | `<project> Milestones` | `<work-stream> Tasks` |
| One row = | a whole milestone (`M4.3 — Emergency Contacts`) | one ticket, usually one PR |
| Has `Layer` | yes — the milestone's work-stream | no |
| How many | exactly **one** per project | one per active work-stream |

Rows never cross levels: tickets go on work-stream boards; the root board gets one
row per milestone, its status hand-synced from the tickets under it. Reference:
**Guardian** — root page holds `Guardian Milestones`, the `Mobile Apps` page holds
`Mobile Apps Tasks`.

## Properties

| Property | Type | Values |
|----------|------|--------|
| `Name` | title | — |
| `Status` | select | `Backlog`, `In progress`, `Done` — this order is the board's left-to-right column order |
| `Ready for development` | checkbox | checked = full spec written, ready for a coding agent |
| `Task Type` | select | the 12 options in the schema below |
| `Layer` | select | **milestone board only** — the project's work-streams |

> **Two deliberate choices — do not "fix" either.** `Status` is a `select`, not a
> `status` property: the MCP DDL cannot customize a `status` property's options
> (creation yields only `Not started` / `In progress` / `Done`, and
> `ALTER COLUMN "Status" SET STATUS(...)` is a parse error), while a `select`
> controls names, colors, and column order. `Ready for development` is a checkbox,
> not a Status column: it is an attribute of a row, not a stage of work — as a
> fourth kanban column it forced a false ordering and went stale.

## Steps

### 1. Resolve page, kind, title — one confirmation

- User gave a URL or page name → `notion-fetch` it and note the **page id**.
  Otherwise `notion-search` the project name. A ticket board's target is the
  work-stream page, not the root — descend to it if needed.
- The kind follows from the page level (root → milestone, work-stream → ticket);
  heading and title come from the table above. Don't double a suffix the page
  title already carries (`Mobile Apps Tasks` page → title stays `Mobile Apps Tasks`).
- Milestone board: `Layer` options are the project's work-stream names — default
  to the sub-pages under the root page's "Work-streams" heading, else ask.
- Check the target page doesn't already hold a board (this skill always creates a
  *new* data source, and the MCP can't delete one it shouldn't have made).
- Confirm it all with the user in **one** message: page, kind, title, and — for a
  milestone board — the `Layer` options.

### 2. Append the heading and legend

`notion-update-page` with `command: "insert_content"`, `position: {type: "end"}`,
on the target page id — before the database, so the board lands after it. Insert
exactly this markdown (heading plus one legend paragraph):

Milestone board:

```
# Milestones

One row per milestone — day-to-day tickets live on the work-stream boards. **Backlog** = not started · **In progress** = being worked on · **Done** = shipped · **Ready for development** ☑ = full spec written, ready for a coding agent
```

Ticket board:

```
# Tasks

**Backlog** = not started · **In progress** = being worked on · **Done** = merged · **Ready for development** ☑ = full spec written, ready for a coding agent
```

### 3. Create the database

`notion-create-database` with `parent: {page_id: <target page id>}`, the title from
step 1, and this schema (column names double-quoted, option values single-quoted):

```sql
CREATE TABLE (
  "Name" TITLE,
  "Status" SELECT('Backlog':default, 'In progress':blue, 'Done':green),
  "Ready for development" CHECKBOX,
  "Task Type" SELECT('Feature':blue, 'Bug':red, 'Enhancement':green, 'Refactor':yellow, 'Chore':orange, 'Ops':gray, 'Research':pink, 'Design':purple, 'Marketing':brown, 'Content':default, 'Legal':gray, 'Finance':yellow)
)
```

Milestone board: add one line before `"Task Type"`, with the real work-stream
names from step 1:

```sql
  "Layer" SELECT('Backend':gray, 'Mobile Apps':blue, ...),
```

Keep the `Status` option order exactly as above — it sets the board's column order.
Save the returned **database id** and **data source id** (the `collection://…` URL).

### 4. Make the database inline

`notion-update-data-source` with the data source id and `is_inline: true`.
Without it the database renders as a sub-page link instead of on the page.

### 5. Create the board view

`notion-create-view` with `database_id`, `data_source_id`, `name: "Board view"`,
`type: "board"`, and this `configure` DSL:

```
GROUP BY "Status"
SHOW "Name", "Task Type", "Ready for development"
```

Milestone board: insert `"Layer", ` after `"Name", ` in the `SHOW` line.

`Board view` lands as a second tab after the auto-created `Default view` — see
[Default view](#notes).

### 6. Verify, then hand off

`notion-fetch` the database and the target page, and confirm:

- heading, database title, and legend match the kind chosen in step 1;
- page order is heading → legend paragraph → the inline database;
- a `board`-type view grouped by `Status` exists (in the `<views>` block);
- `Status` options are, in order, `Backlog`, `In progress`, `Done`;
- `Ready for development` is a `checkbox`, `Task Type` matches the schema, and
  `Layer` exists **only** on a milestone board.

Fix schema mismatches with `notion-update-data-source` `statements`
(`ADD COLUMN` / `DROP COLUMN` / `ALTER COLUMN`) — never by creating a second
database. `notion-fetch` does not render the board, so don't claim to have "seen"
the columns; confirm via the option order.

Then share the board URL and tell the user the one manual step (see
[Default view](#notes)): delete the `Default view` tab, or drag `Board view` first.

## Notes

- **Default view.** `notion-create-database` always auto-creates a `Default view`
  (table) as the **first** tab, Notion renders the first tab, and the MCP cannot
  delete, reorder, or retype a view — so the inline embed shows the *table* until
  the user opens the database in Notion and deletes the `Default view` tab
  (tab ▾ → Delete) or drags `Board view` to first. Always surface this step; do
  not describe the leftover table tab as harmless.
- **Rows.** The MCP cannot trash a database row — `notion-move-pages` it to the
  data source where it belongs; only the user can delete it. A cross-board move
  silently re-creates on the destination any property it lacks (a same-named
  property of a different type lands as `Status 1`; a new `status`-type column
  back-fills every existing row) — after one, re-fetch the destination schema and
  `DROP COLUMN` the strays via `notion-update-data-source` `statements`.
- **Older boards** may carry `Ready for development` as a fourth Status column.
  Leave them; don't migrate a board the user hasn't asked you to touch.
