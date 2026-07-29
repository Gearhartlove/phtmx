defmodule Phtmx.Plug do
  @moduledoc """
  Detects HTMX requests and strips the root layout so responses to HTMX are
  bare HTML fragments instead of full pages.

  Add it to your `:browser` pipeline, right after `:put_root_layout`:

      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_flash
        plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
        plug Phtmx.Plug
        plug :protect_from_forgery
        plug :put_secure_browser_headers
      end

  For every request it assigns a `Phtmx.Request` struct to `conn.assigns.htmx`.
  When the request carries `HX-Request: true` it disables the root layout — the
  `<html>`/`<head>` shell — for the HTML format, so whatever the controller
  renders is returned on its own. That is exactly the HTML HTMX swaps into the
  page.

  ## Boosted vs. targeted requests

  Both `hx-boost` navigations and targeted `hx-get`/`hx-post` swaps send
  `HX-Request: true`, so both get the root layout stripped. The difference is
  simply *what the controller renders*:

    * a **boosted navigation** renders a normal full-page template, which still
      includes your `<Layouts.app>` chrome — HTMX swaps it into `<body>`;
    * a **targeted fragment** renders a single function component — HTMX swaps
      it into the targeted element.

  ## Opting an action back into the full page

  In the rare case an HTMX request should still receive the whole page, re-enable
  the root layout inside the action with Phoenix's own `put_root_layout/2`:

      def show(conn, _params) do
        conn
        |> put_root_layout(html: {MyAppWeb.Layouts, :root})
        |> render(:show)
      end
  """

  @behaviour Plug

  import Plug.Conn, only: [assign: 3]

  alias Phtmx.Request

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    req = Request.from_conn(conn)
    conn = assign(conn, :htmx, req)

    if req.request? do
      Phoenix.Controller.put_root_layout(conn, html: false)
    else
      conn
    end
  end
end
