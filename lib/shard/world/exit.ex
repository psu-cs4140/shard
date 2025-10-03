defmodule Shard.World.Exit do
  use Ecto.Schema
  import Ecto.Changeset
  alias Shard.World.Room

  schema "exits" do
    field :dir, :string
    belongs_to :from_room, Room, foreign_key: :from_room_id
    belongs_to :to_room, Room, foreign_key: :to_id
    timestamps()
  end

  def changeset(exit, attrs) do
    exit
    |> cast(attrs, [:dir, :from_room_id, :to_id])
    |> validate_required([:dir, :from_room_id, :to_id])
    |> foreign_key_constraint(:from_room_id)
    |> foreign_key_constraint(:to_id)
  end
end
