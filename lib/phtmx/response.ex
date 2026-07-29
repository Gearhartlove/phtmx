defmodule Phtmx.Response do
  @moduledoc """
  Controller helpers for driving the HTMX client from the server via `HX-*`
  **response** headers.

  Import them wherever you build controllers — the generated scaffold does this
  for you in the `controller/0` block of your web module:

      import Phtmx.Response

  Then, from an action:

      def create(conn, params) do
        case save(params) do
          {:ok, _} -> conn |> put_htmx_trigger("saved") |> render(:row)
          {:error, cs} -> conn |> htmx_retarget("#form") |> render(:form, changeset: cs)
        end
      end
  """

  import Plug.Conn, only: [put_resp_header: 3]

  @doc """
  Tells HTMX to perform a full client-side redirect (a real browser navigation)
  to `url`, via the `HX-Redirect` header.

  Prefer this over `Phoenix.Controller.redirect/2` for HTMX requests. A normal
  `302` response is transparently *followed* by HTMX and its body swapped into
  the target element — almost never what you want. `HX-Redirect` navigates the
  browser instead.
  """
  @spec htmx_redirect(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def htmx_redirect(conn, url), do: put_resp_header(conn, "hx-redirect", url)

  @doc """
  Client-side redirect performed *without* a full page reload, via the
  `HX-Location` header. HTMX fetches `url` and swaps it in like a boosted
  navigation, pushing a new history entry.
  """
  @spec htmx_location(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def htmx_location(conn, url), do: put_resp_header(conn, "hx-location", url)

  @doc """
  Fires one or more client-side events after the response is received, via the
  `HX-Trigger` header.

  Accepts:

    * a single event name — `put_htmx_trigger(conn, "cartUpdated")`
    * a list of names — `put_htmx_trigger(conn, ["a", "b"])`
    * a map of `name => detail`, JSON-encoded so listeners receive the detail —
      `put_htmx_trigger(conn, %{"cartUpdated" => %{count: 3}})`
  """
  @spec put_htmx_trigger(Plug.Conn.t(), String.t() | [String.t()] | map()) :: Plug.Conn.t()
  def put_htmx_trigger(conn, event) when is_binary(event),
    do: put_resp_header(conn, "hx-trigger", event)

  def put_htmx_trigger(conn, events) when is_list(events),
    do: put_resp_header(conn, "hx-trigger", Enum.join(events, ", "))

  def put_htmx_trigger(conn, events) when is_map(events),
    do: put_resp_header(conn, "hx-trigger", Jason.encode!(events))

  @doc """
  Overrides which element this response is swapped into, via the `HX-Retarget`
  header. `selector` is a CSS selector.
  """
  @spec htmx_retarget(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def htmx_retarget(conn, selector), do: put_resp_header(conn, "hx-retarget", selector)

  @doc """
  Overrides how this response is swapped in, via the `HX-Reswap` header, e.g.
  `"outerHTML"`, `"beforeend"`, or `"innerHTML"`.
  """
  @spec htmx_reswap(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def htmx_reswap(conn, swap), do: put_resp_header(conn, "hx-reswap", swap)
end
