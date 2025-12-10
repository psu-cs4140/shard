defmodule Shard.WorldEvents.WorldEvent do
  use Ecto.Schema
  import Ecto.Changeset

  schema "world_events" do
    field :event_type, :string
    field :title, :string
    field :description, :string
    field :room_id, :id
    field :is_active, :boolean, default: true
    field :duration_minutes, :integer
    field :started_at, :utc_datetime
    field :ended_at, :utc_datetime
    field :data, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(world_event, attrs) do
    world_event
    |> cast(attrs, [
      :event_type,
      :title,
      :description,
      :room_id,
      :is_active,
      :duration_minutes,
      :started_at,
      :ended_at,
      :data
    ])
    |> validate_required([:event_type, :title, :description])
    |> validate_inclusion(:event_type, [
      "boss_spawn",
      "treasure_chest",
      "merchant_visit",
      "weather_event",
      "portal_opening"
    ])
    |> validate_length(:title, min: 1, max: 100)
    |> validate_length(:description, min: 1, max: 500)
    |> put_started_at()
  end

  defp put_started_at(changeset) do
    case get_field(changeset, :started_at) do
      nil -> put_change(changeset, :started_at, DateTime.utc_now())
      _ -> changeset
    end
  end

  @doc """
  Returns true if the event is still active based on duration.
  """
  def active?(%__MODULE__{} = event) do
    cond do
      not event.is_active ->
        false

      is_nil(event.duration_minutes) ->
        true

      is_nil(event.started_at) ->
        true

      true ->
        end_time = DateTime.add(event.started_at, event.duration_minutes * 60, :second)
        DateTime.compare(DateTime.utc_now(), end_time) == :lt
    end
  end

  @doc """
  Returns the remaining time in minutes for the event.
  """
  def remaining_minutes(%__MODULE__{} = event) do
    cond do
      not event.is_active ->
        0

      is_nil(event.duration_minutes) ->
        nil

      is_nil(event.started_at) ->
        event.duration_minutes

      true ->
        end_time = DateTime.add(event.started_at, event.duration_minutes * 60, :second)
        diff_seconds = DateTime.diff(end_time, DateTime.utc_now(), :second)
        max(0, div(diff_seconds, 60))
    end
  end
end
