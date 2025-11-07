defmodule Shard.Characters.Character do
  @moduledoc """
  This module defines the character schema and the changeset so
  changes can be made to a character's fields
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Users.User
  alias Shard.Items.{CharacterInventory, HotbarSlot}
  alias Shard.Map.Zone
  alias Shard.Spells.CharacterSpell

  schema "characters" do
    field :name, :string
    field :level, :integer, default: 1
    field :class, :string
    field :race, :string
    field :health, :integer, default: 100
    field :mana, :integer, default: 50
    field :strength, :integer, default: 10
    field :dexterity, :integer, default: 10
    field :intelligence, :integer, default: 10
    field :constitution, :integer, default: 10
    field :experience, :integer, default: 0
    field :gold, :integer, default: 0
    field :location, :string, default: "starting_town"
    field :description, :string
    field :is_active, :boolean, default: true

    belongs_to :user, User
    belongs_to :current_zone, Zone
    has_many :character_inventories, CharacterInventory
    has_many :hotbar_slots, HotbarSlot
    has_many :character_spells, CharacterSpell
    many_to_many :spells, Shard.Spells.Spells, join_through: CharacterSpell

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(character, attrs) do
    character
    |> cast(attrs, [
      :name,
      :level,
      :class,
      :race,
      :health,
      :mana,
      :strength,
      :dexterity,
      :intelligence,
      :constitution,
      :experience,
      :gold,
      :location,
      :description,
      :is_active,
      :user_id,
      :current_zone_id
    ])
    |> validate_required([:name, :class, :race])
    |> validate_length(:name, min: 2, max: 50)
    |> validate_inclusion(:class, ["warrior", "mage", "rogue", "cleric", "ranger"])
    |> validate_inclusion(:race, ["human", "elf", "dwarf", "halfling", "orc"])
    |> validate_number(:level, greater_than: 0, less_than_or_equal_to: 100)
    |> validate_number(:health, greater_than_or_equal_to: 0)
    |> validate_number(:mana, greater_than_or_equal_to: 0)
    |> validate_number(:strength, greater_than: 0, less_than_or_equal_to: 100)
    |> validate_number(:dexterity, greater_than: 0, less_than_or_equal_to: 100)
    |> validate_number(:intelligence, greater_than: 0, less_than_or_equal_to: 100)
    |> validate_number(:constitution, greater_than: 0, less_than_or_equal_to: 100)
    |> validate_number(:experience, greater_than_or_equal_to: 0)
    |> validate_number(:gold, greater_than_or_equal_to: 0)
    |> unique_constraint(:name)
  end
end
