# Parka

Set monthly spending targets per category, log what you actually spent, and compare the two with variance — including locked periods that become read-only.

**Live URL:** https://parka-jrl3.onrender.com

> **Deployment note:** The live demo is hosted on Render, so the application may take a moment to respond after periods of inactivity. For a faster and more consistent experience, run the application locally with Docker.

---

## Table of contents

1. [Stack](#stack)
2. [Prerequisites](#prerequisites)
3. [Running the app](#running-the-app)
4. [Tests and checks](#tests-and-checks)
5. [Features](#features)
6. [Product decisions](#product-decisions)
7. [Walkthrough video](#walkthrough-video)
8. [Data model](#data-model)
9. [Performance at scale](#performance-at-scale)
10. [Assumptions and tradeoffs](#assumptions-and-tradeoffs)
11. [What I would improve before production](#what-i-would-improve-before-production)
12. [Deployment](#deployment)
13. [API](#api)

---

## Stack

| Layer               | Choice                                      |
| ------------------- | ------------------------------------------- |
| Language            | Ruby 3.4.8                                  |
| Framework           | Rails 8.1                                   |
| Database            | PostgreSQL                                  |
| Frontend            | Hotwire (Turbo + Stimulus), Tailwind CSS v4 |
| Assets              | Propshaft + importmap (no Node build step)  |
| Search / pagination | Ransack, Pagy                               |
| Serialization       | Blueprinter                                 |
| Charts              | Chartkick + Chart.js                        |

---

## Prerequisites

Choose one supported review path:

- **Local Rails path:** Ruby 3.4.8, Bundler, and PostgreSQL 16+.
- **Docker Compose path:** Docker Desktop (or Docker Engine with Compose) and `config/master.key`.

---

## Option A: run locally

```bash
bin/setup --skip-server
bin/rails db:seed
bin/dev
```

Open `http://localhost:3000`. `bin/setup` installs dependencies and prepares the local `parka_development` database; it also starts the server when `--skip-server` is omitted. If PostgreSQL is not using the local socket, set `DATABASE_URL` before setup.

## Option B: run with Docker Compose

```bash
RAILS_MASTER_KEY=$(cat config/master.key) docker compose -f docker-compose.smoke.yml up --build
```

Open `http://localhost:3001`. This starts the production image with PostgreSQL and Redis, so local Ruby and PostgreSQL are not required. The Compose path is separate from Rails development and does not use `bin/dev`.

Stop it with `Ctrl-C`. To remove its containers later:

```bash
docker compose -f docker-compose.smoke.yml down
```

---

## Demo data and review flow

Run `bin/rails db:seed` locally. In Docker, run:

```bash
docker compose -f docker-compose.smoke.yml exec web bin/rails db:seed
```

The seed is idempotent and creates a demo account with the assignment sample data:

**Demo data** — `bin/rails db:seed` creates a demo account with the sample data from the assignment brief (Marketing and Payroll plans and actuals for early 2026):

- Email: `demo@example.com` / Password: `password123`
- The report for 2026 reproduces the sample variance table; Marketing Feb is intentionally unreported and renders as `—`.
- Safe to run repeatedly; existing demo records are not duplicated.

Review flow:

1. Sign in with the demo account.
2. Open **Report**, select FY 2026, and confirm the four sample rows and variances.
3. Use **Plans** and **Actuals** to test filters and locked-month read-only behavior.
4. Use **Actuals → Import CSV** to test validation and import behavior.
5. Use **Locks** to lock a month, then confirm both the UI and API reject writes.

To use an empty account instead, visit `/registration/new`, create an account, add categories, then add plans and actuals.

---

## Running the app

```bash
bin/dev
```

- App: `http://localhost:3000`
- Runs the Rails server and the Tailwind watcher (`Procfile.dev`)
- Development mail opens in the browser via `letter_opener` — nothing is sent

---

## Tests and checks

```bash
bin/rails test
```

Coverage focuses on what the assignment weights: aggregation and variance maths, lock enforcement on every write path, CSV import validation, and per-user isolation.

Other checks:

```bash
bin/rubocop
```

---

## Features

- **Authentication** — email + password, sign-up and sign-in. Every record is scoped to its owner.
- **Categories** — full CRUD. Deletion is blocked while plans or actuals reference the category.
- **Plans** — one monthly target per category per month.
- **Actuals** — logged spend as individual line items, so a category and month can hold several entries.
- **CSV import** — with a downloadable template, per-row error reporting, and all-or-nothing behaviour.
- **Report** — plan vs actual by category and month, with variance, variance %, a category chart, CSV export, and drill-down into the entries behind any figure.
- **Locking** — lock a month to freeze its plans and actuals.
- **API** — see [API.md](API.md).

---

## Product decisions

### Variance

- `Variance = Actual − Plan`. Negative means under plan and renders green; positive means overspend and renders red.
- `Variance % = (Actual − Plan) / Plan × 100`.

### Variance % when plan is zero

- Renders as `—`, never `NaN`, `Infinity`, or a crash.
- Applies whether the plan is explicitly `0` or no plan row exists at all.
- CSV export leaves the cell empty.

### Missing actuals

- A category and month with **no logged entries** shows `—` for Actual, Variance and Variance %.
- Chosen so an unreported month is visibly different from a genuine `$0`.
- An entry of exactly `$0.00` is treated as reported: it shows `$0.00` and produces a real variance.
- Totals and the chart sum only what is logged, so an unreported month contributes nothing rather than counting as zero spend.

### Locking

- **Granularity: one month.** It matches the grain of a plan, so a lock joins directly against `plans.month` and `actuals.month`.
- A locked month rejects **create, update and delete** for both plans and actuals.
- Moving a record **into or out of** a locked month is rejected — the check reads both the new and previous month.
- Enforced in the model layer, so the rule holds through the UI, the CSV import and the API alike. The API returns `422` with the message; the UI hides the controls _and_ the server still refuses.
- Locking and unlocking is reversible at any time.

### Currency

- Single currency, USD. No currency column and no FX handling.
- Amounts are `decimal(12,2)` — never floats.
- Amounts must be zero or greater, for both plans and actuals.

### Report range

- Defaults to the **current calendar year** (applied as a fiscal year with a January start).
- Narrow it with from/to months, quarter presets, a full year, or a fiscal year.
- **An explicit month range overrides the fiscal-year default.** Fiscal years apply only when no range is given. The fiscal-year chip's X removes the fiscal year and falls back to the default (current year).
- The **All time** shortcut clears the fiscal year entirely.
- Fiscal year takes a start month; January is the calendar year and is the default.
- Ranges are inclusive at both ends, and a reversed range is swapped rather than returning nothing.

---

## Walkthrough video

The submission includes a 5–10 minute walkthrough covering:

1. Sign-up/sign-in and per-user data isolation.
2. The seeded FY 2026 report and variance calculations.
3. Plans and Actuals filters, CSV import, and missing-actual behavior.
4. Month locking and the server-side rejection of writes to locked periods.
5. The local Docker Compose review path.
[Watch the Parka walkthrough on Loom](https://www.loom.com/share/c3e530e10b9f434f8dcf88c1cafa7e07)

---

## Data model

```text
users ─┬─< categories ─┬─< plans      (one per category per month)
       │               └─< actuals    (line items, many per month)
       ├─< period_locks               (one row per locked month)
       └─< api_tokens
```

Key points:

- `month` is a `date` pinned to the first of the month, with a `CHECK` constraint enforcing it. `YYYY-MM` is the wire format, parsed at the edge.
- Storing a date rather than a string keeps range filtering and sorting as plain indexed comparisons.
- Cross-user rows are **unrepresentable**: `plans` and `actuals` carry a composite foreign key on `(category_id, user_id)` referencing `categories (id, user_id)`. A row pairing one user's category with another user's account cannot be inserted, even with validations skipped.
- API tokens are stored as SHA-256 digests, never plaintext.

---

## Performance at scale

Current indexes:

| Table          | Index                                  | Serves                                    |
| -------------- | -------------------------------------- | ----------------------------------------- |
| `categories`   | `(user_id, lower(name))` unique        | name lookups, case-insensitive uniqueness |
| `categories`   | `(id, user_id)` unique                 | composite FK target                       |
| `plans`        | `(user_id, category_id, month)` unique | one target per category per month         |
| `plans`        | `(user_id, month)`                     | report range scans                        |
| `actuals`      | `(user_id, category_id, month)`        | report grouping                           |
| `actuals`      | `(user_id, month)`                     | report range scans                        |
| `period_locks` | `(user_id, month)` unique              | lock lookups                              |
| `api_tokens`   | `token_digest` unique                  | per-request auth                          |

What I would do as data grows:

1. **The report is the hot path.** It unions plans and actuals, groups by category × month, and paginates in SQL — `LIMIT`/`OFFSET` rather than loading rows into Ruby. `(user_id, month)` on both tables already covers the range filter.
2. **Totals and the chart each run their own aggregate** over the full filtered set, so a wide range costs three scans. At volume I would fold them into one query with window functions, or cache them keyed on the filter.
3. **Deep pagination** degrades with `OFFSET`. Keyset pagination on `(month, category_name)` would fix it if anyone pages that far.
4. **Materialise the aggregate** if reports outgrow live queries — a summary table or materialised view refreshed on write, since actuals are append-heavy and reads dominate.
5. **Lock lookups** load a user's locked months once per request and reuse the set, rather than querying per row.

---

## Assumptions and tradeoffs

1. **Actuals are line items, not one row per category and month.** Costs a `SUM` on read; buys drill-down and an honest distinction between "nothing reported" and "reported zero".
2. **Unplanned spend appears in the report** with a plan of `0`, so spend in a category with no target is never silently hidden.
3. **The report is built from SQL, not an ActiveRecord model.** Its rows come from a union of two tables, which no single model exposes. Filters are still built by ActiveRecord and escaped — only the union, grouping and ordering are hand-written. Chosen to keep filtering and pagination in the database without adding a view.
4. **A single currency**, as above.
5. **API tokens carry full account access** — no scopes, no expiry.
6. **Categories are user-owned with full CRUD**, rather than a fixed seed list.
7. **Deleting a category is blocked** while it is referenced, rather than cascading, so history cannot be destroyed by accident.

---

## What I would improve before production

1. **Deploy it** and wire up CI.
2. **Rate limiting on the API** — the sign-in and password endpoints are limited; the API is not.
3. **Background the CSV import** for large files, with a job and progress, instead of an inline request.
4. **Audit trail** for locking and unlocking, so a period's history is answerable.
5. **Soft-delete or archive for categories**, so a category can be retired without blocking on its history.
6. **Scoped, expiring API tokens** with read-only and read-write scopes, plus a per-token last-used audit.

---

## Deployment

The submitted application is deployed on Render: **https://parka-jrl3.onrender.com**

- Health check: `/up`
- Signed-out visits redirect to `/session/new`

Required environment variables:

| Variable           | Purpose                               |
| ------------------ | ------------------------------------- |
| `DATABASE_URL`     | PostgreSQL connection                 |
| `RAILS_MASTER_KEY` | Decrypts `config/credentials.yml.enc` |
| SMTP credentials   | `letter_opener` is development-only   |

Also in the repo:

- `Dockerfile` — production image
- `config/deploy.yml` — Kamal config, unused while Render is the host
- `docker-compose.smoke.yml` — smoke-test the production image locally:

```bash
RAILS_MASTER_KEY=$(cat config/master.key) docker compose -f docker-compose.smoke.yml up --build
```

---

## API

Full reference: **[API.md](API.md)**

- Base path `/api/v1`
- Bearer-token auth, managed under **Settings** in the app
- Opt-in pagination, and the same filters as the web tables

```bash
curl -H "Authorization: Bearer sk_live_YOUR_TOKEN" https://parka-jrl3.onrender.com/api/v1/plans
```
