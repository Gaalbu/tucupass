defmodule Tucupass.Tickets do
  @moduledoc "QR code do ingresso e e-mail de confirmação."

  import Swoosh.Email
  require Logger

  alias Tucupass.Mailer
  alias Tucupass.Events.{Attendee, Event}

  use Phoenix.VerifiedRoutes,
    endpoint: TucupassWeb.Endpoint,
    router: TucupassWeb.Router,
    statics: TucupassWeb.static_paths()

  def ticket_url(%Attendee{ticket_token: token}), do: url(~p"/t/#{token}")

  @doc "SVG inline do QR (o payload é apenas o `ticket_token`)."
  def qr_svg(%Attendee{ticket_token: token}) do
    token
    |> EQRCode.encode()
    |> EQRCode.svg(width: 256, background_color: "#ffffff", color: "#000000")
  end

  def qr_png(%Attendee{ticket_token: token}) do
    token |> EQRCode.encode() |> EQRCode.png(width: 320)
  end

  def ticket_email(%Event{} = event, %Attendee{} = attendee) do
    link = ticket_url(attendee)

    new()
    |> to({attendee.name, attendee.email})
    |> from({"Tucupass", "ingressos@tucupass.local"})
    |> subject("Seu ingresso: #{event.name}")
    |> text_body("""
    Oi, #{attendee.name}!

    Você está inscrito em #{event.name}#{when_where(event)}.
    Apresente o QR code na entrada: #{link}
    """)
    |> html_body("""
    <p>Oi, #{escape(attendee.name)}!</p>
    <p>Você está inscrito em <strong>#{escape(event.name)}</strong>#{escape(when_where(event))}.</p>
    <p>Apresente este QR code na entrada:</p>
    <p><img src="cid:ingresso.png" width="240" height="240" alt="QR do ingresso"></p>
    <p><a href="#{link}">Abrir meu ingresso</a></p>
    """)
    |> attachment(
      Swoosh.Attachment.new({:data, qr_png(attendee)},
        filename: "ingresso.png",
        content_type: "image/png",
        type: :inline
      )
    )
  end

  def deliver_ticket(%Event{} = event, %Attendee{} = attendee) do
    case event |> ticket_email(attendee) |> Mailer.deliver() do
      {:ok, _} = ok ->
        ok

      {:error, reason} = error ->
        Logger.error("falha ao enviar ingresso #{attendee.id}: #{inspect(reason)}")
        error
    end
  end

  defp when_where(%Event{starts_at: at, location: loc}) do
    parts =
      [at && Tucupass.Clock.format(at, "%d/%m/%Y %H:%M"), loc]
      |> Enum.reject(&is_nil/1)

    if parts == [], do: "", else: " (" <> Enum.join(parts, " · ") <> ")"
  end

  defp escape(text), do: text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
end
