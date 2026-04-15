# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

dbt (Data Build Tool) project for transforming Airbnb data in Snowflake. Based on the Udemy dbt bootcamp course. The main dbt project lives in `airbnb/`.

## Key Commands

All dbt commands must be run from the `airbnb/` directory:

```bash
cd airbnb

# Run all models
dbt run

# Run a specific model
dbt run --select my_first_dbt_model

# Run tests
dbt test

# Test a specific model
dbt test --select my_first_dbt_model

# Generate and serve docs
dbt docs generate
dbt docs serve

# Load seed data
dbt seed

# Take snapshots (SCD Type 2)
dbt snapshot

# Clean compiled artifacts
dbt clean

# Check connection
dbt debug
```

Python dependencies are managed with UV (`uv sync` from the repo root).

## Architecture

- **Data Warehouse**: Snowflake (`AIRBNB` database)
- **Schemas**: `RAW` (source data from S3), `DEV` (transformed models)
- **Authentication**: RSA key-pair auth via `dbt` service user with `TRANSFORM` role
- **Connection config**: `profiles.yml` at repo root (requires `DBT_PRIVATE_KEY_PASSPHRASE` env var)
- **Orchestration**: Dagster integration available (`dagster-dbt`, `dagster-webserver`)

### Source Tables (AIRBNB.RAW)

| Table | Key Columns |
|-------|------------|
| `raw_listings` | id, listing_url, name, room_type, minimum_nights, host_id, price, created_at, updated_at |
| `raw_reviews` | listing_id, date, reviewer_name, comments, sentiment |
| `raw_hosts` | id, name, is_superhost, created_at, updated_at |

### dbt Project Structure (airbnb/)

- `models/` - SQL models (default materialization: view)
- `tests/` - Custom data tests
- `macros/` - Reusable Jinja macros
- `seeds/` - CSV seed files
- `snapshots/` - SCD snapshot definitions
- `analyses/` - Ad-hoc analytical queries

### Setup Scripts (repo root)

- `002-setup_sa.sh` - Generate RSA key pair for Snowflake auth
- `003-setup_sf.sql` - Create Snowflake warehouse, database, schemas, roles, users, and import raw data from S3
- `004-connections.sh` - Install UV package manager

### Roles

- `TRANSFORM` - Used by `dbt` service user for running models
- `REPORTER` - Used by `preset` service user for dashboards/reporting (read-only on `DEV` schema)
