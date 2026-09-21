defmodule TucupassWeb.FlowTest do
  use TucupassWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Tucupass.Fixtures

  alias Tucupass.Events

  setup do: %{event: event_fixture(%{name: "Meetup Norte"})}

  defp organizer(conn) do
    conn |> Plug.Test.init_test_session(%{organizer: true})
  end

  test "inscrição gera ingresso com QR e redireciona", %{conn: conn, event: event} do
    {:ok, lv, _} = live(conn, ~p"/e/#{event.slug}")

    assert lv |> form("#registration-form", attendee: %{name: "", email: "x"}) |> render_change() =~
             "e-mail inválido"

    {:ok, _ticket, html} =
      lv
      |> form("#registration-form", attendee: %{name: "Ana", email: "ana@example.com"})
      |> render_submit()
      |> follow_redirect(conn)

    assert html =~ "Ana"
    assert html =~ "<svg"
    assert html =~ "Meetup Norte"
  end

  test "inscrição é limitada por IP", %{conn: conn, event: event} do
    ip = "203.0.113.#{System.unique_integer([:positive])}"
    conn = put_req_header(conn, "x-forwarded-for", ip)

    submit = fn n ->
      {:ok, lv, _} = live(conn, ~p"/e/#{event.slug}")

      lv
      |> form("#registration-form", attendee: %{name: "P#{n}", email: "p#{n}@example.com"})
      |> render_submit()
    end

    for n <- 1..5, do: submit.(n)
    assert submit.(6) =~ "Muitas inscrições"
    assert Events.stats(event).total == 5
  end

  test "evento demo não envia e-mail", %{conn: conn} do
    {:ok, demo} = Events.create_event(%{name: "Demo", slug: "demo"})

    conn =
      put_req_header(conn, "x-forwarded-for", "198.51.100.#{System.unique_integer([:positive])}")

    {:ok, lv, _} = live(conn, ~p"/e/#{demo.slug}")

    lv
    |> form("#registration-form", attendee: %{name: "Zé", email: "ze@example.com"})
    |> render_submit()

    assert_redirect(lv)
    refute_received {:swoosh_email, _}
    assert Events.stats(demo).total == 1
  end

  test "evento inexistente redireciona pra home", %{conn: conn} do
    assert {:error, {:live_redirect, %{to: "/"}}} = live(conn, ~p"/e/nao-existe")
  end

  test "ingresso vira 'Check-in feito' ao vivo", %{conn: conn, event: event} do
    a = attendee_fixture(event)
    {:ok, lv, html} = live(conn, ~p"/t/#{a.ticket_token}")
    refute html =~ "Carimbado"

    {:ok, :checked_in, _} = Events.check_in(event, a.ticket_token)
    assert render(lv) =~ "Carimbado"
  end

  test "check-in e dashboard exigem chave de organização", %{conn: conn, event: event} do
    assert conn |> get(~p"/e/#{event.slug}/checkin") |> response(403)
    assert conn |> get(~p"/e/#{event.slug}/dashboard") |> response(403)
    assert conn |> get(~p"/e/#{event.slug}/dashboard?key=errada") |> response(403)

    key = Application.fetch_env!(:tucupass, :organizer_key)
    conn = get(conn, ~p"/e/#{event.slug}/dashboard?key=#{key}")
    assert redirected_to(conn) == "/e/#{event.slug}/dashboard"
    assert conn |> recycle() |> get(~p"/e/#{event.slug}/dashboard") |> html_response(200)
  end

  test "scan faz check-in, detecta repetição e token inválido", %{conn: conn, event: event} do
    a = attendee_fixture(event, %{name: "Beto"})
    {:ok, lv, _} = conn |> organizer() |> live(~p"/e/#{event.slug}/checkin")

    assert render_hook(lv, "scan", %{"token" => a.ticket_token}) =~ "Check-in feito"
    assert render(lv) =~ "1 de 1 já chegaram"
    assert render_hook(lv, "scan", %{"token" => a.ticket_token}) =~ "Já entrou"
    assert render_hook(lv, "scan", %{"token" => "lixo"}) =~ "Ingresso inválido"
    assert render_hook(lv, "camera-error", %{"message" => "negado"}) =~ "Câmera indisponível"
  end

  test "dashboard atualiza em tempo real com check-ins e leitores", %{conn: conn, event: event} do
    a = attendee_fixture(event, %{name: "Caio"})
    _b = attendee_fixture(event)

    {:ok, dash, html} = conn |> organizer() |> live(~p"/e/#{event.slug}/dashboard")
    assert html =~ "Ninguém chegou ainda"
    assert has_element?(dash, "#stat-total", "2")

    {:ok, scanner, _} = conn |> organizer() |> live(~p"/e/#{event.slug}/checkin")
    render_hook(scanner, "scan", %{"token" => a.ticket_token})

    assert render(dash) =~ "Caio"
    assert has_element?(dash, "#stat-checked-in", "1")
    assert has_element?(dash, "#stat-rate", "50.0%")

    # presence propaga de forma assíncrona
    assert eventually(fn -> has_element?(dash, "#stat-scanners", "1") end)
  end

  defp eventually(fun, tries \\ 20) do
    cond do
      fun.() -> true
      tries == 0 -> false
      true -> Process.sleep(50) && eventually(fun, tries - 1)
    end
  end
end
