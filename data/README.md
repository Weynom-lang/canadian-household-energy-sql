# Source Data

This project uses household energy-consumption data published by **Statistics Canada**.

The analysis is based on the following tables:

- **25-10-0060-01** — Household energy consumption, Canada and provinces
- **25-10-0061-01** — Household energy consumption, by type of dwelling
- **25-10-0062-01** — Household energy consumption, by household income

The source files used during development were downloaded as CSV files from Statistics Canada and loaded into PostgreSQL.

## Why the Raw CSV Files Are Not Included

The raw Statistics Canada CSV files are intentionally excluded from this repository.

Instead, the repository contains:

- PostgreSQL raw-table definitions
- validation and profiling queries
- clean analytical views
- analysis SQL
- the completed Jupyter notebook
- generated visualizations

This keeps the repository focused on the analytical workflow while allowing the original public datasets to be obtained directly from Statistics Canada.

## Reference Period

The selected tables contain observations for:

- 2011
- 2013
- 2015
- 2019
- 2021

As of November 2026, **2021 is the latest reference year available in the selected Statistics Canada tables**.

The workflow was designed so that newer comparable observations can be incorporated when they become available, subject to any future changes in the source tables, definitions, or methodology.

## Data-Quality Fields

Statistics Canada quality-status information is retained throughout the database workflow.

In this project:

- `F` observations are treated as suppressed or unavailable, not as zero.
- `E` observations are retained but interpreted cautiously.
- Statistics Canada vector identifiers are preserved in the clean views to support source-series traceability.

## Database Loading

The project uses three raw PostgreSQL datasets:

```text
raw.overall
raw.dwelling
raw.income
```

Their database definitions and validation logic are documented in:

```text
sql/01_raw_overall.sql
sql/02_raw_validation.sql
sql/03_raw_profiling.sql
sql/04_clean_overall.sql
sql/05_clean_validation.sql
sql/06_dwelling_pipeline.sql
sql/07_income_pipeline.sql
```

Raw data should be obtained from Statistics Canada before reproducing the database-loading stage of the project.
