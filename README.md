# Phtmx

A tiny, convention-over-configuration [HTMX](https://htmx.org) integration for Phoenix. 

`Phtmx` is three small modules:

- **`Phtmx.Plug`** - detects HTMX requests via the `HX-*` headers and strips the root layout so responses are bare fragments.
- **`Phtmx.Request`** - the parsed request metadata, assigned to `conn.assigns.htmx` (`@htmx`).
- **`Phtmx.Response`** - controller helpers for the `HX-*` response headers.

Phtmx targets **Phoenix 1.8+** and keeps `Phoenix.Component`/HEEx as your
templating layer - `Phtmx` only owns the request/response plumbing.

## Installation

The fastest path is the [Igniter](https://hexdocs.pm/igniter) installer, which
adds the dependency and does all the wiring below for you - router plug,
response import, CSRF header, and vendoring htmx.js:

```bash
mix igniter.install phtmx
```

Options: `--pipeline` (default `browser`), `--htmx-version` (default `2.0.4`),
`--skip-asset-fetch` (wire the `app.js` import but don't download htmx -
useful offline or in CI), and `--keep-heex-annotations` (leave HEEx debug
annotations as configured instead of disabling them - see below). Each edit is
idempotent and, if it can't find its anchor, prints a notice with the exact
snippet instead of guessing - and you review the full diff before anything is
written.

By default the installer also disables HEEx debug annotations
(`debug_heex_annotations: false` for `:phoenix_live_view` in `config/dev.exs`).
Left enabled, htmx swaps scatter `<!-- <MyAppWeb...> -->` component-source
comments across the DOM every time a fragment is swapped in.

Prefer to wire it by hand? Add the dependency and follow **Setup** below:

```elixir
def deps do
  [{:phtmx, "~> 0.2"}]
end
```

## Setup

If you used the installer, skip this - it's already done. Otherwise, three edits
wire phtmx into a standard Phoenix 1.8 app.

**1. Add the plug to your `:browser` pipeline**, right after `:put_root_layout`:

```elixir
# lib/my_app_web/router.ex
pipeline :browser do
  plug :accepts, ["html"]
  plug :fetch_session
  plug :fetch_flash
  plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
  plug Phtmx.Plug
  plug :protect_from_forgery
  plug :put_secure_browser_headers
end
```

**2. Import the response helpers** into your controllers (in the `controller/0`
block of your web module):

```elixir
# lib/my_app_web.ex
def controller do
  quote do
    use Phoenix.Controller, formats: [:html, :json]
    import Plug.Conn
    import Phtmx.Response
    # ...
  end
end
```

**3. Satisfy CSRF declaratively** by putting the token on `<body>` in your root
layout - Phoenix's existing `:protect_from_forgery` accepts the `x-csrf-token`
header, and every HTMX request in the page inherits it (no JavaScript):

```heex
<body hx-headers={Jason.encode!(%{"x-csrf-token" => get_csrf_token()})}>
  {@inner_content}
</body>
```

Finally, load the htmx client however you prefer - vendor a pinned
`htmx.min.js` into `assets/vendor/` and `import` it from `app.js` (recommended),
or use a CDN/npm. `Phtmx` is server-side only and deliberately ships no
JavaScript.

## How it works

An HTMX request wants just the fragment to swap in - not the `<html>`/`<head>`
shell. `Phtmx.Plug` disables the root layout for any request carrying
`HX-Request: true`, so whatever the controller renders is returned on its own.

Boosted navigations and targeted swaps both send `HX-Request: true`, so both get
the root layout stripped - the difference is simply *what the controller
renders*: a full page template (which still includes your `<Layouts.app>`) for a
boost, or a single function component for a targeted swap.

### A fragment is just a function component

The elegant part: a fragment is a HEEx function component, and it is the single
source of truth. Your full page renders it inside the layout; an HTMX request
renders the *same* component alone. No duplicate markup, no drift.

## Add an HTMX interaction in 3 steps

**1. Write the fragment as a function component:**

```elixir
# counter_html.ex
attr :count, :integer, required: true

def counter(assigns) do
  ~H"""
  <div id="counter" class="flex items-center gap-4">
    <span class="text-5xl font-bold tabular-nums">{@count}</span>
    <button hx-post={~p"/counter/increment"} hx-target="#counter" hx-swap="outerHTML">
      Increment
    </button>
  </div>
  """
end

# *.heex
<.counter count={@count} />
```


**2. Add a route and an action** that renders *just the component*:

```elixir
# router.ex
post "/counter/increment", CounterController, :increment

# counter_controller.ex
def increment(conn, _params) do
  new_count = get_count(conn) + 1

  conn
  |> put_session(:count, new_count)
  # optional: fire a client event
  |> put_htmx_trigger("counter:changed")
  # root layout already stripped by Phtmx.Plug
  |> render(:counter, count: new_count)
end

def get_count(conn), do: get_session(conn, :count) || 0
```

_note: you will need to assign a default value for `@count` because we require it in the `attr` `opts`. This is not tutorialed because it is trivial and can be done a number of ways. One such method is assigning count with `put_session(conn, :count, count).`_

**Bonus. (Optional) React to the triggered event** anywhere on the page:

Here we use all the skills we previously demonstrated; we are piggy-backing off the `put_htmx_trigger("counter:changed")` code from the `increment` controller function. This example shows how elements can update other elements using events with specific names.

```elixir
# counter_html.ex
def activity(assigns) do
  ~H"""
  <div
    id="activity"
    hx-get={~p"/counter/activity"}
    hx-trigger="counter:changed from:body"
    hx-target="#activity"
    hx-swap="outerHTML"
  >
    <p>{"Counter changed at #{DateTime.utc_now()}"}</p>
  </div>
  """
end

# *.heex 
<.activity />

# router.ex
get "/counter/activity", PageController, :activity

# counter_controller.ex
def activity(conn, _params), do: render(conn, :activity)
```

## Response helpers

`Phtmx.Response` provides thin, documented wrappers over the `HX-*` response
headers:

| Helper | Header | Use |
| --- | --- | --- |
| `htmx_redirect/2` | `HX-Redirect` | Full browser navigation (use instead of `redirect/2` - a 302 gets swapped, not followed) |
| `htmx_location/2` | `HX-Location` | Client-side navigation without a full reload |
| `put_htmx_trigger/2` | `HX-Trigger` | Fire client events (string, list, or a JSON-encoded map) |
| `htmx_retarget/2` | `HX-Retarget` | Change which element the response swaps into |
| `htmx_reswap/2` | `HX-Reswap` | Change how the response is swapped in |

_note: phtmx intentionally supports a small subset of what's possible. We can add more upon request and with what makes the most sense._

## License

MIT © Kristoff Finley
