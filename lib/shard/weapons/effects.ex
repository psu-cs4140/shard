defmodule Shard.Weapons.Effects do
  use Ecto.Schema
  import Ecto.Changeset

  schema "effects" do
    field :name, :string
    field :modifier_type, :string
    field :modifier_value, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(effects, attrs, user_scope) do
    effects
    |> cast(attrs, [:name, :modifier_type, :modifier_value])
    |> validate_required([:name, :modifier_type, :modifier_value])
  end
end
