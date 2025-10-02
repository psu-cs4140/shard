defmodule Shard.Weapons.Weapons do
  use Ecto.Schema
  import Ecto.Changeset

  schema "weapons" do
    field :name, :string
    field :damage, :integer
    field :gold_value, :integer
    field :description, :string
    field :weapon_class_id, :id
    field :rarity_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(weapons, attrs) do
    weapons
    |> cast(attrs, [:name, :damage, :gold_value, :description, :weapon_class_id, :rarity_id])
    |> validate_required([:name, :damage, :gold_value, :description])
    |> foreign_key_constraint(:weapon_class_id)
    |> foreign_key_constraint(:rarity_id)
  end
end
