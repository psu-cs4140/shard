defmodule Shard.Achievements.Achievement do
  use Ecto.Schema
  import Ecto.Changeset

  schema "achievements" do
    field :name, :string
    field :description, :string
    field :icon, :string
    field :category, :string
    field :points, :integer, default: 0
    field :hidden, :boolean, default: false
    field :requirements, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(achievement, attrs) do
    achievement
    |> cast(attrs, [:name, :description, :icon, :category, :points, :hidden, :requirements])
    |> validate_required([:name, :description, :category, :points])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:description, min: 1, max: 500)
    |> validate_number(:points, greater_than_or_equal_to: 0)
    |> unique_constraint(:name)
  end
end
