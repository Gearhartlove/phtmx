if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Phtmx.Install do
    @shortdoc "Wires phtmx into a Phoenix app (plug, response import, CSRF, htmx.js)"

    @moduledoc """
    Installs phtmx into a Phoenix 1.8+ application.

        mix igniter.install phtmx

    It performs four edits, each idempotent and each degrading to a printed
    notice (rather than a guessed edit) if it can't confidently locate the
    anchor — you always review the full diff before anything is written:

      1. adds `plug Phtmx.Plug` to the `:browser` router pipeline;
      2. adds `import Phtmx.Response` to the web module's `controller/0`;
      3. adds the CSRF `hx-headers` attribute to `<body>` in the root layout;
      4. vendors `htmx.min.js` into `assets/vendor/` and imports it from
         `assets/js/app.js`.

    ## Options

      * `--pipeline` - the router pipeline to add the plug to (default: `browser`)
      * `--htmx-version` - the htmx version to vendor (default: `2.0.4`)
      * `--skip-asset-fetch` - don't download htmx; still wires the `app.js`
        import and prints a notice so you can vendor it yourself (useful offline
        or in CI)
    """

    use Igniter.Mix.Task

    alias Igniter.Code.Common
    alias Igniter.Code.Function
    alias Igniter.Libs.Phoenix
    alias Igniter.Project.Module, as: Mod

    @htmx_default_version "2.0.4"

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :phtmx,
        example: "mix igniter.install phtmx",
        schema: [pipeline: :string, htmx_version: :string, skip_asset_fetch: :boolean],
        defaults: [
          pipeline: "browser",
          htmx_version: @htmx_default_version,
          skip_asset_fetch: false
        ]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      opts = igniter.args.options
      pipeline = String.to_atom(opts[:pipeline] || "browser")

      igniter
      |> ensure_browser_plug(pipeline)
      |> ensure_response_import()
      |> ensure_csrf_headers()
      |> ensure_htmx_asset(opts)
    end

    # 1. plug Phtmx.Plug in the :browser pipeline ----------------------------

    defp ensure_browser_plug(igniter, pipeline) do
      {igniter, router} = Phoenix.select_router(igniter)

      if is_nil(router) do
        Igniter.add_notice(
          igniter,
          "No Phoenix router found — add `plug Phtmx.Plug` to your :#{pipeline} pipeline manually."
        )
      else
        {igniter, has_pipeline?} = Phoenix.has_pipeline(igniter, router, pipeline)

        if has_pipeline? do
          add_plug_to_pipeline(igniter, router, pipeline)
        else
          Igniter.add_notice(
            igniter,
            "No :#{pipeline} pipeline in #{inspect(router)} — add `plug Phtmx.Plug` to it manually."
          )
        end
      end
    end

    defp add_plug_to_pipeline(igniter, router, pipeline) do
      Mod.find_and_update_module!(igniter, router, fn zipper ->
        with {:ok, zipper} <-
               Function.move_to_function_call_in_current_scope(
                 zipper,
                 :pipeline,
                 2,
                 &Function.argument_equals?(&1, 0, pipeline)
               ),
             {:ok, zipper} <- Common.move_to_do_block(zipper) do
          if function_call_present?(zipper, :plug, Phtmx.Plug) do
            {:ok, zipper}
          else
            {:ok, Common.add_code(zipper, "plug Phtmx.Plug")}
          end
        else
          _ -> {:ok, zipper}
        end
      end)
    end

    # 2. import Phtmx.Response in the web module's controller/0 ---------------

    defp ensure_response_import(igniter) do
      web = Phoenix.web_module(igniter)

      Mod.find_and_update_module!(igniter, web, fn zipper ->
        with {:ok, zipper} <- Function.move_to_def(zipper, :controller, 0),
             {:ok, zipper} <- Function.move_to_function_call(zipper, :quote, 1),
             {:ok, zipper} <- Common.move_to_do_block(zipper) do
          if function_call_present?(zipper, :import, Phtmx.Response) do
            {:ok, zipper}
          else
            {:ok, Common.add_code(zipper, "import Phtmx.Response")}
          end
        else
          _ ->
            {:warning,
             "Could not add `import Phtmx.Response` to #{inspect(web)}.controller/0. Add it manually."}
        end
      end)
    end

    # 3. CSRF hx-headers on <body> in the root layout ------------------------

    defp ensure_csrf_headers(igniter) do
      path = root_layout_path(igniter)
      snippet = ~s|hx-headers={Jason.encode!(%{"x-csrf-token" => get_csrf_token()})}|

      manual = """
      Add HTMX's CSRF token to your root layout's <body> tag:

          <body #{snippet}>
      """

      if Igniter.exists?(igniter, path) do
        Igniter.update_file(igniter, path, fn source ->
          content = Rewrite.Source.get(source, :content)

          cond do
            String.contains?(content, "hx-headers") ->
              source

            String.contains?(content, "<body>") ->
              Rewrite.Source.update(
                source,
                :content,
                String.replace(content, "<body>", "<body #{snippet}>", global: false)
              )

            true ->
              {:notice, manual}
          end
        end)
      else
        Igniter.add_notice(igniter, "Root layout not found at #{path}.\n\n" <> manual)
      end
    end

    # 4. vendor htmx.min.js + import it from app.js --------------------------

    defp ensure_htmx_asset(igniter, opts) do
      version = opts[:htmx_version] || @htmx_default_version

      igniter
      |> vendor_htmx(version, opts[:skip_asset_fetch])
      |> import_htmx_in_app_js()
    end

    defp vendor_htmx(igniter, version, skip?) do
      path = "assets/vendor/htmx.min.js"
      url = "https://unpkg.com/htmx.org@#{version}/dist/htmx.min.js"

      cond do
        Igniter.exists?(igniter, path) ->
          igniter

        skip? ->
          Igniter.add_notice(
            igniter,
            "Skipped htmx download — vendor htmx #{version} to #{path} yourself: #{url}"
          )

        true ->
          case fetch(url) do
            {:ok, body} ->
              Igniter.create_new_file(igniter, path, body, on_exists: :skip)

            {:error, reason} ->
              Igniter.add_notice(
                igniter,
                "Couldn't download htmx #{version} (#{reason}). Download it to #{path} manually: #{url}"
              )
          end
      end
    end

    defp import_htmx_in_app_js(igniter) do
      path = "assets/js/app.js"
      import_line = ~s(import "../vendor/htmx.min")

      if Igniter.exists?(igniter, path) do
        Igniter.update_file(igniter, path, fn source ->
          content = Rewrite.Source.get(source, :content)

          if String.contains?(content, "vendor/htmx") do
            source
          else
            Rewrite.Source.update(source, :content, content <> "\n" <> import_line <> "\n")
          end
        end)
      else
        Igniter.add_notice(
          igniter,
          "#{path} not found — add `#{import_line}` to your JS bundle manually."
        )
      end
    end

    # helpers ----------------------------------------------------------------

    defp function_call_present?(zipper, name, first_arg_module) do
      case Function.move_to_function_call_in_current_scope(
             zipper,
             name,
             [1, 2],
             &Function.argument_equals?(&1, 0, first_arg_module)
           ) do
        {:ok, _} -> true
        _ -> false
      end
    end

    defp root_layout_path(igniter) do
      app = Igniter.Project.Application.app_name(igniter)
      "lib/#{app}_web/components/layouts/root.html.heex"
    end

    defp fetch(url) do
      {:ok, _} = Application.ensure_all_started(:inets)
      {:ok, _} = Application.ensure_all_started(:ssl)

      http_opts = [
        ssl: [
          verify: :verify_peer,
          cacerts: :public_key.cacerts_get(),
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ]
        ],
        timeout: 30_000
      ]

      case :httpc.request(:get, {String.to_charlist(url), []}, http_opts, body_format: :binary) do
        {:ok, {{_, 200, _}, _headers, body}} -> {:ok, body}
        {:ok, {{_, status, _}, _headers, _body}} -> {:error, "HTTP #{status}"}
        {:error, reason} -> {:error, inspect(reason)}
        other -> {:error, inspect(other)}
      end
    end
  end
else
  defmodule Mix.Tasks.Phtmx.Install do
    @shortdoc "Installs phtmx (requires igniter)"
    @moduledoc @shortdoc

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task `phtmx.install` requires igniter.

      Run it with:

          mix igniter.install phtmx

      which installs igniter and phtmx together.
      """)

      exit({:shutdown, 1})
    end
  end
end
