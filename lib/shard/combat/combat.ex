defmodule Shard.Combat.Combat do
  use Ecto.Schema
  import Ecto.Changeset

  schema "combats" do
    field :room_id, :id
    field :started_at, :naive_datetime_usec
    field :ended_at, :naive_datetime_usec
    field :tick_seq, :integer, default: 0
    field :status, :string, default: "active"
    timestamps(updated_at: false)
  end

  def changeset(combat, attrs) do
    combat
    |> cast(attrs, [:room_id, :started_at, :ended_at, :tick_seq, :status])
    |> validate_required([:room_id, :started_at, :status])
  end
end
