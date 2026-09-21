defmodule Tucupass.Events do
  @moduledoc "Eventos, inscrição, ingressos e check-in."

  import Ecto.Query, warn: false

  alias Tucupass.Repo
  alias Tucupass.Events.{Attendee, Event}
  alias Tucupass.Tickets

  @pubsub Tucupass.PubSub

  ## Eventos

  def create_event(attrs), do: %Event{} |> Event.changeset(attrs) |> Repo.insert()
  def change_event(%Event{} = event, attrs \\ %{}), do: Event.changeset(event, attrs)
  def get_event_by_slug(slug), do: Repo.get_by(Event, slug: slug)
  def list_events, do: Repo.all(from e in Event, order_by: [asc: e.starts_at, asc: e.name])

  ## Inscrição

  def change_registration(%Attendee{} = attendee, attrs \\ %{}),
    do: Attendee.registration_changeset(attendee, attrs)

  @doc """
  Inscreve alguém no evento, gera o ticket (UUID) e dispara o e-mail com o QR
  (`notify: false` pula o e-mail; usado pela simulação da demo).
  O e-mail é enviado depois do commit; falha de envio não desfaz a inscrição.
  """
  def register(%Event{} = event, attrs, opts \\ []) do
    result =
      %Attendee{event_id: event.id}
      |> Attendee.registration_changeset(attrs)
      |> Repo.insert()

    with {:ok, attendee} <- result do
      broadcast(event.id, {:registered, attendee})
      if Keyword.get(opts, :notify, true), do: Tickets.deliver_ticket(event, attendee)
      {:ok, attendee}
    end
  end

  def get_attendee_by_token(token) do
    with {:ok, uuid} <- Ecto.UUID.cast(token),
         %Attendee{} = attendee <- Repo.get_by(Attendee, ticket_token: uuid) do
      {:ok, Repo.preload(attendee, :event)}
    else
      _ -> :error
    end
  end

  ## Check-in

  @doc """
  Check-in idempotente e seguro sob concorrência: `SELECT ... FOR UPDATE` no
  ingresso serializa dois leitores lendo o mesmo QR.

  Retorna `{:ok, :checked_in | :already_checked_in, attendee}` ou
  `{:error, :invalid_token | :wrong_event}`.
  """
  def check_in(%Event{} = event, token) do
    with {:ok, uuid} <- Ecto.UUID.cast(token) do
      Repo.transaction(fn ->
        query = from a in Attendee, where: a.ticket_token == ^uuid, lock: "FOR UPDATE"

        case Repo.one(query) do
          nil ->
            Repo.rollback(:invalid_token)

          %Attendee{event_id: other} when other != event.id ->
            Repo.rollback(:wrong_event)

          %Attendee{checked_in_at: nil} = attendee ->
            now = DateTime.utc_now(:second)
            {:checked_in, attendee |> Ecto.Changeset.change(checked_in_at: now) |> Repo.update!()}

          %Attendee{} = attendee ->
            {:already_checked_in, attendee}
        end
      end)
      |> case do
        {:ok, {:checked_in, attendee}} ->
          broadcast(event.id, {:checked_in, attendee})
          {:ok, :checked_in, attendee}

        {:ok, {:already_checked_in, attendee}} ->
          {:ok, :already_checked_in, attendee}

        {:error, reason} ->
          {:error, reason}
      end
    else
      :error -> {:error, :invalid_token}
    end
  end

  ## Dashboard

  def stats(%Event{id: id}) do
    {total, checked_in} =
      Repo.one(
        from a in Attendee,
          where: a.event_id == ^id,
          select: {count(a.id), count(a.checked_in_at)}
      )

    rate = if total == 0, do: 0.0, else: Float.round(checked_in / total * 100, 1)
    %{total: total, checked_in: checked_in, pending: total - checked_in, rate: rate}
  end

  def recent_check_ins(%Event{id: id}, limit \\ 10) do
    Repo.all(
      from a in Attendee,
        where: a.event_id == ^id and not is_nil(a.checked_in_at),
        order_by: [desc: a.checked_in_at, desc: a.updated_at],
        limit: ^limit
    )
  end

  ## PubSub

  def subscribe(%Event{id: id}), do: Phoenix.PubSub.subscribe(@pubsub, topic(id))
  defp broadcast(event_id, msg), do: Phoenix.PubSub.broadcast(@pubsub, topic(event_id), msg)
  defp topic(event_id), do: "event:#{event_id}"
end
