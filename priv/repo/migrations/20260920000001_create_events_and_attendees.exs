defmodule Tucupass.Repo.Migrations.CreateEventsAndAttendees do
  use Ecto.Migration

  def change do
    create table(:events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :starts_at, :utc_datetime
      add :location, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:events, [:slug])

    create table(:attendees, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :event_id, references(:events, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :email, :string, null: false
      add :ticket_token, :uuid, null: false
      add :checked_in_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:attendees, [:ticket_token])
    create unique_index(:attendees, [:event_id, :email])
    create index(:attendees, [:event_id, :checked_in_at])
  end
end
