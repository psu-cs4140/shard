defmodule Shard.Game.Character do
  use Ecto.Schema
  import Ecto.Changeset

  schema "characters" do
    field :name, :string
    belongs_to :current_room, Shard.World.Room
    timestamps()
  end

  def changeset(c, attrs) do
    c
    |> cast(attrs, ~w[name current_room_id]a)
    |> validate_required([:name, :current_room_id])
  end
end
