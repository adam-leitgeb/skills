---
name: tailwind-plus-ui
description: Use when editing admin console UI (Go html/template + HTMX under internal/admin/) or pasting Tailwind Plus HTML blocks. Enforces using blocks verbatim, @tailwindplus/elements for animated drawers/dropdowns/dialogs/popovers, no other component libraries.
paths:
  - "internal/admin/**/*"
  - "reference/**/*.html"
user-invocable: false
---

## UI approach (admin console)

I paid for **Tailwind Plus** specifically to avoid making visual decisions
from scratch — I want worry-free, smooth, consistent UI. Treat the Tailwind
Plus HTML blocks as the **design system of record**:

- When I reference a Tailwind Plus block (by name, screenshot, or pasted
  HTML), **use it as-is**: keep the markup structure, class names, wrapper
  elements, and SVGs verbatim. Don't substitute "equivalent" markup, rename
  classes, or trim things you think are redundant.
- Only change the **content** of a block to fit our data — text, Go
  html/template loops/conditionals, HTMX attributes. Structural or visual
  changes only when I explicitly ask.
- **Don't mix in other component libraries.** No DaisyUI, Preline, FlyonUI,
  Headless UI ports, Alpine. Pure Tailwind + Tailwind Plus only.

### Interactivity — use `@tailwindplus/elements`

Tailwind Plus blocks ship with nice animations (drawers sliding in,
dropdowns expanding, dialogs fading). Those animations are driven by
`data-*` state attributes that `@tailwindplus/elements` web components
(`<el-dialog>`, `<el-dropdown>`, `<el-popover>`, `<el-disclosure>`, …)
toggle. **Vendor that library and use those elements verbatim.**

- **Don't hand-roll** interactivity with native `<dialog>` / `<details>` /
  inline JS to "avoid the dependency" — that ships the block without
  animations and taxes every future block paste.
- **HTMX is for server interactions** (fragment swaps, form submits, partial
  updates). It coexists cleanly with `@tailwindplus/elements`: the elements
  handle client-side open/close/transition state, HTMX handles "go ask the
  server."

### The bottom line

I'm a mobile developer, not a web/backend developer. I bought Tailwind Plus
so I don't have to argue about whether `data-closed:translate-x-full`
belongs on a drawer. Default to pasting blocks faithfully — animations,
classes, structure, and all.