defmodule TucupassWeb.Board do
  @moduledoc "Painel ao vivo (números grandes, quadradinhos de chegada e últimos a entrar)."
  use Phoenix.Component

  alias Tucupass.Events
  alias TucupassWeb.{CheckinLive, Presence}

  @doc "Dados do painel (stats, últimos, leitores) prontos pra `assign/2`."
  def snapshot(event, recent \\ 8) do
    [
      stats: Events.stats(event),
      recent: Events.recent_check_ins(event, recent),
      scanners: event |> CheckinLive.presence_topic() |> Presence.list() |> map_size()
    ]
  end

  @doc "Assina PubSub + Presence do evento (chamar só com socket conectado)."
  def subscribe(event) do
    Events.subscribe(event)
    Phoenix.PubSub.subscribe(Tucupass.PubSub, CheckinLive.presence_topic(event))
  end

  attr :event, :map, required: true
  attr :stats, :map, required: true
  attr :recent, :list, required: true
  attr :scanners, :integer, default: 0
  attr :simulated, :boolean, default: false

  def live_board(assigns) do
    assigns = assign(assigns, :cells, cells(assigns.stats))

    ~H"""
    <section class="board" aria-label={"Painel ao vivo de #{@event.name}"}>
      <div class="board__head">
        <span class="board__live">ao vivo</span>
        <span>{@event.name}</span>
        <span :if={@simulated} class="opacity-70">simulação · gente fictícia</span>
      </div>
      <div class="board__grid">
        <div class="board__cell">
          <div id="stat-checked-in" class="board__num board__num--hot">{@stats.checked_in}</div>
          <div class="board__label">já chegaram</div>
        </div>
        <div class="board__cell">
          <div id="stat-total" class="board__num">{@stats.total}</div>
          <div class="board__label">inscritos</div>
        </div>
        <div class="board__cell">
          <div id="stat-rate" class="board__num board__num--rate">{@stats.rate}%</div>
          <div class="board__label">taxa de check-in</div>
        </div>
        <div class="board__cell">
          <div id="stat-scanners" class="board__num">{@scanners}</div>
          <div class="board__label">leitores online</div>
        </div>
      </div>
      <div class="ticks" aria-hidden="true">
        <span :for={on <- @cells} class={["tick", on && "tick--on"]}></span>
      </div>
      <ul id="recent" class="arrivals">
        <li :for={a <- @recent} id={"recent-#{a.id}"} class={["arrival", fresh?(a) && "arrival--new"]}>
          <span>{a.name}</span>
          <time datetime={DateTime.to_iso8601(a.checked_in_at)}>
            {Tucupass.Clock.format(a.checked_in_at, "%H:%M:%S")}
          </time>
        </li>
        <li :if={@recent == []} class="arrival opacity-70"><span>Ninguém chegou ainda.</span></li>
      </ul>
    </section>
    """
  end

  # Só quem acabou de chegar pisca; ao abrir a página as linhas antigas ficam quietas.
  defp fresh?(%{checked_in_at: at}), do: DateTime.diff(DateTime.utc_now(), at) < 4

  # Uma linha de quadradinhos: proporção de chegadas sobre inscritos (máx. 48).
  defp cells(%{total: 0}), do: List.duplicate(false, 24)

  defp cells(%{total: total, checked_in: checked}) do
    n = min(total, 48)
    on = round(checked / total * n)
    List.duplicate(true, on) ++ List.duplicate(false, n - on)
  end
end
