# analytics

The dbt project that turns the raw WSL data into the marts the app serves.

- **What the data means and how each layer transforms it:** the
  [dbt docs](https://wsl-demo.github.io/wsl-pipeline/). Its home page is
  `models/_overview.md`.
- **How the pipeline runs end to end:** the [repo README](../README.md).

Run dbt through the repo's Justfile, from anywhere in the repo, so it uses the
project's virtualenv and the warehouse path in `.env`:

```sh
just docs          # build and serve these docs locally
just dbt build     # or any other dbt command
```
