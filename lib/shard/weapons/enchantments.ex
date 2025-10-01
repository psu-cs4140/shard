defmodule Shard.Weapons.Enchantments do
  use Ecto.Schema
  import Ecto.Changeset

  schema "enchantments" do
    field :name, :string
    field :modifier_type, :string
    field :modifier_value, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(enchantments, attrs, user_scope) do
    enchantments
    |> cast(attrs, [:name, :modifier_type, :modifier_value])
    |> validate_required([:name, :modifier_type, :modifier_value])

  end
end
