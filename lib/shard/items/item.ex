defmodule Shard.Items.Item do
  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :name, :string
    field :description, :string
    field :item_type, :string
    field :rarity, :string
    field :value, :integer
    field :weight, :float
    field :stackable, :boolean, default: false
    field :max_stack_size, :integer
    field :usable, :boolean, default: false
    field :equippable, :boolean, default: false
    field :equipment_slot, :string
    field :stats, :map
    field :requirements, :map
    field :effects, :map
    field :icon, :string
    field :is_active, :boolean, default: true
    field :pickup, :boolean, default: true
    field :location, :string
    field :map, :string
    field :sellable, :boolean, default: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :name,
      :description,
      :item_type,
      :rarity,
      :value,
      :weight,
      :stackable,
      :max_stack_size,
      :usable,
      :equippable,
      :equipment_slot,
      :stats,
      :requirements,
      :effects,
      :icon,
      :is_active,
      :pickup,
      :location,
      :map,
      :sellable
    ])
    |> validate_required([:name])
  end
end
