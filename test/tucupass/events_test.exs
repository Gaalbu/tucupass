defmodule Tucupass.EventsTest do
  use Tucupass.DataCase, async: false

  import Swoosh.TestAssertions
  import Tucupass.Fixtures

  alias Tucupass.Events

  setup do: %{event: event_fixture()}

  describe "register/2" do
    test "cria inscrito com ticket_token e envia e-mail com QR", %{event: event} do
      assert {:ok, a} = Events.register(event, %{name: " Ana ", email: "ANA@Example.com"})
      assert a.name == "Ana"
      assert a.email == "ana@example.com"
      assert {:ok, _} = Ecto.UUID.cast(a.ticket_token)
      assert_email_sent(subject: "Seu ingresso: #{event.name}", to: {"Ana", "ana@example.com"})
    end

    test "rejeita e-mail inválido e duplicado", %{event: event} do
      assert {:error, cs} = Events.register(event, %{name: "X", email: "nope"})
      assert %{email: ["e-mail inválido"]} = errors_on(cs)

      attendee_fixture(event, %{email: "dup@example.com"})
      assert {:error, cs} = Events.register(event, %{name: "Y", email: "dup@example.com"})
      assert %{email: ["já inscrito neste evento"]} = errors_on(cs)
    end
  end

  describe "check_in/2" do
    test "é idempotente", %{event: event} do
      a = attendee_fixture(event)
      assert {:ok, :checked_in, first} = Events.check_in(event, a.ticket_token)
      assert {:ok, :already_checked_in, again} = Events.check_in(event, a.ticket_token)
      assert first.checked_in_at == again.checked_in_at
      assert %{total: 1, checked_in: 1, rate: 100.0} = Events.stats(event)
    end

    test "rejeita token inválido, desconhecido e de outro evento", %{event: event} do
      assert {:error, :invalid_token} = Events.check_in(event, "lixo")
      assert {:error, :invalid_token} = Events.check_in(event, Ecto.UUID.generate())

      outro = attendee_fixture(event_fixture())
      assert {:error, :wrong_event} = Events.check_in(event, outro.ticket_token)
    end

    test "dois leitores simultâneos: só um faz o check-in", %{event: event} do
      a = attendee_fixture(event)
      parent = self()

      results =
        for _ <- 1..8 do
          Task.async(fn ->
            Ecto.Adapters.SQL.Sandbox.allow(Tucupass.Repo, parent, self())
            Events.check_in(event, a.ticket_token)
          end)
        end
        |> Task.await_many()

      assert Enum.count(results, &match?({:ok, :checked_in, _}, &1)) == 1
      assert Enum.count(results, &match?({:ok, :already_checked_in, _}, &1)) == 7
    end

    test "transmite check-in via PubSub", %{event: event} do
      a = attendee_fixture(event)
      Events.subscribe(event)
      {:ok, :checked_in, _} = Events.check_in(event, a.ticket_token)
      assert_receive {:checked_in, %{id: id}}
      assert id == a.id
    end
  end

  test "stats/1 sem inscritos", %{event: event} do
    assert %{total: 0, checked_in: 0, rate: +0.0} = Events.stats(event)
  end
end
