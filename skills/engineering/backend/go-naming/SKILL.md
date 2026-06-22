---
name: go-naming
description: Go naming conventions — always use full descriptive names, no abbreviations. Use when writing or editing Go code.
paths:
  - "**/*.go"
user-invocable: false
---

# Go Naming: No Abbreviations

Always use full, descriptive names for variables, parameters, and receivers. Never use common Go shorthand abbreviations.

## Common replacements

| Avoid | Use instead |
|-------|-------------|
| `ctx` | `context` |
| `err` | `error` (or a descriptive name like `connectionError`) |
| `db` | `database` |
| `cfg` | `config` |
| `req` | `request` |
| `resp` | `response` |
| `msg` | `message` |
| `buf` | `buffer` |
| `w` | `writer` (or `responseWriter` in HTTP handlers) |
| `r` | `request` (in HTTP handlers) |
| `c` | `ginContext` (in Gin handlers) |
| `svc` | `service` |
| `repo` | `repository` |
| `id` | `id` is fine — it's a universal term, not an abbreviation |

## Examples

```go
// BAD
func (h *Handler) GetAll(c *gin.Context) {
    cards, err := h.svc.GetAll(c.Request.Context())
}

// GOOD
func (h *Handler) GetAll(ginContext *gin.Context) {
    cards, fetchError := h.service.GetAll(ginContext.Request.Context())
}
```

```go
// BAD
func (s *service) GetByID(ctx context.Context, id string) (*Card, error) {

// GOOD
func (s *service) GetByID(context context.Context, id string) (*Card, error) {
```

```go
// BAD
db, err := database.Connect(ctx, cfg.DatabaseURL)

// GOOD
database, connectionError := database.Connect(context, config.DatabaseURL)
```
