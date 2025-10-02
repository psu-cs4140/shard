defmodule Shard.Weapons.WeaponEnchantments do
  use Ecto.Schema
  import Ecto.Changeset

  schema "weapon_enchantments" do
    field :weapon_id, :id
    field :enchantment_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(weapon_enchantments, attrs) do
    weapon_enchantments
    |> cast(attrs, [:weapon_id, :enchantment_id])
    |> validate_required([:weapon_id, :enchantment_id])
  end
end
