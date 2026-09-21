defmodule TucupassWeb.CheckinLive do
  use TucupassWeb, :live_view

  alias Tucupass.Events
  alias TucupassWeb.Presence

  @impl true
  def mount(params, _session, socket) do
    slug = params["slug"] || Tucupass.Demo.slug()

    case Events.get_event_by_slug(slug) do
      nil ->
        {:ok, socket |> put_flash(:error, "Evento não encontrado.") |> push_navigate(to: ~p"/")}

      event ->
        if connected?(socket) do
          Presence.track(
            self(),
            presence_topic(event),
            "scanner:#{System.unique_integer([:positive])}",
            %{
              joined_at: System.system_time(:second)
            }
          )
        end

        {:ok,
         assign(socket,
           page_title: "Check-in · #{event.name}",
           event: event,
           stats: Events.stats(event),
           result: nil,
           camera_error: nil
         )}
    end
  end

  def presence_topic(event), do: "presence:#{event.id}:scanners"

  @impl true
  def handle_event("scan", %{"token" => token}, socket) do
    {result, status} =
      case Events.check_in(socket.assigns.event, String.trim(token)) do
        {:ok, :checked_in, a} ->
          {%{kind: :ok, title: "Check-in feito", name: a.name}, "ok"}

        {:ok, :already_checked_in, a} ->
          {%{kind: :warn, title: "Já entrou", name: a.name, at: a.checked_in_at}, "dup"}

        {:error, :wrong_event} ->
          {%{kind: :error, title: "Ingresso de outro evento"}, "error"}

        {:error, _} ->
          {%{kind: :error, title: "Ingresso inválido"}, "error"}
      end

    {:noreply,
     socket
     |> assign(result: result, stats: Events.stats(socket.assigns.event))
     |> push_event("scan-result", %{status: status})}
  end

  def handle_event("camera-error", %{"message" => msg}, socket),
    do: {:noreply, assign(socket, camera_error: msg)}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1 class="text-4xl sm:text-5xl">Check-in</h1>
      <p class="mono text-xs uppercase tracking-wider opacity-70">{@event.name}</p>
      <p class="opacity-70" id="checkin-counter">
        {@stats.checked_in} de {@stats.total} já chegaram
      </p>

      <div
        id="qr-reader"
        phx-hook="Scanner"
        phx-update="ignore"
        class="w-full border-2 border-base-content"
      >
      </div>

      <p :if={@camera_error} id="camera-error" class="alert alert-error">
        Câmera indisponível ({@camera_error}). Use a digitação manual abaixo.
      </p>

      <div :if={@result} id="scan-result" class={["alert", alert_class(@result.kind)]}>
        <div>
          <p class="font-bold">{@result.title}</p>
          <p :if={@result[:name]}>{@result.name}</p>
          <p :if={@result[:at]} class="text-sm">às {Tucupass.Clock.format(@result.at, "%H:%M:%S")}</p>
        </div>
      </div>

      <form id="manual-form" phx-submit="scan" class="flex gap-2">
        <input
          type="text"
          name="token"
          placeholder="Código do ingresso (manual)"
          class="input input-bordered flex-1"
          autocomplete="off"
        />
        <button type="submit" class="cta cta--ghost">Validar</button>
      </form>
    </Layouts.app>
    """
  end

  defp alert_class(:ok), do: "alert-success"
  defp alert_class(:warn), do: "alert-warning"
  defp alert_class(:error), do: "alert-error"
end
