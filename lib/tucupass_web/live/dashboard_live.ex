defmodule TucupassWeb.DashboardLive do
  use TucupassWeb, :live_view

  alias Tucupass.Events
  alias TucupassWeb.{CheckinLive, Presence}

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case Events.get_event_by_slug(slug) do
      nil ->
        {:ok, socket |> put_flash(:error, "Evento não encontrado.") |> push_navigate(to: ~p"/")}

      event ->
        if connected?(socket) do
          Events.subscribe(event)
          Phoenix.PubSub.subscribe(Tucupass.PubSub, CheckinLive.presence_topic(event))
        end

        {:ok,
         assign(socket,
           page_title: "Dashboard · #{event.name}",
           event: event,
           scanners: scanner_count(event)
         )
         |> load()}
    end
  end

  defp load(socket) do
    assign(socket,
      stats: Events.stats(socket.assigns.event),
      recent: Events.recent_check_ins(socket.assigns.event)
    )
  end

  defp scanner_count(event),
    do: event |> CheckinLive.presence_topic() |> Presence.list() |> map_size()

  @impl true
  def handle_info({event, _attendee}, socket) when event in [:registered, :checked_in, :reset],
    do: {:noreply, load(socket)}

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket),
    do: {:noreply, assign(socket, scanners: scanner_count(socket.assigns.event))}

  def handle_info(_msg, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} wide>
      <h1 class="text-4xl sm:text-6xl">{@event.name}</h1>
      <TucupassWeb.Board.live_board
        event={@event}
        stats={@stats}
        recent={@recent}
        scanners={@scanners}
        simulated={@event.slug == "demo"}
      />
    </Layouts.app>
    """
  end
end
