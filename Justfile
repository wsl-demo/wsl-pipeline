# Run dbt from analytics/ because profiles.yml points DuckDB at the relative
# path; running from the repo root would create an empty database.

set working-directory := "analytics"
set positional-arguments

# Load DATABASE_NAME and WSL_RAW_DIR from the gitignored .env.
set dotenv-load

# Use the proejct's .venv dbt, even when direnv hasn't been activate yet
dbt := justfile_directory() / ".venv/bin/dbt"
python := justfile_directory() / ".venv/bin/python"

# The app's Postgres belongs to the app repo's Docker Compose, which also
# creates the roles and schemas publishing needs. The db-* recipes run that
# repo's own recipes rather than copying them, so there is one definition.
app_justfile := justfile_directory() / "../fullstack/Justfile"

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

# Load the raw CSVs into DuckDB's `raw` schema (creates the warehouse, builds no models)
[working-directory: '..']
setup:
    # Refresh dbt's manifest first: Dagster loads its whole graph from it, even
    # to materialize only the raw tables, and `prepare_if_dev` only re-parses
    # under `dagster dev`, not this command.
    cd analytics && {{ dbt }} parse
    uv run dagster asset materialize -f orchestration/definitions.py --select 'group:raw_ingestion'

# Builds nothing, so run `just build` first. The tests are the gate: a failing
# one stops the recipe before anything reaches the app. Needs the app's
# Postgres running.
# Test the warehouse as it stands, then copy the marts into the app's Postgres
[working-directory: '..']
publish: _require-warehouse
    cd analytics && {{ dbt }} parse && {{ dbt }} test
    uv run dagster asset materialize -f orchestration/definitions.py --select 'key:"publish_marts"'

# Start the app's Postgres, creating its roles and schemas if it's new
db-ready:
    just --justfile {{ app_justfile }} db-ready

# Wipe the app's Postgres and recreate its roles and empty schemas
db-reset:
    just --justfile {{ app_justfile }} db-reset

# Row counts of the published tables, as the app's API sees them
db-status:
    just --justfile {{ app_justfile }} db-status

# Build models (staging, intermediate, marts) and run tests
build *args: _require-warehouse
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
