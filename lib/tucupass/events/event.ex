defmodule Tucupass.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "events" do
    field :name, :string
    field :slug, :string
    field :starts_at, :utc_datetime
    field :location, :string

    has_many :attendees, Tucupass.Events.Attendee

    timestamps(type: :utc_datetime)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:name, :slug, :starts_at, :location])
    |> validate_required([:name, :slug])
    |> validate_format(:slug, ~r/^[a-z0-9]+(-[a-z0-9]+)*$/,
      message: "use minúsculas, números e hífens"
    )
    |> unique_constraint(:slug)
  end
end
