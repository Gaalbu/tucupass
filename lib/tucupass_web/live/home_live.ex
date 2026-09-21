defmodule TucupassWeb.HomeLive do
  use TucupassWeb, :live_view

  alias Tucupass.Events
  alias TucupassWeb.Board

  @impl true
  def mount(_params, _session, socket) do
    event = Events.get_event_by_slug(Tucupass.Demo.slug())
    if event && connected?(socket), do: Board.subscribe(event)

    socket =
      assign(socket, page_title: "Check-in ao vivo para eventos de comunidade", event: event)

    {:ok, if(event, do: load(socket), else: socket)}
  end

  defp load(socket), do: assign(socket, Board.snapshot(socket.assigns.event, 6))

  @impl true
  def handle_info({tag, _}, %{assigns: %{event: %{}}} = socket)
      when tag in [:registered, :checked_in, :reset],
      do: {:noreply, load(socket)}

  def handle_info(
        %Phoenix.Socket.Broadcast{event: "presence_diff"},
        %{assigns: %{event: %{}}} = socket
      ),
      do: {:noreply, load(socket)}

  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} wide>
      <section class="pt-4 sm:pt-10 space-y-8">
        <h1 class="rise text-[clamp(4.5rem,17vw,13rem)]">
          Tucu<br /><span class="text-[var(--tucupi)]">pass</span>
        </h1>
        <p class="rise rise-2 max-w-2xl text-xl sm:text-2xl leading-snug">
          Inscrição, ingresso com QR e check-in na porta, com a organização vendo cada chegada
          acontecer. Feito para eventos de comunidade, começando pelos do Devs Norte.
        </p>
        <div class="rise rise-3 flex flex-wrap gap-4">
          <.link navigate={~p"/e/demo"} class="cta">Pegar meu ingresso</.link>
          <.link navigate={~p"/demo"} class="cta cta--ghost">Ver o painel em tela cheia</.link>
        </div>
      </section>

      <div :if={@event} class="rise rise-3 pt-6">
        <Board.live_board
          event={@event}
          stats={@stats}
          recent={@recent}
          scanners={@scanners}
          simulated
        />
      </div>

      <section class="pt-16 space-y-6">
        <h2 class="text-4xl sm:text-6xl">Três telas, um fluxo</h2>
        <div class="space-y-6">
          <article class="stub" style="transform: rotate(-0.6deg)">
            <div class="stub__main">
              <h3 class="text-5xl">Entra</h3>
              <p class="mt-3 text-lg max-w-md">
                Nome e e-mail. Sem conta, sem senha, sem passo a mais.
              </p>
            </div>
            <div class="stub__side"><span class="display text-7xl text-[var(--tinta)]">A</span></div>
          </article>
          <article class="stub stub--tucupi sm:ml-16" style="transform: rotate(0.5deg)">
            <div class="stub__main">
              <h3 class="text-5xl">Recebe</h3>
              <p class="mt-3 text-lg max-w-md">
                Ingresso com QR único, por e-mail e na tela. O QR carrega só um código, nada
                pessoal.
              </p>
            </div>
            <div class="stub__side"><span class="display text-7xl text-[var(--tinta)]">B</span></div>
          </article>
          <article class="stub sm:mr-16" style="transform: rotate(-0.3deg)">
            <div class="stub__main">
              <h3 class="text-5xl">Passa</h3>
              <p class="mt-3 text-lg max-w-md">
                A câmera do celular de quem organiza lê o QR e carimba na hora. Ler duas vezes
                só confirma; dois leitores no mesmo ingresso não duplicam.
              </p>
            </div>
            <div class="stub__side"><span class="display text-7xl text-[var(--tinta)]">C</span></div>
          </article>
        </div>
      </section>

      <section class="pt-16 pb-6 border-t-2 border-base-content/30 space-y-5">
        <p class="display text-4xl sm:text-6xl">
          Teste de verdade: inscreva-se, abra o painel numa aba e o leitor em outro aparelho.
        </p>
        <div class="flex flex-wrap gap-4">
          <.link navigate={~p"/e/demo"} class="cta">Começar</.link>
          <.link navigate={~p"/demo/checkin"} class="cta cta--ghost">Abrir o leitor</.link>
        </div>
        <p class="mono text-xs opacity-70 pt-6">
          Elixir, Phoenix LiveView e Postgres · o evento demo usa gente fictícia
        </p>
      </section>
    </Layouts.app>
    """
  end
end
