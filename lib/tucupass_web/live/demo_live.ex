defmodule TucupassWeb.DemoLive do
  @moduledoc "Painel público (modo projetor) do evento simulado `demo`."
  use TucupassWeb, :live_view

  alias Tucupass.Events
  alias TucupassWeb.Board

  @impl true
  def mount(_params, _session, socket) do
    case Events.get_event_by_slug(Tucupass.Demo.slug()) do
      nil ->
        {:ok, socket |> put_flash(:error, "Demo indisponível.") |> push_navigate(to: ~p"/")}

      event ->
        if connected?(socket), do: Board.subscribe(event)

        {:ok, socket |> assign(page_title: "Painel ao vivo", event: event) |> load()}
    end
  end

  defp load(socket), do: assign(socket, Board.snapshot(socket.assigns.event))

  @impl true
  def handle_info({tag, _}, socket) when tag in [:registered, :checked_in, :reset],
    do: {:noreply, load(socket)}

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket),
    do: {:noreply, load(socket)}

  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} wide>
      <h1 class="text-5xl sm:text-7xl">Painel ao vivo</h1>
      <p class="max-w-prose opacity-80">
        É a tela que a organização projeta na entrada. Aqui roda com gente fictícia, e cada
        inscrição ou check-in feito por você aparece na hora.
      </p>
      <Board.live_board event={@event} stats={@stats} recent={@recent} scanners={@scanners} simulated />
      <div class="flex flex-wrap gap-4 pt-2">
        <.link navigate={~p"/e/demo"} class="cta">Entrar no evento</.link>
        <.link navigate={~p"/demo/checkin"} class="cta cta--ghost">Abrir o leitor</.link>
      </div>
    </Layouts.app>
    """
  end
end
