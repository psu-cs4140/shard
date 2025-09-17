defmodule World.Room do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :x, :integer
    field :y, :integer
    timestamps()
  end

  def changeset(room, attrs) do
    room
    |> cast(attrs, [:name, :slug, :description, :x, :y])
    |> validate_required([:name])
  end
end
