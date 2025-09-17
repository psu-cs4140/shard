defmodule World.Exit do
  use Ecto.Schema
  import Ecto.Changeset

  @dirs ~w(n s e w)

  schema "exits" do
    field :dir, :string
    field :from_room_id, :id
    field :to_room_id, :id
    timestamps()
  end

  def changeset(exit, attrs) do
    exit
    |> cast(attrs, [:dir, :from_room_id, :to_room_id])
    |> validate_required([:dir, :from_room_id, :to_room_id])
    |> validate_inclusion(:dir, @dirs)
  end
end
