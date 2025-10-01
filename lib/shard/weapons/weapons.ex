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
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(weapons, attrs, user_scope) do
    weapons
    |> cast(attrs, [:name, :damage, :gold_value, :description])
    |> validate_required([:name, :damage, :gold_value, :description])
    |> put_change(:user_id, user_scope.user.id)
  end
end
