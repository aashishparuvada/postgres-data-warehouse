# PostgreSQL data warehouse (Medallion)

Personal learning project: a small **analytics data warehouse** on **PostgreSQL** using the **Medallion architecture** (Bronze → Silver → Gold). Source data is staged as CSVs (CRM + ERP–style feeds); Bronze ingests raw copies, Silver applies cleansing and conformed types, and Gold exposes a **star schema** for reporting (dimensions + fact as views).

## Architecture

| Layer | Schema | Role |
|--------|--------|------|
| **Bronze** | `bronze` | Land source-aligned tables; bulk load from CSV with minimal transformation. |
| **Silver** | `silver` | Cleaned, standardized, typed data; warehouse audit column `dwh_create_date` where defined. |
| **Gold** | `gold` | Analytics-facing **star schema**: `dim_customers`, `dim_products`, and `fact_sales` implemented as `VIEW`s over Silver, with surrogate keys via `DENSE_RANK()`. |

Data flows: CSV files → `bronze.load_bronze()` → `silver.load_silver()` → Gold views (no separate load procedure; they read Silver in real time).

## Tech stack

- **PostgreSQL 16** (via Docker Compose)
- **PL/pgSQL** stored procedures for Bronze/Silver loads
- **SQL** DDL, views, and ad hoc quality-check queries

## Repository layout

```
scripts/
  init_database.sql      # Creates DB `datawarehouse` + schemas bronze, silver, gold (destructive reset)
  bronze/
    ddl_bronze.sql       # Bronze table definitions
    proc_load_bronze.sql # COPY from /datasets/... into Bronze
  silver/
    ddl_silver.sql       # Silver table definitions
    proc_load_silver.sql # Bronze → Silver transformations
  gold/
    ddl_gold.sql         # Gold views + helpful indexes on Silver for joins
datasets/
  source_crm/            # CRM sample CSVs
  source_erp/            # ERP sample CSVs
tests/
  quality_checks_silver.sql
  quality_checks_gold.sql
docker-compose.yaml      # Postgres service + volume mounts
.env.example             # Template for local paths and DB settings
```

## Prerequisites

- Docker and Docker Compose
- `psql` (or any PostgreSQL client) to run SQL scripts and call procedures

## Quick start

### 1. Configure environment

Copy `.env.example` to `.env` and set:

- **`POSTGRES_DATA_PATH`** — host directory for Postgres data files  
- **`DATASETS_PATH`** — host directory that contains a `datasets` folder **or** point it at this repo’s `datasets` directory so files appear under `/datasets` in the container (see Compose volume mapping)

Adjust **`POSTGRES_USER`**, **`POSTGRES_PASSWORD`**, **`POSTGRES_DB`**, and **`POSTGRES_PORT`** as needed.

> **Note:** `scripts/init_database.sql` creates a database named **`datawarehouse`** (and drops it if it already exists). The default `.env.example` uses `POSTGRES_DB=warehouse`. After init, connect to **`datawarehouse`** for medallion objects, or align your `.env` / init script so the target database name matches how you run DDL and loads.

### 2. Start PostgreSQL

```bash
docker compose up -d
```

Wait until the healthcheck reports the server is ready.

### 3. Initialize database and schemas

From the host (example — adjust user/host/port if needed):

```bash
psql -h localhost -U postgres -f scripts/init_database.sql
```

Then, connected to **`datawarehouse`**, run DDL in order:

```bash
psql -h localhost -U postgres -d datawarehouse -f scripts/bronze/ddl_bronze.sql
psql -h localhost -U postgres -d datawarehouse -f scripts/silver/ddl_silver.sql
psql -h localhost -U postgres -d datawarehouse -f scripts/gold/ddl_gold.sql
```

Create the load procedures:

```bash
psql -h localhost -U postgres -d datawarehouse -f scripts/bronze/proc_load_bronze.sql
psql -h localhost -U postgres -d datawarehouse -f scripts/silver/proc_load_silver.sql
```

### 4. Run the pipeline

In `psql` against `datawarehouse`:

```sql
CALL bronze.load_bronze();
CALL silver.load_silver();
```

Query the Gold layer, for example:

```sql
SELECT * FROM gold.dim_customers LIMIT 10;
SELECT * FROM gold.fact_sales LIMIT 10;
```

## Sample data and COPY paths

- Bronze load uses **`COPY ... FROM '/datasets/...'`** inside the container. `docker-compose.yaml` mounts **`DATASETS_PATH`** at **`/datasets`**, so paths must match your mount layout.
- The load procedure expects CRM files such as `cust_info.csv`, `prd_info.csv`, and **`sales_details.csv`** under `source_crm/`. This repository currently includes a subset of those files; add **`sales_details.csv`** (and any missing files) if you want the full Bronze load to succeed.
- ERP `COPY` paths use **lowercase** filenames (e.g. `loc_a101.csv`). The tracked sample files use **uppercase** names (e.g. `LOC_A101.csv`). On Linux-based containers, paths are **case-sensitive** — rename files, adjust the procedure, or use symlinks so container paths match the `COPY` statements.

## Data quality checks

Ad hoc validations live under `tests/`:

- **`quality_checks_silver.sql`** — Silver-layer checks (duplicates, trimming, standardization, dates, consistency).
- **`quality_checks_gold.sql`** — Gold-layer checks (surrogate key uniqueness, fact-to-dimension referential sanity).

Run them in `psql` after loads; many queries expect **empty** result sets when checks pass.

## Gold model (summary)

- **`gold.dim_customers`** — CRM customer attributes enriched with ERP gender, birthdate, and country (joins on customer keys / ids).
- **`gold.dim_products`** — Products with category attributes from ERP category reference; current rows only (`prd_end_dt IS NULL` in Silver logic).
- **`gold.fact_sales`** — Order lines with `product_key` and `customer_key` resolved to the dimension views.

## License

See [LICENSE](LICENSE) in the repository root.
