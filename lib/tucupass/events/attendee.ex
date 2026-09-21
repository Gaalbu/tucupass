defmodule Tucupass.Events.Attendee do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "attendees" do
    field :name, :string
    field :email, :string
    field :ticket_token, Ecto.UUID, autogenerate: true
    field :checked_in_at, :utc_datetime

    belongs_to :event, Tucupass.Events.Event

    timestamps(type: :utc_datetime)
  end

  def registration_changeset(attendee, attrs) do
    attendee
    |> cast(attrs, [:name, :email])
    |> update_change(:name, &String.trim/1)
    |> update_change(:email, &(&1 |> String.trim() |> String.downcase()))
    |> validate_required([:name, :email])
    |> validate_length(:name, max: 160)
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, message: "e-mail inválido")
    |> validate_length(:email, max: 254)
    |> unique_constraint(:email,
      name: :attendees_event_id_email_index,
      message: "já inscrito neste evento"
    )
  end
end
