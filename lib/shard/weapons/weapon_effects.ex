defmodule Shard.Weapons.WeaponEffects do
  use Ecto.Schema
  import Ecto.Changeset

  schema "weapon_effects" do
    field :weapon_id, :id
    field :effect_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(weapon_effects, attrs) do
    weapon_effects
    |> cast(attrs, [])
    |> validate_required([])
  end
end
