defmodule Phtmx.RequestTest do
  use ExUnit.Case, async: true

  import Plug.Test
  import Plug.Conn

  alias Phtmx.Request

  test "defaults to a non-HTMX request when no HX-* headers are present" do
    req = Request.from_conn(conn(:get, "/"))

    refute req.request?
    refute req.boosted?
    refute req.history_restore?
    assert req.target == nil
  end

  test "parses the HX-* request headers" do
    req =
      conn(:get, "/")
      |> put_req_header("hx-request", "true")
      |> put_req_header("hx-boosted", "true")
      |> put_req_header("hx-target", "counter")
      |> put_req_header("hx-trigger", "increment-btn")
      |> put_req_header("hx-current-url", "http://localhost/")
      |> Request.from_conn()

    assert req.request?
    assert req.boosted?
    assert req.target == "counter"
    assert req.trigger == "increment-btn"
    assert req.current_url == "http://localhost/"
  end
end
