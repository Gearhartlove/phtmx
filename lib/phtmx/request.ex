defmodule Phtmx.Request do
  @moduledoc """
  Parsed HTMX request metadata, derived from the `HX-*` request headers that
  the HTMX client sends.

  `Phtmx.Plug` builds one of these for every request and assigns it as
  `conn.assigns.htmx`, so controllers and templates can branch on it:

      <div :if={@htmx.request?}>...only rendered for HTMX requests...</div>

      def index(conn, _params) do
        if conn.assigns.htmx.boosted?, do: ..., else: ...
      end
  """

  @type t :: %__MODULE__{
          request?: boolean(),
          boosted?: boolean(),
          history_restore?: boolean(),
          current_url: String.t() | nil,
          prompt: String.t() | nil,
          target: String.t() | nil,
          trigger: String.t() | nil,
          trigger_name: String.t() | nil
        }

  defstruct request?: false,
            boosted?: false,
            history_restore?: false,
            current_url: nil,
            prompt: nil,
            target: nil,
            trigger: nil,
            trigger_name: nil

  @doc """
  Builds a `t:t/0` from a `Plug.Conn`'s request headers.

  A request is considered an HTMX request when it carries `HX-Request: true`.
  """
  @spec from_conn(Plug.Conn.t()) :: t()
  def from_conn(conn) do
    %__MODULE__{
      request?: header?(conn, "hx-request"),
      boosted?: header?(conn, "hx-boosted"),
      history_restore?: header?(conn, "hx-history-restore-request"),
      current_url: header(conn, "hx-current-url"),
      prompt: header(conn, "hx-prompt"),
      target: header(conn, "hx-target"),
      trigger: header(conn, "hx-trigger"),
      trigger_name: header(conn, "hx-trigger-name")
    }
  end

  defp header(conn, name) do
    case Plug.Conn.get_req_header(conn, name) do
      [value | _] -> value
      [] -> nil
    end
  end

  defp header?(conn, name), do: header(conn, name) == "true"
end
