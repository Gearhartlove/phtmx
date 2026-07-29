defmodule Mix.Tasks.Phtmx.InstallTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  # `--skip-asset-fetch` keeps the suite hermetic (no network): the app.js
  # import is still wired, but htmx.min.js isn't downloaded. The download path
  # is validated manually.
  defp install do
    phx_test_project()
    |> Igniter.compose_task("phtmx.install", ["--skip-asset-fetch"])
  end

  test "adds plug Phtmx.Plug to the :browser pipeline" do
    install()
    |> assert_has_patch("lib/test_web/router.ex", """
    + |    plug(Phtmx.Plug)
    """)
  end

  test "adds import Phtmx.Response to the web module's controller/0" do
    install()
    |> assert_has_patch("lib/test_web.ex", """
    + |      import Phtmx.Response
    """)
  end

  test "adds the CSRF hx-headers attribute to the root layout <body>" do
    install()
    |> assert_has_patch("lib/test_web/components/layouts/root.html.heex", """
    + |  <body hx-headers={Jason.encode!(%{"x-csrf-token" => get_csrf_token()})}>
    """)
  end

  test "imports htmx from app.js" do
    install()
    |> assert_has_patch("assets/js/app.js", """
    + |import "../vendor/htmx.min"
    """)
  end

  test "is idempotent — a second run makes no changes" do
    first = install() |> apply_igniter!()

    first
    |> Igniter.compose_task("phtmx.install", ["--skip-asset-fetch"])
    |> assert_unchanged()
  end
end
