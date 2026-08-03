# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `mix igniter.install phtmx` now disables HEEx debug annotations
  (`debug_heex_annotations: false` for `:phoenix_live_view` in `config/dev.exs`)
  by default. Left enabled, htmx swaps scatter `<!-- <MyAppWeb...> -->`
  component-source comments across the DOM every time a fragment is swapped
  in. Pass `--keep-heex-annotations` to opt out.

## [0.2.0]

### Added

- `mix igniter.install phtmx` — an [Igniter](https://hexdocs.pm/igniter) installer
  that wires phtmx into a Phoenix app: adds `plug Phtmx.Plug` to the `:browser`
  pipeline, `import Phtmx.Response` to the web module's `controller/0`, the CSRF
  `hx-headers` attribute to the root layout's `<body>`, and vendors `htmx.min.js`
  into `assets/vendor/` with an `import` in `app.js`. Each step is idempotent and
  degrades to a printed notice if its anchor can't be found. Flags: `--pipeline`,
  `--htmx-version`, `--skip-asset-fetch`.
- `igniter` as an `optional` dependency (install-time only; not pulled into
  consumers' runtime dependency closure).

## [0.1.0]

Initial extraction from the `hyper` HTMX-first Phoenix scaffold.

### Added

- `Phtmx.Plug` — detects HTMX requests via the `HX-*` request headers, assigns a
  `Phtmx.Request` to `conn.assigns.htmx`, and strips the root layout on HTMX
  requests so responses are bare fragments.
- `Phtmx.Request` — parsed HTMX request metadata (`request?`, `boosted?`,
  `target`, `trigger`, `current_url`, …).
- `Phtmx.Response` — controller helpers for the `HX-*` response headers:
  `htmx_redirect/2`, `htmx_location/2`, `put_htmx_trigger/2`, `htmx_retarget/2`,
  `htmx_reswap/2`.
