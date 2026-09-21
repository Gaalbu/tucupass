alias Tucupass.Events

unless Events.get_event_by_slug("demo") do
  {:ok, _} =
    Events.create_event(%{
      name: "Meetup Devs Norte (demo)",
      slug: "demo",
      starts_at: DateTime.utc_now(:second) |> DateTime.add(7, :day),
      location: "Belém, PA"
    })
end
