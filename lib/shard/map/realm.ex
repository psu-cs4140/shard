defmodule Shard.Map.Realm do
  use Ecto.Schema
  import Ecto.Changeset

  schema "realms" do
    field :name, :string
    field :description, :string
    field :is_active, :boolean, default: true

    has_many :rooms, Shard.Map.Room

    timestamps()
  end

  @doc false
  def changeset(realm, attrs) do
    realm
    |> cast(attrs, [:name, :description, :is_active])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
