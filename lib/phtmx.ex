defmodule Phtmx do
  @moduledoc """
  A tiny, dependency-light integration layer between [HTMX](https://htmx.org)
  and Phoenix.

  HTMX lets you build interactive UIs by returning HTML *fragments* over plain
  HTTP — no WebSocket, no client-side state. This library supplies the small
  amount of glue that makes that pleasant in Phoenix while keeping HEEx as your
  templating language:

    * `Phtmx.Plug` — detects HTMX requests (via the `HX-*` request headers) and
      strips the root layout so responses are bare fragments. Assigns a
      `Phtmx.Request` to `conn.assigns.htmx`.

    * `Phtmx.Request` — the parsed request metadata (`request?`, `boosted?`,
      `target`, `trigger`, …) available to controllers and templates.

    * `Phtmx.Response` — controller helpers for the `HX-*` *response* headers:
      `htmx_redirect/2`, `put_htmx_trigger/2`, `htmx_retarget/2`,
      `htmx_reswap/2`, and friends.

  ## The core idea

  A fragment is just a HEEx **function component**. Your full-page template
  renders `<.counter count={@count} />` inside `<Layouts.app>`; an HTMX request
  renders the *same* component on its own. Because `Phtmx.Plug` has already
  disabled the root layout for HTMX requests, a plain
  `render(conn, :counter, count: @count)` returns exactly that fragment — no
  special API required.

  See the `README` for the "add an HTMX interaction in 3 steps" walkthrough.
  """
end
