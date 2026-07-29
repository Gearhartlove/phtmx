defmodule Phtmx.PlugTest do
  use ExUnit.Case, async: true

  import Plug.Test
  import Plug.Conn
  import Phoenix.Controller, only: [put_root_layout: 2, root_layout: 2]

  # A root layout value is just an opaque {module, template} tuple to Phoenix;
  # the module need not exist for put_root_layout/root_layout to round-trip it.
  defp with_root_layout(conn), do: put_root_layout(conn, html: {SomeApp.Layouts, :root})

  test "non-HTMX request assigns @htmx and leaves the root layout intact" do
    conn =
      conn(:get, "/")
      |> with_root_layout()
      |> Phtmx.Plug.call(Phtmx.Plug.init([]))

    assert %Phtmx.Request{request?: false} = conn.assigns.htmx
    assert root_layout(conn, "html") == {SomeApp.Layouts, :root}
  end

  test "HTMX request assigns @htmx and disables the root layout" do
    conn =
      conn(:get, "/")
      |> put_req_header("hx-request", "true")
      |> with_root_layout()
      |> Phtmx.Plug.call(Phtmx.Plug.init([]))

    assert %Phtmx.Request{request?: true, boosted?: false} = conn.assigns.htmx
    assert root_layout(conn, "html") == false
  end

  test "boosted request is still treated as an HTMX request (root layout disabled)" do
    conn =
      conn(:get, "/")
      |> put_req_header("hx-request", "true")
      |> put_req_header("hx-boosted", "true")
      |> with_root_layout()
      |> Phtmx.Plug.call(Phtmx.Plug.init([]))

    assert %Phtmx.Request{request?: true, boosted?: true} = conn.assigns.htmx
    assert root_layout(conn, "html") == false
  end
end
