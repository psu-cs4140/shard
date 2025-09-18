defmodule Shard.World.Monster do
  use Ecto.Schema
  import Ecto.Changeset

  @level_min 1
  @level_max 50

  schema "monsters" do
    field :name, :string
    field :slug, :string
    field :species, :string
    field :description, :string
    field :level, :integer
    field :hp, :integer
    field :attack, :integer
    field :defense, :integer
    field :speed, :integer
    field :xp_drop, :integer
    field :element, Ecto.Enum, values: [:neutral, :fire, :water, :earth, :air, :lightning, :poison], default: :neutral
    field :ai, Ecto.Enum, values: [:passive, :aggressive, :defensive, :cowardly], default: :passive
    field :spawn_rate, :integer
    field :room_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(monster, attrs) do
    monster
    |> cast(attrs, [:name, :slug, :species, :description, :level, :hp, :attack, :defense, :speed, :xp_drop, :element, :ai, :spawn_rate, :room_id])
    |> validate_required([:name, :level, :hp, :attack, :defense, :speed, :xp_drop, :element, :ai, :spawn_rate])
    |> update_change(:name, &String.trim/1)
    |> put_slug_if_missing()
    |> validate_number(:level, greater_than_or_equal_to: @level_min, less_than_or_equal_to: @level_max)
    |> validate_number(:hp, greater_than_or_equal_to: 1)
    |> validate_number(:attack, greater_than_or_equal_to: 1)
    |> validate_number(:defense, greater_than_or_equal_to: 0)
    |> validate_number(:speed, greater_than_or_equal_to: 1)
    |> validate_number(:xp_drop, greater_than_or_equal_to: 0)
    |> validate_number(:spawn_rate, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> foreign_key_constraint(:room_id)
    |> unique_constraint(:name)
    |> unique_constraint(:slug)
  end

  defp put_slug_if_missing(changeset) do
    case {get_field(changeset, :slug), get_field(changeset, :name)} do
      {nil, name} when is_binary(name) -> put_change(changeset, :slug, slugify(name))
      {<< >>, name} when is_binary(name) -> put_change(changeset, :slug, slugify(name))
      _ -> changeset
    end
  end

  defp slugify(nil), do: nil
  defp slugify(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
  end
end
