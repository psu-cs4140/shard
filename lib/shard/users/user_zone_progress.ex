defmodule Shard.Users.UserZoneProgress do
  @moduledoc """
  Tracks a user's progress through different zones in the game.

  Progress states:
  - "locked" - Zone is not yet accessible to the user
  - "in_progress" - Zone is accessible and user has started exploring
  - "completed" - User has completed all objectives in the zone
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "user_zone_progress" do
    field :progress, :string, default: "locked"

    belongs_to :user, Shard.Users.User
    belongs_to :zone, Shard.Map.Zone

    timestamps(type: :utc_datetime)
  end

  @progress_states ~w(locked in_progress completed)

  @doc false
  def changeset(user_zone_progress, attrs) do
    user_zone_progress
    |> cast(attrs, [:progress, :user_id, :zone_id])
    |> validate_required([:progress, :user_id, :zone_id])
    |> validate_inclusion(:progress, @progress_states)
    |> unique_constraint([:user_id, :zone_id], name: :user_zone_progress_user_id_zone_id_index)
  end

  def progress_states, do: @progress_states

  @doc """
  Creates initial zone progress records for a new user.
  All zones start as "locked" except for any starter zones.
  """
  def initialize_for_user(user_id, starter_zone_ids \\ []) do
    alias Shard.{Map, Repo}

    zones = Repo.all(Map.Zone)

    progress_records =
      Enum.map(zones, fn zone ->
        progress = if zone.id in starter_zone_ids, do: "in_progress", else: "locked"

        %{
          user_id: user_id,
          zone_id: zone.id,
          progress: progress,
          inserted_at: DateTime.utc_now() |> DateTime.truncate(:second),
          updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
        }
      end)

    Repo.insert_all(__MODULE__, progress_records, on_conflict: :nothing)
  end

  @doc """
  Gets all zone progress for a user, ordered by zone name.
  """
  def for_user(user_id) do
    alias Shard.{Map, Repo}

    Repo.all(
      from uzp in __MODULE__,
        join: z in Map.Zone,
        on: uzp.zone_id == z.id,
        where: uzp.user_id == ^user_id,
        order_by: z.name,
        preload: [:zone]
    )
  end

  @doc """
  Updates progress for a specific user and zone.
  """
  def update_progress(user_id, zone_id, new_progress) when new_progress in @progress_states do
    alias Shard.Repo

    case Repo.get_by(__MODULE__, user_id: user_id, zone_id: zone_id) do
      nil ->
        %__MODULE__{}
        |> changeset(%{user_id: user_id, zone_id: zone_id, progress: new_progress})
        |> Repo.insert()

      existing ->
        existing
        |> changeset(%{progress: new_progress})
        |> Repo.update()
    end
  end
end
