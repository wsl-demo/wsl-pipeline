# Run dbt from analytics/ because profiles.yml points DuckDB at the relative
# path; running from the repo root would create an empty database.

set working-directory := "analytics"
set positional-arguments

# Load DATABASE_NAME and WSL_RAW_DIR from the gitignored .env.
set dotenv-load

# Use the proejct's .venv dbt, even when direnv hasn't been activate yet
dbt := justfile_directory() / ".venv/bin/dbt"
python := justfile_directory() / ".venv/bin/python"

# List avaialble recipes
default:
    @just --list

# Fail early, with a pointer, if the warehouse hasn't been created
[private]
_require-warehouse:
    @test -f "${DATABASE_NAME:-warehouse.duckdb}" || { echo "No warehouse yet. Run \`just setup\` first." >&2; exit 1; }

# Start Dagster (ingestion + dbt) at http://localhost:3000
[working-directory: '..']
dagster:
    uv run dagster dev -f orchestration/definitions.py

# Ingest the raw CSVs and build every model (creates the warehouse)
[working-directory: '..']
setup:
    # Refresh dbt's manifest first: Dagster builds its assets from it, and
    # `prepare_if_dev` only re-parses under `dagster dev`, not this command.
    cd analytics && {{ dbt }} parse
    uv run dagster asset materialize -f orchestration/definitions.py --select '*'

# Build models and run tests
build *args:
    {{ dbt }} build "$@"

# Preview a model's rows
show model *args:
    {{ dbt }} show --select "$@"

# Print the rows behind any dbt tests that failed in the latest run
failures: _require-warehouse
    {{ python }} analysis/show_failures.py

# DuckDB allows only one writer, so an open DBeaver connection blocks dbt and
# Dagster; disconnect there before building.
# Open the warehouse in DBeaver (disconnect before building)
dbeaver: _require-warehouse
    /Applications/DBeaver.app/Contents/MacOS/dbeaver \
        -con "driver=duckdb|database=$PWD/${DATABASE_NAME:-warehouse.duckdb}|name=wsl|connect=true|openConsole=true" \
        >/dev/null 2>&1 &

# Generate the docs site with the column-level lineage and service it on :8580
docs:
    # `docs generate` rejects --static-analysis, so compile it in strict mode
    # first and have `generate`` reuese that compile
    {{ dbt }} compile --static-analysis strict --generate-info-schema
    {{ dbt }} docs generate --no-compile
    {{ dbt }} docs serve

# Run any other dbt command
dbt *args:
    {{ dbt }} "$@"
