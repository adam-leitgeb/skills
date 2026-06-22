---
name: notion-project-board
description: Use when the user wants to create a new Notion task board for a project (e.g. "create a Notion board for <project>", "set up a tasks board in Notion"). Creates a "<project> Tasks" database with Name / Status / Task Type and a board view grouped by Status, appended under a "# Tasks" section at the end of the project's Notion root page. Covers only the board itself, not individual tickets.
argument-hint: "<project name> or the project's Notion root page URL"
---

# Create a Notion project task board

Create a fresh task board at the **end of a project's Notion root page**, via the
Notion MCP, with no manual setup. This skill builds **only the board** (database +
view + the heading and legend above it) — never any tickets.

Every board is its own new data source titled **`<project name> Tasks`**.

## What the final result looks like

Appended to the end of the project's root page, in this order:

```
# Tasks
Backlog = not yet fully specced · Ready for development = full spec written, ready for a coding agent · In progress = being worked on · Done = merged
[ <project name> Tasks  — inline board database ]
```

The database has exactly these properties:

| Property | Type | Values |
|----------|------|--------|
| `Name` | title | — |
| `Status` | select | `Backlog`, `Ready for development`, `In progress`, `Done` (in this order) |
| `Task Type` | select | `Feature`, `Bug`, `Enhancement`, `Refactor`, `Chore`, `Ops`, `Research`, `Design`, `Marketing`, `Content`, `Legal`, `Finance` |

And one **board view** named `Board view`, grouped by `Status`, showing `Name` and `Task Type` on cards.

> **Why `Status` is a `select`, not a `status` property.** A Notion `status`-type
> property's options/groups **cannot** be customized through the MCP DDL (only the
> default `Not started` / `In progress` / `Done` are created, and there is no
> option syntax to change them). A `select` gives full control over the option
> names, colors, and left-to-right column order, and a board view groups by it
> identically. Do **not** "fix" this to a `status` type — it will break the four
> required columns.

## Steps

### 1. Identify the project's root page

- If the user gave a Notion URL or page name, `notion-fetch` it to confirm it's the
  intended root page, and note its **page id**.
- Otherwise `notion-search` for the project name, show the best-matching page, and
  **confirm with the user** before continuing.
- Derive the **project name** (default to the root page's title, e.g. page
  `Guardian` → project name `Guardian`). Confirm if ambiguous. The data source
  title is then `<project name> Tasks` (e.g. `Guardian Tasks`).

### 2. Append the heading and legend (do this BEFORE creating the database)

It must come first so the database lands after it. Use `notion-update-page` with
`command: "insert_content"` and `position: {type: "end"}` on the root page id:

```
# Tasks

Backlog = not yet fully specced · Ready for development = full spec written, ready for a coding agent · In progress = being worked on · Done = merged
```

### 3. Create the database under the root page

`notion-create-database` with `parent: {page_id: <root page id>}`,
`title: "<project name> Tasks"`, and this schema (column names double-quoted,
option values single-quoted):

```sql
CREATE TABLE (
  "Name" TITLE,
  "Status" SELECT('Backlog':default, 'Ready for development':gray, 'In progress':blue, 'Done':green),
  "Task Type" SELECT('Feature':blue, 'Bug':red, 'Enhancement':green, 'Refactor':yellow, 'Chore':orange, 'Ops':gray, 'Research':pink, 'Design':purple, 'Marketing':brown, 'Content':default, 'Legal':gray, 'Finance':yellow)
)
```

Keep the `Status` option order exactly as above — it sets the board's column order.
Save the returned **database id** and **data source id** (the `collection://…` URL).

### 4. Make the database inline

`notion-update-data-source` with the data source id and `is_inline: true`, so the
board renders on the page (like the reference board) rather than as a sub-page link.

### 5. Create the board view

`notion-create-view` with the `database_id`, `data_source_id`, `name: "Board view"`,
`type: "board"`, and:

```
GROUP BY "Status"
SHOW "Name", "Task Type"
```

### 6. Verify

`notion-fetch` the root page and confirm the order is: `# Tasks` heading → legend
paragraph → the inline `<project name> Tasks` board, that the four `Status` columns
read left-to-right `Backlog → Ready for development → In progress → Done`, and that
`Task Type` has all 12 options. Share the board URL with the user.

## Notes

- **Default view.** `notion-create-database` always creates a default table view, so
  the board ends up with a `Board view` tab plus that default tab. The MCP has no
  delete-view tool — leave it (it's harmless) or tell the user they can remove the
  default tab manually if they want the board as the sole view.
- **Scope.** Do not create example/sample tickets. The board ships empty.
- **Re-runs.** This always creates a *new* data source. If a `<project name> Tasks`
  board may already exist, check first and confirm with the user before adding a
  second one.
