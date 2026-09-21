defmodule Tucupass.RateLimit do
  @moduledoc """
  Limitador de janela fixa em ETS (sem dependência). Protege inscrições
  públicas de spam; o estado vive na memória do nó e zera no restart.
  """
  use GenServer

  @table __MODULE__

  def start_link(_opts), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  # O GenServer só existe pra ser dono da tabela ETS (que morre com o dono).
  @impl true
  def init(nil) do
    :ets.new(@table, [:named_table, :public, :set, write_concurrency: true])
    {:ok, nil}
  end

  @doc "Registra uma tentativa de `key`; `{:error, :rate_limited}` ao passar de `limit` na janela."
  def hit(key, limit, window_ms) do
    bucket = div(System.system_time(:millisecond), window_ms)
    counter = :ets.update_counter(@table, {key, bucket}, {2, 1}, {{key, bucket}, 0})
    if counter == 1, do: sweep(bucket)

    if counter <= limit, do: :ok, else: {:error, :rate_limited}
  end

  # Remove janelas antigas quando abre uma nova (mantém a tabela pequena).
  defp sweep(bucket),
    do: :ets.select_delete(@table, [{{{:_, :"$1"}, :_}, [{:<, :"$1", bucket - 1}], [true]}])
end
