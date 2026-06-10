# postgres-data-modeling

> Dimensional warehouse design on PostgreSQL — a star schema, range partitioning, purpose-built indexes (BRIN / partial), Alembic migrations, and pgTAP schema tests.

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-4169E1?logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-data%20modeling-336791?logo=postgresql&logoColor=white)
![Alembic](https://img.shields.io/badge/Alembic-migrations-6BA81E)
![pgTAP](https://img.shields.io/badge/pgTAP-schema%20tests-336791)
![Docker](https://img.shields.io/badge/Docker-compose-2496ED?logo=docker&logoColor=white)
![Status](https://img.shields.io/badge/status-working%20core-success)

---

## Overview / Aim

This repository is a focused study in **physical data modelling for analytics on
PostgreSQL**. It covers the decisions that determine warehouse query performance
and maintainability: a **dimensional (star) schema**, **range partitioning** of a
high-volume events table, **deliberate index choices** (BRIN for time-ordered data,
partial indexes for selective predicates), **versioned migrations** via Alembic,
and **schema assertions** via pgTAP.

## Architecture / How It Works

```
              ┌────────────────┐        ┌────────────────┐
              │  dim_customer  │        │   dim_product  │
              │  PK customer_id│        │  PK product_id │
              └───────┬────────┘        └────────┬───────┘
                      │  FK                   FK  │
                      └──────────┬───────────────┘
                                 ▼
                        ┌──────────────────┐
                        │    fact_sales    │   indexes:
                        │  customer_id FK  │   • BRIN(sold_at)
                        │  product_id  FK  │   • btree(customer_id)
                        │  quantity, amount│   • partial(amount>1000)
                        │  sold_at         │
                        └──────────────────┘

   events (PARTITION BY RANGE created_at)
   ├── events_2023_01   ├── events_2023_02   ...   (monthly partitions, JSONB payload)
```

- **Star schema** — `fact_sales` references `dim_customer` and `dim_product`,
  the classic shape for fast slice-and-dice analytics.
- **Range partitioning** — `events` is partitioned monthly on `created_at`, so
  time-bounded queries prune irrelevant partitions.
- **Index strategy** — BRIN on the naturally time-ordered `sold_at` (tiny,
  effective for append-only fact data), a B-tree on the `customer_id` join key,
  and a **partial index** that materialises only high-value (`amount > 1000`) sales.

## Tech Stack & Tools

| Tool | Role |
|------|------|
| **PostgreSQL 15** | Relational warehouse (alpine, via Docker) |
| **SQL DDL** | Star schema, partitioning, indexing |
| **BRIN / partial / B-tree indexes** | Performance tuning per access pattern |
| **Alembic** | Versioned schema migrations (SQLAlchemy engine) |
| **pgTAP** | Database-native schema/structure tests |
| **Docker Compose** | One-command local Postgres |

## Project Structure

```
postgres-data-modeling/
├── schema/
│   ├── star_schema.sql        # dim_customer, dim_product, fact_sales
│   ├── partitioned_events.sql # events PARTITION BY RANGE(created_at) + monthly parts
│   └── indexes.sql            # BRIN(sold_at), btree(customer_id), partial(amount>1000)
├── migrations/
│   └── env.py                 # Alembic online-migration runner
├── tests/
│   └── test_schema.sql        # pgTAP: has_table/has_column/col_not_null/has_index
├── docs/
│   └── query_optimisation.md  # EXPLAIN ANALYZE notes + partitioning observations
└── docker-compose.yml         # PostgreSQL 15-alpine
```

## Key Features / Highlights

- **Dimensional star schema** — clean fact/dimension separation with referential
  constraints (`REFERENCES`, `UNIQUE`, `NOT NULL`) enforcing integrity at the DB.
- **Range partitioning** — monthly `events` partitions with a `JSONB` payload
  column, enabling partition pruning and cheap retention drops.
- **Access-pattern-aware indexing** — BRIN for time-ordered fact scans, B-tree for
  joins, and a **partial index** to keep a hot high-value-sales subset small.
- **Versioned migrations** — Alembic `env.py` wires online migrations through a
  SQLAlchemy engine for repeatable, reviewable schema evolution.
- **Database-native tests** — pgTAP asserts table/column/constraint/index existence,
  so structural regressions fail loudly.
- **Documented tuning rationale** — `docs/query_optimisation.md` records
  `EXPLAIN ANALYZE` observations (seq-scan → BRIN, hash vs. nested-loop joins) and
  partition-pruning gains from the author's own analysis.

## Challenges

- **Index selection trade-offs** — choosing BRIN vs. B-tree and adding a partial
  index requires matching the index to real query predicates, not guessing.
- **Partitioning scheme** — range-by-month balances pruning benefit against
  partition-management overhead.
- **Safe schema evolution** — migrations must be ordered and reversible, which the
  Alembic setup enables.

## Future Work

- Automated partition creation (pg_partman or a scheduled DDL job).
- Concrete, numbered Alembic revision scripts under `versions/`.
- Slowly-changing-dimension (SCD Type 2) handling for `dim_customer`.
- Materialised views for common rollups + refresh scheduling.
- Seed/benchmark harness to reproduce the `EXPLAIN ANALYZE` findings on demand.

## Getting Started / Usage

```bash
# 1. Start Postgres
docker-compose up -d        # warehouse / analyst / secret on :5432

# 2. Apply schema
psql -h localhost -U analyst warehouse -f schema/star_schema.sql
psql -h localhost -U analyst warehouse -f schema/partitioned_events.sql
psql -h localhost -U analyst warehouse -f schema/indexes.sql

# 3. Run pgTAP tests (requires the pgtap extension)
psql -h localhost -U analyst warehouse -f tests/test_schema.sql

# 4. Migrations (Alembic) — once a sqlalchemy.url is configured
alembic upgrade head
```

## Conclusion

Demonstrates **physical data-modelling** depth on PostgreSQL: dimensional design,
range partitioning, index strategy grounded in query plans, migration discipline,
and database-native testing — the schema-design skills behind a performant
analytics warehouse.
