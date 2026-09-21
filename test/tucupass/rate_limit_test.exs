defmodule Tucupass.RateLimitTest do
  use ExUnit.Case, async: true

  alias Tucupass.RateLimit

  test "libera até o limite e bloqueia depois, por chave" do
    key = {:t, System.unique_integer()}
    assert for(_ <- 1..3, do: RateLimit.hit(key, 3, 60_000)) == [:ok, :ok, :ok]
    assert {:error, :rate_limited} = RateLimit.hit(key, 3, 60_000)
    assert :ok = RateLimit.hit({:t, System.unique_integer()}, 3, 60_000)
  end
end
