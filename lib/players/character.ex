defmodule Players.Character do
  use Ecto.Schema
  import Ecto.Changeset

  schema "characters" do
    field :name, :string
    field :current_room_id, :id
    timestamps()
  end

  def changeset(char, attrs) do
    char
    |> cast(attrs, [:name, :current_room_id])
    |> validate_required([:name])
  end
end
