defmodule Phtmx.ResponseTest do
  use ExUnit.Case, async: true

  import Plug.Test
  import Plug.Conn
  import Phtmx.Response

  defp conn, do: conn(:post, "/")

  test "htmx_redirect/2 sets HX-Redirect" do
    assert get_resp_header(htmx_redirect(conn(), "/next"), "hx-redirect") == ["/next"]
  end

  test "htmx_location/2 sets HX-Location" do
    assert get_resp_header(htmx_location(conn(), "/next"), "hx-location") == ["/next"]
  end

  test "put_htmx_trigger/2 accepts a single event name" do
    assert get_resp_header(put_htmx_trigger(conn(), "saved"), "hx-trigger") == ["saved"]
  end

  test "put_htmx_trigger/2 joins a list of event names" do
    assert get_resp_header(put_htmx_trigger(conn(), ["a", "b"]), "hx-trigger") == ["a, b"]
  end

  test "put_htmx_trigger/2 JSON-encodes a map of event => detail" do
    conn = put_htmx_trigger(conn(), %{"saved" => %{count: 3}})
    assert get_resp_header(conn, "hx-trigger") == [Jason.encode!(%{"saved" => %{count: 3}})]
  end

  test "htmx_retarget/2 sets HX-Retarget" do
    assert get_resp_header(htmx_retarget(conn(), "#form"), "hx-retarget") == ["#form"]
  end

  test "htmx_reswap/2 sets HX-Reswap" do
    assert get_resp_header(htmx_reswap(conn(), "outerHTML"), "hx-reswap") == ["outerHTML"]
  end
end
