defmodule Shard.World.Room do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :slug, :string
    field :name, :string
    field :x, :integer, default: 0
    field :y, :integer, default: 0
    field :description, :string, default: ""
    has_many :exits_from, Shard.World.Exit, foreign_key: :from_room_id
    timestamps()
  end

  def changeset(room, attrs) do
    room
    |> cast(attrs, ~w[slug name x y description]a)
    |> validate_required([:slug, :name])
    |> unique_constraint(:slug)
  end
end
