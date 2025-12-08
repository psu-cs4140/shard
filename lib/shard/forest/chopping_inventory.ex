defmodule Shard.Forest.ChoppingInventory do
  @moduledoc """
  Stores woodcutting resources for a character.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Characters.Character

  schema "chopping_inventories" do
    field :wood, :integer, default: 0
    field :sticks, :integer, default: 0
    field :seeds, :integer, default: 0
    field :mushrooms, :integer, default: 0
    field :resin, :integer, default: 0

    belongs_to :character, Character

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chopping_inventory, attrs) do
    chopping_inventory
    |> cast(attrs, [:character_id, :wood, :sticks, :seeds, :mushrooms, :resin])
    |> validate_required([:character_id])
    |> validate_number(:wood, greater_than_or_equal_to: 0)
    |> validate_number(:sticks, greater_than_or_equal_to: 0)
    |> validate_number(:seeds, greater_than_or_equal_to: 0)
    |> validate_number(:mushrooms, greater_than_or_equal_to: 0)
    |> validate_number(:resin, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:character_id)
    |> unique_constraint(:character_id)
  end
end
