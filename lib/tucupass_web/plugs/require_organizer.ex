defmodule TucupassWeb.Plugs.RequireOrganizer do
  @moduledoc """
  Protege check-in e dashboard. A organização entra uma vez com `?key=...`;
  a chave vai pra sessão e a URL é limpa por redirect.
  """
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]

  def init(opts), do: opts

  def call(conn, _opts) do
    expected = Application.fetch_env!(:tucupass, :organizer_key)

    cond do
      valid?(conn.params["key"], expected) ->
        conn |> put_session(:organizer, true) |> redirect(to: conn.request_path) |> halt()

      get_session(conn, :organizer) == true ->
        conn

      true ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(403, "Acesso restrito à organização.")
        |> halt()
    end
  end

  defp valid?(key, expected) when is_binary(key), do: Plug.Crypto.secure_compare(key, expected)
  defp valid?(_, _), do: false
end
