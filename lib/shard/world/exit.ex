defmodule Shard.World.Exit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "exits" do
    field :dir, :string
    belongs_to :from_room, Shard.World.Room
    belongs_to :to_room, Shard.World.Room
    timestamps()
  end

  def changeset(exit, attrs) do
    exit
    |> cast(attrs, ~w[dir from_room_id to_room_id]a)
    |> validate_required([:dir, :from_room_id, :to_room_id])
  end
end
