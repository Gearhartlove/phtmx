# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] — Unreleased

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
