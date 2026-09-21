defmodule Tucupass.Demo do
  @moduledoc """
  Simulador do evento público `demo`: gente fictícia se inscreve e chega em
  ritmo humano, pra vitrine ter painel vivo sem depender de evento real.
  Tudo que é simulado usa e-mail `@demo.invalid`, então é fácil de apagar e
  nunca se confunde com inscrição de visitante.
  """
  use GenServer
  import Ecto.Query
  require Logger

  alias Tucupass.{Events, Repo}
  alias Tucupass.Events.Attendee
  alias TucupassWeb.{CheckinLive, Presence}

  @slug "demo"
  @target 48
  @pause_after_full 9_000
  @sim_domain "@demo.invalid"
  @visitor_ttl_hours 6

  @firsts ~w(Ana Beatriz Cauã Iracema Raimundo Luana Tiago Nazaré Davi Socorro Yuri Marina Otávio Kauane Heitor Jandira Lucas Rayane Breno Aline)
  @lasts ~w(Souza Lima Farias Nogueira Pinheiro Cardoso Monteiro Tavares Batista Ribeiro Xavier Coelho Mendes Araújo Ferreira)

  def slug, do: @slug
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    {:ok, %{event: nil}, {:continue, :boot}}
  end

  @impl true
  def handle_continue(:boot, state), do: {:noreply, state, {:continue, :ensure_event}}

  def handle_continue(:ensure_event, state) do
    case ensure_event() do
      {:ok, event} ->
        Presence.track(self(), CheckinLive.presence_topic(event), "sim-reader-1", %{})
        Presence.track(self(), CheckinLive.presence_topic(event), "sim-reader-2", %{})
        schedule()
        {:noreply, %{state | event: event}}

      _ ->
        Process.send_after(self(), :retry_boot, 5_000)
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(:retry_boot, state), do: {:noreply, state, {:continue, :ensure_event}}

  def handle_info(:tick, %{event: event} = state) do
    delay =
      try do
        step(event)
      rescue
        e ->
          Logger.warning("demo: #{Exception.message(e)}")
          5_000
      end

    Process.send_after(self(), :tick, delay)
    {:noreply, state}
  end

  defp schedule, do: send(self(), :tick)

  defp ensure_event do
    case Events.get_event_by_slug(@slug) do
      nil ->
        Events.create_event(%{
          name: "Meetup Devs Norte (demo)",
          slug: @slug,
          location: "Simulação · nada aqui é gente de verdade",
          starts_at: DateTime.utc_now(:second)
        })

      event ->
        {:ok, event}
    end
  rescue
    _ -> :error
  end

  # Um passo da simulação; devolve o atraso até o próximo.
  @doc false
  def step(event) do
    sim = sim_query(event)
    total = Repo.aggregate(sim, :count)
    pending = Repo.all(from a in sim, where: is_nil(a.checked_in_at), select: a.ticket_token)

    cond do
      total >= @target and pending == [] ->
        reset(event)
        @pause_after_full

      total < @target and (pending == [] or :rand.uniform() < 0.55) ->
        register_fake(event)
        Enum.random(500..1400)

      true ->
        Events.check_in(event, Enum.random(pending))
        Enum.random(700..2200)
    end
  end

  defp register_fake(event) do
    name = "#{Enum.random(@firsts)} #{Enum.random(@lasts)}"
    email = "sim#{System.unique_integer([:positive])}#{@sim_domain}"
    Events.register(event, %{name: name, email: email}, notify: false)
  end

  defp sim_query(event),
    do: from(a in Attendee, where: a.event_id == ^event.id and like(a.email, ^"%#{@sim_domain}"))

  # Apaga a simulação e inscrições de visitantes com mais de algumas horas.
  defp reset(event) do
    cutoff = DateTime.add(DateTime.utc_now(), -@visitor_ttl_hours * 3600)

    Repo.delete_all(
      from a in Attendee,
        where:
          a.event_id == ^event.id and
            (like(a.email, ^"%#{@sim_domain}") or a.inserted_at < ^cutoff)
    )

    Phoenix.PubSub.broadcast(Tucupass.PubSub, "event:#{event.id}", {:reset, event.id})
  end
end
