defmodule Tucupass.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        TucupassWeb.Telemetry,
        Tucupass.Repo,
        Tucupass.RateLimit,
        {DNSCluster, query: Application.get_env(:tucupass, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Tucupass.PubSub},
        # Start a worker by calling: Tucupass.Worker.start_link(arg)
        # {Tucupass.Worker, arg},
        # Start to serve requests, typically the last entry
        TucupassWeb.Presence,
        TucupassWeb.Endpoint
      ] ++ demo_children()

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tucupass.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp demo_children do
    if Application.get_env(:tucupass, :demo_enabled, false), do: [Tucupass.Demo], else: []
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TucupassWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
