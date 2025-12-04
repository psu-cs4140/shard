defmodule Shard.Mining.MiningInventory do
  @moduledoc """
  Schema for storing mining resources per character.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Characters.Character

  schema "mining_inventories" do
    field :stone, :integer, default: 0
    field :coal, :integer, default: 0
    field :copper, :integer, default: 0
    field :iron, :integer, default: 0
    field :gems, :integer, default: 0

    belongs_to :character, Character

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(mining_inventory, attrs) do
    mining_inventory
    |> cast(attrs, [:character_id, :stone, :coal, :copper, :iron, :gems])
    |> validate_required([:character_id])
    |> validate_number(:stone, greater_than_or_equal_to: 0)
    |> validate_number(:coal, greater_than_or_equal_to: 0)
    |> validate_number(:copper, greater_than_or_equal_to: 0)
    |> validate_number(:iron, greater_than_or_equal_to: 0)
    |> validate_number(:gems, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:character_id)
    |> unique_constraint(:character_id)
  end
end