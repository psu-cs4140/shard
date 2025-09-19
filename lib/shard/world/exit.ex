defmodule Shard.World.Exit do
  use Ecto.Schema

  schema "exits" do
    field :dir, :string
    belongs_to :from_room, Shard.World.Room
    belongs_to :to_room, Shard.World.Room
    timestamps()
  end

  def changeset(exit, attrs) do
    exit
    |> Ecto.Changeset.cast(attrs, [:dir, :from_room_id, :to_room_id])
    |> Ecto.Changeset.validate_required([:dir, :from_room_id, :to_room_id])
    |> Ecto.Changeset.validate_inclusion(:dir, ~w(n s e w up down))
    |> Ecto.Changeset.foreign_key_constraint(:from_room_id)
    |> Ecto.Changeset.foreign_key_constraint(:to_room_id)
    |> Ecto.Changeset.unique_constraint(:dir, name: :exits_from_room_id_dir_index)
  end
end
