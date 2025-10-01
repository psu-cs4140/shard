defmodule Shard.Weapons.DamageTypes do
  use Ecto.Schema
  import Ecto.Changeset

  schema "damage_types" do
    field :name, :string
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(damage_types, attrs, user_scope) do
    damage_types
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> put_change(:user_id, user_scope.user.id)
  end
end
