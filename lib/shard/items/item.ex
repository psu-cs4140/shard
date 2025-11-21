defmodule Shard.Items.Item do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  New schema for items
  """

  # Define valid item types and rarities
  @item_types [
    "weapon",
    "shield",
    "head",
    "body",
    "legs",
    "feet",
    "ring",
    "necklace",
    "consumable",
    "misc",
    "material",
    "tool",
    "quest"
  ]
  @rarities ["common", "uncommon", "rare", "epic", "legendary"]
  @equipment_slots [
    "head",
    "body",
    "legs",
    "feet",
    "weapon",
    "shield",
    "ring",
    "necklace"
  ]

  # Define valid stat types for weapons and armor
  @weapon_stats [
    "attack_power",
    "critical_chance",
    "critical_damage",
    "attack_speed",
    "accuracy",
    "durability"
  ]
  @armor_stats [
    "defense",
    "magic_resistance",
    "health_bonus",
    "mana_bonus",
    "durability"
  ]
  @general_stats [
    "strength",
    "agility",
    "intelligence",
    "vitality",
    "luck"
  ]

  # Expose these for other modules to use
  def item_types, do: @item_types
  def rarities, do: @rarities
  def equipment_slots, do: @equipment_slots
  def weapon_stats, do: @weapon_stats
  def armor_stats, do: @armor_stats
  def general_stats, do: @general_stats
  def all_stats, do: @weapon_stats ++ @armor_stats ++ @general_stats

  schema "items" do
    field :name, :string
    field :description, :string
    field :item_type, :string
    field :rarity, :string
    field :value, :integer
    field :weight, :decimal
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
    # Added :item_type to required fields
    |> validate_required([:name, :item_type])
    # Validate item_type is in allowed list
    |> validate_inclusion(:item_type, @item_types)
    # Validate rarity is in allowed list
    |> validate_inclusion(:rarity, @rarities)
    # Validate equipment_slot when present
    |> validate_inclusion(:equipment_slot, @equipment_slots)
    # Add unique constraint on name
    |> unique_constraint(:name)
    # Auto-set equippable and equipment_slot for armor pieces
    |> set_equipment_defaults()
    # Validate stats format and values
    |> validate_stats()
  end

  # Automatically set equippable=true and equipment_slot for armor pieces
  defp set_equipment_defaults(changeset) do
    item_type = get_field(changeset, :item_type)

    case item_type do
      type
      when type in ["head", "body", "legs", "feet", "weapon", "shield", "ring", "necklace"] ->
        changeset
        |> put_change(:equippable, true)
        |> maybe_set_equipment_slot(type)

      _ ->
        changeset
    end
  end

  # Set equipment_slot if not already set
  defp maybe_set_equipment_slot(changeset, item_type) do
    current_slot = get_field(changeset, :equipment_slot)

    if is_nil(current_slot) do
      put_change(changeset, :equipment_slot, item_type)
    else
      changeset
    end
  end

  # Validate stats based on item type
  defp validate_stats(changeset) do
    stats = get_field(changeset, :stats)
    item_type = get_field(changeset, :item_type)

    case {stats, item_type} do
      {nil, _} ->
        changeset

      {stats, item_type} when is_map(stats) ->
        validate_stat_values(changeset, stats, item_type)

      _ ->
        add_error(changeset, :stats, "must be a map")
    end
  end

  # Validate individual stat values and types
  defp validate_stat_values(changeset, stats, item_type) do
    valid_stats = get_valid_stats_for_type(item_type)

    Enum.reduce(stats, changeset, fn {stat_name, stat_value}, acc ->
      cond do
        not is_binary(stat_name) ->
          add_error(acc, :stats, "stat names must be strings")

        stat_name not in valid_stats ->
          add_error(acc, :stats, "#{stat_name} is not a valid stat for #{item_type}")

        not is_number(stat_value) ->
          add_error(acc, :stats, "#{stat_name} value must be a number")

        stat_value < 0 ->
          add_error(acc, :stats, "#{stat_name} value cannot be negative")

        true ->
          acc
      end
    end)
  end

  # Get valid stats for a given item type
  defp get_valid_stats_for_type("weapon"), do: @weapon_stats ++ @general_stats
  defp get_valid_stats_for_type(type) when type in ["shield", "head", "body", "legs", "feet"], do: @armor_stats ++ @general_stats
  defp get_valid_stats_for_type(type) when type in ["ring", "necklace"], do: @general_stats
  defp get_valid_stats_for_type(_), do: []

  @doc """
  Get the total stats for an item, combining base stats with any bonuses
  """
  def get_total_stats(%__MODULE__{stats: stats}) when is_map(stats), do: stats
  def get_total_stats(%__MODULE__{stats: nil}), do: %{}

  @doc """
  Check if an item has a specific stat
  """
  def has_stat?(%__MODULE__{stats: stats}, stat_name) when is_map(stats) do
    Map.has_key?(stats, stat_name)
  end
  def has_stat?(%__MODULE__{stats: nil}, _stat_name), do: false

  @doc """
  Get a specific stat value from an item
  """
  def get_stat(%__MODULE__{stats: stats}, stat_name) when is_map(stats) do
    Map.get(stats, stat_name, 0)
  end
  def get_stat(%__MODULE__{stats: nil}, _stat_name), do: 0
end
