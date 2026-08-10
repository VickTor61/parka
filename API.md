# Parka API

JSON API for categories, plans, actuals, locks and the report.

- **Base path:** `/api/v1`
- **Auth:** bearer token
- **Format:** JSON request and response bodies

| Environment | Base URL |
| --- | --- |
| Production | `https://parka-jrl3.onrender.com/api/v1` |
| Local | `http://localhost:3000/api/v1` |

Examples below use the local host; swap the origin for production.

---

## Table of contents

1. [Authentication](#authentication)
2. [Conventions](#conventions)
3. [Errors](#errors)
4. [Pagination](#pagination)
5. [Filtering and search](#filtering-and-search)
6. [Categories](#categories)
7. [Plans](#plans)
8. [Actuals](#actuals)
9. [CSV import](#csv-import)
10. [Locks](#locks)
11. [Report](#report)

---

## Authentication

1. Sign in to the app.
2. Go to **Settings → New token**.
3. Copy the token — it is shown **once** and cannot be recovered.

Send it on every request:

```bash
curl -H "Authorization: Bearer sk_test_YOUR_TOKEN" http://localhost:3000/api/v1/plans
```

Notes:

- Tokens are prefixed `sk_test_` outside production and `sk_live_` in production.
- Only a SHA-256 digest is stored. Lose the token and you rotate it.
- **Rotate** issues a new value and invalidates the old one immediately.
- **Deactivate** blocks the token without deleting it; reactivate at any time.
- A token carries the same access as its owner's account. There are no scopes and no expiry.
- Missing, unknown, deactivated or rotated tokens all return `401`.

---

## Conventions

| | |
| --- | --- |
| Single resource | `{ "data": { ... } }` |
| Collection | `{ "data": [ ... ], "meta": { ... } }` |
| Failure | `{ "errors": ["message", ...] }` |

- Money is returned as a **string** (`"5000.0"`) to avoid float rounding.
- Months are `YYYY-MM` strings, both in and out.
- Timestamps are ISO 8601 UTC.
- `null` means genuinely absent — see [Report](#report).

Status codes:

| Code | Meaning |
| --- | --- |
| `200` | OK |
| `201` | Created |
| `204` | Deleted, no body |
| `400` | Missing parameter section |
| `401` | Missing or invalid token |
| `404` | Not found, or not yours |
| `409` | Delete blocked by a dependency |
| `422` | Validation or lock rejection |

---

## Errors

```json
{ "errors": ["2026-01 is locked. Unlock the period before making changes."] }
```

Common cases:

- **Locked period** — `422`. Applies to create, update and delete on plans and actuals, including moving a record into or out of a locked month.
- **Validation** — `422`, one string per message.
- **Another user's record** — `404`, never `403`, so the API does not confirm the record exists.
- **Category still referenced** — `409` on delete.

---

## Pagination

Pagination is **opt-in**.

- Omit `page` and `limit` → the full collection, with `meta.paginated: false`.
- Pass either → a paginated page.

| Param | Default | Notes |
| --- | --- | --- |
| `page` | `1` | Out of range returns `404` |
| `limit` | `25` | Clamped to `1..100` |

Unpaginated:

```json
{ "meta": { "paginated": false, "count": 17 } }
```

Paginated:

```json
{
  "meta": {
    "paginated": true,
    "page": 2,
    "limit": 3,
    "count": 17,
    "pages": 6,
    "next_page": 3,
    "prev_page": 1
  }
}
```

---

## Filtering and search

Index endpoints accept the same Ransack predicates as the web tables, under `q`.

```bash
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:3000/api/v1/plans?q[category_name_cont]=marketing&q[month_gteq]=2026-01-01"
```

| Resource | Filterable |
| --- | --- |
| Categories | `name`, `created_at` |
| Plans | `month`, `amount`, `category_id`, `category_name` |
| Actuals | `month`, `amount`, `note`, `category_id`, `category_name` |
| Locks | `month`, `month_text` |

Predicates: `_eq`, `_cont`, `_gteq`, `_lteq`, `_in`. Anything outside the allowlist is ignored, not an error.

---

## Categories

| Method | Path |
| --- | --- |
| `GET` | `/api/v1/categories` |
| `POST` | `/api/v1/categories` |
| `GET` | `/api/v1/categories/:id` |
| `PATCH` | `/api/v1/categories/:id` |
| `DELETE` | `/api/v1/categories/:id` |

```json
{
  "data": {
    "id": 3,
    "name": "Marketing",
    "created_at": "2026-08-09T13:36:25.823Z",
    "updated_at": "2026-08-09T13:36:25.823Z"
  }
}
```

Create:

```bash
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"category":{"name":"Tools"}}' http://localhost:3000/api/v1/categories
```

- `name` is required and unique per user, case-insensitively.
- `DELETE` returns `409` while plans or actuals reference the category.

---

## Plans

| Method | Path |
| --- | --- |
| `GET` | `/api/v1/plans` |
| `POST` | `/api/v1/plans` |
| `GET` | `/api/v1/plans/:id` |
| `PATCH` | `/api/v1/plans/:id` |
| `DELETE` | `/api/v1/plans/:id` |

```json
{
  "data": {
    "id": 6,
    "month": "2026-01",
    "amount": "5000.0",
    "locked": false,
    "category": { "id": 3, "name": "Marketing" },
    "created_at": "2026-08-09T10:54:15.535Z",
    "updated_at": "2026-08-09T10:54:15.535Z"
  }
}
```

Create:

```bash
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"plan":{"category_id":3,"month":"2026-01","amount":"5000"}}' \
  http://localhost:3000/api/v1/plans
```

| Field | Rules |
| --- | --- |
| `category_id` | Required, must be yours |
| `month` | Required, `YYYY-MM` |
| `amount` | Required, `>= 0` (zero is allowed) |

- One plan per category per month; a duplicate returns `422`.
- Writes to a locked month return `422`.

---

## Actuals

| Method | Path |
| --- | --- |
| `GET` | `/api/v1/actuals` |
| `POST` | `/api/v1/actuals` |
| `GET` | `/api/v1/actuals/:id` |
| `PATCH` | `/api/v1/actuals/:id` |
| `DELETE` | `/api/v1/actuals/:id` |

```json
{
  "data": {
    "id": 12,
    "month": "2026-01",
    "amount": "4800.0",
    "note": "Q1 ad campaign",
    "locked": false,
    "category": { "id": 3, "name": "Marketing" },
    "created_at": "2026-08-09T10:54:15.535Z",
    "updated_at": "2026-08-09T10:54:15.535Z"
  }
}
```

| Field | Rules |
| --- | --- |
| `category_id` | Required, must be yours |
| `month` | Required, `YYYY-MM` |
| `amount` | Required, `>= 0` |
| `note` | Optional, max 500 characters |

- Several actuals may share a category and month; the report sums them.

---

## CSV import

| Method | Path |
| --- | --- |
| `POST` | `/api/v1/actuals/import` |

Multipart upload:

```bash
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -F "actuals_import[file]=@actuals.csv" \
  http://localhost:3000/api/v1/actuals/import
```

Format — `note` is optional:

```csv
month,category,amount,note
2026-01,Marketing,4800,Q1 ad campaign
2026-01,Payroll,20500,
```

Success — `201`:

```json
{ "data": { "imported_count": 3 } }
```

Failure — `422`, with the offending row numbers:

```json
{ "errors": ["Row 3: category \"Nonexistent\" does not exist."] }
```

Rules:

- **All or nothing** — one bad row rolls back the whole file.
- Categories must already exist; matching is case-insensitive.
- Amounts accept `$` and thousands separators.
- Limits: 2 MB, 5,000 rows.
- Rows landing in a locked month are rejected.

---

## Locks

| Method | Path |
| --- | --- |
| `GET` | `/api/v1/locks` |
| `POST` | `/api/v1/locks` |
| `GET` | `/api/v1/locks/:id` |
| `DELETE` | `/api/v1/locks/:id` |

```json
{ "data": { "id": 4, "month": "2026-01", "created_at": "2026-08-09T10:54:15.535Z" } }
```

Lock a month:

```bash
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"period_lock":{"month":"2026-01"}}' http://localhost:3000/api/v1/locks
```

- `DELETE` unlocks the month.
- Locking granularity is one month.
- Locking an already-locked month returns `422`.

---

## Report

| Method | Path |
| --- | --- |
| `GET` | `/api/v1/report` |

Rows are one per category × month, drawn from plans **and** actuals — so spend with no target still appears, with a plan of `0`.

| Param | Notes |
| --- | --- |
| `from`, `to` | `YYYY-MM`, inclusive. Either may be omitted |
| `fiscal_year` | e.g. `2026`. Overrides `from`/`to` |
| `fiscal_start_month` | `1`–`12`, default `1` (calendar year) |
| `category_id` | Restrict to one category |
| `query` | Match category name |
| `page`, `limit` | As above |

```bash
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:3000/api/v1/report?from=2026-01&to=2026-03&limit=25"
```

```json
{
  "data": [
    {
      "category": { "id": 3, "name": "Marketing" },
      "month": "2026-01",
      "plan": "5000.0",
      "actual": "4800.0",
      "variance": "-200.0",
      "variance_percentage": "-4.0",
      "reported": true,
      "entries_count": 1,
      "locked": false
    },
    {
      "category": { "id": 3, "name": "Marketing" },
      "month": "2026-02",
      "plan": "5000.0",
      "actual": null,
      "variance": null,
      "variance_percentage": null,
      "reported": false,
      "entries_count": 0,
      "locked": false
    }
  ],
  "meta": {
    "paginated": false,
    "count": 4,
    "range": { "from": "2026-01", "to": "2026-03", "label": "Jan 2026 – Mar 2026" },
    "totals": {
      "plan": "50000.0",
      "actual": "45100.0",
      "variance": "-4900.0",
      "variance_percentage": "-9.8",
      "entries_count": 3
    }
  }
}
```

Reading the fields:

- `reported: false` means **no entries logged** — `actual`, `variance` and `variance_percentage` are all `null`. It is not the same as spending zero.
- `variance_percentage` is `null` whenever `plan` is `0`, since the percentage is undefined.
- `variance` is `actual − plan`; negative is under plan.
- `totals` and `range` cover the **whole filtered set**, not just the current page.
- With no range, `label` is `"All time"` and `from`/`to` are `null`.
