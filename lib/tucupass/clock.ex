defmodule Tucupass.Clock do
  @moduledoc """
  Exibição de horários no fuso de Belém (UTC-3, sem horário de verão).
  O banco guarda tudo em UTC; só a apresentação converte.
  """

  @offset -3 * 3600

  def format(%DateTime{} = at, pattern) do
    at |> DateTime.add(@offset, :second) |> Calendar.strftime(pattern)
  end
end
