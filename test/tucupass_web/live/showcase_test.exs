defmodule TucupassWeb.ShowcaseTest do
  use TucupassWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Tucupass.{Demo, Events}

  test "home e painel demo sem evento não quebram", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/")
    assert html =~ "pass"
    assert {:error, {:live_redirect, %{to: "/"}}} = live(conn, ~p"/demo")
  end

  describe "com o evento demo" do
    setup do
      {:ok, event} = Events.create_event(%{name: "Demo", slug: Demo.slug()})
      %{event: event}
    end

    test "painel e leitor são públicos e a home mostra o painel", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")
      assert html =~ "já chegaram"
      assert {:ok, _lv, html} = live(conn, ~p"/demo")
      assert html =~ "simulação"
      assert {:ok, _lv, html} = live(conn, ~p"/demo/checkin")
      assert html =~ "Check-in"
    end

    test "simulador inscreve, faz check-in e reinicia no ciclo completo", %{event: event} do
      for _ <- 1..400, do: Demo.step(event)

      # ao completar o ciclo a simulação é apagada e recomeça: nunca passa da meta
      assert %{total: total} = Events.stats(event)
      assert total <= 48
      refute_received {:swoosh_email, _}
    end

    test "painel reage à simulação em tempo real", %{conn: conn, event: event} do
      {:ok, lv, _} = live(conn, ~p"/demo")
      for _ <- 1..30, do: Demo.step(event)
      assert has_element?(lv, "#stat-total")
      assert render(lv) =~ "inscritos"
    end
  end
end
