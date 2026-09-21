defmodule Tucupass.Repo do
  use Ecto.Repo,
    otp_app: :tucupass,
    adapter: Ecto.Adapters.Postgres
end
