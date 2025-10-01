defmodule Shard.Weapons.Classes do
  use Ecto.Schema
  import Ecto.Changeset

  schema "weapon_classes" do
    field :name, :string
    field :damage_type_id, :id
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(classes, attrs, user_scope) do
    classes
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> put_change(:user_id, user_scope.user.id)
  end
end
