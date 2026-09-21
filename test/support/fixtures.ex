defmodule Tucupass.Fixtures do
  alias Tucupass.Events

  def event_fixture(attrs \\ %{}) do
    {:ok, event} =
      attrs
      |> Enum.into(%{name: "Meetup", slug: "meetup-#{System.unique_integer([:positive])}"})
      |> Events.create_event()

    event
  end

  def attendee_fixture(event, attrs \\ %{}) do
    {:ok, attendee} =
      Events.register(
        event,
        Enum.into(attrs, %{
          name: "Fulana",
          email: "f#{System.unique_integer([:positive])}@example.com"
        })
      )

    attendee
  end
end
