defmodule TucupassWeb.EventLive.Register do
  use TucupassWeb, :live_view

  alias Tucupass.Events
  alias Tucupass.Events.Attendee

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case Events.get_event_by_slug(slug) do
      nil ->
        {:ok, socket |> put_flash(:error, "Evento não encontrado.") |> push_navigate(to: ~p"/")}

      event ->
        {:ok,
         socket
         |> assign(page_title: event.name, event: event, client_ip: client_ip(socket))
         |> assign_form(Events.change_registration(%Attendee{}))}
    end
  end

  @impl true
  def handle_event("validate", %{"attendee" => params}, socket) do
    changeset =
      %Attendee{} |> Events.change_registration(params) |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @window :timer.minutes(10)
  @per_ip 5

  def handle_event("save", %{"attendee" => params}, socket) do
    with :ok <- Tucupass.RateLimit.hit({:register, socket.assigns.client_ip}, @per_ip, @window),
         {:ok, attendee} <- register(socket.assigns.event, params) do
      {:noreply, push_navigate(socket, to: ~p"/t/#{attendee.ticket_token}")}
    else
      {:error, :rate_limited} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Muitas inscrições deste endereço. Tente de novo em alguns minutos."
         )}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  # No evento demo ninguém recebe e-mail: a inscrição é só pra testar o fluxo.
  defp register(event, params),
    do: Events.register(event, params, notify: event.slug != Tucupass.Demo.slug())

  # IP do cliente; atrás de proxy (Fly, etc.) vale o primeiro X-Forwarded-For.
  defp client_ip(socket) do
    forwarded =
      socket
      |> get_connect_info(:x_headers)
      |> List.wrap()
      |> Enum.find_value(fn {k, v} -> if k == "x-forwarded-for", do: v end)

    case {forwarded, get_connect_info(socket, :peer_data)} do
      {ip, _} when is_binary(ip) -> ip |> String.split(",") |> hd() |> String.trim()
      {_, %{address: address}} -> address |> :inet.ntoa() |> to_string()
      _ -> "unknown"
    end
  end

  defp assign_form(socket, changeset), do: assign(socket, form: to_form(changeset, as: :attendee))

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1 class="text-4xl sm:text-6xl">{@event.name}</h1>
      <p :if={@event.starts_at || @event.location} class="opacity-70">
        <span :if={@event.starts_at}>
          {Tucupass.Clock.format(@event.starts_at, "%d/%m/%Y %H:%M")}
        </span>
        <span :if={@event.location}> · {@event.location}</span>
      </p>

      <p :if={@event.slug == "demo"} class="mono text-xs opacity-70">
        Evento de demonstração: seu nome aparece no painel público quando você fizer check-in, e
        tudo é apagado depois de algumas horas.
      </p>

      <.form for={@form} id="registration-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Nome" autocomplete="name" phx-debounce="300" />
        <.input
          field={@form[:email]}
          type="email"
          label="E-mail"
          autocomplete="email"
          phx-debounce="300"
        />
        <button type="submit" class="cta" phx-disable-with="Emitindo...">
          Emitir meu ingresso
        </button>
      </.form>
    </Layouts.app>
    """
  end
end
