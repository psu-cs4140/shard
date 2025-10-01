defmodule Shard.Weapons.Rarities do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rarities" do
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(rarities, attrs, user_scope) do
    rarities
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
