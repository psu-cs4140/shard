defmodule Shard.Weapons.WeaponEnchantments do
  use Ecto.Schema
  import Ecto.Changeset

  schema "weapon_enchantments" do

    field :weapon_id, :id
    field :enchantment_id, :id


    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(weapon_enchantments, attrs, user_scope) do
    weapon_enchantments
    |> cast(attrs, [])
    |> validate_required([])

  end
end
