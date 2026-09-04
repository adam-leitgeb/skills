---
paths:
  - "**/*.go"
---

# Go Naming: Prefer Full Descriptive Names

Prefer full, descriptive names for variables, parameters, and struct fields — they
make the code readable without Go fluency. There is one hard rule that overrides
this: **never name a variable the same as an imported package or a built-in type.**
Doing so *shadows* that package/type, so you can no longer use it in scope — which
silently breaks the code. A short list of names must therefore stay short.

## Expand these (safe and more readable)

| Avoid | Use instead |
|-------|-------------|
| `req` | `request` |
| `resp` | `response` |
| `msg` | `message` |
| `buf` | `buffer` |
| `svc` | `service` |
| `repo` | `repository` |
| `w` | `responseWriter` (HTTP handlers) |
| `r` | `request` (HTTP handlers) |
| `c` | `ginContext` (Gin handlers) |
| `db` | `database` **or** `databaseConnection` — but *not* when a package named `database` is in scope (see shadowing rule) |
| `cfg` | `config` or `appConfig` — prefer `appConfig` when a `config` package is imported |

## Keep these short — expanding them breaks the code or fights universal idiom

| Keep | Why |
|------|-----|
| `ctx` | Naming it `context` **shadows the `context` package** — you lose `context.Background()`, `context.WithTimeout()`, etc. `ctx` is the universal Go idiom. |
| `err` | Naming it `error` **shadows the built-in `error` type**. Keep `err`, or use a *descriptive* name like `connectionError` / `fetchError` when several errors are in scope — never bare `error`. |
| `id` | A universal term, not an abbreviation. |
| Receiver names (`s`, `h`) | Go style deliberately keeps receivers to 1–2 chars (e.g. `func (s *service)`). Do **not** expand them. |

## The shadowing rule

Before expanding an abbreviation, check what's imported. If the full word matches a
package or built-in type in scope, keep the short form or qualify the name:

- `context` (package) → keep `ctx`
- `error` (built-in) → keep `err`, or `connectionError`
- `config` / `database` (if imported as packages) → use `appConfig` / `databaseConnection`

## Examples

```go
// BAD
func (h *Handler) GetAll(c *gin.Context) {
    cards, err := h.svc.GetAll(c.Request.Context())
}

// GOOD — expand svc→service and the gin param; keep the short receiver;
//        give err a descriptive name.
func (h *Handler) GetAll(ginContext *gin.Context) {
    cards, fetchError := h.service.GetAll(ginContext.Request.Context())
}
```

```go
// BAD
func (s *svc) GetByID(ctx context.Context, id string) (*Card, error) {

// GOOD — expand the receiver's TYPE (svc→service); keep ctx, id, err, and the
//        short receiver name `s`. Naming the param `context` would shadow the package.
func (s *service) GetByID(ctx context.Context, id string) (*Card, error) {
```

```go
// BAD
db, err := database.Connect(ctx, cfg.DatabaseURL)

// GOOD — expand cfg→appConfig; name the result databaseConnection so it doesn't
//        shadow the `database` package; keep ctx and err.
databaseConnection, err := database.Connect(ctx, appConfig.DatabaseURL)
```
