defmodule TucupassWeb.TicketLive do
  use TucupassWeb, :live_view

  alias Tucupass.{Events, Tickets}

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    case Events.get_attendee_by_token(token) do
      {:ok, attendee} ->
        if connected?(socket), do: Events.subscribe(attendee.event)

        {:ok,
         assign(socket,
           page_title: "Ingresso · #{attendee.event.name}",
           attendee: attendee,
           qr: Tickets.qr_svg(attendee)
         )}

      :error ->
        {:ok, socket |> put_flash(:error, "Ingresso não encontrado.") |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def handle_info({:checked_in, %{id: id} = updated}, %{assigns: %{attendee: %{id: id}}} = socket) do
    {:noreply,
     assign(socket, attendee: %{socket.assigns.attendee | checked_in_at: updated.checked_in_at})}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <article id="ticket" class="stub stub--tucupi rise">
        <div class="stub__main">
          <p class="label">Ingresso · admite uma pessoa</p>
          <h1 class="mt-3 text-5xl sm:text-6xl">{@attendee.event.name}</h1>
          <p class="mt-5 text-2xl font-bold break-words">{@attendee.name}</p>
          <p class="label mt-1 break-all">{@attendee.email}</p>
          <p :if={@attendee.event.starts_at || @attendee.event.location} class="label mt-4">
            <span :if={@attendee.event.starts_at}>
              {Tucupass.Clock.format(@attendee.event.starts_at, "%d/%m/%Y %H:%M")}
            </span>
            <span :if={@attendee.event.location}> · {@attendee.event.location}</span>
          </p>
          <p :if={@attendee.checked_in_at} id="ticket-status" class="mt-6 display text-3xl">
            Carimbado. Pode entrar.
          </p>
          <p :if={!@attendee.checked_in_at} id="ticket-status" class="label mt-6">
            <%= if @attendee.event.slug == "demo" do %>
              Ingresso de demonstração. Nenhum e-mail é enviado.
            <% else %>
              Mostre o QR na entrada. Copiamos o ingresso no seu e-mail.
            <% end %>
          </p>
        </div>
        <div class="stub__side">
          <div id="ticket-qr" class="bg-white p-1.5 w-full">{raw(@qr)}</div>
          <p class="label">leia aqui</p>
        </div>
      </article>
      <p :if={@attendee.event.slug == "demo"} class="mono text-xs opacity-70">
        Dica: abra o <.link navigate={~p"/demo"} class="underline">painel</.link>
        numa aba e o <.link navigate={~p"/demo/checkin"} class="underline">leitor</.link>
        em outro aparelho, e aponte a câmera pra este QR.
      </p>
    </Layouts.app>
    """
  end
end
